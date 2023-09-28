from re import S
from basicblock import BasicBlock
from opcodes import get_opcode
import memory_slots
from memory_accesses import MemoryAccesses
from memory_basic_analysis import MemoryAbstractState
from memory_offset_analysis import MemoryOffsetAbstractState
from memory_offset import OffsetAnalysisAbstractState
from memory_slots import SlotsAbstractState
from memory_utils import set_memory_utils_globals
from memory_optimizer_connector import MemoryOptimizerConnector

global debug_info

class BlockAnalysisInfo: 

    ## Creates an initial abstract state with the received information
    def __init__ (self, block_info, input_state): 
        self.block_info = block_info
        self.input_state = input_state
        self.output_state = None
        self.state_per_instr = []

    def get_input_state (self): 
        return self.input_state

    def get_output_state (self): 
        return self.output_state  

    def get_state_at_instr (self,pos): 
        return self.state_per_instr[pos]

    ## Evaluates if a block need to be revisited or not
    def revisit_block (self,input_state, jump_target): 
        leq = input_state.leq(self.input_state)

        if leq: 
            return False
        self.input_state = self.input_state.lub(input_state)
        del self.state_per_instr[:]
        return True
        
    def process_block (self):
        instructions = self.block_info.get_instructions()

        # We start with the initial state of the block
        current_state = self.input_state
        idblock = self.block_info.get_start_address()

        if debug_info:
            print("\n\nProcessing " + str(idblock) + 
            " :: " + str(current_state) + 
            " -- " + str(self.block_info.get_stack_info()))
        
        i = 0
        for instr in self.block_info.get_instructions(): 
            # From the current state we generate a new state by processing the instruction
            current_state = current_state.process_instruction(instr, str(idblock) + ":" + str(i))
            if debug_info:
                print("      -- " + str(self.block_info.get_start_address()) + "[" + str(i) + "]" + 
                        instr + " -- " + str(current_state))
            self.state_per_instr.append(current_state)
            i = i + 1

        self.output_state = current_state
    
    def __repr__(self):

        i = 0
        for state in self.state_per_instr: 
            print (str(self.block_info.get_start_address()) + "." + str(i) + ": " + str(self.state_per_instr[i]))
            i = i + 1
        return "" # "Block id: " + str(self.block_info.get_start_address()) + " States: " + str(len(self.state_per_instr))

class Analysis: 

    def __init__(self,vertices, blockid, initialState): 
        self.vertices = vertices
        self.pending = [blockid]
        self.blocks_info = {}
        self.blocks_info[blockid] = BlockAnalysisInfo(vertices[blockid], initialState)

    def analyze (self):
        while (len(self.pending) > 0) :
            block_id = self.pending.pop()

            # Process the block
            block_info = self.blocks_info[block_id]

            block_info.process_block()

            output_state = block_info.get_output_state()
            self.process_jumps(block_id,output_state)

    def process_jumps (self,block_id, input_state): 
        basic_block = self.vertices[block_id]
        if basic_block.get_block_type() == "terminal": 
            return 

        jump_target = basic_block.get_jump_target()        
        if (jump_target != 0 and jump_target != -1) and self.blocks_info.get(jump_target) == None:
            self.pending.append(jump_target)
            # print("************")
            # print(block_id)
            # print(jump_target)
            # print(self.vertices[block_id].display())
            self.blocks_info[jump_target] = BlockAnalysisInfo(self.vertices[jump_target], input_state)

        elif (jump_target != 0 and jump_target != -1) and self.blocks_info.get(jump_target).revisit_block(input_state,jump_target): 
            #print("REVISITING BLOCK!!! " + str(jump_target))
            self.pending.append(jump_target)

        jump_target = basic_block.get_falls_to()
        if jump_target != None and self.blocks_info.get(jump_target) == None:
            self.pending.append(jump_target)
            self.blocks_info[jump_target] = BlockAnalysisInfo(self.vertices[jump_target], input_state)
        elif jump_target != None and self.blocks_info.get(jump_target).revisit_block(input_state,jump_target): 
            self.pending.append(jump_target)
                
    def get_analysis_results(self,pc,posrel):
        block = pc.split(":")[0]
        if str(block).find("_")==-1:
            block = int(block)
        # try:
        #     block = int(block)
        # except ValueError: 
        #     pass
        id = pc.split(":")[1] 
        return self.blocks_info[block].get_state_at_instr(int(id)+posrel)

    def get_block_results(self,blockid): 
        if str(blockid).find("_")==-1:
            blockid = int(blockid)
        return self.blocks_info[blockid]

    def __repr__(self): 
        for id in self.blocks_info:
            print(str(self.blocks_info[id]))    
        return ""

def perform_memory_analysis(vertices, cname, csource, compblocks, fblockmap, type_analysis, debug, compact_clones):     
    global debug_info 

    debug_info = debug
    
    set_memory_utils_globals(compblocks, fblockmap)
    print("Slots analysis started!")

    MemoryAccesses.init_globals(csource, cname, type_analysis)
    accesses = MemoryAccesses({},{},{},{},vertices)
    
    init_slot = memory_slots.slots_autoid
    SlotsAbstractState.initglobals(accesses)
    slots = Analysis(vertices,0,SlotsAbstractState(set({}),{},{}))
    slots.analyze()

    print("Slots analysis finished!")

    constants = Analysis(vertices,0, OffsetAnalysisAbstractState(0,{},debug_info))
    constants.analyze()

    print("Constants analysis finished!")

    print("Starting offset memory analysis " + str(cname))

    if type_analysis == "baseref":
        MemoryAbstractState.initglobals(slots,accesses)
        memory = Analysis(vertices,0, MemoryAbstractState(0,{},{}))
        memory.analyze()

    
    elif type_analysis == "offset":
        MemoryOffsetAbstractState.init_globals(slots,accesses, constants)
        memory = Analysis(vertices,0, MemoryOffsetAbstractState(0,{},{}))
        memory.analyze()

    else:
        raise Exception("Type for memory analysis incorrect")
        
    # MemoryAbstractState.initglobals(slots,accesses)
    # memory = Analysis(vertices,0, MemoryAbstractState(0,{},{}))
    # memory.analyze()


    # if debug:
    #     print("Memory results:")
    #     print(str(memory))
    #     print("End Memory results:")

    print("Memory accesess analysis finished!\n\n")
    print(accesses)

    #     print("\n\n")
    accesses.process_free_mstores()
    print("GASOL: Useless accesses found: " + str(accesses.get_useless()))

    print('Free memory analyss finished\n\n')

    nslots = memory_slots.slots_autoid - init_slot

    print ("SLOTS Contract " + cname + ": " + str(nslots))
    print("Memory read accesses Contract"+ cname+": "+str(len(accesses.readset.keys())))
    print("Memory write accesses Contract"+ cname+": "+str(len(accesses.writeset.keys())))
    
    print("********************************** INIT")
    memopt = MemoryOptimizerConnector(accesses.readset, accesses.writeset, vertices, cname, debug_info)
    memopt.process_blocks_memory()
    memopt.process_blocks_storage()
    memopt.add_useless_accesses_info(accesses.get_useless())
    memopt.process_context_constancy(constants)
    

    if type_analysis == "offset": 
        memopt.process_context_aliasing(memory)

    print("COMPACT CLONES: " + str(compact_clones))

    if compact_clones: 
        memopt.compact_clones()

    memopt.print_optimization_info()
    print("********************************** END")
    
    return slots, memory, accesses, memopt


