from analysis.fixpoint_analysis import Analysis, BlockAnalysisInfo


from memory.memory_accesses import MemoryAccesses
from memory.memory_basic_analysis import MemoryAbstractState
from memory.memory_offset_analysis import MemoryOffsetAbstractState
from memory.memory_offset import OffsetAnalysisAbstractState, OFFSET_MEMORY
from memory.memory_slots import SlotsAbstractState, get_slots_autoid
from memory.memory_utils import set_memory_utils_globals
from memory.memory_optimizer_connector import MemoryOptimizerConnector

global debug_info


def perform_memory_analysis(vertices, cname, csource, compblocks, fblockmap, type_analysis, debug, compact_clones):     
    global debug_info 

    debug_info = debug
    
    Analysis.initglobals(debug)
    BlockAnalysisInfo.initglobals(debug)

    set_memory_utils_globals(compblocks, fblockmap)
    print("Slots analysis started!")

    MemoryAccesses.init_globals(csource, cname, type_analysis)
    accesses = MemoryAccesses({},{},{},{},vertices)
    
    init_slot = get_slots_autoid()
    SlotsAbstractState.initglobals(accesses)
    slots = Analysis(vertices,0,SlotsAbstractState(set({}),{},{},debug_info))
    slots.analyze()

    print("Slots analysis finished!")

    offsets = Analysis(vertices,0, OffsetAnalysisAbstractState(0,{},OFFSET_MEMORY,debug_info))
    offsets.analyze()

    print("Constants analysis finished!")

    print("Starting offset memory analysis " + str(cname))

    if type_analysis == "baseref":
        MemoryAbstractState.initglobals(slots,accesses)
        memory = Analysis(vertices,0, MemoryAbstractState(0,{},{},debug_info))
        memory.analyze()

    
    elif type_analysis == "offset":
        MemoryOffsetAbstractState.init_globals(slots,accesses, offsets)
        memory = Analysis(vertices,0, MemoryOffsetAbstractState(0,{},{},debug_info))
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
    if debug_info:
        print(accesses)

    #     print("\n\n")
    accesses.process_free_mstores()
    print("GASOL: Useless accesses found: " + str(accesses.get_useless()))

    print('Free memory analyss finished\n\n')

    nslots = get_slots_autoid() - init_slot

    print ("SLOTS Contract " + cname + ": " + str(nslots))
    print("Memory read accesses Contract"+ cname+": "+str(len(accesses.readset.keys())))
    print("Memory write accesses Contract"+ cname+": "+str(len(accesses.writeset.keys())))
    
    print("********************************** INIT")
    memopt = MemoryOptimizerConnector(accesses.readset, accesses.writeset, vertices, cname, debug_info)
    memopt.process_blocks_memory()
    memopt.process_blocks_storage()
    memopt.add_useless_accesses_info(accesses.get_useless())
    memopt.process_context_constancy(offsets)
    

    if type_analysis == "offset": 
        memopt.process_context_aliasing(memory)

    print("COMPACT CLONES: " + str(compact_clones))

    if compact_clones: 
        memopt.compact_clones()

    memopt.print_optimization_info()
    print("********************************** END")
    
    return slots, memory, accesses, memopt


