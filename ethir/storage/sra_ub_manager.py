
class SRA_UB_manager: 
    
    def __init__(self, ubs, set_ids,) -> None:
        ## Ubs per public function identified by block id
        self.ubs = ubs
        self.set_ids = set_ids

        self.ubs_info = {}

        self.__compute_ubs()
        print(str(self))

    def __compute_ubs(self): 
        for function in self.ubs: 
            ubinfo = UB_info()
            ubinfo.process_ubs(self.ubs[function], self.set_ids)

            self.ubs_info[function] = ubinfo

    def __repr__(self) -> str:
        res = ""
        for bl in self.ubs_info: 
            res += "UB information from block: {}\n".format(str(bl))
            res += str(self.ubs_info[bl])  
        return res
    

class UB_info: 

    def __init__(self) -> None:
        self.gas_ub = "unkown"
        self.store_vists_ub = "unkown"
        self.ub_x_set = {}

    def process_ubs(self,origub,ids): 
        ## Computing gas ub
        ub = origub.replace("c(g)","1")
        ub = ub.replace("c(store)","0")
        for id in ids: 
            ub = ub.replace("c(set{})".format(id),"0")

        self.gas_ub = eval(ub)

        # Computing visits ub
        ub = origub.replace("c(g)","0")
        ub = ub.replace("c(store)","1")
        for id in ids: 
            ub = ub.replace("c(set{})".format(id),"0")

        self.store_vists_ub = eval(ub)

        # Computing sets ub's
        entryub = origub.replace("c(g)","0")
        entryub = entryub.replace("c(store)","0")
        for id in ids: 
            ub = entryub.replace("c(set{})".format(id),"1")
            for id2 in ids: 
                if id == id2: 
                    continue

                ub = ub.replace("c(set{})".format(id2),"0")

            self.ub_x_set[id] = eval(ub)
        



    def get_gas_ub(self): 
        return self.gasub

    def get_gas_ub(self): 
        return self.gasub

    def get_set_ub(self, setid): 
        setid = "set" + setid
        if setid not in self.ub_x_set: 
            print ("WARN!!! UB not found for set " + setid)
        return self.ub_x_set[setid]
    
    def __repr__(self) -> str:
        res = "   UBgas: {} \n".format(self.gas_ub)
        res += "   UBVisits: {} \n".format(self.store_vists_ub)
        for id in self.ub_x_set: 
            res += "   UBSet[{}]: {} \n".format(id, self.store_vists_ub)
        return res

