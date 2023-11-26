from opcodes import get_opcode
from sequence import Sequence

global K
K = 10000


class JumpOriginAbstractState:
    ssequence = Sequence(
        sequence=(
            "PUSH2",
            "EXP",
            "DUP2",
            "SLOAD",
            "DUP2",
            "PUSH8",
            "MUL",
            "NOT",
            "AND",
            "SWAP1",
            "DUP4",
            "PUSH8",
            "AND",
            "MUL",
            "OR",
            "SWAP1",
            "SSTORE",
            "POP",
        ),
        stack_position=4,
    )
    lsequence = Sequence(
        sequence=(
            "PUSH2",
            "EXP",
            "SWAP1",
            "DIV",
            "DUP1",
            "ISZERO",
            "PUSH",
            "MUL",
            "OR",
            "PUSH8",
            "AND",
            "PUSH4",
            "AND",
            "JUMP",
        ),
        stack_position=3,
    )

    stack_next_position: int
    stack: dict
    jump_directions: list
    debug: bool
    storage: dict

    def __init__(
        self,
        _: int,
        stack: dict,
        storage: dict,
        debug: bool,
        jump_directions: list,
    ):
        self.stack_next_position = len(stack)
        self.stack = stack
        self.jump_directions = jump_directions
        self.debug = debug
        self.storage = storage

    def leq(self, state: "JumpOriginAbstractState") -> bool:
        if len(self.stack) != len(state.stack):
            print("JUMP ORIGIN ANALYSIS WARNING: Different stacks in leq !!! ")
            print("JUMP ORIGIN ANALYSIS WARNING: " + str(self))
            print("JUMP ORIGIN ANALYSIS WARNING: " + str(state))
        for skey in self.stack:
            if skey not in state.stack:
                return False
            else:
                if not self.stack[skey].issubset(state.stack[skey]):
                    return False

        for skey in self.storage:
            if skey not in state.storage:
                return False
            else:
                if isinstance(self.storage[skey], set):
                    if not self.storage[skey].issubset(state.storage[skey]):
                        return False
                else:
                    word = set()
                    for value in self.storage[skey].values():
                        word.union(value)
                    if not word.issubset(state.storage[skey]):
                        return False

        return True

    def lub(self, state: "JumpOriginAbstractState") -> "JumpOriginAbstractState":
        if self.debug:
            print("DOING LUB: " + str(self.stack) + " " + str(state.stack))
        if len(self.stack) != len(state.stack):
            print("JUMP ORIGIN ANALYSIS WARNING: Different stacks in lub !!! ")
            print("JUMP ORIGIN ANALYSIS WARNING: " + str(self))
            print("JUMP ORIGIN ANALYSIS WARNING: " + str(state))

        res_stack = self.stack.copy()

        for skey in state.stack:
            if skey in res_stack:
                res_stack[skey] = res_stack[skey].union(state.stack[skey])
            else:
                res_stack[skey] = state.stack[skey]

        res_storage = self.storage.copy()

        for skey in state.storage:
            if skey in res_storage:
                if isinstance(res_storage[skey], set) and isinstance(
                    state.storage[skey], set
                ):
                    res_storage[skey] = res_storage[skey].union(state.storage[skey])
                elif isinstance(res_storage[skey], dict) and isinstance(
                    state.storage[skey], dict
                ):
                    for key, value in state.storage[skey].items():
                        res_storage[skey][key] = res_storage[skey][key].union(value)
                elif isinstance(res_storage[skey], set) and isinstance(
                    state.storage[skey], dict
                ):
                    set_value = res_storage[skey]
                    res_storage[skey] = state.storage[skey]
                    res_storage[skey][0].union(set_value)
                elif isinstance(res_storage[skey], dict) and isinstance(
                    state.storage[skey], set
                ):
                    res_storage[skey][0].union(state.storage[skey])
            else:
                res_storage[skey] = state.storage[skey]

        return JumpOriginAbstractState(
            len(self.stack),
            res_stack,
            res_storage,
            self.debug,
            self.jump_directions,
        )

    def process_instruction(self, instr: str, pc) -> "JumpOriginAbstractState":
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_result_length = len(self.stack) - stack_in + stack_out
        top = len(self.stack) - 1

        self.ssequence.register_instruction(op_code, stack)
        self.lsequence.register_instruction(op_code, stack)

        treated = False

        if op_code.startswith("PUSH"):
            if len(instr.split()) == 2:
                strvalue = instr.split()[1]
                value = int(strvalue, 16)
            else:
                value = -1

            if 0 <= value < K:
                stack[len(stack)] = set({value})
            else:
                stack[len(stack)] = set({"*"})
            top += 1
            treated = True

        elif op_code.startswith("DUP"):
            position = len(stack) - 1 - int(op_code[3:], 10) + 1

            if position in stack:
                stack[len(stack)] = stack[position]
            top += 1
            treated = True

        elif op_code.startswith("SWAP", 0):
            position = len(stack) - 1 - int(op_code[4:], 10)

            if position in stack and top not in stack:
                stack[len(stack) - 1] = stack[position]
                stack.pop(position, None)
            elif top in stack and position not in stack:
                stack[position] = stack[len(stack) - 1]
                stack.pop(len(stack) - 1, None)
            elif top in stack and position in stack:
                valpos = stack[position]
                stack[position] = stack[len(stack) - 1]
                stack[len(stack) - 1] = valpos
                treated = True

        elif op_code == "JUMP":
            sloaded_values = self.lsequence.get_storage_value()

            if sloaded_values is None:
                direction = stack.pop(len(stack) - 1)
                top -= 1
            else:
                direction = sloaded_values
                stack.pop(len(stack) - 1)
                top -= 1
                print(f"Jump direction is {direction}")
                self.jump_directions.append((self.parse_pc(pc), direction))

            treated = True

        elif op_code == "JUMPI":
            sloaded_values = self.lsequence.get_storage_value()

            if sloaded_values is None:
                direction = stack.pop(len(stack) - 1)
            else:
                direction = sloaded_values
                stack.pop(len(stack) - 1)
                print(f"Jumpi direction is {direction}")
                self.jump_directions.append((self.parse_pc(pc), direction))
            top -= 1
            stack.pop(len(stack) - 1)
            top -= 1

            treated = True

        elif op_code.startswith("SSTORE"):
            if instr.endswith("?"):
                direction = [-1]

            else:
                direction = instr.split()[1].split(
                    "_"
                )  # instruction can be in the form of either SSTORE 0 or SSTORE 0_0

            sstore_values = self.ssequence.get_storage_value()
            if sstore_values is None:
                stack.pop(len(stack) - 1)  # direction
                top -= 1
                values = stack.pop(len(stack) - 1)  # value
                top -= 1
            else:
                values = sstore_values
                stack.pop(len(stack) - 1)  # direction
                top -= 1
                stack.pop(len(stack) - 1)  # value
                top -= 1

            if self.storage.get(direction[0]) is None:
                if len(direction) == 1:
                    self.storage[direction[0]] = values
                else:
                    self.storage[direction[0]] = {direction[1]: values}

            else:
                if len(direction) == 1:
                    if isinstance(self.storage[direction[0]], dict):
                        self.storage[direction[0]] = self.storage[direction[0]][
                            direction[0]
                        ].union(values)
                    else:
                        self.storage[direction[0]] = self.storage[direction[0]].union(
                            values
                        )
                    self.storage[direction[0]] = self.storage[direction[0]].union(
                        values
                    )
                else:
                    self.storage[direction[0]][direction[1]] = values
            treated = True

        elif op_code.startswith("SLOAD"):
            direction = instr.split()[1]
            # get the value at the direction or if no explicit value has been stored, load the values that could go anywhere
            value = self.storage.get(direction, self.storage[-1])
            if value is None:
                stack[len(stack) - 1] = {None}
            else:
                # If anything could be anywhere or the value loaded is allready anythin introduce '*'
                if "*" in value or "*" in self.storage[-1]:
                    stack[len(stack) - 1] = {"*"}
                # join the value at the requested direction and all values that could go anywhere
                else:
                    if isinstance(value, dict):
                        for slot in value.values():
                            slot = slot.union(self.storage[-1])
                        stack[len(stack) - 1] = value
                    else:
                        stack[len(stack) - 1] = value.union(self.storage[-1])

            treated = True

        for key in stack.keys():
            if key >= len(stack):
                print()

        if not treated:
            # eliminates the positions used by the instruction if stack_in > stack_out
            for i in range(stack_in):
                stack.pop(len(stack) - 1, None)
                top -= 1
            self.stack_next_position -= stack_in
            # fills the new positions with unknown if stack_out > stack_in
            for i in range(stack_out):
                stack[len(stack)] = set({"*"})
                self.stack_next_position += 1
                top += 1

        return JumpOriginAbstractState(
            len(self.stack), stack, self.storage, self.debug, self.jump_directions
        )

    def parse_pc(self, pc):
        return int(pc.split(":")[0])

    def __repr__(self):
        return " stack^" + str(len(self.stack)) + " = " + str(self.stack)
