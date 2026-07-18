import json
import os
import re
import sys

import sympy

# Operators ordered so that multi-character operators are matched before
# their single-character prefixes (">=" before "=", etc). clpq uses "="
# for equality, not "==".
_OPERATORS = [">=", "<=", "=", ">", "<"]

_FLIPPED_OP = {
    "<": ">",
    "<=": ">=",
    ">": "<",
    ">=": "<=",
    "=": "!=",
    "!=": "="
}

_OP_SACO = {
    "<": "lt",
    "<=": "leq",
    ">": "gt",
    ">=": "geq",
    "=": "eq",
    "!=": "neq"
    }

def load_file(path):
    with open(path, "r") as f:
        return json.load(f)


def _normalize_int_types(signature):
    """Expand the bare 'uint'/'int' type aliases to their explicit 256-bit
    form ('uint256'/'int256'), leaving sized variants (uint8, int128, ...)
    untouched."""
    signature = re.sub(r"\buint\b", "uint256", signature)
    signature = re.sub(r"\bint\b", "int256", signature)
    return signature


def get_function_identifiers(data):
    """Return the identifier (signature) of every function in the file."""
    return [_normalize_int_types(function["signature"]) for function in data.get("functions", [])]


def get_state_variables_fields(data):
    """Map each state variable to field(gN), where N is its position
    (0-indexed) in the stateVariables list."""
    state_variables = data.get("stateVariables", [])
    return {variable: "field(g{})".format(i) for i, variable in enumerate(state_variables)}


def get_params_fields(params):
    """Map each function param to l(calldataloadN), where N is its position
    (0-indexed) in the params list."""
    return {param: "l(calldataload{})".format(i) for i, param in enumerate(params)}


def _split_operator(constraint):
    for op in _OPERATORS:
        idx = constraint.find(op)
        if idx != -1:
            return constraint[:idx].strip(), op, constraint[idx + len(op):].strip()
    return None


def _to_sympy_expr(expr_str):
    # Force every identifier found to be treated as a plain symbol, so
    # variable names that collide with sympy builtins (I, E, S, N, ...)
    # are not misinterpreted.
    names = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", expr_str))
    local_dict = {name: sympy.Symbol(name) for name in names}
    return sympy.sympify(expr_str, locals=local_dict)


def unify_constraint(constraint):
    """Rewrite a clpq constraint that expresses 'a - b > 0' (or the
    equivalent addition form '-a + b > 0') as 'a > b', unifying both
    representations into "one element is greater/lesser/equal than the
    other". Constraints that don't reduce to a two-term difference
    against zero are returned unchanged."""
    constraint = constraint.strip()
    split = _split_operator(constraint)
    if split is None:
        return constraint

    lhs, op, rhs = split

    if rhs == "0":
        expr_str = lhs
    elif lhs == "0":
        expr_str = rhs
        op = _FLIPPED_OP[op]
    else:
        return constraint

    try:
        expr = _to_sympy_expr(expr_str)
    except (sympy.SympifyError, TypeError):
        return constraint

    terms = expr.as_ordered_terms()
    if len(terms) != 2:
        return constraint

    positive, negative = None, None
    for term in terms:
        if term.could_extract_minus_sign():
            negative = -term
        else:
            positive = term

    if positive is None or negative is None:
        return constraint

    return "{}{}{}".format(positive, op, negative)


def replace_identifiers(constraint, identifiers_mapping):
    """Replace every occurrence of a name in constraint with its mapped
    representation, longest names first so that no name is replaced as a
    substring of another."""
    for name in sorted(identifiers_mapping, key=len, reverse=True):
        pattern = r"\b{}\b".format(re.escape(name))
        constraint = re.sub(pattern, identifiers_mapping[name], constraint)
    return constraint


def to_saco_constraint(constraint):
    """Rewrite 'left OP right' as the SACO predicate 'opname(left,right)',
    using _OP_SACO for the operator name. Longer operators are matched
    before their single-character prefixes ("!=" before "=", ">=" before
    ">", etc)."""
    constraint = constraint.strip()
    for op in ("!=", ">=", "<=", "=", ">", "<"):
        idx = constraint.find(op)
        if idx != -1:
            left = constraint[:idx].strip()
            right = constraint[idx + len(op):].strip()
            return "{}({},{})".format(_OP_SACO[op], left, right)
    return constraint


def get_unified_constraints(test_case, identifiers_mapping):
    unified = [unify_constraint(constraint) for constraint in test_case.get("constraints_clpq", [])]
    substituted = [replace_identifiers(constraint, identifiers_mapping) for constraint in unified]
    return [to_saco_constraint(constraint) for constraint in substituted]


def get_concrete_values(test_case, identifiers_mapping):
    return [replace_identifiers(value, identifiers_mapping) for value in test_case.get("concrete_values", [])]


def summarize_test_cases(data):
    """Build a dict associating each function's identifier with its
    summarized info: params (renamed to l(calldataloadN) by position) and the
    unified clpq constraints for each of its test cases."""
    state_variables_fields = get_state_variables_fields(data)
    result = {}
    for function in data.get("functions", []):
        identifier = _normalize_int_types(function["signature"])
        params = function.get("params", [])
        params_fields = get_params_fields(params)
        identifiers_mapping = {**state_variables_fields, **params_fields}
        function_summary = {
            "identifier": identifier,
            "params": [params_fields[param] for param in params],
            "test_cases": [],
        }
        for test_case in function.get("test_cases", []):
            function_summary["test_cases"].append({
                "id": test_case.get("id"),
                "kind": test_case.get("kind"),
                "concrete_values": get_concrete_values(test_case, identifiers_mapping),
                "constraints_clpq": get_unified_constraints(test_case, identifiers_mapping),
            })
        result[identifier] = function_summary
    return result


if __name__ == "__main__":
    data = load_file(sys.argv[1])

    print("Function identifiers:", get_function_identifiers(data))
    print("State variables fields:", get_state_variables_fields(data))

    for identifier, function_summary in summarize_test_cases(data).items():
        print(identifier, function_summary)
