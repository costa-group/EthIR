from storage.sramultiset import SRASet, SRAMultiSet


class StorageResourceAnalysis: 


    def __init__(self, vertices, storage, paths, cfgdag):
        self.vertices = vertices
        self.paths = paths
        self.cfgdag = cfgdag

        self.accessesdag = {}
        self.sra_cold_sets = {}
        self.sra_cold_results = {}

        self.writeblocksdag = {}
        self.sra_final_sets = {}
        self.sra_final_results = {}

        for pp in storage.get_read_accesses(): 
            bid = pp.split(":")[0]
            blockra = self.cfgdag.get_nodedag(str(bid))
            accesses = [x for x in storage.get_read_accesses()[pp] if "*" not in str(x)]
            if len(accesses) > 0:
                if blockra not in self.accessesdag: 
                    self.accessesdag[blockra] = list()
                self.accessesdag[blockra].append(SRASet(set(accesses)))

        for pp in storage.get_write_accesses(): 
            bid = pp.split(":")[0]
            blockra = self.cfgdag.get_nodedag(bid)
            accesses = [x for x in storage.get_write_accesses()[pp] if "*" not in str(x)]

            if len(accesses) > 0:
                if blockra not in self.accessesdag: 
                    self.accessesdag[blockra] = list()
                if blockra not in self.writeblocksdag: 
                    self.writeblocksdag[blockra] = list()
                
                self.accessesdag[blockra].append(SRASet(set(accesses)))
                self.writeblocksdag[blockra].append(SRASet(set(accesses)))

        # print("PATHS: " + str(self.paths))
        # print("ACCESSES DAG " + str(self.accessesdag))
        # print("WRITE    DAG " + str(self.writeblocksdag))

    def compute_paths_accesses (self): 
        for entry in self.paths: 
            paths = self.paths[entry]
            i = 0
            for path in paths: 
                self.__process_path(entry, path,i)
                i = i + 1

    def __process_path(self, entry, path,i): 
        for block in path: 
            self.__check_accesses_in_block(block,entry,i,self.accessesdag,self.sra_cold_sets)
            self.__check_accesses_in_block(block,entry,i,self.writeblocksdag,self.sra_final_sets)

    def __check_accesses_in_block(self,block,entry,i,accesses,srasets): 
        (fromnode,tonode) = entry
        isscc = self.cfgdag.is_scc(block)

        ## Wwe have to duplicate to deal with int and string in block identifers
        if block in accesses: 
            acset = accesses[block]
            if (fromnode,tonode,i) not in srasets:
                srasets[(fromnode,tonode,i)] = SRAMultiSet()   
            srasets[(fromnode,tonode,i)].add(acset, isscc) 

        if str(block) in accesses: 
            acset = accesses[str(block)]
            if (fromnode,tonode,i) not in srasets:
                srasets[(fromnode,tonode,i)] = SRAMultiSet()    
            srasets[(fromnode,tonode,i)].add(acset, isscc) 


    def compute_accesses_in_paths (self): 
        self.__compute_accesses_number_in_paths(self.sra_cold_sets,self.sra_cold_results)
        self.__compute_accesses_number_in_paths(self.sra_final_sets,self.sra_final_results)

    def __compute_accesses_number_in_paths (self,srasets,sraresults): 
        for entry in srasets: 
            (initblock,_,_) = entry
            num_accesses, _, sets = srasets[entry].compute_accesses_number()

            if initblock not in sraresults: 
                sraresults[initblock] = num_accesses
            else:
                sraresults[initblock] = max(num_accesses,sraresults[initblock])

        print()

    def get_cold_results(self): 
        return self.sra_cold_results

    def get_final_results(self): 
        return self.sra_final_results


    def __repr__(self):
        res = ""
        for entry in self.sra_cold_sets: 
            res = res + "  SRA:" + str(entry) + " -> " + str(self.sra_cold_sets[entry]) + "\n"
        res = res + "\n"
        for entry in self.sra_final_sets: 
            res = res + "  SRA:" + str(entry) + " -> " + str(self.sra_final_sets[entry]) + "\n"
        res = res + "\n"
        for initblock in self.sra_cold_results: 
            res = res + "  SRA: Method " + str(initblock) + " executes " + str(self.sra_cold_results[initblock]) + " cold accesses\n"
        res = res + "\n"
        for initblock in self.sra_final_results: 
            res = res + "  SRA: Method " + str(initblock) + " executes " + str(self.sra_final_results[initblock]) + " final accesses\n"
        return res


