from memory_utils import order_accesses, get_block_id, get_function_from_blockid, TOP, TOPK


class MemoryAccesses: 

    contract_name = None
    contract_source = None

    def __init__ (self,readset,writeset,initset,closeset,vertices):
        self.readset = readset
        self.writeset = writeset
        self.initset = initset
        self.closeset = closeset
        self.vertices = vertices
        self.found_outofslot = False


    @staticmethod
    def init_globals (contract_source,contract_name): 
        MemoryAccesses.contract_source = contract_source
        MemoryAccesses.contract_name = contract_name

    def add_read_access (self,pc,slot): 
        if self.readset.get(pc) is None: 
            self.readset[pc] = set([slot])
        else:    
            self.readset[pc].add(slot)

    def add_write_access (self,pc,slot): 
        if self.writeset.get(pc) is None:
            self.writeset[pc] = set([slot])
        else:    
            self.writeset[pc].add(slot)

    def add_allocation_init (self,pc,slot): 
        if self.initset.get(pc) is None:
            self.initset[pc] = set([slot])
        else:    
            self.initset[pc].add(slot)

    def add_allocation_close (self,pc,slot): 
        if self.closeset.get(pc) is None:
            self.closeset[pc] = set([slot])
        else:    
            self.closeset[pc].add(slot)

    def process_free_mstores (self): 

        # print("Evaluating potential optimizations WRITE: " + " " + str(self.writeset))
        # print("Evaluating potential optimizations  READ: " + " " + str(self.readset))
        
        for writepp in self.writeset:
            for slot in self.writeset[writepp]: 

                # Check write block...
                visited = set({})
                block_id = get_block_id(writepp)
                found,pp = self.search_read(slot, block_id, visited)
                if found: 
                    print("MEMRES: Found read -> " + writepp + " : " + pp)
                elif self.is_for_revert(writepp): 
                    print("MEMRES: Found write for revert -> " + writepp)
                elif not self.found_outofslot:
                    func = get_function_from_blockid(writepp)
                    print("MEMRES: NOT Found read (potential optimization) -> " + str(slot) + " " + str(writepp) + " : " + str(pp) + " --> " + str(self.contract_source) + " " + str(self.contract_name) + "--" + str(func))

    def set_found_outofslot(self):
        self.found_outofslot = True

    def is_for_revert(self,writepp): 
        block_id = get_block_id(writepp)
        block_info = self.vertices[block_id]
        instr = block_info.get_instructions()[-1]
        return instr == "REVERT"

    def process_useless_mstores (self):

        print("*********** Procesando MSTORES")

        for writepp in self.writeset:
            for slot in self.writeset[writepp]: 
                print ("Procesando write " + writepp + " --  " + str(slot))
                if slot.offset != TOP and slot.offset != TOPK:
                    self.process_slot_rewritten(writepp,slot)

    def process_slot_rewritten(self, writepp, slot): 
        foundread = False
        for writepp2 in self.writeset: 
            for slot2 in self.writeset[writepp2]: 
                if (slot == slot2 and writepp != writepp2): 
                    block_from = get_block_id(writepp)
                    block_to = get_block_id(writepp2)
                    visited = set({})
                    path = []
                    print("Procesando: Encontrado slot igual" + str(slot) + " " + writepp + "--" +  writepp2)
                    print("Procesando: Buscando caminos " + str(block_from) + "--" +  str(block_to))
                    foundpath, foundread = self.find_all_paths(slot,block_from,block_to, visited, path)
                    print("Procesando Tengo found " + str(foundpath) + " " + str(foundread))
                    if foundpath and not foundread: 
                        print ("Procesando Found useless write " + str(slot) + " " + writepp + "--" +  writepp2)

    def find_all_paths (self, slot, blkfrom, blkto, visited, path): 

        print("     Procesando " + str(blkfrom) + " " + str(visited))
        if blkfrom in visited: 
            return False, False

        visited.add(blkfrom)
        path.append(blkfrom)

        found = False
        foundread = False
        if blkfrom == blkto:
            print ("Procesando PATH FOUND " + str(path))
            foundread = self.blockset_contains_read(visited,slot)
            # for block in visited:
            #     filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            #     for readblock in filtered: 
            #         foundread = self.eval_read_write_access(slot,self.readset[readblock])

            return True, foundread
        else: 
            blockinfo = self.vertices[blkfrom]

            foundpath1 = False
            foundpath2 = False
            jump_target = blockinfo.get_jump_target()        
            if (jump_target != 0 and jump_target != -1):
                foundpath1, foundread = self.find_all_paths(slot,jump_target, blkto, visited, path) 

            jump_target = blockinfo.get_falls_to()
            if jump_target != None and not foundread: 
                foundpath2, foundread  = self.find_all_paths(slot,jump_target, blkto, visited, path) 

        visited.remove(blkfrom)
        path.pop()

        return (foundpath1 or foundpath2, found)

    def blockset_contains_read (self, blocks, slot): 
        for block in blocks:
            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            for readblock in filtered: 
                foundread = self.eval_read_write_access(slot,self.readset[readblock])
                if foundread: 
                    return True
        return False
    
    def search_read(self, slot, block_id, visited): 
        if (block_id in visited): 
            return False, None
        
        filtered = list(filter(lambda x: x.startswith(str(block_id)+":"), self.readset))
        for readblock in filtered: 
            #print("Searching: " + str(slot) + " " + str(block_id) + " ** " + str(self.readset[readblock]))
            #if slot in self.readset[readblock]: 
            #    return True, readblock
            found = self.eval_read_write_access(slot,self.readset[readblock])
            if found: 
                return True, readblock

        found = False
        pp = None
        visited.add(block_id)
        blockinfo = self.vertices[block_id]
        jump_target = blockinfo.get_jump_target()        
        if (jump_target != 0 and jump_target != -1):
           found, pp = self.search_read(slot, jump_target, visited) 

        jump_target = blockinfo.get_falls_to()
        if jump_target != None and not found: 
           found, pp = self.search_read(slot, jump_target, visited) 

        return found, pp

    def eval_read_write_access (self,writeaccess,readset): 
        if isinstance(writeaccess, str): 
            if writeaccess in readset: 
                return True
        else: 
            for readaccess in readset: 
                if isinstance(readaccess,str): 
                    continue
                if (writeaccess.slot == readaccess.slot and 
                    (writeaccess.offset == readaccess.offset or readaccess.offset == TOP or writeaccess.offset == TOP)): 
                    return True
        return False

    def get_cfg_info (self,block_in): 
        result = []
        self.process_set(block_in,self.initset, "I", result)
        self.process_set(block_in,self.closeset, "C", result)
        self.process_set(block_in,self.readset, "R", result)
        self.process_set(block_in,self.writeset, "W", result)
        
        return sorted(result,key=order_accesses)

    def process_set (self,block_in, set_in, text, result): 
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            #instr = self.vertices[block_in].get_instructions()[offset]
            if block == block_in: 
                #result.append(offset + " " + instr + "[" + text + "] -> " + str(list(set_in[pc]))) 
                result.append(offset + " [" + text + "] -> " + str(list(set_in[pc]))) 

    def __repr__(self):
        return ("INIT ALLOC: " + str(self.initset) +
                "\n\nCLOSE ALLOC:" + str(self.closeset) + 
                "\n\nREAD: " + str(self.readset) + 
                "\n\nWRITE: " + str(self.writeset))
