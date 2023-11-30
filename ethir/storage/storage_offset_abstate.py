from opcodes import get_opcode
from memory.memory_utils import is_mload, is_mstore, TOP, TOPK, K

global MEM0
MEM0 = 0

global MEM20
MEM20 = 32


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
        print ("******************************** HACIENDO LEQ")
        print ("LEQ: " + str(self) + " " + str(state))
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
        print ("******************************** HACIENDO LUB")
        print ("LUB: " + str(self) + " " + str(state))
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

        print("LUB Resultado: " + str(StorageOffsetAbstractState(self.stack_pos, res_stack, res_memory,self.debug)))
        return StorageOffsetAbstractState(self.stack_pos, res_stack, res_memory,self.debug)

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


        if is_mstore(instr,"0"):
            if top-1 in stack:
                memory[MEM0] = stack[top-1]
            else: 
                memory[MEM0] = {StorageAccess(BOTTOM,TOP,0)}
        
        elif is_mload(instr,"0"):
            stack[top] = memory[MEM0]

        elif is_mstore(instr,"32") and top-1 in stack:
            if top-1 in stack:
                memory[MEM20] = stack[top-1]
            else: 
                memory[MEM0] = {StorageAccess(BOTTOM,TOP,0)}


        elif is_mload(instr,"32"):
            stack[top] = memory[MEM20]

        elif op_code == "PUSH0":
            stack[self.stack_pos] = {StorageAccess(BOTTOM,str(0),0)} 

        # TODO Decidir que push guardar... 
        # elif (op_code == "PUSH1" and 
        #       int(op_operand,16) >= 0 and 
        #       int(op_operand,16) <= K): 
        elif (op_code == "PUSH1"): 
            stack[self.stack_pos] = {StorageAccess(BOTTOM,str(int(op_operand,16)),0)}

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
            self.add_read_access(pc,stack[top])

        elif op_code == "SSTORE":
            self.add_write_access(pc,stack[top])

        elif op_code == "SHA3" or op_code == "KECCAK256": 
            ctop = stack[top]
            ctopm1 = stack[top-1]

            ## Reading a kecack for arrays
            if (ctop == {StorageAccess(BOTTOM,str(0),0)} and ctopm1 == {StorageAccess(BOTTOM,str(32),0)}): 
                res = set([])
                for access in memory[MEM0]: 
                    newAcc = StorageAccess(access,str("0"),access.noper)   
                    res.add(newAcc)
                stack[top-1] = res
            elif (ctop == {StorageAccess(BOTTOM,str(0),0)} and ctopm1 == {StorageAccess(BOTTOM,str(64),0)}): 
                res = set([])
                for access in memory[MEM0]: 
                    for access2 in memory[MEM20]: 
                        if access2.access != BOTTOM: 
                            newAcc = StorageAccess(access2.get_access_expr()+"#"+access.offset,str("0"),max(access2.noper,access.noper))   
                        else: 
                            newAcc = StorageAccess(access2.offset+"#"+access.offset ,str("0"),max(access2.noper,access.noper))   
                        res.add(newAcc)
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

        # elif op_code.startswith("CALLDATALOAD"):
        #     stack[top] = {StorageAccess(BOTTOM,op_operand,0)}

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
                self.accesses.add_read_access(pc,StorageAccess(access.slot,TOP))

    def add_read_access (self,pc, accesses):
        StorageOffsetAbstractState.accesses.add_read_access(pc,accesses)
        
    def add_write_access (self,pc, accesses):
        StorageOffsetAbstractState.accesses.add_write_access(pc,accesses)


    def get_stack (self): 
        return self.stack

    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))


global KECCAK
KECCAK="k"

global BOTTOM
BOTTOM="_"

global TOP_OPER
TOP_OPER=5


## Exp = N | k(Exp) | k(Exp) + N
## N = 1..K | T
class StorageAccess: 

    def __init__(self,stoAccess):
        self.access = stoAccess.access
        self.offset = stoAccess.offset
        self.noper = stoAccess.noper

    def __init__(self,access,offset,noper):
        self.access = access
        self.offset = offset
        self.noper = noper

    def leq (self,access): 
        if self == access: 
            return True

        elif self.access == TOP and access.access != TOP: 
            return False
        elif self.access != TOP and access.access == TOP: 
            return True
        elif self.access != access.access: 
            return False
        # self.access == access.access
        elif self.offset == TOP and access.offset != TOP: 
            return False
        elif self.offset != TOP and access.offset == TOP: 
            return True

        return False

    def isTop (self): 
        return self.access == TOP or self.offset == TOP

    def add(self,operand): 

        if self.access != BOTTOM and operand.access != BOTTOM: 
            print("STORAGE ANALYSIS WARNING: Adding two keccak's " + str(self.access) + " " + str(operand.access))
            return StorageAccess(TOP,TOP)
        
        noper = self.noper + operand.noper + 1
        print ("ADDING " + str(self.offset) + " + " + str(operand.offset) + " " + str(noper)) 
        if self.offset == TOP or operand.offset == TOP: 
            value = TOP
        elif noper >= TOP_OPER: 
            value = TOP
        else: 
            value = int(self.offset) + int(operand.offset)

        if self.access != BOTTOM: 
            return StorageAccess(self.access,str(value),noper)
        elif operand.access != BOTTOM: 
            return StorageAccess(operand.access,str(value),noper)
        else: 
            return StorageAccess(BOTTOM,str(value),noper)        

    def get_access_expr(self): 
        return KECCAK + "(" + str(self.access) + ")"

    def __repr__(self):
        if self.access == BOTTOM: 
            return str(self.offset)
        if self.access == TOP and self.offset == TOP: 
            return TOP
        if self.access != TOP and self.offset == "0": 
            return KECCAK + "(" + str(self.access) + ")"
        
        return KECCAK + "(" + str(self.access) + ")" + "," + str(self.offset)

    def __eq__(self,ob):
        if not isinstance(ob, StorageAccess):
            return False

        return self.access == ob.access and self.offset == ob.offset

    def __hash__(self):
        return hash(self.access) + hash(self.offset)
