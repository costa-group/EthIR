from memory.memory_utils import TOP
from storage.storage_offset_abstate import StorageAccess
from storage.storage_access import  BOTTOM
from memory.memory_utils import order_accesses, order_accesses_set
from optimizer.optimizer_connector import EQUALS, NONEQUALS, UNKOWN

class StorageAccesses: 

    def __init__(self): 
        self.read_accesses = {}
        self.write_accesses = {}
        self.written_values = {}


    def add_read_access (self,pc, slot):
        accesses = self.read_accesses.get(pc)

        if accesses is None:
            self.read_accesses[pc] = set(slot)
        else:    
            self.read_accesses[pc] = self.clean_under_top(set(accesses.union(slot)))

    def add_write_access (self,pc, slot, inputval):
        accesses = self.write_accesses.get(pc)

        if accesses is None:
            self.write_accesses[pc] = set(slot)
        else:
            self.write_accesses[pc] = self.clean_under_top(set(accesses.union(slot)))

        if inputval is None: 
            inputval = TOP

        values = self.written_values.get(pc)

        if values is None:
            self.written_values[pc] = set(inputval)
        else:
            self.written_values[pc] = values.union(inputval)

    def clean_under_top (self,accesses): 
        res = set([])
        for s in accesses: 
            if s.offset == TOP: 
                res.add(StorageAccess(s.access,TOP,0))

        for s in accesses:
            if StorageAccess(s.access,TOP,0) not in res:
                res.add(StorageAccess(s.access,s.offset,0))

        return res


    def get_cfg_info (self,block_in): 
        result = []
        self.process_set_string(block_in,self.read_accesses, "R", result)
        self.process_set_string(block_in,self.write_accesses, "W", result)
        
        return sorted(result,key=order_accesses)

    def get_storage_analysis_info(self, block_in):
        result = []
        self.process_set(block_in,self.read_accesses,"l",result)
        self.process_set(block_in,self.write_accesses,"s",result)
        
        return sorted(result,key=order_accesses_set)
        
    def process_set_string (self,block_in, set_in, text, result): 
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            #instr = self.vertices[block_in].get_instructions()[offset]
            if block == block_in: 
                #result.append(offset + " " + instr + "[" + text + "] -> " + str(list(set_in[pc])))
                result.append(offset + " [" + text + "] -> " + str(list(set_in[pc]))) 

    def process_set(self, block_in, set_in, t_ins, result):
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            if block == block_in:
                if t_ins == "s":
                    written_val = self.written_values[pc]
                    
                    if len(written_val) == 1 and StorageAccess(BOTTOM,str(0),0) in written_val:
                        zero = "z"
                    else:
                        zero = "nz"
                else:
                    zero = None
                        
                result.append((offset,list(set_in[pc]),t_ins,zero))
                
    def get_read_accesses (self): 
        return self.read_accesses

    def get_write_accesses (self): 
        return self.write_accesses

    def compare_accesses (self,pp1,pp2): 

        if pp1 not in self.read_accesses and pp1 not in self.write_accesses: 
            print(f"Warning: access at program point {pp1} not found")
            return UNKOWN

        if pp2 not in self.read_accesses and pp2 not in self.write_accesses: 
            print(f"Warning: access at program point {pp2} not found")
            return UNKOWN
        
        if pp1 in self.read_accesses: 
            accesses1 = self.read_accesses[pp1]
        if pp1 in self.write_accesses: 
            accesses1 = self.write_accesses[pp1]

        if pp2 in self.read_accesses: 
            accesses2 = self.read_accesses[pp2]
        if pp2 in self.write_accesses: 
            accesses2 = self.write_accesses[pp2]

        # print (f"   Comparing storage accesses: {pp1} {pp2} {accesses1}--{accesses2}")

        # Contains only one access
        if len(accesses1) == 1 and len(accesses2) == 1: 
            return StorageAccess.compare_acesses(list(accesses1)[0],list(accesses2)[0])


        ## All must return NONEQUALS, otherwise, we return unknown
        for a1 in accesses1: 
            for a2 in accesses2: 
                cmp = StorageAccess.compare_acesses(a1,a2)
                if cmp == EQUALS or cmp == UNKOWN: 
                    return UNKOWN

        return NONEQUALS


    def is_mload_concrete (self, pp): 
        if pp not in self.read_accesses: 
            print ("STORAGE: MLOAD not found in the analysis")
            raise "STORAGE: MLOAD not found in the analysis"
            
        return self.__contains_TOP(self,self.read_accesses[pp])

    def is_mstore_concrete (self, pp): 
        if pp not in self.write_accesses: 
            print ("STORAGE: MSTORE not found in the analysis")
            raise "STORAGE: MSTORE not found in the analysis"
            
        return self.__contains_TOP(self,self.write_accesses[pp])

    def __contains_TOP (self,accesses): 
        for access in accesses: 
            if "*" in str(access): 
                return True
        return False

    def __repr__(self):
        return ("Storage: \n" + 
                "   READ:  " + str(self.read_accesses) + " \n" +
                "   WRITE: " + str(self.write_accesses) + " \n" + 
                "   WRITTEN VALUES: " + str(self.written_values) + " \n")

