import math
import sys
import rbr_rule

def getKey(block):
    return block.get_start_address()

def compile_block(block):
    current = -1
    block_id = block.get_start_address()
    rule = new RBRRule(block_id,"block")
    l_instr = block.get_instructions()
    for evm_instr in l_instr:
        def compile_instr(evm_instr,current)
    

'''
Current is used to create the new local stack variables.
'''
def compile_instr(evm_opcode,current):
    opcode = evm_opcode.split(" ")
  


    
'''
Main function that build the rbr representation from the CFG of a solidity file.
It receives as input the blocks of the CFG (basicblock.py)
'''
def evm2rbr_compiler(blocks_input = None):
    if blocks_input :
        blocks = sorted(blocks_input.values(), key = getKey)
        for block in blocks:
            compile_block(block)
    else :
        print "Error, you have to provide the CFG associated with the solidity file analyzed"

