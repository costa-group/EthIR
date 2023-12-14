from analysis.fixpoint_analysis import Analysis, BlockAnalysisInfo
from memory.jump_origin_analysis import JumpOriginAbstractState
import global_params_ethir
import os


def perform_jump_origin_analysis(vertices, debug):
    global debug_info
    debug_info = debug
    jump_directions = []

    Analysis.initglobals(debug)
    BlockAnalysisInfo.initglobals(debug)

    memory = Analysis(
        vertices, 0, JumpOriginAbstractState(0, {}, {-1: set()}, debug, jump_directions)
    )
    memory.analyze()

    if "costabs" not in os.listdir(global_params_ethir.tmp_path):
        os.mkdir(global_params_ethir.costabs_path)

    name = global_params_ethir.costabs_path

    with open(f"{name}/saltos_storage.txt", "w") as f:
        f.write(str(jump_directions) + "\n")

    return jump_directions
