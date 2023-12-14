from opcodes import get_opcode
from memory_utils import arithemtic_operations

global K
K = 256


class ConstantsAbstractState:
    stack_pos = None

    def __init__(self, stack_pos, stack, debug):
        self.stack_pos = stack_pos
        self.stack = stack
        self.debug = debug

    def leq(self, state):
        if self.debug and self.stack_pos != state.stack_pos:
            print("CONSTANT ANALYSIS WARNING: Different stacks in leq !!! ")
            print("CONSTANT ANALYSIS WARNING: " + str(self))
            print("CONSTANT ANALYSIS WARNING: " + str(state))
        for skey in self.stack:
            if skey not in state.stack:
                return False
            else:
                if not self.stack[skey].issubset(state.stack[skey]):
                    return False
        return True

    def lub(self, state):
        if self.debug:
            print("DOING LUB: " + str(self.stack) + " " + str(state.stack))
        if self.debug and self.stack_pos != state.stack_pos:
            print("CONSTANT ANALYSIS WARNING: Different stacks in lub !!! ")
            print("CONSTANT ANALYSIS WARNING: " + str(self))
            print("CONSTANT ANALYSIS WARNING: " + str(state))

        res_stack = self.stack.copy()
        for skey in state.stack:
            if skey in res_stack:
                res_stack[skey] = res_stack[skey].union(state.stack[skey])
            else:
                res_stack[skey] = state.stack[skey]

        return ConstantsAbstractState(self.stack_pos, res_stack, self.debug)

    def process_instruction(self, instr, _):
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos - 1

        treated = False
        # We save in the stack special memory addresses
        if op_code == "PUSH1":
            strvalue = instr.split()[1]
            value = int(strvalue, 16)
            if value >= 0 and value % 32 == 0 and value < K:
                stack[self.stack_pos] = set({value})
            treated = True

        elif op_code == "POP":
            treated = True
            stack.pop(top, None)

        elif op_code.startswith("DUP", 0):
            treated = True
            position = top - int(op_code[3:], 10) + 1
            if position in stack:
                stack[self.stack_pos] = stack[position]

        elif op_code.startswith("SWAP", 0):
            treated = True
            position = top - int(op_code[4:], 10)
            if position in stack and not (top in stack):
                stack[top] = stack[position]
                stack.pop(position, None)
            elif top in stack and not (position in stack):
                stack[position] = stack[top]
                stack.pop(top, None)
            elif top in stack and position in stack:
                valpos = stack[position]
                stack[position] = stack[top]
                stack[top] = valpos

        if not treated:
            if not op_code.startswith("DUP", 0) and not op_code.startswith("SWAP", 0):
                for i in range(self.stack_pos - stack_in, self.stack_pos):
                    stack.pop(i, None)
        else:
            for i in range(stack_res, self.stack_pos):
                stack.pop(i, None)

        return ConstantsAbstractState(stack_res, stack, self.debug)

    def get_constants(self, stackpos):
        return self.stack.get(stackpos)

    def __repr__(self):
        return " stack^" + str(self.stack_pos) + " = " + str(self.stack)
