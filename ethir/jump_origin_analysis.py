from opcodes import get_opcode
from memory_utils import arithemtic_operations
from sequence import Sequence

global K 
K = 10000

class JumpOriginAbstractState:          
    ssequence = Sequence(sequence = ("PUSH2","EXP","DUP2","SLOAD","DUP2","PUSH8","MUL","NOT","AND","SWAP1","DUP4","PUSH8","AND","MUL","OR","SWAP1","SSTORE","POP"), stack_position = 4)
    lsequence = Sequence(sequence = ("PUSH2","EXP","SWAP1","DIV","DUP1","ISZERO","PUSH","MUL","OR","PUSH8","AND","PUSH4","AND","JUMP"), stack_position=3)

    stack_next_position: int
    stack: dict
    jump_directions: list
    debug: bool
    storage: dict
    
    def __init__(self,stack_pos: int,stack: dict,storage: dict,debug: bool,jump_directions:list):
        self.stack_next_position = stack_pos
        self.stack = stack
        self.jump_directions = jump_directions
        self.debug = debug
        self.storage = storage



    def leq(self, state: 'JumpOriginAbstractState') -> bool:
        if self.stack_next_position != state.stack_next_position: 
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

    def lub(self, state: 'JumpOriginAbstractState')-> 'JumpOriginAbstractState':
        if self.debug:
            print ("DOING LUB: " + str(self.stack) + " " + str(state.stack))
        if self.stack_next_position != state.stack_next_position: 
            print("CONSTANT ANALYSIS WARNING: Different stacks in lub !!! ")
            print("CONSTANT ANALYSIS WARNING: " + str(self))
            print("CONSTANT ANALYSIS WARNING: " + str(state))

        res_stack = self.stack.copy()

        for skey in state.stack: 
            if skey in res_stack: 
                res_stack[skey] = res_stack[skey].union(state.stack[skey])
            else:
                res_stack[skey] = state.stack[skey]

        return JumpOriginAbstractState(self.stack_next_position, res_stack, self.storage, self.debug, self.jump_directions)

    def process_instruction(self, instr: str, pc) -> 'JumpOriginAbstractState':
        
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_result_length = self.stack_next_position - stack_in + stack_out
        top = self.stack_next_position-1

        self.ssequence.register_instruction(op_code, stack)
        self.lsequence.register_instruction(op_code, stack)

        treated = False

        if op_code.startswith("PUSH"):
            strvalue = instr.split()[1]
            value = int(strvalue, 16)

            if 0 <= value < K:
                stack[self.stack_next_position] = set({value})
            else:
                stack[self.stack_next_position] = set({'*'})
            treated = True

        elif op_code.startswith("DUP"):
            position = top - int(op_code[3:], 10)+1

            if position in stack:
                stack[self.stack_next_position] = stack[position]
            treated = True
        
        elif op_code.startswith("SWAP",0):
            position = top-int(op_code[4:], 10)

            if position in stack and top not in stack:
                stack[top] = stack[position] 
                stack.pop(position,None)
            elif top in stack and position not in stack:
                stack[position] = stack[top]
                stack.pop(top,None) 
            elif top in stack and position in stack:
                valpos = stack[position] 
                stack[position] = stack[top] 
                stack[top] = valpos
                treated = True

        elif op_code == "JUMP":
            sloaded_values = self.lsequence.get_storage_value()

            if sloaded_values is None:
                direction = stack.pop(top)
            else:
                direction = sloaded_values
                stack.pop(top)

            print(f"Jump direction is {direction}")
            self.jump_directions.append(direction)
            treated = True

        elif op_code == "JUMPI":
            sloaded_values = self.lsequence.get_storage_value()

            if sloaded_values is None:
                direction = stack.pop(top)
            else:
                direction = sloaded_values
                stack.pop(top)
            top -= 1
            stack.pop(top)

            print(f"Jumpi direction is {direction}")
            self.jump_directions.append(direction)
            treated = True

        elif op_code.startswith("SSTORE") and not instr.endswith('?'):
            sstore_values = self.ssequence.get_storage_value()
            if sstore_values is None:
                stack.pop(top) #direction
                top -= 1
                values = stack.pop(top)#value
                top -= 1
            else:
                values = sstore_values
                stack.pop(top)#direction
                top -= 1
                stack.pop(top)#value
                top -= 1
            
            direction = instr.split()[1].split('_') # instruction can be in the form of either SSTORE 0 or SSTORE 0_0

            if self.storage.get(direction[0]) is None:
                if len(direction) == 1:
                    self.storage[direction[0]] = values
                else:
                    self.storage[direction[0]] = {direction[1]: values}

            else:
                if len(direction) == 1:
                    self.storage[direction[0]] = self.storage[direction[0]].union(values)
                else:
                    self.storage[direction[0]][direction[1]] = values
            treated = True

        elif op_code.startswith("SLOAD") and not instr.endswith('?'):
            direction = instr.split()[1]
            value = self.storage.get(direction)
            if value is None:
                stack[top] = {None}
            else:
                stack[top] = value
            top += 1

            treated = True


        if not treated:
            # eliminates the positions used by the instruction if stack_in > stack_out
            for i in range(stack_in):
                stack.pop(self.stack_next_position-1-i,None)
            self.stack_next_position -=stack_in
            # fills the new positions with unknown if stack_out > stack_in
            for i in range(stack_out):
                stack[self.stack_next_position] = set({"*"})
                self.stack_next_position += 1
        
        return JumpOriginAbstractState(stack_result_length, stack, self.storage, self.debug, self.jump_directions)
    
    def __repr__(self):
        return (" stack^" + str(self.stack_next_position) + " = " + str(self.stack))