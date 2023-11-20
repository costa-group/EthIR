from opcodes import get_opcode
from memory_utils import is_mload, is_mstore
from memory_utils import arithemtic_operations

class StorageAbstractState:          
    
    @staticmethod
    def initglobals (accesses,offsets): 
        StorageAbstractState.accesses = accesses
        StorageAbstractState.ofssets = offsets

    def __init__(self,stack_pos,stack,memory,debug):
        self.stack_pos = stack_pos
        self.stack = stack
        self.memory = memory
        self.debug = debug
        
    def get_stack_pos (self): 
        return self.stack_pos

    def get_stack (self): 
        return self.stack

    def get_memory (self): 
        return self.memory

    def leq (self,state): 
        for skey in self.get_stack(): 
            if (skey not in state.stack or 
                not (set(self.get_stack()[skey]) <= set(state.stack[skey]))):
                return False

        for mkey in self.get_memory(): 
            if (mkey not in state.memory or 
                not (set(self.get_memory()[mkey]) <= set(state.memory[mkey]))):
                return False
        
        return True

    def lub (self,state): 
        if self.debug and self.stack_pos != state.get_stack_pos(): 
            print("MEM ANALYSIS WARNING: Different stacks in lub !!! ")
            print("MEM ANALYSIS WARNING: " + str(self))
            print("MEM ANALYSIS WARNING: " + str(state))


        res_stack = self.stack.copy(); 
        res_memory = self.memory.copy();

        for skey in state.get_stack(): 
            if skey in res_stack: 
                res_stack[skey] = list(set(res_stack[skey] + state.get_stack()[skey]))
            else:
                res_stack[skey] = state.get_stack()[skey]

        for mkey in state.get_memory(): 
            if mkey in res_memory: 
                res_memory[mkey] = list(set(res_memory[mkey] + state.get_memory()[mkey]))
            else:
                res_memory[mkey] = state.get_memory()[mkey]

        return StorageAbstractState(self.stack_pos, res_stack, res_memory, self.debug)


    def process_instruction (self,instr,pc):
       
        
        op_code = instr.split()[0]
        if len(instr.split()) > 1:
            op_operand = instr.split()[1]

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        # We save in the stack special memory addresses        

        if is_mstore(instr,"0") and top-1 in stack:
            memory[0] = stack[top-1]
        
        elif is_mload(instr,"0"):
            stack[top] = memory[0]

        elif is_mstore(instr,"32"):
            if top-1 in stack:
                memory[20] =  stack[top-1]

        elif is_mload(instr,"32"):
            stack[top] = memory[20]

        # TODO Completar con 0-32 o con 0-64
        elif op_code == "KECCAK256":
            val = "k(" + str(memory[0][0]) + ")"
            stack[top-1] = [val]

        elif op_code == "PUSH0":
            stack[self.stack_pos] = [0] 

        # elif op_code == "PUSH1": 
        # TODO Decidir que push guardar... 
        elif (op_code == "PUSH1"  and 
             (int(op_operand,16) < 10 or 
              int(op_operand,16) == 32 or 
              int(op_operand,16) == 64 or 
              int(op_operand,16) == 10 )): 
            stack[self.stack_pos] = [str(int(op_operand,16))]

        # TODO Completar el ADD (ojo: kecack + offset)
        elif op_code == "ADD":
            if top in stack and top-1 in stack: 
                stack[top-1] = [str(stack[top]) + "+" + str(stack[top-1])]

        elif op_code == "SLOAD":
            self.add_read_access(pc,stack[top])

        elif op_code == "SSTORE":
            self.add_write_access(pc,stack[top])

        elif op_code == "POP":
            stack.pop(top,None)

        elif op_code.startswith("DUP",0):
            position = top-int(op_code[3:], 10)+1
            if position in stack:
                stack[self.stack_pos] = stack[position]

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

        for i in range(stack_res,self.stack_pos): 
            stack.pop(i,None)

        return StorageAbstractState(stack_res, stack, memory, self.debug)

    def add_read_access (self,pc, slot):
        print ("Adding a read access " + str(pc) + " " + str(slot))
        StorageAbstractState.accesses.add_read_access(pc,slot)
        
    def add_write_access (self,pc, slot):
        print ("Adding a write access " + str(pc) + " " + str(slot))
        StorageAbstractState.accesses.add_write_access(pc,slot)


    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))

        

