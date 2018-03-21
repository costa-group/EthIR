import math
import sys
import rbr_rule
import opcodes

'''
'''
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
'''
'''    
def getKey(block):
    return block.get_start_address()

'''
'''
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

'''
'''
def get_new_variable(index_variables):
    new_current = index_variables[0]+1
    return "s("+str(new_current)+")", (new_current, index_variables[1])


'''
'''
def get_current_variable(index_variables):
    current = index_variables[0]
    input_idx = index_variables[1]
    if current>=0:
        variable = "s("+str(current)+")"
    else: #We have to take one of the inputs
        variable = "in["+str(input_idx)+"]"
    return variable

'''
pos start at 0
'''
def get_ith_variable(index_variables, pos):
    current = index_variables[0]
    input_idx = index_variables[1]
    if (current>=pos):
        idx = current-pos
        variable = "s("+str(idx)+")"
    else:
        idx = pos-current-1
        variable = "in["+str(idx)+"]"
    

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

    else:
        instr = "Error opcodes0"
        update_variables = index_variables

    return instr, update_variables

'''
'''
def translateOpcodes10(opcode, index_variables):
    if opcode == "LT":
        
    elif opcode == "GT":
        pass
    # elif opcode == "SLT":
    #     pass
    # elif opcode == "SGT":
    #     pass
    elif opcode == "EQ":
        pass
    elif opcode == "ISZERO":
        pass
    elif opcode == "AND":
        pass
    elif opcode == "OR":
        pass
    elif opcode == "XOR":
        pass
    elif opcode == "NOT":
        pass
    elif opcode == "BYTE":
        pass
    else:
        instr = "Error opcodes10"
        update_variables = index_variables
        
    return instr, update_variables

'''
'''
def translateOpcodes20(opcode, index_variables):
    if opcode == "SHA3":
        v1, update_variables = get_consume_variable(index_variables)
        v2, update_variables = get_consume_variable(update_variables)
        v3, update_variables = get_new_variable(update_variables)
        instr = v3+" = sha3( "+ v1+", "+v2+")"

    else:
        instr = "Error opcodes20"
        update_variables = index_variables

    return instr, update_variables


'''
'''
def translateOpcodes30(opcode, index_variables):
    if opcode == "ADDRESS":
        pass
    elif opcode == "BALANCE":
        pass
    elif opcode == "ORIGIN":
        pass
    elif opcode == "CALLER":
        pass
    elif opcode == "CALLVALUE":
        pass
    elif opcode == "CALLDATALOAD":
        pass
    elif opcode == "CALLDATASIZE":
        pass
    elif opcode == "CALLDATACOPY":
        pass
    elif opcode == "CODESIZE":
        pass
    elif opcode == "CODECOPY":
        pass
    elif opcode == "GASPRICE":
        pass
    elif opcode == "EXTCODESIZE":
        pass
    elif opcode == "EXTCODECOPY":
        pass
    elif opcode == "MCOPY":
        pass
    else:
        instr = "Error opcodes30"
        update_variables = index_variables

    return instr, index_variables


'''
'''
def translateOpcodes40(opcode, index_variables):
    if opcode == "BLOCKHASH":
        pass
    elif opcode == "COINBASE":
        pass
    elif opcode == "TIMESTAMP":
        pass
    elif opcode == "NUMBER":
        pass
    elif opcode == "DIFFICULTY":
        pass
    elif opcode == "GASLIMIT":
        pass
    else:
        instr = "Error opcodes40"
        update_variables = index_variables

    return instr, update_variables


'''
'''
def translateOpcodes50(opcode, index_variables):
    if opcode == "POP":
        v1, update_variables = get_consume_variable(index_variables)
        instr=""
    elif opcode == "MLOAD":
        pass
    elif opcode == "MSTORE":
        pass
    elif opcode == "MSTORE8":
        pass
    elif opcode == "SLOAD":
        pass
    elif opcode == "SSTORE":
        pass
    elif opcode == "JUMP":
        pass
    elif opcode == "JUMPI":
        pass
    elif opcode == "PC":
        pass
    elif opcode == "MSIZE":
        pass
    elif opcode == "GAS":
        pass
    elif opcode == "JUMPDEST":
        pass
    elif opcode == "SLOADEXT":
        pass
    elif opcode == "SSTOREEXT":
        pass
    elif opcode == "SLOADBYTESEXT":
        pass
    elif opcode == "SSTOREBYTESEXT":
        pass
    else:
        instr = "Error opcodes20"
        update_variables = index_variables

    return instr, update_variables

# def translateOpcodesA(opcode, index_variables):
#     pass

'''
'''
def translateOpcodesF(opcode, index_variables):
    if opcode == "CREATE":
        pass
    elif opcode == "CALL":
        pass
    elif opcode == "CALLCODE":
        pass
    elif opcode == "RETURN":
        pass
    elif opcode == "REVERT":
        pass
    elif opcode == "ASSERTFAIL":
        pass
    elif opcode == "DELEGATECALL":
        pass
    elif opcode == "BREAKPOINT":
        pass
    elif opcode == "RNGSEED":
        pass
    elif opcode == "SSIZEEXT":
        pass
    elif opcode == "SLOADBYTES":
        pass
    elif opcode == "SSTOREBYTES":
        pass
    elif opcode == "SSIZE":
        pass
    elif opcode == "STATEROOT":
        pass
    elif opcode == "TXEXECGAS":
        pass
    elif opcpde == "CALLSTATIC":
        pass
    elif opcode == "INVALID":
        pass
    elif opcode == "SUICIDE":
        pass
    else:
        instr = "Error opcodesF"
        update_variables = index_variables

'''
'''
def translateOpcodes60(opcode, value, index_variables):
    if opcode == "PUSH":
        var1,update_variables = get_new_variable(index_variables)
        dec_value = int(value, 16)
        instr = var1+" = " + str(dec_value)
    else:
        instr = "Error opcodes60"
        update_variables = index_variables

    return instr, update_variables

def translateOpcodes80(opcode, value, index_variables):
    if opcode == "DUP":
        pass
    else:
        instr = "Error opcodes80"
        update_variables = index_variables

    return instr, update_variables

'''
'''     
def get_oposite_guard(guard):
    if guard == "LT":
        oposite = "geq"
    elif guard == "GT":
        oposite = "leq"
    # elif guard == "SLT":
    #     pass
    # elif guard == "SGT":
    #     pass
    elif guard == "EQ":
        oposite = "neq"
    elif guard == "ISZERO":
        oposite = "notzero"

    return oposite


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

'''
'''
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

