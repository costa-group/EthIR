from storage.storage_access import StorageAccess, BOTTOM
from opcodes import get_opcode
from memory.memory_utils import is_mload, is_mstore, TOP, TOPK, K

global MEM0
MEM0 = 0

global MEM20
MEM20 = 32

global KECCAKs
KECCAKs = {"0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563": "0", 
           "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6": "1", 
           "0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace": "2",
           "0xc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b": "3", 
           "0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b": "4",
           "0x036b6384b5eca791c62761152d0c79bb0604c104a5fb6f4eb0703f3154bb3db0": "5", 
           "0xf652222313e28459528d920b65115c16c04f3efc82aaedc97be59f3f377c0d3f": "6", 
           "0xa66cc928b5edb82af9bd49922954155ab7b0942694bea4ce44661d9a8736c688": "7", 
           "0xf3f7a9fe364faab93b216da50a3214154f22a0a2b415b23a84c8169e8b636ee3": "8", 
           "0x6e1540171b6c0c960b71a7020d9f60077f6af931a8bbf590da0223dacf75c7af": "9", 
           "0xc65a7bb8d6351c1cf70c95a316cc6a92839c986682d98bc35f958f4883f9d2a8": "10", 
           "0x0175b7a638427703f0dbe7bb9bbf987a2551717b34e79f33b5b1008d1fa01db9": "11", 
           "0xdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7": "12", 
           "0xd7b6990105719101dabeb77144f2a3385c8033acd3af97e9423a695e81ad1eb5": "13",
           "0xbb7b4a454dc3493923482f07822329ed19e8244eff582cc204f8554c3620c3fd": "14", 
           "0x8d1108e10bcb7c27dddfc02ed9d693a074039d026cf4ea4240b40f7d581ac802": "15", 
           "0x1b6847dc741a1b0cd08d278845f9d819d87b734759afb55fe2de5cb82a9ae672": "16", 
           "0x31ecc21a745e3968a04e9570e4425bc18fa8019c68028196b546d1669c200c68": "17", 
           "0xbb8a6a4669ba250d26cd7a459eca9d215f8307e33aebe50379bc5a3617ec3444": "18", 
           "0x66de8ffda797e3de9c05e8fc57b3bf0ec28a930d40b0d285d93c06501cf6a090": "19", 
           "0xce6d7b5282bd9a3661ae061feed1dbda4e52ab073b1f9285be6e155d9c38d4ec": "20"}

class StorageOffsetAbstractState:          
    
    accesses = None
    slots = None
    offsets = None
    g_found_outofslot = False
    
    def __init__(self,stack_pos,stack,memory,debug):
        self.stack_pos = stack_pos
        self.stack = stack
        self.memory = memory 
        self.debug = debug
        
    @staticmethod
    def init_globals (accesses,offsets): 
        StorageOffsetAbstractState.accesses = accesses
        StorageOffsetAbstractState.offsets = offsets

    def get_stack_pos (self): 
        return self.stack_pos

    def leq (self,state): 
        #print ("******************************** HACIENDO LEQ")
        #print ("LEQ: " + str(self) + " " + str(state))
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
        #print ("******************************** HACIENDO LUB")
        #print ("LUB: " + str(self) + " " + str(state))
        if self.debug and self.stack_pos != state.get_stack_pos(): 
            print("STORAGE ANALYSIS WARNING: Different stacks in lub !!! ")
            print("STORAGE ANALYSIS WARNING: " + str(self))
            print("STORAGE ANALYSIS WARNING: " + str(state))

       
        res_stack = self.stack.copy(); 

        for skey in state.stack: 
            if skey in res_stack: 
                res_stack[skey] = self.clean_under_top(res_stack[skey].union(state.stack[skey]))
            else:
                res_stack[skey] = set(state.stack[skey])

        res_memory = self.memory.copy(); 
        for skey in state.memory: 
            if skey in res_memory: 
                res_memory[skey] = self.clean_under_top(res_memory[skey].union(state.memory[skey]))
            else:
                res_memory[skey] = set(state.memory[skey])

        #print("LUB Resultado: " + str(StorageOffsetAbstractState(self.stack_pos, res_stack, res_memory,self.debug)))
        return StorageOffsetAbstractState(self.stack_pos, res_stack, res_memory,self.debug)

    def process_instruction (self,instr,pc):
       
        op_code = instr.split()[0]
        if len(instr.split()) > 1:
            op_operand = instr.split()[1]
        else: 
            op_operand = None

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1


        if is_mstore(instr,"0"):
            if top-1 in stack:
                memory[MEM0] = stack[top-1]
            else: 
                memory[MEM0] = {StorageAccess(BOTTOM,TOP,0)}

        elif is_mstore(instr,"32") and top-1 in stack:
            if top-1 in stack:
                memory[MEM20] = stack[top-1]
            else: 
                memory[MEM20] = {StorageAccess(BOTTOM,TOP,0)}

        elif is_mload(instr,"0"):
            
            if MEM0 in memory: 
                stack[top] = memory[MEM0]
            else: 
                stack[top] = {StorageAccess(BOTTOM,TOP,0)}

        elif is_mload(instr,"32"):
            if MEM20 in memory:
                stack[top] = memory[MEM20]
            else: 
                stack[top] = {StorageAccess(BOTTOM,TOP,0)}

        elif op_code == "PUSH0":
            stack[self.stack_pos] = {StorageAccess(BOTTOM,str(0),0)} 

        # TODO Decidir que push guardar... 
        elif (op_code == "PUSH1"): 
            stack[self.stack_pos] = {StorageAccess(BOTTOM,str(int(op_operand,16)),0)}

        # Keccaks pre-cooked
        elif (op_code == "PUSH32"):

            if str(op_operand) in KECCAKs: 
                stack[self.stack_pos] = {StorageAccess(KECCAKs[str(op_operand)],str(0),0)}

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

        elif op_code == "SLOAD":
            value = None
            if top in stack:
                value = stack[top]
            else:
                print("WARNING: No value for SLOAD")
                value = {StorageAccess(BOTTOM,TOP,0)}
            self.add_read_access(pc,value)
            
                
        elif op_code == "SSTORE":
            value  = None
            if top-1 in stack: 
                value = stack[top-1]
            if top in stack:
                value_address = stack[top]
            else:
                print("WARNING: No value for SSTORE")
                value_address = {StorageAccess(BOTTOM,TOP,0)}
                
            self.add_write_access(pc,value_address, value)

        elif op_code == "SHA3" or op_code == "KECCAK256":

            if top in stack and top-1 in stack:
                ctop = stack[top]
                ctopm1 = stack[top-1]

                ## Reading a kecack for arrays
                if (ctop == {StorageAccess(BOTTOM,str(0),0)} and ctopm1 == {StorageAccess(BOTTOM,str(32),0)}): 
                    res = set([])
                    if MEM0 in memory: 
                        for access in memory[MEM0]: 
                            newAcc = StorageAccess(access,str("0"),access.noper)   
                            res.add(newAcc)
                    else: 
                        res = {StorageAccess(BOTTOM,TOP,0)}
                    stack[top-1] = res
                elif (ctop == {StorageAccess(BOTTOM,str(0),0)} and ctopm1 == {StorageAccess(BOTTOM,str(64),0)}): 
                    res = set([])
                    if MEM0 in memory and MEM20 in memory: 
                        for access in memory[MEM0]: 
                            for access2 in memory[MEM20]: 
                                if access2.access != BOTTOM: 
                                    newAcc = StorageAccess(access2.get_access_expr()+"#"+access.offset,str("0"),max(access2.noper,access.noper))   
                                else: 
                                    newAcc = StorageAccess(access2.offset+"#"+access.offset ,str("0"),max(access2.noper,access.noper))   
                                res.add(newAcc)
                    else:
                        res = {StorageAccess(BOTTOM,TOP,0)}
                    stack[top-1] = res

        elif op_code in "ADD":
            pass
            res = set([])
            if top not in stack and top-1 in stack: 
                for access in stack[top-1]: 
                    res.add(access.add(StorageAccess(BOTTOM,TOP,0)))
                stack[top-1] = res                    
            elif top in stack and top-1 not in stack: 
                for access in stack[top]: 
                    res.add(access.add(StorageAccess(BOTTOM,TOP,0))) 
                stack[top-1] = res                    
            elif top in stack and top-1 in stack:
                ctop = stack[top]
                ctopm1 = stack[top-1]

                for a1 in ctop:
                    for a2 in ctopm1:
                        newAcc = a1.add(a2)   
                        res.add(newAcc)

                stack[top-1] = res                    

        elif op_code.startswith("CALLDATALOAD") and instr.split()[1].startswith("Id"):

            if op_operand: 
                stack[top] = {StorageAccess(BOTTOM,op_operand,0)}
            else:
                stack[top] = {StorageAccess(BOTTOM,TOP,0)}


        elif op_code == "AND" and len(instr.split()) > 1 and instr.split()[1].startswith("Id"): #For considering arguments of CALLDATALOAD
            print("Tengo INST: " + str(instr))

            if op_operand: 
                stack[top-1] = {StorageAccess(BOTTOM,op_operand,0)}
            else:
                stack[top] = {StorageAccess(BOTTOM,TOP,0)}
            
        else: 
            for i in range( self.stack_pos-stack_in,self.stack_pos): 
                stack.pop(i,None)

        for i in range(stack_res,self.stack_pos): 
            stack.pop(i,None)

        # if (not op_code.startswith("DUP",0) and
        #     not op_code.startswith("SWAP",0) and 
        #     not op_code.startswith("CALLDATALOAD")): 
        #     for i in range( self.stack_pos-stack_in,self.stack_pos): 
        #         stack.pop(i,None)

        return StorageOffsetAbstractState(stack_res, stack, memory, self.debug)


    def clean_under_top (self,slots): 
        res = set([])
        for s in slots: 
            if s.offset == TOP: 
                res.add(StorageAccess(s.access,TOP,0))

        for s in slots:
            if StorageAccess(s.access,TOP,0) not in res:
                res.add(StorageAccess(s.access,s.offset,s.noper))
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
            for access in stack[pos]: 
                self.accesses.add_read_access(pc,StorageAccess(access.slot,TOP,access.noper))

    def add_read_access (self,pc, accesses):
        StorageOffsetAbstractState.accesses.add_read_access(pc,accesses)
        
    def add_write_access (self,pc, accesses, value):
        StorageOffsetAbstractState.accesses.add_write_access(pc,accesses, value)


    def get_stack (self): 
        return self.stack

    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))





