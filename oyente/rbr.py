import math
import sys
import rbr_rule
import opcodes




def init_globals():
    
    global opcodes0
    opcodes0 = ["STOP", "ADD", "MUL", "SUB", "DIV", "SDIV", "MOD",
                "SMOD", "ADDMOD", "MULMOD", "EXP", "SIGNEXTEND"]

    global opcodes10
    opcode10 = ["LT", "GT", "SLT", "SGT", "EQ", "ISZERO", "AND", "OR",
                "XOR", "NOT", "BYTE"]

    global opcodes20
    opcode20 = ["SHA3"]

    global opcodes30
    opcode30 = ["ADDRESS", "BALANCE", "ORIGIN", "CALLER", "CALLVALUE",
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
    
def getKey(block):
    return block.get_start_address()

def get_consume_variable(index_variables):
    current = index_variables[0]
    input_idx = index_variables[1]
    if current>=0:
        variable = "s("+str(current)+")"
        current = current-1
    else:
        variable ="in["+str(input_idx)+"]"
        input_idx = input_idx+1
    return  variable, (current, input_idx)

def get_new_variable(index_variables):
    new_current = index_variables[0]+1
    return "s("+str(new_current)+")", (new_current, index_variables[1])
    

'''

'''
def translateOpcodes0(opcode,index_variables):
    if opcode == "ADD":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "+" + v2
    elif opcode == "MUL":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "*" + v2
    elif opcode == "SUB":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "-" + v2
    elif opcode == "DIV":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "/" + v2
    # elif opcode == "SDIV":
    #     pass
    elif opcode == "MOD":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "%" + v2
    # elif opcode == "SMOD":
    #     pass
    elif opcode == "ADDMOD":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_consume_variable(update_variables)
        v4, update_variables = get_new_variable(update_variables)
        instr = v4+" = (" + v1 + "+" + v2 + ") % " + v3
    elif opcode == "MULMOD":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_consume_variable(update_variables)
        v4, update_variables = get_new_variable(update_variables)
        instr = v4+" = (" + v1 + "*" + v2 + ") % " + v3
    elif opcode == "EXP":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = " + v1 + "^" + v2
    # elif opcode == "SIGNEXTEND":
    #     pass
    elif opcode == "STOP":
        instr = ""
        update_variables = index_variables

    return instr, update_variables

'''
Current is used to create the new local stack variables.
'''
def compile_instr(evm_opcode,variables):
    opcode = evm_opcode.split(" ")
    opcode_name = opcode[0]
    opcode_rest = opcode[1]
    if opcode_name in opcodes0:
        value, index_variables = translateOpcodes0(opcode_name,variables)
    else:
        value = ""
        index_variables = variables
    return value, index_variables

def compile_block(block):
    index_variables = (-1,0) #(current, inputs)
    block_id = block.get_start_address()
    rule = rbr_rule.RBRRule(block_id,"block")
    l_instr = block.get_instructions()
    for evm_instr in l_instr:
        instr, index_variables = compile_instr(evm_instr,index_variables)
        rule.add_instr(instr)

    
'''
Main function that build the rbr representation from the CFG of a solidity file.
It receives as input the blocks of the CFG (basicblock.py)
'''
def evm2rbr_compiler(blocks_input = None):
    print opcodes.opcodes.keys()
    init_globals()
    if blocks_input :
        blocks = sorted(blocks_input.values(), key = getKey)
        for block in blocks:
            compile_block(block)
    else :
        print "Error, you have to provide the CFG associated with the solidity file analyzed"

