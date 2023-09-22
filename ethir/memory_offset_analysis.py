from opcodes import get_opcode
from memory_utils import is_mload, is_mstore, TOP, TOPK, K

class MemoryOffsetAbstractState:          
    
    accesses = None
    slots = None
    constancy = None
    g_found_outofslot = False
    
    def __init__(self,stack_pos,stack,memory):
        self.stack_pos = stack_pos
        self.stack = stack
        self.memory = memory 

    @staticmethod
    def init_globals (slots,accesses,constancy): 
        MemoryOffsetAbstractState.accesses = accesses
        MemoryOffsetAbstractState.slots = slots
        MemoryOffsetAbstractState.constancy = constancy

    def get_stack_pos (self): 
        return self.stack_pos

    def leq (self,state): 
        for skey in self.stack: 
            if (skey not in state.stack or 
                not self.leq_slots(self.stack[skey],state.stack[skey])):
                return False

        for skey in self.memory: 
            if (skey not in state.memory or 
                not self.leq_slots(self.memory[skey],state.memory[skey])):
                return False
        
        return True

    def lub (self,state): 
        if self.stack_pos != state.get_stack_pos(): 
            print("MEM ANALYSIS WARNING: Different stacks in lub !!! ")
            print("MEM ANALYSIS WARNING: " + str(self))
            print("MEM ANALYSIS WARNING: " + str(state))

       
        res_stack = self.stack.copy(); 

        for skey in state.stack: 
            if skey in res_stack: 
                res_stack[skey] = self.clean_under_top(res_stack[skey].union(state.stack[skey]))
            else:
                res_stack[skey] = set(state.stack[skey])

        res_memory = self.memory.copy(); 
        # for skey in state.memory: 
        #     if skey in res_memory: 
        #         res_memory[skey] = self.clean_under_top(res_memory[skey].union(state.memory[skey]))
        #     else:
        #         res_memory[skey] = set(state.memory[skey])

        toremove = list([])
        for memaddress in state.memory:
            if not memaddress in res_memory and MemAccess(memaddress.slot,TOP) not in res_memory: 
                res_memory[memaddress] = set(state.memory[memaddress])

            for memelem in res_memory: 
                if (memaddress.slot == memelem.slot and 
                    (memaddress.offset == memelem.offset or memaddress.offset == TOP or memelem.offset == TOP)): 
                    res_memory[memelem] = set(list(res_memory[memelem]) + list(state.memory[memaddress]))

                if memaddress.slot == memelem.slot and memaddress.offset == TOP and memelem.offset != TOP: 
                    toremove.append(memelem)
                    res_memory[memaddress] = set(list(res_memory[memaddress]) + list(res_memory[memelem]))

        for elem in toremove: 
            res_memory.pop(elem)

        return MemoryOffsetAbstractState(self.stack_pos, res_stack, res_memory)

    def process_instruction (self,instr,pc):
       
        op_code = instr.split()[0]

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        if (not op_code.startswith("DUP",0) and
            not op_code.startswith("SWAP",0)): 
            for i in range( self.stack_pos-stack_in,self.stack_pos): 
                stack.pop(i,None)

        # We save in the stack special memory addresses        
        if is_mload(instr,"64"):
            self.accesses.add_read_access(pc,"mem40")
            res = set([])
            slots = self.slots.get_analysis_results(pc,0).get_slot(pc)
            for s in slots: 
                res.add(MemAccess(s,0))
            stack[top] = res

        # elif op_code == "PUSH1" and instr.split()[1] == "0x60": 
        #     stack[self.stack_pos] = ["null"]
        #     self.accesses.add_allocation_init(pc,"null")                                

        # elif op_code == "POP":
        #     stack.pop(top,None)

        elif op_code.startswith("DUP",0):
            position = top-int(op_code[3:], 10)+1
            if position in self.stack:
                stack[self.stack_pos] = self.stack[position]

        elif op_code.startswith("SWAP",0):
            position = top-int(op_code[4:], 10)
            if position in self.stack and not(top in self.stack):
                stack[top] = self.stack[position] 
                stack.pop(position,None)
            elif top in self.stack and not(position in self.stack): 
                stack[position] = self.stack[top] 
                stack.pop(top,None)
            elif top in self.stack and position in self.stack:
                valpos = self.stack[position] 
                stack[position] = self.stack[top]
                stack[top] = valpos

        elif op_code in "ADD":
            ctop = self.constancy.get_analysis_results(pc,-1).get_constants(top)   
            ctopm1 = self.constancy.get_analysis_results(pc,-1).get_constants(top-1)
            slottop = self.stack.get(top)
            slottopm1 = self.stack.get(top-1)

            if slottop != None and ctopm1 != None: 
                stack[top-1] = self.add_slots(slottop,ctopm1)
            if slottopm1 != None and ctop != None: 
                stack[top-1] =  self.add_slots(slottopm1,ctop)
            
            if slottop != None and ctopm1 == None: 
                stack[top-1] = self.add_slots(slottop,set([TOP]))
            if slottopm1 != None and ctop == None: 
                stack[top-1] = self.add_slots(slottopm1,set([TOP]))
            
            # if slottop != None and ctop != None:
            #     print("ADD ERROR top [" + pc + "]:" + str(slottop) + " -- " + str(ctop))
            # if slottopm1 != None and ctopm1 != None:
            #     print("ADD ERROR top-1 [" + pc + "]:" + str(slottopm1) + " -- " + str(ctopm1))


        elif op_code == "MLOAD": 
            self.add_read_access(top,pc,self.stack)
            self.perform_mload(self.stack, stack, memory, top)

        #     else: 
        #     print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)

        
        #         self.accesses.add_read_access(pc,"unknown")
        
        elif op_code == "MSTORE8":
            self.add_write_access(top,pc,self.stack)

        elif is_mstore(instr,"64"):
            self.accesses.add_write_access(pc,"mem40")

        elif is_mstore(instr,"4"):
            self.accesses.add_write_access(pc,"mem4")

        elif is_mstore(instr,"32"):
            self.accesses.add_write_access(pc,"mem32")

        elif is_mstore(instr,"0"):
            self.accesses.add_write_access(pc,"mem0")

        elif op_code == "MSTORE": 
            self.add_write_access(top,pc,self.stack)
            self.perform_mstore(self.stack,memory,top)
        #     else: 
        #         print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)
        #         self.accesses.add_write_access(pc,"unknown")
        

        elif op_code == "RETURN" or op_code == "REVERT": 
            if top in self.stack: 
                self.add_read_access_top(top,pc,self.stack)

        elif op_code.startswith("LOG"): 
            if top in self.stack: 
                self.add_read_access_top(top,pc,self.stack)

        elif op_code == "SHA3" or op_code == "KECCAK256": 
            if top in self.stack: 
                self.add_read_access_top(top,pc,self.stack)
            else:
                self.accesses.add_read_access(pc,"mem0")
                ctopm1 = self.constancy.get_analysis_results(pc,-1).get_constants(top-1)
                if 64 in ctopm1:
                    self.accesses.add_read_access(pc,"mem32")
                
        elif op_code == "CALL" or op_code == "CALLCODE": 
            self.add_read_access_top(top-3,pc,self.stack)
            self.add_write_access_top(top-5,pc,self.stack)

        elif op_code == "STATICCALL" or op_code == "DELEGATECALL": 
            self.add_read_access_top(top-2,pc,self.stack)
            self.add_write_access_top(top-4,pc,self.stack)

        elif op_code in ["CALLDATACOPY","CODECOPY","RETURNDATACOPY"]:
            self.add_write_access_top(top,pc,self.stack)

        elif op_code == "EXTCODECOPY":
            self.add_write_access_top(top-1,pc,self.stack)

        elif op_code.startswith("CREATE"):
            self.add_read_access_top(top-1,pc,self.stack)

        return MemoryOffsetAbstractState(stack_res, stack, memory)


    def perform_mstore(self,stackin, memory, top):
        ## If not info to store we return
        if not top in stackin or not top-1 in stackin:
            return

        toremove = list([])
        for memaddress in stackin[top]:
            if not memaddress in memory and MemAccess(memaddress.slot,TOP) not in memory: 
                memory[memaddress] = set(stackin[top-1])

            for memelem in memory: 
                if (memaddress.slot == memelem.slot and 
                    (memaddress.offset == memelem.offset or memaddress.offset == TOP or memelem.offset == TOP)): 
                    memory[memelem] = set(list(memory[memelem]) + list(stackin[top-1]))

                if memaddress.slot == memelem.slot and memaddress.offset == TOP and memelem.offset != TOP: 
                    toremove.append(memelem)
                    memory[memaddress] = set(list(memory[memaddress]) + list(memory[memelem]))

        for elem in toremove: 
            memory.pop(elem)

    def perform_mload(self, stackin, stackout, memory, top):
        if top not in stackin: 
            return

        res = set([])
        for memaddress in stackin[top]: 
            topval = MemAccess(memaddress.slot,TOP)
            if memaddress in memory: 
                res = res.union(memory[memaddress])
            if topval in memory: 
                res = res.union(memory[topval])

            if memaddress.offset == TOP:
                for memelem in memory: 
                    if memelem.slot == memaddress.slot: 
                        res = res.union(memory[memelem])
 
        if len(res) > 0:
            stackout[top] = res 


    def clean_under_top (self,slots): 
        res = set([])
        for s in slots: 
            if s.offset == TOP: 
                res.add(MemAccess(s.slot,TOP))

        for s in slots:
            if MemAccess(s.slot,TOP) not in res:
                res.add(MemAccess(s.slot,s.offset))

        return res

    def leq_slots(self, slots1, slots2):
        for s1 in slots1: 
            foundLeq = False
            for s2 in slots2: 
                if s1.leq(s2):
                   foundLeq = True
                   break
            if not foundLeq: 
                return False
        return True

    def add_slots (self, slots, offsets): 
        res = set([])
        for s in slots: 
            for o in offsets: 
                res.add(s.add(o))

        res = self.clean_under_top(res)                
        return res

    def add_read_access_top (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_read_access(pc,MemAccess(memaddress.slot,TOP))

    def add_read_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_read_access(pc,memaddress)

    def add_write_access_top (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_write_access(pc,MemAccess(memaddress.slot,TOP))

    def add_write_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                self.accesses.add_write_access(pc,memaddress)

    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))

class MemAccess: 
    def __init__(self,slot,offset):
        self.slot = slot
        self.offset = offset
   
    def leq (self,access): 
        if self.slot != access.slot: 
            return False

        if access.offset == TOP or self.offset == access.offset: 
            return True
        
        return False

    def add(self,offset): 
        
        # print ("SUMANDO: " + str(self.offset) + " + " + str(offset))

        
        if self.offset == TOP or offset == TOP: 
            return MemAccess(self.slot,TOP)
        elif self.offset == TOPK or offset == TOPK or self.offset+offset > K: 
            return MemAccess(self.slot,TOPK)
        elif self.offset+offset % 32 != 0: 
            return MemAccess(self.slot,TOP)

        return MemAccess(self.slot,self.offset+offset)

    def __repr__(self):
        return "<" + str(self.slot) + "," + str(self.offset) + ">"    

    def __eq__(self,ob):
        if not isinstance(ob, MemAccess):
            return False

        return self.slot == ob.slot and self.offset == ob.offset

    def __hash__(self):
        return hash(self.slot) + hash(self.offset)
