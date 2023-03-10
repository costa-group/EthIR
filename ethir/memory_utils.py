
global arithemtic_operations
arithemtic_operations = ["ADD","SUB","MUL","DIV","AND","OR","EXP","SHR","SHL"]

global g_function_block_map
g_function_block_map = None
global g_component_of_blocks
g_component_of_blocks = None

global TOP 
TOP = "*"

global TOPK
TOPK = "+"

global K 
K = 128

def set_memory_utils_globals(g_function_block_map_p,g_component_of_blocks_p):
    global g_function_block_map
    g_function_block_map = g_function_block_map_p

    global g_component_of_blocks
    g_component_of_blocks = g_component_of_blocks_p


### Auxiliary functions 
def is_mload(opcode,pos):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MLOAD" and value==pos

def is_mstore(opcode, pos):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MSTORE" and value == pos

def order_accesses(text): 
    return int(text.split()[0])

def get_block_id(pc):
    block = pc.split(":")[0]
    try:
        block = int(block)
        pass
    except ValueError: 
        pass
    return block


def get_function_from_blockid (pp): 
    global g_function_block_map
    global g_component_of_blocks

    blockid = get_block_id(pp)

    initblock = None

    pred = g_function_block_map[blockid]

    for block in pred:
        for key in g_component_of_blocks: 
            (initblock, _) = g_component_of_blocks[key]
            if (initblock == block): 
                return key

