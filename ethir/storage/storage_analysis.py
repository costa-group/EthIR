import os
from storage.cfg2dag import CFG2DAG
import global_params_ethir

from storage.storage_resource_analysis import StorageResourceAnalysis
from storage.storage_offset_abstate import StorageOffsetAbstractState
from storage.storage_accesses import StorageAccesses
from memory.memory_offset import OffsetAnalysisAbstractState,OFFSET_STORAGE
from analysis.fixpoint_analysis import Analysis, BlockAnalysisInfo


def perform_storage_analysis(vertices, debug):     

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

    print("Accesses")
    print(str(accesses))

   
    return storage, accesses


def perform_sra_analysis (accesses, vertices, sccs, sra_analysis, input_blocks, cname): 

    print("Ejecutando storage analysis")

    print("Input blocks: "+str(input_blocks))

    if sra_analysis == "satsol": 
        
        pass

    else:
        cfgdag = CFG2DAG(vertices, sccs)
        perform_sra_no_backend_analysis (vertices, accesses, cfgdag)

        for fblock in input_blocks: 
            print("Processing paths: " + str(fblock))
            if sra_analysis == "allpaths": 
                cfgdag.process_all_paths_from(fblock)
            elif sra_analysis == "nopaths": 
                cfgdag.process_all_blocks_in_method(fblock)

        perform_sra_no_backend_analysis (vertices, accesses, cfgdag)


def perform_sra_no_backend_analysis (vertices, accesses, cfgdag): 
    
    sra = StorageResourceAnalysis (vertices,accesses,cfgdag.paths2terminal, cfgdag)
    print("Computing (non-backend) storage path accesses")
    sra.compute_paths_accesses()
    sra.compute_accesses_in_paths()
    print("SRA results: " + str(sra))