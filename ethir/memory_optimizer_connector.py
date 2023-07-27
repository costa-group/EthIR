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

    def __init__(self,readset, writeset, vertices, cname):
        self.readset = readset
        self.writeset = writeset
        self.vertices = vertices
        self.contract = cname
        self.optimizable_blocks = OptimizableBlocks(vertices, cname)

    def process_blocks (self,debug): 
        for pc in self.writeset:
            block = pc.split(":")[0]
#            print("\n\nBuscando en el bloque " + pc + " " + block)

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            for readpc in filtered: 
                if pc == readpc: 
                    continue
                wset = self.writeset[pc]
                rset = self.readset[readpc]
                res = self.eval_pcs_relation(wset,rset)
#                print("Read - Comparando " + block + " " + str(pc) + "**" + str(readpc) + " " + str(wset) + " " + str(rset) + " --> " + str(res))
                if res == EQUALS or res == NONEQUALS: 
#                    print("**************************************")
                    self.optimizable_blocks.add_block_info(block,pc,readpc,res)

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.writeset))
            for writepc in filtered: 
                if pc == writepc: 
                    continue
                wset = self.writeset[pc]
                wset2 = self.writeset[writepc]
                res = self.eval_pcs_relation(wset,wset2)
#                print("Write - Comparando " + block + " " + str(pc) + "**" + str(writepc) + " " + str(wset) + " " + str(wset2) + " --> " + str(res))
                if res == EQUALS or res == NONEQUALS: 
#                    print("**************************************")
                    self.optimizable_blocks.add_block_info(block,pc,writepc,res)

        if debug:
            self.optimizable_blocks.print_blocks()

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
        return self.optimizable_blocks
        
class OptimizableBlocks: 
    optimizable_blocks = {}

    def __init__(self,vertices, cname):
        self.contract = cname
        self.vertices = vertices    

    def get_contract_name(self):
        return self.contract
        
    def add_block_info(self,block,pc1,pc2,cmpres):
#        print("Adding block info " + block)
        
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

            instr = self._process_memory_instructions(instr)
                
            self.optimizable_blocks[block] = OptimizableBlockInfo(block, list(instr))
        
        info = self.optimizable_blocks[block].add_pair(pc1,pc2,cmpres)

    def get_optimizable_blocks(self):
        return self.optimizable_blocks
        

    def _process_memory_instructions(self,instr):
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
        for inst in SPLIT_INSTRUCTIONS: 
            if inst in instructions: 
                return (True,inst)
        return (False,None)

    # def split_blocks (self): 
    #     for block in self.optimizable_blocks: 
    #         if self.optimizable_blocks[block].is_divisible(): 
    #             print ("LLLLL Bloque divisible " + str(self.optimizable_blocks[block].get_instructions()))

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
        self.equal_pairs = []
        self.nonequal_pairs = []


    def add_pair(self,pc1,pc2,cmpres): 
        if cmpres == EQUALS and CmpPair(pc1,pc2) not in self.equal_pairs and CmpPair(pc2,pc1) not in self.equal_pairs: 
            self.equal_pairs.append(CmpPair(pc1,pc2))
        elif cmpres == NONEQUALS and CmpPair(pc1,pc2) not in self.nonequal_pairs and CmpPair(pc2,pc1) not in self.nonequal_pairs: 
            self.nonequal_pairs.append(CmpPair(pc1,pc2))

    def get_instructions(self): 
        return self.instr

    def get_equal_pairs(self):
        return self.equal_pairs

    def get_nonequal_pairs(self):
        return self.nonequal_pairs
    
    def __repr__(self):
        return "Block: " + self.block_id + "\n" + "Instr:<< " + str(self.instr) + ">> " + "\nEquals:<< " + str(self.equal_pairs) + ">> " + "\nNonEquals: << " + str(self.nonequal_pairs) + ">> "




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

    def same_pair(self, val1, val2):
        return (val1 == self.pc1 and val2 == self.pc2) or (val2 == self.pc1 and val1 == self.pc2) 



