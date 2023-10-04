from opcodes import get_opcode
from memory_utils import arithemtic_operations

global K 
K = 10000

class JumpOriginAbstractState:          
    stack_pos = None
    
    def __init__(self,stack_pos,stack,debug, jump_directions:list):
        self.stack_pos = stack_pos
        self.stack = stack
        self.jump_directions = jump_directions
        self.debug = debug

    def leq(self, state):
        if self.stack_pos != state.stack_pos: 
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
            print ("DOING LUB: " + str(self.stack) + " " + str(state.stack))
        if self.stack_pos != state.stack_pos: 
            print("CONSTANT ANALYSIS WARNING: Different stacks in lub !!! ")
            print("CONSTANT ANALYSIS WARNING: " + str(self))
            print("CONSTANT ANALYSIS WARNING: " + str(state))

        res_stack = self.stack.copy(); 

        for skey in state.stack: 
            if skey in res_stack: 
                res_stack[skey] = res_stack[skey].union(state.stack[skey])
            else:
                res_stack[skey] = state.stack[skey]

        return JumpOriginAbstractState(self.stack_pos, res_stack, self.debug, self.jump_directions)

    def process_instruction(self, instr: str, pc):
        
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        treated = False

        if op_code.startswith("PUSH"):
            strvalue = instr.split()[1]
            value = int(strvalue, 16)
            if 0 <= value < K:
                stack[self.stack_pos] = set({value})
            else:
                stack[self.stack_pos] = set({'*'})
            treated = True
        
        
        elif op_code == "POP":
            stack.pop(top,None)
            treated = True

        elif op_code.startswith("DUP"):
            position = top - int(op_code[3:], 10)+1
            if position in stack:
                stack[self.stack_pos] = stack[position]
            treated = True
        
        elif op_code.startswith("SWAP",0):
            position = top-int(op_code[4:], 10)
            if position in stack and not(top in stack):
                stack[top] = stack[position] 
                stack.pop(position,None)
            elif top in stack and not(position in stack): 
                stack[position] = stack[top] 
                stack.pop(top,None)
            elif top in stack and position in stack:
                valpos = stack[position] 
                stack[position] = stack[top]
                stack[top] = valpos
            treated = True


        elif op_code == "JUMP":
            direction = stack.pop(top)
            print(f"Jump direction is {direction}")
            self.jump_directions.append(direction)

        elif op_code == "JUMPI":
            direction = stack.pop(top)
            top -= 1
            stack.pop(top)
            print(f"Jumpi direction is {direction}")
            self.jump_directions.append(direction)

        if not treated:
            for i in range(stack_in):
                stack.pop(self.stack_pos-1-i,None)
            self.stack_pos -=stack_in
            for i in range(stack_out):
                stack[self.stack_pos] = set({"*"})
                self.stack_pos += 1
        else:
            for i in range(stack_res,self.stack_pos): 
                stack.pop(i,None)
            self.stack_pos = min(stack_res, self.stack_pos)
        
        return JumpOriginAbstractState(stack_res, stack, self.debug, self.jump_directions)
    
    def __repr__(self):
        return (" stack^" + str(self.stack_pos) + " = " + str(self.stack))