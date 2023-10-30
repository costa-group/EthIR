from opcodes import get_opcode
from memory_utils import arithemtic_operations
from sequence import Sequence

global K 
K = 10000

class JumpOriginAbstractState:          
    stack_pos = None
    ssequence = Sequence(sequence = ("PUSH2","EXP","DUP2","SLOAD","DUP2","PUSH8","MUL","NOT","AND","SWAP1","DUP4","PUSH8","AND","MUL","OR","SWAP1","SSTORE","POP"), stack_position = 4)
    lsequence = Sequence(sequence = ("PUSH2","EXP","SWAP1","DIV","DUP1","ISZERO","PUSH","MUL","OR","PUSH8","AND","PUSH4","AND","JUMP"), stack_position=3)
    
    def __init__(self,stack_pos,stack,storage,debug,jump_directions:list):
        self.stack_pos = stack_pos
        self.stack = stack
        self.jump_directions = jump_directions
        self.debug = debug
        self.storage = storage



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
                    
        for skey in self.storage:
            if skey not in state.storage:
                return False
            else:
                if not self.storage[skey].issubset(state.stack[skey]):
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

        return JumpOriginAbstractState(self.stack_pos, res_stack, self.storage, self.debug, self.jump_directions)

    def process_instruction(self, instr: str, pc):
        
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        self.ssequence.is_in_sequence(op_code, stack)
        self.lsequence.is_in_sequence(op_code, stack)

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
            if self.lsequence.get_storage_value() is None:
                direction = stack.pop(top)
            else:
                direction = set(self.lsequence.get_storage_value())
                stack.pop(top)
            print(f"Jump direction is {direction}")
            self.jump_directions.append(direction)
            treated = True

        elif op_code == "JUMPI":
            direction = stack.pop(top)
            top -= 1
            stack.pop(top)
            print(f"Jumpi direction is {direction}")
            self.jump_directions.append(direction)
            treated = True

        elif op_code.startswith("SSTORE") and not instr.endswith('?'):
            if self.ssequence.get_storage_value() is None:
                direction = stack.pop(top)
                top -= 1
                values = stack.pop(top)
            else:
                values = self.ssequence.get_storage_value()
                stack.pop(top)
                top -= 1
                stack.pop(top)
            top -= 1
            direction = instr.split()[1].split('_')

            if self.storage.get(direction[0]) is not None:
                if len(direction) == 1:
                    self.storage[direction[0]].union(values)
                else:
                    self.storage[direction[0]][direction[1]] = set(values)

            else:
                if len(direction) == 1:
                    self.storage[direction[0]] = set(values)
                else:
                    self.storage[direction[0]] = {direction[1]: set(values)}
            treated = True

        elif op_code.startswith("SLOAD") and not instr.endswith('?'):
            direction = instr.split()[1]
            value = self.storage.get(direction)
            if value is None:
                stack[top] = {value}
            else:
                stack[top] = value
            top += 1

            treated = True


        if not treated:
            for i in range(stack_in):
                stack.pop(self.stack_pos-1-i,None)
            self.stack_pos -=stack_in
            for i in range(stack_out):
                stack[self.stack_pos] = set({"*"})
                self.stack_pos += 1
        else:
            self.stack_pos = min(stack_res, self.stack_pos)
        
        return JumpOriginAbstractState(stack_res, stack, self.storage, self.debug, self.jump_directions)
    
    def __repr__(self):
        return (" stack^" + str(self.stack_pos) + " = " + str(self.stack))