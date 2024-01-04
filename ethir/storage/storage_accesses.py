from memory.memory_utils import TOP
from storage.storage_offset_abstate import StorageAccess
from memory.memory_utils import order_accesses

class StorageAccesses: 

    def __init__(self): 
        self.read_accesses = {}
        self.write_accesses = {}

    def add_read_access (self,pc, slot):
        accesses = self.read_accesses.get(pc)

        if accesses is None:
            self.read_accesses[pc] = set(slot)
        else:    
            self.read_accesses[pc] = self.clean_under_top(set(accesses.union(slot)))

    def add_write_access (self,pc, slot):
        accesses = self.write_accesses.get(pc)

        if accesses is None:
            self.write_accesses[pc] = set(slot)
        else:
            self.write_accesses[pc] = self.clean_under_top(set(accesses.union(slot)))

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
        self.process_set(block_in,self.read_accesses,result)
        self.process_set(block_in,self.write_accesses,result)

        return sorted(result,key=order_accesses)
        
    def process_set_string (self,block_in, set_in, text, result): 
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            #instr = self.vertices[block_in].get_instructions()[offset]
            if block == block_in: 
                #result.append(offset + " " + instr + "[" + text + "] -> " + str(list(set_in[pc]))) 
                result.append(offset + " [" + text + "] -> " + str(list(set_in[pc]))) 

    def process_set(self, block_in, set_in, result):
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            if block == block_in: 
                result.append(offset+" : "+str(list(set_in[pc])))
                
    def get_read_accesses (self): 
        return self.read_accesses

    def get_write_accesses (self): 
        return self.write_accesses

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
                "   WRITE: " + str(self.write_accesses) + " \n")
