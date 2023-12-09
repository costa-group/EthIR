class SRAMultiSet: 
    def __init__(self):
        self.stosets = {}

    def add (self,set, isscc): 
        for sraset in set:
            lenset = sraset.len() 
            if not isscc: 
                if sraset not in self.stosets: 
                    self.stosets[sraset] = 1
                elif self.stosets[sraset] < lenset:
                    self.stosets[sraset] = self.stosets[sraset] + 1
            else:
                self.stosets[sraset] = lenset
    
    def __copy_stosets (self): 
        res = {}
        for sraset in self.stosets: 
            ck = SRASet(set(sraset.get_set()))
            res[ck] = self.stosets[sraset]
        return res

    def compute_accesses_number (self): 

        sets = self.__copy_stosets()

        processed_sets = list()
        number_accesses = 0
        modified = True
        while modified: 
            modified = False
            for access in sets: 
                ntimes = sets[access]
                if access.len() == ntimes: 
                    number_accesses = number_accesses + ntimes
                    processed_sets.append(access)
                    sets.pop(access)
                    modified = True
                    self.__remove(sets,access.get_set())
                    break 


        joined = self.__join_all(sets)

        number_accesses = number_accesses + min(len(sets),len(joined))

        return number_accesses, processed_sets, sets

    def __join_all (self,sets): 
        res = set()
        for access in sets: 
            for elem in access.get_set():
                res.add(elem)
        
        return res

    def __remove (self,sets,toremove): 
        for access in toremove: 
            modified = True
            while modified: 
                modified = False
                for sraset in sets: 
                    if access in sraset.get_set(): 
                        modified = True
                        ntimes = sets.pop(sraset)
                        sraset.get_set().remove(access)
                        if len(sraset.get_set()) > 0: 
                            sets[sraset] = ntimes
                        break

    def __repr__(self):
        return str(self.stosets)

class SRASet:
    
    def __init__(self,set):
        self.set = set

    def len(self): 
        return len(self.set)
    
    def get_set(self): 
        return self.set

    def __eq__(self,o):
        return self.set == o.set
        
    def __hash__(self):
        return len(self.set);

    def __repr__(self):
        return str(self.set)

