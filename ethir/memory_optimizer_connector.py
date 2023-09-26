from memory_utils import TOP, TOPK

global SPLIT_INSTRUCTIONS 
SPLIT_INSTRUCTIONS = {"LOG0","LOG1","LOG2","LOG3","LOG4","CALLDATACOPY","CODECOPY","EXTCODECOPY","RETURNDATACOPY",
               "CALL","STATICCALL","DELEGATECALL","CREATE","CREATE2","ASSIGNIMMUTABLE", "GAS"}

global EQUALS 
EQUALS = "=="

global NONEQUALS 
NONEQUALS = "!="

global UNKNOWN
UNKOWN = "UNK"

class MemoryOptimizerConnector :

    optimizable_blocks = None
    debug = False
    
    def __init__(self,readset, writeset, vertices, cname, debug):
        self.readset = readset
        self.writeset = writeset
        self.vertices = vertices
        self.contract = cname
        self.optimizable_blocks = OptimizableBlocks(vertices, cname)
        self.debug = debug

    def process_blocks_memory (self): 
        for pc in self.writeset:
            block = pc.split(":")[0]

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            for readpc in filtered: 
                if pc == readpc: 
                    continue
                wset = self.writeset[pc]
                rset = self.readset[readpc]
                res = self.eval_pcs_relation(wset,rset)
                if res == EQUALS or res == NONEQUALS: 
                    self.optimizable_blocks.add_block_info(block,pc,readpc,res,"memory")

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.writeset))
            for writepc in filtered: 
                if pc == writepc: 
                    continue
                wset = self.writeset[pc]
                wset2 = self.writeset[writepc]
                res = self.eval_pcs_relation(wset,wset2)
                if res == EQUALS or res == NONEQUALS: 
                    self.optimizable_blocks.add_block_info(block,pc,writepc,res,"memory")

    def process_blocks_storage (self): 
        
        for block in self.vertices: 
            instructions=self.vertices[block].instructions
            # if not self.contains_two_or_more_storageins(instructions): 
            #     continue

            pc1 = -1
            for inst1 in instructions: 
                pc1 = pc1 + 1
                if not inst1.startswith("SLOAD") and not inst1.startswith("SSTORE"): 
                    
                    continue

                access1 = access1 = inst1.split(" ")[1].split("_")
                if access1 == "?": 
                    continue

                pc2 = -1
                for inst2 in instructions: 
                    pc2 = pc2 + 1
                    if pc1 == pc2 or not inst2.startswith("SLOAD") and not inst2.startswith("SSTORE"): 
                        continue

                    access2 = inst2.split(" ")[1].split("_")
                    if access2 == "?": 
                        continue

                    if access1 == access2: 
                        cmp = EQUALS
                    else: 
                        cmp = NONEQUALS

                    bpc1 = str(str(block) + ":" + str(pc1))
                    bpc2 = str(str(block) + ":" + str(pc2))
                    self.optimizable_blocks.add_block_info(str(block),bpc1,bpc2,cmp,"storage")

    def add_useless_accesses_info(self, useless): 
        self.optimizable_blocks.add_useless_info(useless)

    def eval_pcs_relation(self,set1, set2): 
        ## Check simple case 
        if len(set1) == 1 and len(set2) == 1: 
            # Only one iteration per loop
            elem1 = list(set1)[0] 
            elem2 = list(set2)[0] 
            return self.are_equal(elem1,elem2)

        ## All different
        for elem1 in set1: 
            for elem2 in set2: 
                areequals = self.are_equal(elem1,elem2)
                if areequals == EQUALS or areequals == UNKOWN: 
                    return UNKOWN
        
        return NONEQUALS

    def are_equal(self,access1, access2):
        # Check mem40 accesses
        if isinstance(access1, str) and isinstance(access2, str) and access1 == access2: 
            return EQUALS
        elif isinstance(access1, str) or isinstance(access2, str): 
            return NONEQUALS
        
        ## We have a tuple

        if access1.slot != access2.slot: 
            return NONEQUALS

        # Same baseref
        if access1.offset == TOP or access2.offset == TOP: 
            return UNKOWN

        if access1.offset == TOPK and access2.offset == TOPK: 
            return UNKOWN

        # if access1.offset == TOPK or access2.offset == TOPK: 
        #     return NONEQUALS

        if access1.offset == access2.offset: 
            return EQUALS
        else:
            return NONEQUALS
        
    def get_optimizable_blocks(self):
        self.optimizable_blocks.cleanup_empty_blocks()
        return self.optimizable_blocks

    def process_context_constancy(self, constants): 
        self.optimizable_blocks.add_context_constancy(constants)

    def process_context_aliasing(self, aliasing): 
        self.optimizable_blocks.add_context_aliasing(aliasing)       

    def print_optimization_info(self): 
        if self.debug:
            print("\nMemory block dependences")
            print("------------\n")
            self.optimizable_blocks.print_blocks()
    
        
class OptimizableBlocks: 

    def __init__(self,vertices, cname):
        self.contract = cname
        self.vertices = vertices    
        self.optimizable_blocks = {}
        
    def get_contract_name(self):
        return self.contract
        
    def add_block_info(self,block,pc1,pc2,cmpres, location):
        if block.find("_") != -1:
            instr = list(self.vertices[block].get_instructions())
        else:
            instr = list(self.vertices[int(block)].get_instructions())

        (ressplit,instsplit) = self.contains_split_instruction(instr)
        if ressplit: 
            print ("INFO: Block with split instruction " + self.contract + "--" + str(block) + "[" + instsplit + "] -- ** " + str(instr) + "**")
            return

        if block not in self.optimizable_blocks:
            if block.find("_") != -1:
                instr = self.vertices[block].get_instructions()
            else:
                instr = self.vertices[int(block)].get_instructions()

            instr = self._process_instructions(instr)
                
            self.optimizable_blocks[block] = OptimizableBlockInfo(block, list(instr))
        
        info = self.optimizable_blocks[block].add_pair(pc1,pc2,cmpres, location)

    def cleanup_empty_blocks(self):
        for block in self.optimizable_blocks: 
            blockinfo = self.optimizable_blocks[block]
            if blockinfo.is_info_empty():
                self.optimizable_blocks.pop(block)
        
    def get_optimizable_blocks(self):
        return self.optimizable_blocks
        
    def add_useless_info(self, useless_info): 
        for blockid in useless_info:
            print("GASOL: Adding block useless " + blockid  )
            if blockid in self.optimizable_blocks: 
                self.optimizable_blocks[blockid].add_useless_info(useless_info[blockid])
            else: 
                if blockid.find("_") != -1:
                    instr = list(self.vertices[blockid].get_instructions())
                else:
                    instr = list(self.vertices[int(blockid)].get_instructions())
                
                (ressplit,instsplit) = self.contains_split_instruction(instr)
                if ressplit: 
                    print ("INFO: Block with split instruction " + self.contract + "--" + str(blockid) + "[" + instsplit + "] -- ** " + str(instr) + "**")
                    return
                
                self.optimizable_blocks[blockid] = OptimizableBlockInfo(blockid, list(instr))
                self.optimizable_blocks[blockid].add_useless_info(useless_info[blockid])

    def _process_instructions(self,instr):
        new_instr = []
        
        for i in instr:
            elems = i.split()
            if len(elems)>1 and elems[0].find("PUSH")==-1:
                new_instr.append(elems[0])
            else:
                new_instr.append(i)

        return new_instr
                
    ## Split the blocks according to the instructions in 
    def contains_split_instruction (self, instructions):
        
        new_ins = list(map(lambda x: x.strip(), instructions))

        for inst in SPLIT_INSTRUCTIONS: 
            if inst in new_ins:
                return (True,inst)
        return (False,None)

    def add_context_constancy(self, constants): 
        for block in self.optimizable_blocks: 
            self.optimizable_blocks[block].add_constancy_context(constants.get_block_results(block).get_input_state())

    def add_context_aliasing(self, aliasing): 
        for block in self.optimizable_blocks: 
            self.optimizable_blocks[block].add_aliasing_context(aliasing.get_block_results(block).get_input_state())
         

    def print_blocks(self):
        print("CONTRACT: "+self.contract)
        for elem in self.optimizable_blocks:
            print("-----")
            print(self.optimizable_blocks[elem])
            print(".....")
            
class OptimizableBlockInfo: 

    def __init__(self,block_id, instr):
        self.block_id = block_id
        self.instr = instr
        self.equal_pairs_memory = []
        self.nonequal_pairs_memory = []
        self.equal_pairs_storage = []
        self.nonequal_pairs_storage = []
        self.useless = []
        self.constancy_context = []
        self.aliasing_context = []

    def add_pair(self,pc1,pc2,cmpres, location):
        if location == "memory":
            if cmpres == EQUALS and CmpPair(pc1,pc2) not in self.equal_pairs_memory and CmpPair(pc2,pc1) not in self.equal_pairs_memory: 
                self.equal_pairs_memory.append(CmpPair(pc1,pc2))
            elif cmpres == NONEQUALS and CmpPair(pc1,pc2) not in self.nonequal_pairs_memory and CmpPair(pc2,pc1) not in self.nonequal_pairs_memory: 
                self.nonequal_pairs_memory.append(CmpPair(pc1,pc2))
        elif location == "storage":
            if cmpres == EQUALS and CmpPair(pc1,pc2) not in self.equal_pairs_storage and CmpPair(pc2,pc1) not in self.equal_pairs_storage: 
                self.equal_pairs_storage.append(CmpPair(pc1,pc2))
            elif cmpres == NONEQUALS and CmpPair(pc1,pc2) not in self.nonequal_pairs_storage and CmpPair(pc2,pc1) not in self.nonequal_pairs_storage: 
                self.nonequal_pairs_storage.append(CmpPair(pc1,pc2))
        else:
            raise Exception("Unknown location")
                
    def get_instructions(self): 
        return self.instr

    def get_equal_pairs_memory(self):
        return self.equal_pairs_memory

    def get_nonequal_pairs_memory(self):
        return self.nonequal_pairs_memory

    def get_equal_pairs_storage(self):
        return self.equal_pairs_storage

    def get_nonequal_pairs_storage(self):
        return self.nonequal_pairs_storage
    
    def is_info_empty(self): 
        return (len(self.nonequal_pairs_memory) == 0 and len(self.equal_pairs_memory) == 0 and
                len(self.nonequal_pairs_storage) == 0 and len(self.equal_pairs_storage) == 0 and
                len(self.useless) == 0)

    def add_useless_info(self, useless_list): 
        self.useless = useless_list.copy()

    def get_useless_info(self):
        return self.useless

    def add_constancy_context(self, input): 
        stack = input.get_stack()
        for spos in stack: 
            if len(stack[spos]) == 1: 
                for value in stack[spos]: 
                    if value != TOP and value != TOPK: 
                        self.constancy_context.append((spos,value))

    def add_aliasing_context(self, input): 
        print("******* " + str(input))
        stack = input.get_stack()
        print(str(stack))


    def delete_info_with(self, idx):
        list(filter(lambda x: idx in x, self.equal_pairs_memory))
        list(filter(lambda x: idx in x, self.nonequal_pairs_memory))

    
    def __repr__(self):
        return ("Block: " + self.block_id + "\n" + 
                "Instr:<< " + str(self.instr) + ">> " + 
                "\nEquals Mem:<< " + str(self.equal_pairs_memory) + ">> " + 
                "\nNonEquals Mem: << " + str(self.nonequal_pairs_memory) + ">> " + 
                "\nEquals Sto:<< " + str(self.equal_pairs_storage) + ">> " + 
                "\nNonEquals Sto: << " + str(self.nonequal_pairs_storage) + ">> " + 
                "\nUseless: " + str(self.useless) + 
                "\nConstancy: " + str(self.constancy_context) + 
                "\nAliasing: " + str(self.aliasing_context) + "\n")


class CmpPair: 
    def __init__(self,pc1,pc2):
        self.pc1 = int(pc1.split(":")[1])
        self.pc2 = int(pc2.split(":")[1])
        
    def __repr__(self):
        return "<" + str(self.pc1) + "," + str(self.pc2) + ">"
    
    def __eq__(self, obj):
        if not isinstance(obj, CmpPair):
            return False
        return self.pc1 == obj.pc1 and self.pc2 == obj.pc2

    def __hash__(self):
        return hash(self.pc1) + hash(self.pc2)

    def get_first(self):
        return self.pc1

    def get_second(self):
        return self.pc2

    def set_values(self,v1,v2):
        self.pc1 = v1
        self.pc2 = v2

    def set_first(self,v1):
        self.pc1 = v1

    def set_second(self,v2):
        self.pc2 = v2
    
    def order(self):
        if self.pc1 > self.pc2:
            tmp = self.pc1
            self.pc1 = self.pc2
            self.pc2 = tmp

    def __contains__(self, elem):
        return self.pc1 == elem or self.pc2 == elem
            

    def same_pair(self, val1, val2):
        return (val1 == self.pc1 and val2 == self.pc2) or (val2 == self.pc1 and val1 == self.pc2) 
