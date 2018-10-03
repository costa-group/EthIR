import opcodes
from utils import getLevel, getKey
import os
from dot_tree import Tree, build_tree

def init():
    global cloned_blocks
    cloned_blocks = []

    global stack_index
    stack_index = {}

def preprocess_push(block,addresses,blocks_input):
    push_per_block = {}

    b_source = blocks_input[block]
    comes_from = b_source.get_comes_from()
    # print "COMESFROM"
    # print comes_from
    for bl in comes_from:
        b = blocks_input[bl]
        instructions = b.get_instructions()
        m = filter(lambda x: x.split()[0][:-1]=="PUSH",instructions)
        numbers = map(lambda x: int(x.split()[1],16),m)
        push_per_block[bl]=numbers
    return push_per_block

def get_push_block(m_blocks,address):
    block = -1
    for l in m_blocks:
        if address in m_blocks[l]:
            block = l
    return block

def get_common_predecessors(block,blocks_input):
    return get_common_predecessor_aux(block,blocks_input,[block.get_start_address()])

def get_common_predecessor_aux(block,blocks_input,pred):
    c = block.get_comes_from()
    if len(c)>1:
        b = block.get_start_address()
        if b not in pred:
            pred.append(b)
    else:
        pred.append(c[0])
        get_common_predecessor_aux(blocks_input[c[0]],blocks_input,pred)
    return pred

def get_stack_evol(block,inpt):
    i = inpt
    instr = block.get_instructions()
    for ins in instr:
        op = ins.split()
        op_info = opcodes.get_opcode(op[0])
        i = i-op_info[1]+op_info[2]
    return i
        
def update_block_cloned(new_block,pre_block,pred,idx,stack_in):
    global cloned_blocks
    global stack_index
    
    stack_out = get_stack_evol(new_block,stack_in)

    new_block.set_stack_info((stack_in,stack_out))
    
    cloned_blocks.append(new_block.get_start_address())
    new_block.set_start_address(str(new_block.get_start_address())+"_"+str(idx))

    
    jumps_to = new_block.get_jump_target()
    falls_to = new_block.get_falls_to()
    
    comes_from = new_block.get_comes_from()
    if (pre_block in cloned_blocks) and (pre_block in comes_from):
        # print "UPDATE COMESFROM"
        i = comes_from.index(pre_block)
        comes_from[i] = str(pre_block)+"_"+str(idx)
        new_block.set_comes_from(comes_from)

    if jumps_to in pred:
        new_block.set_jump_target(str(jumps_to)+"_"+str(idx),True)
        new_block.update_list_jump_cloned(str(jumps_to)+"_"+str(idx))
    else:
        new_block.set_falls_to(str(falls_to)+"_"+str(idx))

    stack_index[new_block.get_start_address()] = [stack_in,stack_out]
    
    return new_block

def delete_old_blocks(blocks_to_remove, blocks):
    for block in blocks_to_remove:
        del blocks[block]

        
def modify_jump_first_block(block_obj,source_block,idx):
    if block_obj.get_falls_to() == source_block:
        block_obj.set_falls_to(str(source_block)+"_"+str(idx))
        #blocks_input[push_block] = push_block_obj
        block_obj.update_list_jump_cloned(str(source_block)+"_"+str(idx))

    else:
        block_obj.set_jump_target(str(source_block)+"_"+str(idx),True)
        #blocks_input[push_block] = push_block_obj
        block_obj.update_list_jump_cloned(str(source_block)+"_"+str(idx))

def modify_last_block(block,stack_in,idx,pred,pre_block,address):
    global cloned_blocks
    global stack_index
    
    stack_out = get_stack_evol(block,stack_in)
    block.set_stack_info((stack_in,stack_out))

    cloned_blocks.append(block.get_start_address())
    block.set_start_address(str(block.get_start_address())+"_"+str(idx))

    stack_index[block.get_start_address()] = [stack_in,stack_out]
    
    if (len(pred) != 1):
        comes_from = block.get_comes_from()
            
        if (pre_block in cloned_blocks) and (pre_block in comes_from):
            pos = comes_from.index(pre_block)
            comes_from[pos] = str(pre_block)+"_"+str(idx)
            block.set_comes_from(comes_from)
    else: #It is the only block
        block.set_comes_from([pre_block])
            
    block.set_jump_target(address,True) #By definition
    block.set_list_jump(filter(lambda x: x == address,block.get_list_jumps()))
    return block

def modify_target_block(target_block,block_cloned,last_block):
    comes_from = target_block.get_comes_from()
    if (block_cloned.get_start_address() in comes_from):
        idx = comes_from.index(block_cloned.get_start_address())
        comes_from[idx] = last_block.get_start_address()
        target_block.set_comes_from(comes_from)
    
def clone(block, blocks_input):
    global cloned_blocks
    global stack_index

    rules = []
    pred = get_common_predecessors(block, blocks_input)

    address = block.get_list_jumps()
    n_clones = len(address)
    
    source_path = pred[-1]

    in_blocks = preprocess_push(source_path,address,blocks_input)
    cloned_blocks = cloned_blocks+pred

    # print "PRED"
    # print pred
    # print "ADDRESS"
    # print address
    
    i = 0    
    while (i<n_clones): #bucle que hace las copias
        
        #clonar
        a = address[i]
        # print "ESTO ES LO QUE CALCULA"
        # print a
        # print in_blocks
        push_block = get_push_block(in_blocks,a)
        
        #modified the jump address of the first block
        # print "PUSHBLOCK ERROR"
        # print push_block
        
        push_block_obj = blocks_input[push_block]
        modify_jump_first_block(push_block_obj,source_path,i)

        #we copy the last block
        pre_block = push_block
        # print "PUSH"
        # print pre_block
        # print "ADDRESS"
        # print a
        first = True
        stack_in = stack_index[pre_block][1]

        #We start to clone each path
        for idx in xrange(len(pred)-1,0,-1):
            new_block = blocks_input[pred[idx]].copy()
            # new_block = copy.deepcopy(blocks_input[pred[idx]])
            new_block = update_block_cloned(new_block,pre_block,pred,i,stack_in)
            # print "CLONED"
            # new_block.display()
            # print new_block.get_comes_from()
            if first == True:
                first = False
                comes_from = [push_block]
                new_block.set_comes_from(comes_from)
                
            blocks_input[new_block.get_start_address()] = new_block
            pre_block = pred[idx]
            stack_in = new_block.get_stack_info()[1]
            

        if first: #It means that the block to copy has no predecessor
            stack_in = stack_index[pre_block][1]
        else:
            stack_in = new_block.get_stack_info()[1]
            
        #We modify the last block
        new_block = blocks_input[pred[0]].copy()
        # new_block = copy.deepcopy(blocks_input[pred[0]])
        new_block = modify_last_block(new_block,stack_in,i,pred,pre_block,a)
        blocks_input[new_block.get_start_address()] = new_block
        
        #Target block
        target_block = blocks_input[a]
        modify_target_block(target_block,block,new_block)
        
        i = i+1
        
    delete_old_blocks(pred,blocks_input)
    # for e in blocks_input.values():
    #     e.display()
    #     print e.get_comes_from()

    return blocks_input

def compute_cloning(blocks_to_clone,blocks_input,stack_info):
    global stack_index
    
    init()
    blocks_dict = blocks_input
    stack_index = stack_info
    
    blocks2clone = sorted(blocks_to_clone, key = getLevel)

    for b in blocks2clone:
        blocks_dict = clone(b,blocks_dict)

    # for e in blocks_dict.values():
    #     e.display()
    #     print e.get_comes_from()
        
    return blocks_dict, stack_index

    
