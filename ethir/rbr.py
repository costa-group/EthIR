#Pablo Gordillo

from rbr_rule import RBRRule
import opcodes
from basicblock import Tree
from utils import getKey, orderRBR, getLevel, store_times
import os
import saco
import c_translation
import c_utranslation
from timeit import default_timer as dtimer
from graph_scc import get_entry_scc
import traceback

costabs_path = "/tmp/costabs/" 
tmp_path = "/tmp/"

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
                "XOR", "NOT", "BYTE"]

    global opcodes20
    opcodes20 = ["SHA3"]

    global opcodes30
    opcodes30 = ["ADDRESS", "BALANCE", "ORIGIN", "CALLER", "CALLVALUE",
                "CALLDATALOAD", "CALLDATASIZE", "CALLDATACOPY", "CODESIZE",
                "CODECOPY", "GASPRICE", "EXTCODESIZE", "EXTCODECOPY", "MCOPY"]

    global opcodes40
    opcodes40 = ["BLOCKHASH", "COINBASE", "TIMESTAMP", "NUMBER",
                 "DIFFICULTY", "GASLIMIT"]

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
                "CALLSTATIC", "INVALID", "SUICIDE"]

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

    global unknown_mstore
    unknown_mstore = False

    global blockhash_cont
    blockhash_cont = 0

    global c_trans
    c_trans = False

    global c_words
    c_words = ["char","for","index","y1","log","rindex","round","exp"]

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
def translateOpcodes0(opcode,index_variables):
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
        instr = v2+" = byte(" + v1 + " , " + v0 + ")" 
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
def translateOpcodes20(opcode, index_variables):
    if opcode == "SHA3":
        v1, updated_variables = get_consume_variable(index_variables)
        v2, updated_variables = get_consume_variable(updated_variables)
        v3, updated_variables = get_new_variable(updated_variables)
        instr = v3+" = sha3("+ v1+", "+v2+")"

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
    elif opcode == "GASLIMIT":
        v1, updated_variables = get_new_variable(index_variables)
        instr = v1+" = gaslimit"
        update_bc_in_use("gaslimit",block)
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
def translateOpcodes50(opcode, value, index_variables,block):
    global new_fid
    global unknown_mstore
    
    if opcode == "POP":        
        v1, updated_variables = get_consume_variable(index_variables)
        instr=""
    elif opcode == "MLOAD":
        _ , updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        try:
            l_idx = get_local_variable(value)
            instr = v1+ " = " + "l(l"+str(l_idx)+")"
            update_local_variables(l_idx,block)
        except ValueError:
            instr = ["ll = " + v1, v1 + " = fresh("+str(new_fid)+")"]
            new_fid+=1
        # if vertices[block].get_trans_mstore() == False and unknown_mstore == False:
        #     _ , updated_variables = get_consume_variable(index_variables)
        #     v1, updated_variables = get_new_variable(updated_variables)
        #     try:
        #         l_idx = get_local_variable(value)
        #         instr = v1+ " = " + "l(l"+str(l_idx)+")"
        #         update_local_variables(l_idx,block)
        #     except ValueError:
        #         instr = ["ll = " + v1, v1 + " = fresh("+str(new_fid)+")"]
        #         new_fid+=1
        # else:
        #     _ , updated_variables = get_consume_variable(index_variables)
        #     v1, updated_variables = get_new_variable(updated_variables)
            
        #     instr = v1 + " = "+ "fresh("+str(new_fid)+")"
        #     new_fid+=1
            
             
    elif opcode == "MSTORE":
        if vertices[block].get_trans_mstore() == False and unknown_mstore == False:
            v0 , updated_variables = get_consume_variable(index_variables)
            v1 , updated_variables = get_consume_variable(updated_variables)
            try:
                l_idx = get_local_variable(value)
                instr = "l(l"+str(l_idx)+") = "+ v1
                update_local_variables(l_idx,block)
            except ValueError:
                instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
                if vertices[block].is_mstore_unknown():
                    unknown_mstore = True
        else:
            v0 , updated_variables = get_consume_variable(index_variables)
            v1 , updated_variables = get_consume_variable(updated_variables)
            try:
                l_idx = get_local_variable(value)
                instr = "l(l"+str(l_idx)+") = "+ "fresh("+str(new_fid)+")"
                new_fid+=1
                update_local_variables(l_idx,block)
            except ValueError:
                instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
            
    elif opcode == "MSTORE8":
        if vertices[block].get_trans_mstore() == False and unknown_mstore == False:
            v0 , updated_variables = get_consume_variable(index_variables)
            v1 , updated_variables = get_consume_variable(updated_variables)
            try:
                l_idx = get_local_variable(value)
                instr = "l(l"+str(l_idx)+") = "+ v1
                update_local_variables(l_idx,block)
            except ValueError:
                instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
                if vertices[block].is_mstore_unknown():
                    unknown_mstore = True
        else:
            v0 , updated_variables = get_consume_variable(index_variables)
            v1 , updated_variables = get_consume_variable(updated_variables)
            try:
                l_idx = get_local_variable(value)
                instr = "l(l"+str(l_idx)+") = "+ "fresh("+str(new_fid)+")"
                new_fid+=1
                update_local_variables(l_idx,block)
            except ValueError:
                instr = ["ls(1) = "+ v1, "ls(2) = "+v0]
    elif opcode == "SLOAD":
        _ , updated_variables = get_consume_variable(index_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        try:
            val = value.split("_")
            if len(val)==1:
                idx = int(value)
            instr = v1+" = " + "g(" + value + ")"
            update_field_index(value,block)
        except ValueError:
            instr = ["gl = " + v1, v1 + " = fresh("+str(new_fid)+")"]
            new_fid+=1
    elif opcode == "SSTORE":
        v0 , updated_variables = get_consume_variable(index_variables)
        v1 , updated_variables = get_consume_variable(updated_variables)
        try:
            val = value.split("_")
            if len(val)==1:
                idx = int(value)
            instr = "g(" + value + ") = " + v1
            update_field_index(value,block)
        except ValueError:
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
def translateOpcodesF(opcode, index_variables, addr):
    if opcode == "CREATE":
        _, updated_variables = get_consume_variable(index_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        _, updated_variables = get_consume_variable(updated_variables)
        v1, updated_variables = get_new_variable(updated_variables)
        instr=""
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
    
    if opcode == "PUSH":
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
        _, updated_variables = get_consume_variable(index_variables)
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
    if instr[0] in ["LT","GT","EQ","ISZERO"] and instr[-1] in ["JUMP","JUMPI"]:
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
    elif guard == "slt":
        opposite = "geq"+guard[3:]
    elif guard == "sgt":
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
def compile_instr(rule,evm_opcode,variables,list_jumps,cond):
    opcode = evm_opcode.split(" ")
    opcode_name = opcode[0]
    opcode_rest = ""

    if len(opcode) > 1:
        opcode_rest = opcode[1]

    if opcode_name in opcodes0:
        value, index_variables = translateOpcodes0(opcode_name, variables)
        rule.add_instr(value)
    elif opcode_name in opcodes10:
        value, index_variables = translateOpcodes10(opcode_name, variables,cond)
        rule.add_instr(value)
    elif opcode_name in opcodes20:
        value, index_variables = translateOpcodes20(opcode_name, variables)
        rule.add_instr(value)
    elif opcode_name in opcodes30:
        value, index_variables = translateOpcodes30(opcode_name,opcode_rest,variables,rule.get_Id())
        rule.add_instr(value)
    elif opcode_name in opcodes40:
        value, index_variables = translateOpcodes40(opcode_name,variables,rule.get_Id())
        rule.add_instr(value)
    elif opcode_name in opcodes50:
        value, index_variables = translateOpcodes50(opcode_name, opcode_rest, variables,rule.get_Id())
        if type(value) is list:
            for ins in value:
                rule.add_instr(ins)
        else:
            rule.add_instr(value)
    elif opcode_name[:4] in opcodes60:
        value, index_variables = translateOpcodes60(opcode_name[:4], opcode_rest, variables)
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
        value, index_variables = translateOpcodesF(opcode_name,variables,opcode_rest)
        #RETURN
        rule.add_instr(value)
    elif opcode_name in opcodesZ:
        value, index_variables = translateOpcodesZ(opcode_name,variables,rule.get_Id())
        rule.add_instr(value)
    else:
        value = "Error. No opcode matchs"
        index_variables = variables
        rule.add_instr(value)

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
    
    rule1 = RBRRule(block_id,"jump")
    rule1.set_guard(guard)
    instr = "call(block"+str(jumps[0])+"("+p1_vars+"globals,bc))"
    rule1.add_instr(instr)
    rule1.set_call_to(str(jumps[0]))

    rule2 = RBRRule(block_id,"jump")
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


    rule1 = RBRRule(block_id,"jump")
    rule1.set_guard(guard)
    instr = "call(block"+str(jumps[0])+"("+p1_vars+"globals,bc))"
    rule1.add_instr(instr)
    rule1.set_call_to(str(jumps[0]))

    rule2 = RBRRule(block_id,"jump")
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
def compile_block(block):
    global rbr_blocks
    global top_index
    global new_fid
    global unknown_mstore
    
    cont = 0
    top_index = 0
    new_fid = 0
    finish = False
    
    index_variables = block.get_stack_info()[0]-1
    block_id = block.get_start_address()
    is_string_getter = block.get_string_getter()
    rule = RBRRule(block_id, "block",is_string_getter)
    rule.set_index_input(block.get_stack_info()[0])
    l_instr = block.get_instructions()
    unknown_mstore = False
    
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

        elif l_instr[cont] == "JUMP":
            rule1,rule2,instr = create_uncond_jump(block.get_start_address(),index_variables,block.get_list_jumps())

            if rule1:
                rbr_blocks[rule1.get_rule_name()]=[rule1,rule2]
            else:
                rule.set_call_to(block.get_list_jumps()[0])
                
            rule.add_instr(instr)

            rule.add_instr("nop(JUMP)")
        else:
            index_variables = compile_instr(rule,l_instr[cont],
                                                   index_variables,block.get_list_jumps(),True)        
        cont+=1

    if(block.get_block_type()=="falls_to"):
        instr = process_falls_to_blocks(index_variables,block.get_falls_to())
        rule.set_call_to(block.get_falls_to())
        rule.add_instr(instr)

    rule.set_fresh_index(top_index)

    # #    inv = block_has_invalid(l_instr)
    # inv = block_access_array(block)
    # if inv:
    #     rule.activate_invalid()

    return rule


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
    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)

    if executions == None:
        name = costabs_path+"rbr.rbr"
    elif cname == None:
        name = costabs_path+"rbr"+str(executions)+".rbr"
    else:
        name = costabs_path+cname+".rbr"
    with open(name,"w") as f:
        for rules in rbr:
            for r in rules:
                f.write(r.rule2string()+"\n")

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
            
'''
Main function that build the rbr representation from the CFG of a solidity file.
-blocks_input contains a list with the blocks of the CFG. basicblock.py instances.
-stack_info is a mapping block_id => height of the stack.
-block_unbuild is a list that contains the id of the blocks that have not been considered yet. [string].
-nop_opcodes is True if it has to annotate the evm bytecodes.
-saco_rbr is True if it has to generate the RBR in SACO syntax.
-exe refers to the number of smart contracts analyzed.
'''
def evm2rbr_compiler(blocks_input = None, stack_info = None, block_unbuild = None,saco_rbr = None,c_rbr = None, exe = None, contract_name = None, component = None, oyente_time = 0,scc = None,svc_labels = None,gotos=None,fbm = []):
    global rbr_blocks
    global stack_index
    global vertices
    global c_trans
    
    init_globals()
    c_trans = c_rbr
    
    stack_index = stack_info
    component_of = component

    
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
            for block in blocks:
            #if block.get_start_address() not in to_clone:
                rule = compile_block(block)

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
                        l = rbr_blocks["block"+str(jumps_to)][0].build_local_vars()
                        r.set_call_to_info((f,bc,l))

                    r.update_rule()


            rbr = sorted(rbr_blocks.values(),key = orderRBR)
            write_rbr(rbr,exe,contract_name)
        
            end = dtimer()
            ethir_time = end-begin
            print("Build RBR: "+str(ethir_time)+"s")
            store_times(oyente_time,ethir_time)
            
            if saco_rbr:
                saco.rbr2saco(rbr,exe,contract_name)
            if c_rbr == "int":
                c_translation.rbr2c(rbr,exe,contract_name,scc,svc_labels,gotos,fbm)
            elif c_rbr == "uint":
                c_utranslation.rbr2c(rbr,exe,contract_name,scc,svc_labels,gotos,fbm)
            print("*************************************************************")

        else :
            print ("Error, you have to provide the CFG associated with the solidity file analyzed")
    except Exception as e:
        #traceback.print_exc()
        if len(e.args)>1:
            arg = e[1]
            if arg == 5:
                raise Exception("Error in SACO trnaslation",5)
            elif arg == 6:
                raise Exception("Error in C trnaslation",6)
        else:    
            raise Exception("Error in RBR generation",4)
            
