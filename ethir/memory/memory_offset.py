from opcodes import get_opcode
from memory.memory_utils import TOP,TOPK, K


## Types of offset analysis 
global OFFSET_MEMORY
OFFSET_MEMORY=1

global OFFSET_STORAGE
OFFSET_STORAGE=2


class OffsetAnalysisAbstractState:          
    stack_pos = None
    
    def __init__(self,stack_pos,stack, analysis, debug):
        self.stack_pos = stack_pos
        self.stack = stack
        self.analysis = analysis # memory or storage
        self.debug = debug

    # def is_leq (self,s1, s2):
    #     print ("PROCESANDO IS LEQ " + str(s1) + " " + str(s2)
    #     if s1.slot != s2.slot: 
    #         return False
    #     elif s2.offset == TOP or s1.offset == s2.offset: 
    #         return True
    #     else:  
    #         return False

    def is_leq (self,s1, s2):
        if TOP in s2: 
             return True
        allLeq = True
        for sleft in s1: 
            found = False
            for sright in s2: 
                if (sright == TOP or sleft == sright): 
                    found = True
                    break

            if not found: 
                allLeq = False
                break
        return allLeq
    
    def leq (self,state): 
        if self.stack_pos != state.stack_pos: 
            print("OFFSET ANALYSIS WARNING: Different stacks in leq !!! ")
            print("OFFSET ANALYSIS WARNING: " + str(self))
            print("OFFSET ANALYSIS WARNING: " + str(state))
        allLeq = True
        for skey in self.stack: 
            if skey not in state.stack: 
                return False
            
            allLeq = self.is_leq(self.stack[skey],state.stack[skey])
            if not allLeq:
                break
        return allLeq

    def do_lub(self,s1,s2): 
        if TOP in s1 or TOP in s2: 
            return set([TOP])
        else: 
            return s1.union(s2)

    def lub (self,state): 
        if self.debug:
            print ("DOING LUB: " + str(self.stack) + " " + str(state.stack))
        if self.stack_pos != state.stack_pos: 
            print("OFFSET ANALYSIS WARNING: Different stacks in lub !!! ")
            print("OFFSET ANALYSIS WARNING: " + str(self))
            print("OFFSET ANALYSIS WARNING: " + str(state))

        res_stack = self.stack.copy(); 

        for skey in state.stack: 
            if skey in res_stack: 
                res_stack[skey] = self.do_lub(res_stack[skey],state.stack[skey])
            else:
                res_stack[skey] = state.stack[skey]

        if self.debug:
            print ("LUB RES " + str(res_stack))

        return OffsetAnalysisAbstractState(self.stack_pos, res_stack, self.analysis,self.debug)


    def process_instruction (self,instr,pc):
       
        op_code = instr.split()[0]

        stack = self.stack.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        if op_code == "PUSH0" :
            stack[self.stack_pos] = set({0})
        
        elif op_code.startswith("PUSH") :
            strvalue = instr.split()[1]
            value = int(strvalue,16)

            if self.analysis == OFFSET_MEMORY and value >= 0 and value % 32 == 0 and value < K: 
                stack[self.stack_pos] = set({value})
            elif self.analysis == OFFSET_STORAGE and value >= 0 and value < K: 
                stack[self.stack_pos] = set({value})
            else:
                stack[self.stack_pos] = set({TOP})

        elif op_code == "POP":
            stack.pop(top,None)

        elif op_code.startswith("DUP",0):
            position = top-int(op_code[3:], 10)+1
            if position in stack:
                stack[self.stack_pos] = stack[position]
            else:
                print("ERROR: DUP copying a non-existent value in offset analysis")

        elif op_code.startswith("SWAP",0):
            position = top-int(op_code[4:], 10)
            if top in stack and position in stack:
                valpos = stack[position] 
                stack[position] = stack[top]
                stack[top] = valpos
            else:
                print("ERROR: SWAP moving a non-existent value in offset analysis")

        elif op_code == "ADD":
            set1 = stack[top]
            set2 = stack[top-1]
            stack[top-1] = self.add_set(set1, set2)
            
        elif stack_out > 0:
            for i in range(1,stack_out+1):
                stack[top-stack_in+i] = set({TOP})

        for i in range(stack_res,self.stack_pos): 
            stack.pop(i,None)

        return OffsetAnalysisAbstractState(stack_res, stack, self.analysis, self.debug)


    def get_offsets (self,stackpos):  
        return self.stack.get(stackpos)


    def add_set(self,set1,set2):

        if TOP in set1 or TOP in set2: 
            return set({TOP})
        
        result = set({})
        
        for i in set1:
            for j in set2:
                if j == TOPK or i == TOPK:
                    result.add(TOPK)
                else:
                    suma = i+j
                    if suma > K:
                        result.add(TOPK)
                    else:
                        result.add(suma)
        return result

    def get_stack (self): 
        return self.stack

    def __repr__(self):
        return (" stack^" + str(self.stack_pos) + " = " + str(self.stack))
