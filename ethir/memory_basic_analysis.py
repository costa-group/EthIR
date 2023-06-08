from opcodes import get_opcode
from memory_utils import is_mload, is_mstore
from memory_utils import arithemtic_operations

class MemoryAbstractState:          
    
    accesses = None
    slots = None
    g_found_outofslot = False
    
    def __init__(self,stack_pos,stack,memory):
        self.stack_pos = stack_pos
        self.stack = stack
        self.memory = memory

    @staticmethod
    def initglobals (slots,accesses): 
        MemoryAbstractState.accesses = accesses
        MemoryAbstractState.slots = slots

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
        if self.stack_pos != state.get_stack_pos(): 
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

        return MemoryAbstractState(self.stack_pos, res_stack, res_memory)


    def process_instruction (self,instr,pc):
       
        op_code = instr.split()[0]

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        # We save in the stack special memory addresses        
        if is_mload(instr,"64"):
            self.accesses.add_read_access(pc,"mem40")
            stack[top] = self.slots.get_analysis_results(pc,0).get_slot(pc)

        elif is_mstore(instr,"64"):
            self.accesses.add_write_access(pc,"mem40")

        elif is_mstore(instr,"4"):
            self.accesses.add_write_access(pc,"mem4")

        elif is_mstore(instr,"32"):
            self.accesses.add_write_access(pc,"mem0")

        elif is_mstore(instr,"0"):
            self.accesses.add_write_access(pc,"mem0")

        elif op_code == "PUSH1" and instr.split()[1] == "0x60": 
            stack[self.stack_pos] = ["null"]
            self.accesses.add_allocation_init(pc,"null")                             

        elif op_code.startswith("LOG") or op_code == "RETURN" or op_code == "REVERT": 
            if top in stack: 
                self.add_read_access(top,pc,stack)

        elif op_code == "SHA3" or op_code == "KECCAK256": 
            if top in stack: 
                self.add_read_access(top,pc,stack)
            else:  
                self.accesses.add_read_access(pc,"mem0") 

        elif op_code.startswith("CREATE"):
            self.add_read_access(top-1,pc,stack)

        elif op_code == "CALL" or op_code == "CALLCODE": 
            self.add_read_access(top-3,pc,stack)
            self.add_write_access(top-5,pc,stack)

        elif op_code == "STATICCALL" or op_code == "DELEGATECALL": 
            self.add_read_access(top-2,pc,stack)
            self.add_write_access(top-4,pc,stack)

        elif op_code in ["CALLDATACOPY","CODECOPY","RETURNDATACOPY"]:
            self.add_write_access(top,pc,stack)

        elif op_code == "EXTCODECOPY":
            self.add_write_access(top-1,pc,stack)

        elif op_code == "MLOAD": 
            self.add_read_access(top,pc,stack)
            if top in stack: 
                reslist = []
                for memaddress in stack[top]: 
                    if memaddress in memory: 
                        reslist = reslist+memory[memaddress]
                if len(reslist) > 0: 
                    stack[top] = list(set(reslist))
                else:
                    stack.pop(top,None)
            else: 
                print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)
                self.accesses.add_read_access(pc,"unknown")                                   
            

        elif op_code == "MSTORE8":
            self.add_write_access(top,pc,stack)

        elif op_code == "MSTORE": 
            self.add_write_access(top,pc,stack)
            if top in stack:
                for memaddress in stack[top]:
                    if top-1 in stack: 
                        for memitem in stack[top-1]:
                            if memaddress in memory:
                                memory[memaddress] = list(set(memory[memaddress] + [memitem]))
                            else: 
                                memory[memaddress] = [memitem]
            else: 
                print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)
                self.accesses.add_write_access(pc,"unknown")                                

        elif op_code in arithemtic_operations:

            if top in stack and (not top-1 in stack): 
                stack[top-1] = stack[top]
                if op_code == "SUB": 
                    print ("MEMORY ANALYSIS WARNING (" + pc + "): Substracting a slot minus a number " + str(stack[top]) + ". Ignoring optimizations of this function")
                    self.g_found_outofslot = True

            elif top-1 in stack and (not top in stack): 
                pass
                #stack[top-1] = stack[top-1]
            elif top in stack and top-1 in stack: 
                # print ("MEMORY ANALYSIS WARNING (" + pc + "): Arithmentic operations with two slots: " + 
                #         op_code + " (" + 
                #         str(stack[top-1]) + "," + 
                #         str(stack[top]) + ")")
                if stack[top] == ["null"] and stack[top-1] != ["null"]: 
                    #stack[top-1] = stack[top-1]
                    pass
                elif stack[top] != ["null"] and stack[top-1] == ["null"]: 
                    stack[top-1] = stack[top]
                elif op_code == "SUB": 
                    stack.pop(top-1,None)
                elif stack[top] != ["null"] or stack[top-1] != ["null"]: 
                    stack[top-1] = filter(lambda x: x != "null", list(set(stack[top]+stack[top-1])))

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

        return MemoryAbstractState(stack_res, stack, memory)

    def add_read_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_read_access(pc,memaddress)

    def add_write_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_write_access(pc,memaddress)


    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))

