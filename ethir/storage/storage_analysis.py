import os
import global_params_ethir

from storage.storage_resource_analysis import StorageResourceAnalysis
from storage.cfg2dag import CFG2DAG
from storage.storage_offset_abstate import StorageOffsetAbstractState
from storage.storage_accesses import StorageAccesses
from memory.memory_offset import OffsetAnalysisAbstractState,OFFSET_STORAGE
from analysis.fixpoint_analysis import Analysis, BlockAnalysisInfo


def perform_storage_analysis(vertices, cname, csource, compblocks, fblockmap, type_analysis, debug, compact_clones, sccs):     

    print("Storage analysis started! ")

    accesses = StorageAccesses()

    Analysis.initglobals(debug)
    BlockAnalysisInfo.initglobals(debug)

    offsets = Analysis(vertices,0, OffsetAnalysisAbstractState(0,{},OFFSET_STORAGE,debug))
    offsets.analyze()

    if debug: 
        print("\n*************************************************************")
        print("*************************************************************")

    StorageOffsetAbstractState.init_globals(accesses, offsets)
    storage = Analysis(vertices,0,StorageOffsetAbstractState(0,{},{},debug))
    storage.analyze()

    print(str(accesses))

    input_blocks = list(map(lambda x: fblockmap[x][0], fblockmap.keys()))
    print("Input blocks: "+str(input_blocks))

    ## Computed all simple paths compacting SCC's 
    cfgdag = CFG2DAG(vertices, sccs)

    print("Processing paths")

    for fblock in input_blocks: 
        print("Processing paths: " + str(fblock))
        cfgdag.process_all_paths_from(fblock)

    sra = StorageResourceAnalysis (vertices,accesses,cfgdag.paths2terminal, cfgdag)
    print("Computing storage path accesses")
    sra.compute_paths_accesses()

     # print("SRA sets: " + str(sra))

    sra.compute_accesses_in_paths()

    print("SRA results: " + str(sra))
   
    return storage, accesses, sra.get_cold_results(),sra.get_final_results()


