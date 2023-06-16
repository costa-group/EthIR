from opcodes import get_opcode
from memory_utils import is_mload, is_mstore

global slots_autoid 
slots_autoid = 0

class SlotsAbstractState:

    accesses = None

    def __init__(self,opened,closing_pairs,pc_slot):
        self.opened = opened
        self.closing_pairs = closing_pairs
        self.pc_slot = pc_slot

    @staticmethod
    def initglobals (accesses): 
        SlotsAbstractState.accesses = accesses

    def leq (self,state): 
        return state.opened <= self.opened

    def lub (self,state): 
        opened = self.opened.copy()
        stateopen = state.opened.copy()
        stateclose = state.closing_pairs.copy()
        pc_slot = self.pc_slot.copy()

        lubopen= opened.union(stateopen)

        for skey in state.closing_pairs:
            if skey in stateclose: 
                stateclose[skey] = stateclose[skey].union(state.closing_pairs[skey])
            else:
                stateclose[skey] = state.closing_pairs[skey]

        for skey in state.pc_slot:
            if skey in stateclose: 
                pc_slot[skey] = list(set(pc_slot[skey] + state.pc_slot[skey]))
            else:
                pc_slot[skey] = state.pc_slot[skey]

        return SlotsAbstractState(lubopen,stateclose,pc_slot)

    def process_instruction (self,instr, pc):

        global slots_autoid

        opened = self.opened.copy()
        closed = self.closing_pairs.copy()
        pc_slot = self.pc_slot.copy()
        
        op_code = instr.split()[0]
        #opinfo = get_opcode(op_code)

        if is_mload(instr,"64"):
            slots = None
            
            # We take the slot pointed by any opened pc at this pp
            if (len(opened) > 0):
                slots = []
                for item in opened:
                    slots = slots + self.pc_slot[item]
                slots = list(set(slots))
            else:
                slots_autoid = slots_autoid + 1
                slots = ["slot" + str(slots_autoid)]

            for s in slots: 
                self.accesses.add_allocation_init(pc,s)
            pc_slot[pc] = slots
            opened.add(pc)

        # pc != "0:2": Hack to avoid warning the initial assignment of MEM40
        elif (is_mstore(instr,"64") or 
            #op_code == "CALL" or 
            #op_code == "STATICCALL" or 
            #op_code == "DELEGATECALL" or 
            #op_code == "CREATE2" or 
            op_code == "RETURN" or 
            op_code == "REVERT" or 
            op_code == "STOP" or 
            op_code == "SELFDESTRUCT"):
                    
            if len(self.opened) > 1 and op_code != "RETURN" and pc != "0:2": 
                print ("WARNING!!: More than one slot closed at: " + pc + " :: " + str(opened))

            for item in opened:
                for slot in self.pc_slot[item]:
                    self.accesses.add_allocation_close(pc,slot)

            closed[pc] = self.opened.copy()

            opened.clear()

        return SlotsAbstractState(opened, closed, pc_slot)

    def get_slot(self,pc):
        return self.pc_slot[pc]        

    def __repr__(self):

        return ("opened " + str(self.opened) +
                " :: closing_pairs " + str(self.closing_pairs) + 
                " :: pc_slot " + str(self.pc_slot))


