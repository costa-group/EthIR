from memory.memory_utils import TOP
from storage.storage_offset_abstate import StorageAccess


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

        print ("ACCESSES Adding READ at " + str(pc) + ": " + str(accesses) + " U " + str(slot) + " = " + str(self.read_accesses[pc]))


    def add_write_access (self,pc, slot):
        accesses = self.write_accesses.get(pc)

        if accesses is None:
            self.write_accesses[pc] = set(slot)
        else:
            self.write_accesses[pc] = self.clean_under_top(set(accesses.union(slot)))

        print ("ACCESSES Adding WRITE at " + str(pc) + ": " + str(accesses) + " U " + str(slot) + " = " + str(self.write_accesses[pc]))



    def clean_under_top (self,accesses): 
        res = set([])
        for s in accesses: 
            if s.offset == TOP: 
                res.add(StorageAccess(s.access,TOP,0))

        for s in accesses:
            if StorageAccess(s.access,TOP,0) not in res:
                res.add(StorageAccess(s.access,s.offset,0))

        return res


    def __repr__(self):
        return ("Storage: \n" + 
                "   READ:  " + str(self.read_accesses) + " \n" +
                "   WRITE: " + str(self.write_accesses) + " \n")
