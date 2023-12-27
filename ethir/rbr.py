#Pablo Gordillo

from rbr_rule import RBRRule
import opcodes
from basicblock import Tree
from utils import getKey, orderRBR, getLevel, store_times
import os
import saco
import c_translation
import c_utranslation
import e_translation
from timeit import default_timer as dtimer
from graph_scc import get_entry_scc
import global_params_ethir
import traceback

init_fields = []

'''
It initialize the globals variables. 
-List opcodeX contains the evm bytecodes from set X.
-current_local_var has the max index of the local variables created.
-local_variables is a mapping address->local_variable if known.
-rbr_blocks is a mapping rbr_id->list of rbr rules (jumps contains 2 rules per rbr_id).
-stack_index is a mapping block_id->[stack_height_begin, stack_heigh_end].
-max_field_list keeps the id of the known fields accessed during the execution.
-bc_in_use keeps the contract data used during the execution.
-new fid keeps the index of the new fresh variable.
'''
def init_globals():
    
    global opcodes0
    opcodes0 = ["STOP", "ADD", "MUL", "SUB", "DIV", "SDIV", "MOD",
                "SMOD", "ADDMOD", "MULMOD", "EXP", "SIGNEXTEND"]

    global opcodes10
    opcodes10 = ["LT", "GT", "SLT", "SGT", "EQ", "ISZERO", "AND", "OR",
                 "XOR", "NOT", "BYTE","SHL","SHR","SAR"]

    global opcodes20
    opcodes20 = ["SHA3", "KECCAK256"]

    global opcodes30
    opcodes30 = ["ADDRESS", "BALANCE", "ORIGIN", "CALLER",
                 "CALLVALUE", "CALLDATALOAD", "CALLDATASIZE",
                 "CALLDATACOPY", "CODESIZE", "CODECOPY", "GASPRICE",
                 "EXTCODESIZE", "EXTCODECOPY", "MCOPY","EXTCODEHASH"]

    global opcodes40
    opcodes40 = ["BLOCKHASH", "COINBASE", "TIMESTAMP", "NUMBER",
                 "DIFFICULTY","PREVRANDAO", "GASLIMIT","SELFBALANCE","CHAINID","BASEFEE"]

    global opcodes50
    opcodes50 = ["POP", "MLOAD", "MSTORE", "MSTORE8", "SLOAD",
                 "SSTORE", "JUMP", "JUMPI", "PC", "MSIZE", "GAS", "JUMPDEST",
                 "SLOADEXT", "SSTOREEXT", "SLOADBYTESEXT", "SSTOREBYTESEXT"]

    global opcodes60
    opcodes60 = ["PUSH"]

    global opcodes80
    opcodes80 = ["DUP"]

    global opcodes90
    opcodes90 = ["SWAP"]

    global opcodesA
    opcodesA = ["LOG0", "LOG1", "LOG2", "LOG3", "LOG4"]

    global opcodesF
    opcodesF = ["CREATE", "CALL", "CALLCODE", "RETURN", "REVERT",
                "ASSERTFAIL", "DELEGATECALL", "BREAKPOINT", "RNGSEED", "SSIZEEXT",
                "SLOADBYTES", "SSTOREBYTES", "SSIZE", "STATEROOT", "TXEXECGAS",
                "CALLSTATIC", "INVALID", "SUICIDE","STATICCALL","CREATE2"]

    global opcodesZ
    opcodesZ = ["RETURNDATACOPY","RETURNDATASIZE"]
    
    global current_local_var
    current_local_var = 0

    global local_variables
    local_variables = {}
    
    global lvariables_per_block
    lvariables_per_block = {}
    
    global rbr_blocks
    rbr_blocks = {}

    global stack_index
    stack_index = {}
    
    # global max_field_list
    # max_field_list = []

    # global bc_in_use
    # bc_in_use = []

    global bc_per_block
    bc_per_block = {}

    global top_index
    top_index = 0

    global new_fid
    new_fid = 0

    global fields_per_block
    fields_per_block = {}

    global cloned_blocks
    cloned_blocks = []

    global vertices
    vertices = {}

    global all_state_vars
    all_state_vars = []


    global forget_memory_blocks
    forget_memory_blocks = []

    global forget_memory
    forget_memory = False

    # global forget_storage_blocks
    # forget_storage_blocks = []

    # global forget_storage
    # forget_storage = False

    global blockhash_cont
    blockhash_cont = 0

    global extcodehash_cont
    extcodehash_cont = 0
    
    global c_trans
    c_trans = False

    global c_words
    c_words = ["char","for","index","y1","log","rindex","round","exp","long"]

    global memory_intervals
    memory_intervals = None

    global c_address
    c_address = 0

    global storage_arrays
    storage_arrays = {"ids":{},"vals":{}}

    global str_arr
    str_arr = False

    global sha3_blocks_arr
    sha3_blocks_arr = {}

    global val_mem40
    val_mem40 = ""
    
'''
Given a block it returns a list containingn the height of its
stack when arriving and leaving the block.
-bock:block start address. int.
-It returns a list with 2 elements. [int, int].
'''
def get_stack_index(block):
    try:
        return stack_index[block]
    
    except:
        return [0,0]


def update_top_index(val):
    global top_index

    if top_index < val:
        top_index = val
        

'''
It is used when a bytecode consume stack variables. It returns the
current stack variable (the top most one) and after that update the variable index.
index_variables contains the index of current stack variable.
-index_variables: int.
-It returns a tuple (stack variable, top stack index). (string, int).
'''
def get_consume_variable(index_variables):
    current = index_variables

    if current >= 0 :
        variable = "s(" + str(current) + ")"
        current = current-1
        
    return  variable, current


'''
It returns the next fresh stack variable and updates the current
index.
-index_variables: int.
-It returns a tuple (stack variable, top stack index). (string, int).
'''
def get_new_variable(index_variables):
    new_current = index_variables + 1
    update_top_index(new_current)
    return "s(" + str(new_current) + ")", new_current


'''
It returns the variable palced in the top of stack.
-index_variables: int.
variable: stack variable returned. string.
'''
def get_current_variable(index_variables):
    current = index_variables
    if current >= 0 :
        variable = "s(" + str(current) + ")"

    return variable

'''
It returns a list that contains all the stack variables which are "active".
It goes from current to 0. 
s_vars: [string].
'''
def get_stack_variables(index_variables):
    current = index_variables
    s_vars = []
    for i in range(current,-1,-1):
        s_vars.append("s("+str(i)+")")

    return s_vars


'''
It returns the posth variable.
index_variables: top stack index. int.
pos: position of the variable required. int.
variable: stack variable returned. string.
'''
def get_ith_variable(index_variables, pos):
    current = index_variables
    if (current >= pos):
        idx = current-pos
        variable = "s(" + str(idx) + ")"
        
    return variable

'''
It returns the local variable bound to argument address.  If it
does not exist, the method creates and store it in the dictionary
local_variables.
-address: memory address. string.
-var: new local variable. string.
'''
def get_local_variable(address):
    global current_local_var
    global local_variables
    
    try:
        idx = local_variables[int(address)]
        #var = "l(" + str(idx) + ")"
        return idx
    except KeyError:
        local_variables[int(address)] = current_local_var
        #var = "l(" + str(current_local_var) + ")"
        current_local_var += 1
        return current_local_var-1

'''
It adds to the list max_field_list the index of the field used.
-value: index_field. int.
'''
def update_field_index(value,block):
#    global max_field_list
    global fields_per_block

    if block not in fields_per_block:
        fields_per_block[block]=[value]
    elif value not in fields_per_block[block]:
        fields_per_block[block].append(value)
        
    # if value not in max_field_list:
    #     max_field_list.append(value)
        
'''
It adds to the list bc_in_use the name of the contract variable used.
-value: contract variable name. string.
'''
def update_bc_in_use(value,block):
    # global bc_in_use
    global bc_per_block


    if block not in bc_per_block:
        bc_per_block[block]=[value]
    elif value not in bc_per_block[block]:
        bc_per_block[block].append(value)
    
    # if value not in bc_in_use:
    #     bc_in_use.append(value)

def update_local_variables(value,block):
    global lvariables_per_block

    if block not in lvariables_per_block:
        lvariables_per_block[block]=[value]
    elif value not in lvariables_per_block[block]:
        lvariables_per_block[block].append(value)
        
def process_tops(top1,top2):
    top1_aux = 0 if top1 == float("inf") else top1
    top2_aux = 0 if top2 == float("inf") else top2

    return top1_aux, top2_aux

'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes0(opcode,index_variables,block):
    if opcode == "ADD":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
       
        instr = v3+" = " + v1 + "+" + v2
        
    elif opcode == "MUL":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "*" + v2
    elif opcode == "SUB":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "-" + v2
    elif opcode == "DIV":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "/" + v2
    elif opcode == "SDIV":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "/" + v2
    elif opcode == "MOD":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "%" + v2
    elif opcode == "SMOD":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "%" + v2
    elif opcode == "ADDMOD":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_consume_variable(updated_variables)
        v4, updated_variables = get_new_variable(updated_variables)
        instr = v4+" = (" + v1 + "+" + v2 + ") % " + v3
    elif opcode == "MULMOD":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_consume_variable(updated_variables)
        v4, updated_variables = get_new_variable(updated_variables)
        instr = v4+" = (" + v1 + "*" + v2 + ") % " + v3
    elif opcode == "EXP":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = " + v1 + "^" + v2
    elif opcode == "SIGNEXTEND":
        _, updated_variables = get_consume_variable(index_variables)
        v0, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1+" = "+v0
    elif opcode == "STOP":
        instr = "skip"
        updated_variables = index_variables

    else:
        instr = "Error opcodes0: "+opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes10(opcode, index_variables,cond):
    if opcode == "LT":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3 , updated_variables = get_new_variable(updated_variables)
        if cond :
            instr = v3+ " = lt(" + v1 + ", "+v2+")"
        else :
            instr = "lt(" + v1 + ", "+v2+")"
        
    elif opcode == "GT":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3 , updated_variables = get_new_variable(updated_variables)
        if cond :
            instr = v3+ " = gt(" + v1 + ", "+v2+")"
        else :
            instr = "gt(" + v1 + ", "+v2+")"


    elif opcode == "SLT":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3 , updated_variables = get_new_variable(updated_variables)
        if cond :
            instr = v3+ " = slt(" + v1 + ", "+v2+")"
        else :
            instr = "slt(" + v1 + ", "+v2+")"

    elif opcode == "SGT":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3 , updated_variables = get_new_variable(updated_variables)
        if cond :
            instr = v3+ " = sgt(" + v1 + ", "+v2+")"
        else :
            instr = "sgt(" + v1 + ", "+v2+")"

    elif opcode == "EQ":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3 , updated_variables = get_new_variable(updated_variables)
        if cond:
            instr = v3+ "= eq(" + v1 + ", "+v2+")"
        else:
            instr = "eq(" + v1 + ", "+v2+")"

    elif opcode == "ISZERO":
        v1, updated_variables = get_consume_variable(index_variables)
        v2 , updated_variables = get_new_variable(updated_variables)
        if cond:
            instr = v2+ "= eq(" + v1 + ", 0)"
        else:
            instr = "eq(" + v1 + ", 0)"

    elif opcode == "AND":
            v1, updated_variables = get_consume_variable(index_variables)
            v2, updated_variables = get_consume_variable(updated_variables)
            v3, updated_variables = get_new_variable(updated_variables)
            instr = v3+" = and(" + v1 + ", " + v2+")"

    elif opcode == "OR":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = or(" + v1 + ", " + v2+")"

    elif opcode == "XOR":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = xor(" + v1 + ", " + v2+")"

    elif opcode == "NOT":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_new_variable(updated_variables)
        instr = v2+" = not(" + v1 + ")"

    elif opcode == "BYTE":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_consume_variable(updated_variables)
        v2, updated_variables = get_new_variable(updated_variables)
        instr = v2+" = byte(" + v0 + " , " + v1 + ")" 

    elif opcode == "SHL":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_consume_variable(updated_variables)
        v2, updated_variables = get_new_variable(updated_variables)
        instr = v2+" = shl(" + v0 + " , " + v1 + ")" 

    elif opcode == "SHR":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_consume_variable(updated_variables)
        v2, updated_variables = get_new_variable(updated_variables)
        instr = v2+" = shr(" + v0 + " , " + v1 + ")" 

    elif opcode == "SAR":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_consume_variable(updated_variables)
        v2, updated_variables = get_new_variable(updated_variables)
        instr = v2+" = sar(" + v0 + " , " + v1 + ")" 
        
    else:    
        instr = "Error opcodes10: "+ opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes20(opcode, index_variables,block):
    global str_arr
    
    if opcode == "SHA3":
        
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)

        blocks_sha3 = list(map(lambda x: x[1],sha3_blocks_arr.values()))

        if block in blocks_sha3:
            instr = v3+" = 0"
        else:
            instr = v3+" = sha3("+ v1+", "+v2+")"

    elif opcode == "KECCAK256":
        
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)

        blocks_sha3 = list(map(lambda x: x[1],sha3_blocks_arr.values()))

        if block in blocks_sha3:
            instr = v3+" = 0"
        else:
            instr = v3+" = keccak256("+ v1+", "+v2+")"

            
        
    else:
        instr = "Error opcodes20: "+opcode
        updated_variables = index_variables

    return instr, updated_variables

'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes30(opcode, value, index_variables,block):
    global extcodehash_cont
    
    if opcode == "ADDRESS":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = address"
        update_bc_in_use("address",block)
    elif opcode == "BALANCE":
        _, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1+" = balance"
        update_bc_in_use("balance",block)
    elif opcode == "ORIGIN":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = origin"
        update_bc_in_use("origin",block)
    elif opcode == "CALLER":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = caller"
        update_bc_in_use("caller",block)
    elif opcode == "CALLVALUE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = callvalue"
        update_bc_in_use("callvalue",block)
    elif opcode == "CALLDATALOAD":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        val = str(value).split("_")
        if val[0] == "Id":
            instr = v1+" = calldataload"
            update_bc_in_use("calldataload",block)
        elif str(value).startswith("/*"):
            val = str(value).strip("/*").strip("*/")
            instr = v1+" = "+val
            update_bc_in_use(val,block)
        else:
            if not c_trans:
                instr = v1+" = "+str(value).strip("_")
                update_bc_in_use(str(value).strip("_"),block)
            else:
                if str(value) in c_words:
                    val_end = str(value)+"_sol"
                else:
                    val_end = str(value)
                instr = v1+" = "+val_end
                update_bc_in_use(val_end,block)
    elif opcode == "CALLDATASIZE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = calldatasize"
        update_bc_in_use("calldatasize",block)
    elif opcode == "CALLDATACOPY":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "CODESIZE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = codesize"
        update_bc_in_use("codesize",block)
    elif opcode == "CODECOPY":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "GASPRICE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = gasprice"
        update_bc_in_use("gasprice",block)
    elif opcode == "EXTCODESIZE":
        _, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1+" = extcodesize"
        update_bc_in_use("extcodesize",block)

    elif opcode == "EXTCODEHASH":
        _, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)

        # if not c_rbr and not saco:
        #     instr = v1+" = extcodehash("+v1+")"
        # else:
        instr = v1+" = extcodehash"+str(extcodehash_cont)
        update_bc_in_use("extcodehash"+str(extcodehash_cont),block)
        extcodehash_cont +=1
        
    elif opcode == "EXTCODECOPY":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "MCOPY":
        pass
    else:
        instr = "Error opcodes30: "+opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes40(opcode, index_variables,block):
    global blockhash_cont
    
    if opcode == "BLOCKHASH":
        v0, updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1+" = blockhash_"+str(blockhash_cont)
        update_bc_in_use("blockhash_"+str(blockhash_cont),block)
        blockhash_cont +=1
    elif opcode == "COINBASE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = coinbase"
        update_bc_in_use("coinbase",block)
    elif opcode == "TIMESTAMP":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = timestamp"
        update_bc_in_use("timestamp",block)
    elif opcode == "NUMBER":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = number"
        update_bc_in_use("number",block)
    elif opcode == "DIFFICULTY":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = difficulty"
        update_bc_in_use("difficulty",block)
    elif opcode == "PREVRANDAO":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = prevrandao"
        update_bc_in_use("prevrandao",block)
    elif opcode == "GASLIMIT":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = gaslimit"
        update_bc_in_use("gaslimit",block)
    elif opcode == "SELFBALANCE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = selfbalance"
        update_bc_in_use("selfbalance",block)
    elif opcode == "CHAINID":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = chainid"
        update_bc_in_use("chainid",block)
    elif opcode == "BASEFEE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = basefee"
        update_bc_in_use("basefee",block)

    else:
        instr = "Error opcodes40: "+opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodes50(opcode, value, index_variables,block,state_names):
    global new_fid
    global forget_memory
    global memory_intervals
    # global unknown_mstore
    
    if opcode == "POP":        
        v1, updated_variables = get_consume_variable(index_variables)
        instr=""
    elif opcode == "MLOAD":        
        _ , updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        try:
            l_idx = get_local_variable(value)

            if memory_intervals == "arrays" and val_mem40 != value:
                instr = v1+ " = " + "l(mem"+str(value)+")"
                update_local_variables(str(value),block)

            elif memory_intervals == "arrays" and val_mem40 == value:
                instr = ["ll = " + v1, v1 + " = fresh("+str(new_fid)+")"]
                new_fid+=1

            else:
                instr = v1+ " = " + "l(l"+str(l_idx)+")"
                update_local_variables(l_idx,block)
        except ValueError:
            instr = ["ll = " + v1, v1 + " = fresh("+str(new_fid)+")"]
            new_fid+=1
             
    elif opcode == "MSTORE":
        v0 , updated_variables = get_consume_variable(index_variables)
        v1 , updated_variables = get_consume_variable(updated_variables)
        try:
            l_idx = get_local_variable(value)
            if memory_intervals == "arrays" and val_mem40 != value:
               instr = "l(mem"+str(value)+") = "+ v1
               update_local_variables(str(value),block)
            elif memory_intervals == "arrays" and val_mem40 == value:
                instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
            else:
                instr = "l(l"+str(l_idx)+") = "+ v1
                update_local_variables(l_idx,block)
        except ValueError:
            #forget_memory = True
            #instr = ["FORGET MEM","ls(1) = "+ v1, "ls(2) = "+v0]
            instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
                # if vertices[block].is_mstore_unknown():
                #     unknown_mstore = True
            
    elif opcode == "MSTORE8":
        v0 , updated_variables = get_consume_variable(index_variables)
        v1 , updated_variables = get_consume_variable(updated_variables)
        try:
            l_idx = get_local_variable(value)
            if memory_intervals == "arrays":
               instr = "l(mem"+str(value)+") = "+ v1
               update_local_variables(str(value),block)
            else:
                instr = "l(l"+str(l_idx)+") = "+ v1
                update_local_variables(l_idx,block)
        except ValueError:
            #forget_memory = True
            #instr = ["FORGET MEM","ls(1) = "+ v1, "ls(2) = "+v0]
            instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
            
    elif opcode == "SLOAD":
        _ , updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        try:

            val = value.split("_")
            if len(val)==1:
                int(value)
                idx = value
            else:
                idx = value
            var_name = state_names.get(idx,idx)

            if var_name == "":
                var_name = idx

            instr = v1+" = " + "g(" + str(var_name) + ")"
            update_field_index(str(var_name),block)
        except ValueError:
            instr = ["gl = " + v1, v1 + " = fresh("+str(new_fid)+")"]
            new_fid+=1
    elif opcode == "SSTORE":
        v0 , updated_variables = get_consume_variable(index_variables)
        v1 , updated_variables = get_consume_variable(updated_variables)
        try:
            val = value.split("_")
            if len(val)==1:
                int(value)
                idx = value
            else:
                idx = value
            var_name = state_names.get(idx,idx)

            if var_name == "":
                var_name = idx

            instr = "g(" + str(var_name) + ") = " + v1
            update_field_index(str(var_name),block)
        except ValueError:
            #instr = ["gs(1) = "+ v0, "gs(2) = "+v1,"FORGET STR"]
            instr = ["gs(1) = "+ v0, "gs(2) = "+v1]
    # elif opcode == "JUMP":
    #     pass
    # elif opcode == "JUMPI":
    #     pass
    # elif opcode == "PC":
    #     pass
    elif opcode == "MSIZE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1 + " = msize"
        update_bc_in_use("msize",block)
    elif opcode == "GAS":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = "+"gas"
        update_bc_in_use("gas",block)
    elif opcode == "JUMPDEST":
        instr = ""
        updated_variables = index_variables
    # elif opcode == "SLOADEXT":
    #     pass
    # elif opcode == "SSTOREEXT":
    #     pass
    # elif opcode == "SLOADBYTESEXT":
    #     pass
    # elif opcode == "SSTOREBYTESEXT":
    #     pass
    else:
        instr = "Error opcodes50: "+ opcode
        updated_variables = index_variables

    return instr, updated_variables
'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
They corresponds to LOGS opcodes.
'''
def translateOpcodesA(opcode, index_variables):

    if opcode == "LOG0":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "LOG1":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "LOG2":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "LOG3":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
        
    elif opcode == "LOG4":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
        
    else:
        instr = "Error opcodesA: "+ opcode
    
    return instr, updated_variables


'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
'''
def translateOpcodesF(opcode, index_variables, addr,block):
    global c_address

    if opcode == "CREATE":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)

        val = "c_address"+str(c_address)
        
        instr = v1+" = "+val
        c_address+=1
        update_bc_in_use(val,block)


    elif opcode == "CREATE2":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)

        val = "c_address"+str(c_address)
        
        instr = v1+" = "+val
        c_address+=1
        update_bc_in_use(val,block)

    elif opcode == "CALL": #Suppose that all the calls are executed without errors
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1 +" = 1"
    elif opcode == "CALLCODE":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1 +" = 1" 
    elif opcode == "RETURN":
        # var = get_local_variable(addr)
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        # instr = "r "+var
        instr = ""
    elif opcode == "REVERT":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    elif opcode == "ASSERTFAIL":
        instr = ""
        updated_variables = index_variables
    elif opcode == "DELEGATECALL":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1 +" = 1"

    elif opcode == "STATICCALL":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr = v1 +" = 1"

    # elif opcode == "BREAKPOINT":
    #     pass
    # elif opcode == "RNGSEED":
    #     pass
    # elif opcode == "SSIZEEXT":
    #     pass
    # elif opcode == "SLOADBYTES":
    #     pass
    # elif opcode == "SSTOREBYTES":
    #     pass
    # elif opcode == "SSIZE":
    #     pass
    # elif opcode == "STATEROOT":
    #     pass
    # elif opcode == "TXEXECGAS":
    #     pass
    # elif opcode == "CALLSTATIC":
    #     pass
    # elif opcode == "INVALID":
    #     pass
    elif opcode == "SUICIDE":
        instr = ""
        updated_variables = index_variables
    else:
        instr = "Error opcodesF: "+opcode
        updated_variables = index_variables

    return instr, updated_variables

        
'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
-value is astring that contains the number pushed to the stack.
'''
def translateOpcodes60(opcode, value, index_variables):
    
    if opcode.startswith("PUSH0"):
        v1,updated_variables = get_new_variable(index_variables)
        instr = v1+" = 0"
    elif opcode.startswith("PUSH"):
        v1,updated_variables = get_new_variable(index_variables)
        dec_value = int(value, 16) #convert hex to dec
        instr = v1+" = " + str(dec_value)
    else:
        instr = "Error opcodes60: "+opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of dup bytecode.
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.

It duplicates what is stored in the stack at pos value (when
value == 1, it duplicates the top of the stack) .
-value refers to the position to be duplicated. string.
'''
def translateOpcodes80(opcode, value, index_variables):
    if opcode == "DUP":
        v1 = get_ith_variable(index_variables,int(value)-1)
        v2, updated_variables= get_new_variable(index_variables)
        instr = v2+" = "+v1
    else:
        instr = "Error opcodes80: "+opcode
        updated_variables = index_variables

    return instr, updated_variables


'''
It simulates the execution of swap bytecode.
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
-value refers to the position involved in the swap. string.
'''
def translateOpcodes90(opcode, value, index_variables):
    if opcode == "SWAP":
        v1 = get_ith_variable(index_variables,int(value))
        v2 = get_current_variable(index_variables)
        v3,_ = get_new_variable(index_variables)
        instr1 = v3 + " = " + v1
        instr2 = v1 + " = " + v2
        instr3 = v2 + " = " + v3
        instr = [instr1,instr2,instr3]
    else:
        instr = "Error opcodes90: "+opcode

    return instr, index_variables

'''
It simulates the execution of evm bytecodes.  It consumes or
generates variables depending on the bytecode and returns the
corresponding translated instruction and the variables's index
updated. It also updated the corresponding global variables.
Unclassified opcodes.
'''
def translateOpcodesZ(opcode, index_variables,block):
    if opcode == "RETURNDATASIZE":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = returndatasize"
        update_bc_in_use("returndatasize",block)
    elif opcode == "RETURNDATACOPY":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        instr = ""
    else:
        instr = "Error opcodesZ: "+opcode

    return instr, updated_variables

'''
It checks if the list instr contains the element to generated a
guard,i.e., just conditional statements, push and ended with a jump
intruction.
-instr is a list with instructions.
-It returns a boolean.
'''
def is_conditional(instr):
    valid = True
    i = 1
    if instr[0] in ["LT","SLT", "SGT","GT","EQ","ISZERO"] and instr[-1] in ["JUMP","JUMPI"]:
        while(i<len(instr)-2 and valid):
            ins = instr[i].split()
            if(ins[0] not in ["ISZERO","PUSH"]):
                valid = False
            i+=1
    else:
        valid = False

    return valid

'''
It returns the opposite guard of the one given as parameter.
-guard is the guard to be "reversed". string.
-opposit = not(guard). string.
'''     
def get_opposite_guard(guard):
    if guard[:2] == "lt":
        opposite = "geq"+guard[2:]
    elif guard[:3] == "leq":
        opposite = "gt"+guard[3:]
    elif guard[:2] == "gt":
        opposite = "leq"+guard[2:]
    elif guard[:3] == "geq":
        opposite = "lt"+guard[3:]
    elif guard[:3] == "slt":
        opposite = "geq"+guard[3:]
    elif guard[:3] == "sgt":
        opposite = "leq"+guard[3:]
    elif guard[:2] == "eq":
        opposite = "neq"+guard[2:]
    elif guard[:3] == "neq":
        opposite = "eq"+guard[3:]
    # elif guard[:6] == "isZero":
    #     opposite = "notZero"+guard[6:]
    # elif guard[:7] == "notZero":
    #     opposite = "isZero"+guard[7:]
    else:
        opposite = None
    return opposite


'''
It translates the bytecode corresponding to evm_opcode.
We mantain some empty instructions to insert the evm bytecodes.
They are remove when displaying.
-rule refers to the rule that is being built. rbr_rule instance.
-evm_opcode is the bytecode to be translated. string.
-list_jumps contains the addresses of next blocks.
-cond is True if the conditional statemnt refers to a guard. False otherwise.
-nop is True when generating nop annotations with the opcode. False otherwise.
-index_variables refers to the top stack index. int.
'''
def compile_instr(rule,evm_opcode,variables,list_jumps,cond,state_vars,results_sto_analysis):
    opcode = evm_opcode.split(" ")
    opcode_name = opcode[0]
    opcode_rest = ""
    
    if len(opcode) > 1:
        opcode_rest = opcode[1]

    if opcode_name in opcodes0:
        value, index_variables = translateOpcodes0(opcode_name, variables,rule.get_Id())
        rule.add_instr(value)
            
    elif opcode_name in opcodes10:
        value, index_variables = translateOpcodes10(opcode_name, variables,cond)
        rule.add_instr(value)
    elif opcode_name in opcodes20:
        value, index_variables = translateOpcodes20(opcode_name, variables,rule.get_Id())
        rule.add_instr(value)
    elif opcode_name in opcodes30:
        value, index_variables = translateOpcodes30(opcode_name,opcode_rest,variables,rule.get_Id())
        rule.add_instr(value)
    elif opcode_name in opcodes40:
        value, index_variables = translateOpcodes40(opcode_name,variables,rule.get_Id())
        rule.add_instr(value)
    elif opcode_name in opcodes50:
        value, index_variables = translateOpcodes50(opcode_name, opcode_rest, variables,rule.get_Id(),state_vars)
        if type(value) is list:
            for ins in value:
                rule.add_instr(ins)
        else:
            rule.add_instr(value)
    elif opcode_name[:4] in opcodes60:
        value, index_variables = translateOpcodes60(opcode_name, opcode_rest, variables)
        rule.add_instr(value)
    elif opcode_name[:3] in opcodes80:
        value, index_variables = translateOpcodes80(opcode_name[:3], opcode_name[3:], variables)
        rule.add_instr(value)
    elif opcode_name[:4] in opcodes90:
        value, index_variables = translateOpcodes90(opcode_name[:4], opcode_name[4:], variables)

        for ins in value: #SWAP returns a list (it is translated into 3 instructions)
            rule.add_instr(ins)
            
    elif opcode_name in opcodesA:
        value, index_variables = translateOpcodesA(opcode_name, variables)
        rule.add_instr(value)
    elif opcode_name in opcodesF:
        value, index_variables = translateOpcodesF(opcode_name,variables,opcode_rest,rule.get_Id())
        #RETURN
        rule.add_instr(value)
    elif opcode_name in opcodesZ:
        value, index_variables = translateOpcodesZ(opcode_name,variables,rule.get_Id())
        rule.add_instr(value)
    else:
        value = "Error. No opcode matchs"
        index_variables = variables
        rule.add_instr(value)
        
    if results_sto_analysis != [] and (opcode_name.startswith("SLOAD") or opcode_name.startswith("SSTORE")):
        r = results_sto_analysis.pop(0)
        
        if "*" in r:
            new_opcode_name = opcode_name+"COLD"
        else:
            set_access = r.split("->")[-1].strip()
            
            new_opcode_name = opcode_name+"WARM"+set_access
        rule.add_instr("nop("+new_opcode_name+")")
        
    else:
        rule.add_instr("nop("+opcode_name+")")

    return index_variables


'''
It creates the call to next block when the type of the current one is falls_to.
-index_variables refers to the top stack index. int.
-falls_to contains the address of the next block. int.
-instr contains the call instruction generated. string.
'''
def process_falls_to_blocks(index_variables, falls_to):
    top = get_stack_index(falls_to)[0]
    stack_variables = get_stack_variables(index_variables)[:top]
    if(len(stack_variables)!=0):
        p_vars = ",".join(stack_variables)+","
    else:
        p_vars = ""
        
    instr = "call(block"+str(falls_to)+"("+p_vars+"globals, bc))"
    return instr

'''
It translates the jump instruction. 
If the len(jumps)==1, it corresponds to a uncondtional jump.
Otherwise we have to convert it into a conditional jump. 
-block_id refers to the id of the current block. int. 
-variables refers to the top stack index. int.
-jumps is a list with the addresses of the next blocks. 
-It returns a tuple (rule1, rule2, instr) where rule1 and rule2 
 are rule_rbr instances corresponding to the guarded jump rules
 (if it is the case), and instr is the called instruction to the
 jump rule generated. If it is a jump, rule1 = rule2 = None.
'''
def create_uncond_jump(block_id,variables,jumps):
    if (len(jumps)>1):
        rule1, rule2 = create_uncond_jumpBlock(block_id,variables,jumps)
        stack_variables = get_stack_variables(variables)
        head = "jump"+str(block_id)

        in_vars = len(stack_variables)
        rule1.set_index_input(in_vars)
        rule2.set_index_input(in_vars)

    else:
        _ , updated_variables = get_consume_variable(variables)
        
        stack_variables = get_stack_variables(updated_variables)
        top = get_stack_index(jumps[0])[0]
        stack_variables = stack_variables[:top]
        head = "block"+str(jumps[0])
        rule1 = rule2 = None

    if (len(stack_variables)!=0):
        p_vars = ",".join(stack_variables)+","
    else:
        p_vars = ""

        
    instr = "call("+ head +"("+p_vars+"globals, bc))"
    return rule1,rule2,instr

'''
It generates the new two jump blocks (if it is the case).
-block_id is the address of jump blocks. int.
-variables refers to the top stack index when starting the rule. int.
-jumps is a list with the addresses of the next blocks.
- rule1 and rule2 are rbr_rule instances containing the jump rules.
'''
def create_uncond_jumpBlock(block_id,variables,jumps):
    v1, index_variables = get_consume_variable(variables)
    guard = "eq("+ v1 + ","+ str(jumps[0])+")"

    stack_variables = get_stack_variables(index_variables)

    top1 = get_stack_index(jumps[0])[0]
    top2 = get_stack_index(jumps[1])[0]
    
    if (len(stack_variables)!=0):
        p1_vars = ", ".join(stack_variables[:top1])+","
        p2_vars = ", ".join(stack_variables[:top2])+","
    else:
        p1_vars = p2_vars = ""
    
    rule1 = RBRRule(block_id,"jump",False,all_state_vars)
    rule1.set_guard(guard)
    instr = "call(block"+str(jumps[0])+"("+p1_vars+"globals,bc))"
    rule1.add_instr(instr)
    rule1.set_call_to(str(jumps[0]))

    rule2 = RBRRule(block_id,"jump",False,all_state_vars)
    guard = get_opposite_guard(guard)
    rule2.set_guard(guard)
    instr = "call(block"+str(jumps[1])+"("+p2_vars+"globals,bc))"
    rule2.add_instr(instr)
    rule2.set_call_to(str(jumps[1]))
    
    return rule1, rule2

'''
It translates the jumpi instruction.  
-block_id refers to the id of the current block. int.
-l_instr contains the instructions involved in the generation of the jump. 
-variables refers to the top stack index. int.
-jumps is a list with the addresses of the next blocks. [int].
- falls_to is the address of one of the next blocks. int.
-nop is True when generating nop annotations with the opcode. False otherwise.
-guard is true if we have to generate the guard. Otherwise we have to compare
 it he top variable is equal to 1.
-It returns a tuple (rule1, rule2, instr) where rule1 and rule2 
 are rule_rbr instances corresponding to the guarded jump rules,
 and instr is the called instruction to the jump rule generated.
'''
def create_cond_jump(block_id,l_instr,variables,jumps,falls_to,guard = None):

    rule1, rule2 = create_cond_jumpBlock(block_id,l_instr,variables,jumps,falls_to,guard)
    consume = 1 if l_instr[0] == "ISZERO" else 2
    stack_variables = get_stack_variables(variables)

    if (len(stack_variables)!=0):
        p_vars = ",".join(stack_variables)+","
    else:
        p_vars = ""


    in_vars = len(stack_variables)
    rule1.set_index_input(in_vars)
    rule2.set_index_input(in_vars)
    
    instr = "call(jump"+str(block_id)+"("+p_vars+"globals,bc))"
    
    return rule1, rule2, instr

'''
-l_instr contains the instructions involved in the generation of the jump. 
-variables refers to the top stack index. int.
-jumps is a list with the addresses of the next blocks. [int].
- falls_to is the address of one of the next blocks. int.
-nop is True when generating nop annotations with the opcode. False otherwise.
-guard is true if we have to generate the guard. Otherwise we have to compare
 it he top variable is equal to 1.
- rule1 and rule2 are rbr_rule instances containing the jump rules.
'''
def create_cond_jumpBlock(block_id,l_instr,variables,jumps,falls_to,guard):
    if guard:
        guard, index_variables = translateOpcodes10(l_instr[0], variables,False)
    else:
        _ , index_variables = get_consume_variable(variables)
        v1, index_variables = get_consume_variable(index_variables)
        guard = "eq("+v1+", 1 )"
        
    for elem in l_instr[1:]:
        if elem == "ISZERO":
            guard = get_opposite_guard(guard)
        elif elem[:4] == "PUSH":
            _, index_variables = get_new_variable(index_variables)
        elif elem == "JUMPI":
            _, index_variables = get_consume_variable(index_variables)
            _, index_variables = get_consume_variable(index_variables)
        else:
            guard = "Error while creating the jump"

    stack_variables = get_stack_variables(index_variables)

    top1 = get_stack_index(jumps[0])[0]
    top2 = get_stack_index(falls_to)[0]
    top1, top2 = process_tops(top1, top2)

    if (len(stack_variables)!=0):
        p1_vars = ", ".join(stack_variables[:top1])+"," if top1 !=0 else ""
        p2_vars = ", ".join(stack_variables[:top2])+"," if top2 != 0 else ""
    else:
        p1_vars = p2_vars = ""


    rule1 = RBRRule(block_id,"jump",False,all_state_vars)
    rule1.set_guard(guard)
    instr = "call(block"+str(jumps[0])+"("+p1_vars+"globals,bc))"
    rule1.add_instr(instr)
    rule1.set_call_to(str(jumps[0]))

    rule2 = RBRRule(block_id,"jump",False,all_state_vars)
    guard = get_opposite_guard(guard)
    rule2.set_guard(guard)
    instr = "call(block"+str(falls_to)+"("+p2_vars+"globals,bc))"
    rule2.add_instr(instr)
    rule2.set_call_to(str(falls_to))
    
    return rule1, rule2

'''
It returns true if the opcode ASSERTFAIL appears in the list of
intructions of the block
'''
def block_has_invalid(block):
    instr = block.get_instructions()
    comes_from_getter = block.get_assertfail_in_getter()
    array_access = block.get_access_array()
    div0_invalid = block.get_div_invalid_pattern()
    
    if "ASSERTFAIL" in instr and (not comes_from_getter):
        if array_access:
            t = "array"
        elif div0_invalid:
            t = "div0"
        else:
            t = "other"
                
        return (True,t)
    else:
        return (False, "no")
    
def block_access_array(block):
    return (block.get_access_array(), "array")

def block_div_invalid(block):
    return (block.get_div_invalid_pattern(), "div0")
'''
It generates the rbr rules corresponding to a block from the CFG.
index_variables points to the corresponding top stack index.
The stack could be reconstructed as [s(ith)...s(0)].
'''
def compile_block(block,state_vars, results_sto_analysis = []):
    global rbr_blocks
    global top_index
    global new_fid
    global forget_memory_blocks
    global str_arr

    str_arr = False
    
    cont = 0
    top_index = 0
    new_fid = 0
    finish = False
    has_lm40 = False #mload mem40
    has_sm40 = False #mstore mem40
    
    index_variables = block.get_stack_info()[0]-1
    block_id = block.get_start_address()
    is_string_getter = block.get_string_getter()
    rule = RBRRule(block_id, "block",is_string_getter,all_state_vars)
    rule.set_index_input(block.get_stack_info()[0])
    l_instr = block.get_instructions()
    
    mem_creation = 0 #mem_abs
    
    while not(finish) and cont< len(l_instr):
        if block.get_block_type() == "conditional" and is_conditional(l_instr[cont:]):
            rule1,rule2, instr = create_cond_jump(block.get_start_address(), l_instr[cont:],
                        index_variables, block.get_list_jumps(),
                                                  block.get_falls_to(),True)
            rule.add_instr(instr)
            
            for elem in l_instr[cont:]:
                rule.add_instr("nop("+elem.split()[0]+")")
                    

            rbr_blocks[rule1.get_rule_name()]=[rule1,rule2]
            finish = True
            
        elif l_instr[cont] == "JUMPI": #JUMPI without conditional instruction before. It checks if top == 1
            rule1,rule2, instr = create_cond_jump(block.get_start_address(),
                             l_instr[cont:], index_variables,
                             block.get_list_jumps(),
                             block.get_falls_to())

            rule.add_instr(instr)

            for elem in l_instr[cont:]:
                rule.add_instr("nop("+elem.split()[0]+")")
                    
            rbr_blocks[rule1.get_rule_name()]=[rule1,rule2]
            finish = True

        elif l_instr[cont] == "JUMP" and block.get_block_type() == "unconditional":
            rule1,rule2,instr = create_uncond_jump(block.get_start_address(),index_variables,block.get_list_jumps())

            if rule1:
                rbr_blocks[rule1.get_rule_name()]=[rule1,rule2]
            else:
                rule.set_call_to(block.get_list_jumps()[0])
                
            rule.add_instr(instr)

            rule.add_instr("nop(JUMP)")
        else:
            index_variables = compile_instr(rule,l_instr[cont],
                                                   index_variables,block.get_list_jumps(),True,state_vars,results_sto_analysis)
            has_lm40 = has_lm40 or is_mload40(l_instr[cont])
            has_sm40 = has_sm40 or is_mstore40(l_instr[cont])
            
        cont+=1

        if has_lm40 and has_sm40:
            mem_creation += 1
            has_lm40 = False
            has_sm40 = False

    if(block.get_block_type()=="falls_to"):
        instr = process_falls_to_blocks(index_variables,block.get_falls_to())
        rule.set_call_to(block.get_falls_to())
        rule.add_instr(instr)

    rule.set_fresh_index(top_index)

    # #    inv = block_has_invalid(l_instr)
    # inv = block_access_array(block)
    # if inv:
    #     rule.activate_invalid()

    # if forget_memory:
    #     forget_memory_blocks.append(rule)

    return rule,mem_creation


'''
Disasm files can be modified manually and may contain nonexistent
blocks. This function generate one empty rule for these blocks.
-blocks is a list with the id of the unbuilt blocks.
-It returns a list with the new rules generated.
'''
def create_blocks(blocks):
    global rbr_blocks
    
    rules = []
    for b in blocks:
        rule = RBRRule(b,"block")
        rbr_blocks["block"+str(b)]=[rule]
        rules.append(rule)
    return rules


'''
It creates a file with the rbr rules generated for the programa
analyzed. If it contains more than 1 smart contract it creates a file
for each smart contract.
-rbr is a list containing instances of rbr_rule.
-executions refers to the number of smart contract that has been translated. int.
'''
def write_rbr(rbr,executions,cname = None):
    

    if "costabs" not in os.listdir(global_params_ethir.costabs_path):
        os.mkdir(global_params_ethir.costabs_path+"/costabs")

    if executions == None:
        name = global_params_ethir.costabs_path+"/costabs/rbr.rbr"
    elif cname == None:
        name = global_params_ethir.costabs_path+"/costabs/rbr"+str(executions)+".rbr"
    else:
        name = global_params_ethir.costabs_path+"/costabs/"+cname+".rbr"
    with open(name,"w") as f:
        for rules in rbr:
            for r in rules:
                f.write(r.rule2string(memory_intervals)+"\n")

    f.close()
        
def component_update_fields_block(block,data):
    fields, bc, local = data #local
    rule = rbr_blocks.get("block"+str(block),-1)
    if rule != -1:
        rule[0].update_global_arg(fields)
        rule[0].update_bc(bc)
        rule[0].update_local_arg(local)

    rule = rbr_blocks.get("jump"+str(block),-1)
    if rule != -1:
        rule[0].update_global_arg(fields)
        rule[1].update_global_arg(fields)
        rule[0].update_bc(bc)
        rule[1].update_bc(bc)
        rule[0].update_local_arg(local)
        rule[1].update_local_arg(local)

    
def component_update_fields(rule,component):
    
    block = rule.get_Id()
    
    fields = fields_per_block.get(block,[])
    bc = bc_per_block.get(block,[])
    local = lvariables_per_block.get(block,[])
    
    if fields != [] or bc !=[] or local !=[]:
        rule.update_global_arg(fields)
        rule.update_bc(bc)
        rule.update_local_arg(local)
        
        # if rule.get_type() == "block":
        #         rule = rbr_blocks.get("jump"+str(block),-1)
        #         if rule != -1:
        #             print "JUMP"
        #             rule[0].update_global_arg(fields)
        #             rule[1].update_global_arg(fields)
        # print "COMPONENT_OF"
        # print component[block]
        for elem_c in component[block]:
            component_update_fields_block(elem_c,(fields,bc,local))#local)

def forget_mem_variables():
    global new_fid
    
    for frule in forget_memory_blocks:
        new_fid = frule.forget_memory(new_fid)
            
def check_invalid_options(block,invalid_options):
    if invalid_options == "all":
        inv = block_has_invalid(block)
    elif invalid_options == "array":
        inv = block_access_array(block)
    elif invalid_options == "div":
        inv = block_div_invalid(block)
    else:
        inv = (False, "no")

    return inv

def is_mload40(opcode):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    if opcode_name == "MLOAD" and value=="64":
        return True
    else:
        return False

def is_mstore40(opcode):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    if opcode_name == "MSTORE" and value == "64":
        return True
    else:
        return False


'''
Main function that build the rbr representation from the CFG of a solidity file.
-blocks_input contains a list with the blocks of the CFG. basicblock.py instances.
-stack_info is a mapping block_id => height of the stack.
-block_unbuild is a list that contains the id of the blocks that have not been considered yet. [string].
-nop_opcodes is True if it has to annotate the evm bytecodes.
-saco_rbr is True if it has to generate the RBR in SACO syntax.
-exe refers to the number of smart contracts analyzed.
'''
def evm2rbr_compiler(blocks_input = None, stack_info = None, block_unbuild = None,saco_rbr = None,c_rbr = None, exe = None, contract_name = None, component = None, oyente_time = 0,scc = None,svc_labels = None,gotos=None,fbm = [], source_info = None,mem_abs = None,sto = None,storage_analysis = None):
    global rbr_blocks
    global stack_index
    global vertices
    global c_trans
    global all_state_vars
    global forget_memory
    global memory_intervals
    global storage_arrays    
    global sha3_blocks_arr
    global val_mem40

    
    init_globals()
    c_trans = c_rbr
    
    stack_index = stack_info
    component_of = component

    source_map = source_info["source_map"]
    if source_map and source_map.var_names !=[]:
        all_state_vars = source_map._get_var_names()

    mapping_state_variables = source_info["name_state_variables"]

    memory_intervals = mem_abs[0]
    storage_arrays["ids"] = mem_abs[1]

    sha3_blocks_arr = (mem_abs[2])
    val_mem40 = mem_abs[3]

    
    begin = dtimer()
    blocks_dict = blocks_input
    vertices = blocks_input
    
    if svc_labels.get("verify",False):
        invalid_options = svc_labels.get("invalid",False)
        if not(invalid_options):
            invalid_options = "all"
    else:
        invalid_options = False
        
    try:
        if blocks_dict and stack_info:
            blocks = sorted(blocks_dict.values(), key = getKey)
            mem_creation = []
            for block in blocks:

                if storage_analysis != None:
                    results_sto_analysis = storage_analysis.get_cfg_info(str(block.get_start_address()))
                else:
                    results_sto_analysis = []

            #if block.get_start_address() not in to_clone:
                forget_memory = False
                rule, mem_result = compile_block(block,mapping_state_variables,results_sto_analysis)

                if mem_result>0:
                    mem_creation.append((block.get_start_address(),mem_result))
                
                inv = check_invalid_options(block,invalid_options)
                    
                if inv[0]:
                    rule.activate_invalid()
                    rule.set_invalid_source(inv[1])

                rbr_blocks[rule.get_rule_name()]=[rule]
            

            rule_c = create_blocks(block_unbuild)
               
            for rule in rbr_blocks.values():# _blocks.values():
                for r in rule:
                    component_update_fields(r,component_of)
                    #                r.update_global_arg(fields_per_block.get(r.get_Id(),[]))
                    #                r.set_global_vars(max_field_list)
                    #r.set_args_local(current_local_var)
                    #r.display()

            for rule in rbr_blocks.values():
                for r in rule:
                    # if r.get_Id() == 1552 and r.get_type() == "block":
                    #     print "HOLAAAAAAA"
                    #     r.display()
                    #     print r.get_call_to()
                    jumps_to = r.get_call_to()
                    if jumps_to != -1 and jumps_to !="-1":
                        f = rbr_blocks["block"+str(jumps_to)][0].build_field_vars()
                        bc = rbr_blocks["block"+str(jumps_to)][0].vars_to_string("data")

                        if memory_intervals == "arrays":
                            l = rbr_blocks["block"+str(jumps_to)][0].build_local_vars_memabs()
                        else:
                            l = rbr_blocks["block"+str(jumps_to)][0].build_local_vars()

                        r.set_call_to_info((f,bc,l))

                    r.update_rule(saco_rbr,memory_intervals)

            #forget_mem_variables()

            # for rule in rbr_blocks.values():
            #     for r in rule:
            #         if r.get_Id() == 1552 and r.get_type() == "block":
            #             print "HOLAAAAAAA"
            #             r.display()
            
            rbr = sorted(rbr_blocks.values(),key = orderRBR)
            write_rbr(rbr,exe,contract_name)
        
            end = dtimer()
            ethir_time = end-begin
            print("Build RBR: "+str(ethir_time)+"s")
            store_times(oyente_time,ethir_time)

            if source_map:
                write_info_lines(rbr,source_map,contract_name)
               

            if init_fields != []:
                init_fields_def = rename_init_fields(mapping_state_variables)
            else:
                init_fields_def ={}


            # print(mem_creation)
                
            # print "********************************************"
            # print storage_arrays
            if saco_rbr:
                saco.rbr2saco(rbr,exe,contract_name)
            if c_rbr == "int":
                c_translation.rbr2c(rbr,exe,contract_name,component_of,scc,svc_labels,gotos,fbm,init_fields_def,mem_creation,memory_intervals,sto,storage_arrays,mapping_state_variables)
            elif c_rbr == "uint":
                c_utranslation.rbr2c(rbr,exe,contract_name,component_of,scc,svc_labels,gotos,fbm,init_fields_def,mem_creation,memory_intervals,sto,storage_arrays,mapping_state_variables)
            elif c_rbr == "uint256":
                e_translation.rbr2c(rbr,exe,contract_name,scc,svc_labels,gotos,fbm,init_fields_def)
            
            print("*************************************************************")

            return rbr
        
        else :
            print ("Error, you have to provide the CFG associated with the solidity file analyzed")
    except Exception as e:
        traceback.print_exc()
        if len(e.args)>1:
            arg = e[1]
            if arg == 5:
                raise Exception("Error in SACO trnaslation",5)
            elif arg == 6:
                raise Exception("Error in C trnaslation",6)
        else:    
            raise Exception("Error in RBR generation",4)


def evm2rbr_init(blocks_input = None, stack_info = None, block_unbuild = None, component = None,source_info = None):
    global rbr_blocks
    global stack_index
    global vertices
    global c_trans
    global all_state_vars
    global forget_memory
    
    init_globals()
    
    stack_index = stack_info
    component_of = component
    
    blocks_dict = blocks_input
    vertices = blocks_input

    invalid_options = False

    source_map = source_info["source_map"]
    if source_map:
        all_state_vars = source_map._get_var_names()

    mapping_state_variables = source_info["name_state_variables"]

   


    try:
        if blocks_dict and stack_info:
            blocks = sorted(blocks_dict.values(), key = getKey)
            for block in blocks:
            #if block.get_start_address() not in to_clone:
                forget_memory = False
                rule = compile_block(block,mapping_state_variables)

                inv = check_invalid_options(block,invalid_options)
                    
                if inv[0]:
                    rule.activate_invalid()
                    rule.set_invalid_source(inv[1])

                rbr_blocks[rule.get_rule_name()]=[rule]
            

            rule_c = create_blocks(block_unbuild)
               
            for rule in rbr_blocks.values():# _blocks.values():
                for r in rule:
                    component_update_fields(r,component_of)
                    #                r.update_global_arg(fields_per_block.get(r.get_Id(),[]))
                    #                r.set_global_vars(max_field_list)
                    #r.set_args_local(current_local_var)
                    #r.display()

            for rule in rbr_blocks.values():
                for r in rule:
                    jumps_to = r.get_call_to()
                
                    if jumps_to != -1:
                        f = rbr_blocks["block"+str(jumps_to)][0].build_field_vars()
                        bc = rbr_blocks["block"+str(jumps_to)][0].vars_to_string("data")
                        
                        if memory_intervals == "arrays":
                            l = rbr_blocks["block"+str(jumps_to)][0].build_local_vars_memabs()
                        else:
                            l = rbr_blocks["block"+str(jumps_to)][0].build_local_vars()
                        r.set_call_to_info((f,bc,l))

                    r.update_rule(memory_intervals)

            #forget_mem_variables()
                    
            rbr = sorted(rbr_blocks.values(),key = orderRBR)

            process_init_values_fields(rbr)
            # for r in rbr:
            #     for rr in r:
            #         rr.display()
            #TODO: Filter fields
        
        else :
            print ("Error, you have to provide the CFG associated with the solidity file analyzed")
    except Exception as e:
        #traceback.print_exc()
        raise Exception("Error in RBR generation for init fields",4)


def process_init_values_fields(rbr):
    global init_fields

    field_vals = []
    for rules in rbr:
        for r in rules:
            ins = r.get_instructions()
            fields = list(filter(lambda x: x.startswith("g("),ins))

            init_fields_of_rule = get_initialization(fields,ins)
            field_vals+=init_fields_of_rule
            
    init_fields = field_vals

def get_initialization(fields,instructions):
    field_vals = []
    
    for f in fields:
        elems = f.split("=")
        field_var = elems[0].strip()
        stack_var = elems[-1].strip()
        idx = instructions.index(f)
        potential_ins = instructions[:idx]
        assignments = list(filter(lambda x: x.startswith(stack_var),potential_ins))
        init_value = assignments[-1].split("=")[-1].strip()
        fields_vals = field_vals.append(field_var+" = "+str(init_value))

    return field_vals

def rename_init_fields(mapping_state_variables):

    rename_ins = []
    name_vars = []
    initialized_fields = {}
    for f in init_fields:
        elems = f.split("=")
        g_var = elems[0].strip()
        val = elems[1].strip()

        f_index = g_var[2:-1]
        name = mapping_state_variables.get(f_index,f_index)
        initialized_fields[name]  = val

    # print initialized_fields
        # if name not in name_vars:
        #     name_vars.append(name)
            
        # rename_ins.append(new_ins)

    return initialized_fields

def get_info_lines(rbr,source_map,f):
    for rules in rbr:
        for rule in rules:
            if 'block' in rule.get_rule_name(): 
                cont_rbr = 0
                offset=0
                i = 0
                nBq = rule.get_Id()
                bq=''
                if '_' in str(nBq): #Caso con _X
                    while nBq[i] != '_' :
                        bq = bq + nBq[i]
                        i = i+1
                    nBq = bq

                for inst in rule.get_instructions(): 
                    if not('nop' in inst):
                        continue;
							
                    pc = int(nBq)+offset
                        
                    try:
                        nLineCom = source_map.get_init_pos(pc)
                        nLineFin = source_map.get_end_pos(pc)
                        nLine = source_map.get_location(pc)['begin']['line']
                        nLine = nLine+1
                            # bloque = rule.get_rule_name()[5:]
                        f.write("solidityline(" + str(rule.get_rule_name()) + "," + str(cont_rbr) + "," + str(nLine) + "," + str(nLineCom)  + "," + str(nLineFin) + ").  " + " % " + str(offset) + " " + str(inst) + "	\n")  

                    except:
                        continue;

                    if 'nop'in inst:
                        offset = offset + get_inc_offset(inst);
                                
                    cont_rbr = cont_rbr +1          

def get_fun_lines_info(rbr, source_map,f):
    functions = []
    
    for rules in rbr:
        for rule in rules:
            if 'block' in rule.get_rule_name(): 
                nBq = get_block_id(rule)
                
                source = source_map.get_source_code(nBq)
                lines = source.split("\n")

                if lines[0].find("function ")!=-1:
                    fun_name = get_func_name(lines[0])

                    init_pos = source_map.get_init_pos(nBq)
                    end_pos =  source_map.get_end_pos(nBq)

                    if (fun_name,init_pos,end_pos) not in functions:
                        functions.append((fun_name,init_pos,end_pos))

    lines = list(map(lambda x: "solidityfunctionline("+x[0]+","+str(x[1])+","+str(x[2])+").",functions))
    f.write("\n".join(lines))


def write_info_lines(rbr,source_map,contract_name):
    final_path = global_params_ethir.costabs_path + "/costabs/" + contract_name + "_lines.pl"
    f = open (final_path, "w")
    get_info_lines(rbr,source_map,f)
    get_fun_lines_info(rbr,source_map,f)
    f.close()


   
def get_inc_offset(op): 
    if 'PUSH' in op: # nop(PUSH1)
        n=op[8:-1]
        return int(n)+1
    return 1; 

def get_block_id(rule) :
    nBq = str(rule.get_Id())
    pos = nBq.find("_")
    if pos == -1:
        return int(nBq)
    else:
        return int(nBq[0:pos])
    
def get_func_name(line):
    pos_func = line.find("function")
    
    pos_init = line.find("(",pos_func+8)

    if pos_init !=-1:
        name = line[pos_func+8:pos_init].strip()

    else:
        pos_init = line.find("\\")
        pos_init2 = line.find("\*")
        if pos_init!=-1:
             name = line[pos_func+8:pos_init].strip()
        elif pos_init2 !=-1:
            name = line[pos_func+8:pos_init2].strip()
        else:
            name = line[pos_func+8::].strip()

    return name
