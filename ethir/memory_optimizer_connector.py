from memory_utils import TOP


global EQUALS 
EQUALS = "=="

global NONEQUALS 
NONEQUALS = "!="

global UNKNOWN
UNKOWN = "UNK"

class MemoryOptimizerConnector :

    optimizable_blocks = None

    def __init__(self,readset, writeset, vertices):
        self.readset = readset
        self.writeset = writeset
        self.vertices = vertices
        self.optimizable_blocks = OptimizableBlocks(vertices)

    def process_blocks (self): 
        for pc in self.writeset:
            block = pc.split(":")[0]
            print("\n\nBuscando en el bloque " + pc + " " + block)

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.readset))
            for readpc in filtered: 
                if pc == readpc: 
                    continue
                wset = self.writeset[pc]
                rset = self.readset[readpc]
                res = self.eval_pcs_relation(wset,rset)
                print("Read - Comparando " + block + " " + str(wset) + " " + str(rset) + " --> " + str(res))
                if res == EQUALS or res == NONEQUALS: 
                    print("**************************************")
                    self.optimizable_blocks.add_block_info(block,pc,readpc,res)

            filtered = list(filter(lambda x: x.startswith(str(block)+":"), self.writeset))
            for writepc in filtered: 
                if pc == writepc: 
                    continue
                wset = self.writeset[pc]
                wset2 = self.writeset[writepc]
                res = self.eval_pcs_relation(wset,wset2)
                print("Write - Comparando " + block + str(wset) + " " + str(wset2) + " --> " + str(res))
                if res == EQUALS or res == NONEQUALS: 
                    print("**************************************")
                    self.optimizable_blocks.add_block_info(block,pc,writepc,res)

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

        if access1.offset == TOP or access2.offset == TOP: 
            return UNKOWN

        if access1.offset == access2.offset: 
            return EQUALS
        else:
            return NONEQUALS

class OptimizableBlocks: 
    optimizable_blocks = {}

    def __init__(self,vertices):
        self.vertices = vertices    

    def add_block_info(self,block,pc1,pc2,cmpres):
        print("Adding block info " + block)


        if block not in self.optimizable_blocks:
            instr = self.vertices[int(block)].get_instructions()
            
            self.optimizable_blocks[block] = OptimizableBlockInfo(block, list(instr))
        
        info = self.optimizable_blocks[block].add_pair(pc1,pc2,cmpres)
        

    def print_blocks(self):
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

    def __repr__(self):
        return "Block: " + self.block_id + "\n" + "Instr:<< " + str(self.instr) + ">> " + "\nEquals:<< " + str(self.equal_pairs) + ">> " + "\nNonEquals: << " + str(self.nonequal_pairs) + ">> "

class CmpPair: 
    def __init__(self,pc1,pc2):
        self.pc1 = pc1
        self.pc2 = pc2
    def __repr__(self):
        return "<" + str(self.pc1) + "," + str(self.pc2) + ">"
    
    def __eq__(self, obj):
        if not isinstance(obj, CmpPair):
            return False
        return self.pc1 == obj.pc1 and self.pc2 == obj.pc2

    def __hash__(self):
        return hash(self.pc1) + hash(self.pc2)






