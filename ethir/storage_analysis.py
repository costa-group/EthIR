from storage_offset_abstate import StorageOffsetAbstractState
from storage_accesses import StorageAccesses
from memory_offset import OffsetAnalysisAbstractState,OFFSET_STORAGE
from fixpoint_analysis import Analysis, BlockAnalysisInfo

def perform_storage_analysis(vertices, cname, csource, compblocks, fblockmap, type_analysis, debug, compact_clones):     

    print("Storage analysis started! " + str(debug))

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

    print("Storage analysis finished!")

    input_blocks = list(map(lambda x: fblockmap[x][0], fblockmap.keys()))
    print("Input blocks: "+str(input_blocks))
    




    
    


