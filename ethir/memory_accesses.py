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
            found = False

            if self.is_for_revert(writepp): 
                print("MEMRES: Found write for revert -> " + writepp)
                continue

            for slot in self.writeset[writepp]: 

                # Check write block...
                visited = set({})
                block_id = get_block_id(writepp)

                found = self.search_read(writepp, slot, block_id, visited)
                print("search_read: " + str(block_id) + " -- " + str(slot) + " " + str(found) + " ++ " + str(self.found_outofslot))

                if found: 
                    print("MEMRES: Found read for -> " + writepp)
                    break
                    
                
            if not found and not self.found_outofslot:
                func = get_function_from_blockid(writepp)
                print("MEMRES: NOT Found read (potential optimization) -> " + str(slot) + " " + str(writepp) + " --> " + str(self.contract_source) + " " + str(self.contract_name) + "--" + str(func))


    def set_found_outofslot(self):
        self.found_outofslot = True

    def is_for_revert(self,writepp): 
        block_id = get_block_id(writepp)
        block_info = self.vertices[block_id]
        instr = block_info.get_instructions()[-1]
        return instr == "REVERT"

    def blockset_contains_read (self, blocks, slot): 
        for block in blocks:
            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            for readblock in filtered: 
                #print("  PATH READBLOCK " + str(readblock) + " " + str(self.readset[readblock]))
                foundread = self.eval_read_write_access(slot,self.readset[readblock])
                if foundread:
                    return True
        return False
    
    def search_read(self, writepp, slot, block_id, visited): 
        if (block_id in visited): 
            return False
        
        ## Check if there exists a read of "slot" in the current block
        filtered = list(filter(lambda x: x.startswith(str(block_id)+":"), self.readset))
        for readblock in filtered: 
            found = self.eval_read_write_access(slot,self.readset[readblock])
            if found: 
                return True

        ## Check if there exists a write of "slot" in the current block
        filteredW = list(filter(lambda x: x.startswith(str(block_id)+":"), self.writeset))
        for writeblock in filteredW:

            if writeblock == writepp: 
                continue 

            found = self.eval_write_write_access(slot,self.writeset[writeblock])
            if found: 
                return False

        found = False
        visited.add(block_id)
        blockinfo = self.vertices[block_id]
        jump_target = blockinfo.get_jump_target()        
        if (jump_target != 0 and jump_target != -1):
           found = self.search_read(writepp,slot, jump_target, visited) 

        jump_target = blockinfo.get_falls_to()
        if jump_target != None and not found: 
           found = self.search_read(writepp,slot, jump_target, visited) 

        return found

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
                    print ("PATH Read found " + str(readaccess))
                    return True
        return False

    def eval_write_write_access (self,writeaccess,writeset):
        print("Comparando " + str(writeaccess) + " " + str(writeset)) 

        if len(writeset) > 1: 
            return False
        elif isinstance(writeaccess, str): 
            for writeoption in writeset: 
                if (writeoption == writeaccess):
                    return True
        elif writeaccess.offset == TOP or writeaccess.offset == TOPK: 
            return False
        else: 
            for writeoption in writeset: 
                if isinstance(writeoption,str): 
                    continue
                if (writeaccess.slot == writeoption.slot and 
                    (writeaccess.offset == writeoption.offset and writeoption.offset != TOP and writeoption.offset != TOPK)): 
                    print ("PATH truncated found " + str(writeoption))
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
