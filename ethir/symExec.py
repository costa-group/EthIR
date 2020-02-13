import tokenize
#import zlib, base64
import base64
from tokenize import NUMBER, NAME, NEWLINE
import re
import math
import sys
import atexit
import pickle
import json
import traceback
import signal
from timeit import default_timer as dtimer
import logging
import six
from collections import namedtuple
#from z3 import *
import gasol

from vargenerator import *
from basicblock import BasicBlock
from analysis import *
# from test_evm.global_test_params import (TIME_OUT, UNKNOWN_INSTRUCTION,
#                                          EXCEPTION, PICKLE_PATH)
from vulnerability import CallStack, TimeDependency, MoneyConcurrency, Reentrancy, AssertionFailure, ParityMultisigBug2
import global_params

import rbr
from clone import compute_cloning
from utils import cfg_dot, write_cfg, update_map, get_public_fields, getLevel, update_sstore_map,correct_map_fields1, get_push_value, get_initial_block_address, check_graph_consistency, find_first_closing_parentheses, check_if_same_stack
from opcodes import get_opcode
from graph_scc import Graph_SCC, get_entry_all,filter_nested_scc
from pattern import look_for_string_pattern,check_sload_fragment_pattern,sstore_fragment

log = logging.getLogger(__name__)

UNSIGNED_BOUND_NUMBER = 2**256 - 1
CONSTANT_ONES_159 = BitVecVal((1 << 160) - 1, 256)

Assertion = namedtuple('Assertion', ['pc', 'model'])
ebso_path = "/tmp/costabs/blocks"
costabs_path = "/tmp/costabs/"
tmp_path = "/tmp/"


class Parameter:
    def __init__(self, **kwargs):
        attr_defaults = {
            "stack": [],
            "calls": [],
            "memory": [],
            "visited": [],
            "mem": {},
            "analysis": {},
            "sha3_list": {},
            "global_state": {},
            "path_conditions_and_vars": {}
        }
        for (attr, default) in six.iteritems(attr_defaults):
            setattr(self, attr, kwargs.get(attr, default))

    def copy(self):
        _kwargs = custom_deepcopy(self.__dict__)
        return Parameter(**_kwargs)

def initGlobalVars():
    global g_src_map
    global solver
    # Z3 solver

    if global_params.PARALLEL:
        t2 = Then('simplify', 'solve-eqs', 'smt')
        _t = Then('tseitin-cnf-core', 'split-clause')
        t1 = ParThen(_t, t2)
        solver = OrElse(t1, t2).solver()
    else:
        solver = Solver()

    solver.set("timeout", global_params.TIMEOUT)

    global MSIZE
    MSIZE = False

    global g_disasm_file
    with open(g_disasm_file, 'r') as f:
        disasm = f.read()
    if 'MSIZE' in disasm:
        MSIZE = True

    global g_timeout
    g_timeout = False

    global visited_pcs
    visited_pcs = set()

    global results
    if g_src_map:
        results = {
            'evm_code_coverage': '',
            'vulnerabilities': {
                'callstack': [],
                'money_concurrency': [],
                'time_dependency': [],
                'reentrancy': [],
                'assertion_failure': [],
                'parity_multisig_bug_2': []
            }
        }
    else:
        results = {
            'evm_code_coverage': '',
            'vulnerabilities': {
                'callstack': False,
                'money_concurrency': False,
                'time_dependency': False,
                'reentrancy': False,
            }
        }

    global calls_affect_state
    calls_affect_state = {}

    # capturing the last statement of each basic block
    global end_ins_dict
    end_ins_dict = {}

    # capturing all the instructions, keys are corresponding addresses
    global instructions
    instructions = {}

    # capturing the "jump type" of each basic block
    global jump_type
    jump_type = {}

    global vertices
    vertices = {}

    global edges
    edges = {}

    global visited_edges
    visited_edges = {}

    global money_flow_all_paths
    money_flow_all_paths = []

    global reentrancy_all_paths
    reentrancy_all_paths = []

    # store the path condition corresponding to each path in money_flow_all_paths
    global path_conditions
    path_conditions = []

    global global_problematic_pcs
    global_problematic_pcs = {"money_concurrency_bug": [], "reentrancy_bug": [], "time_dependency_bug": [], "assertion_failure": []}

    # store global variables, e.g. storage, balance of all paths
    global all_gs
    all_gs = []

    global total_no_of_paths
    total_no_of_paths = 0

    global no_of_test_cases
    no_of_test_cases = 0

    # to generate names for symbolic variables
    global gen
    gen = Generator()

    global data_source
    if global_params.USE_GLOBAL_BLOCKCHAIN:
        data_source = EthereumData()

    global rfile
    if global_params.REPORT_MODE:
        rfile = open(g_disasm_file + '.report', 'w')

     # Added by Pablo for Cost Analysis
    
    global jump_addr
    jump_addr = {}

    global stack_h
    stack_h = {}

    global calldataload_values
    calldataload_values = {}

    global visited_blocks
    visited_blocks = []
        
    global blocks_to_create
    blocks_to_create =[]

    global ls_cont #load store cont 
    ls_cont = [0,0,0,0] #[mload, mstore, sload, sstore]

    global f_hashes
    f_hashes = None

    global function_block_map
    function_block_map = {}

    global component_of_blocks
    component_of_blocks = {}

    global function_info
    function_info = (False,"")

    global debug_info
    debug_info = False

    global potential_jump
    potential_jump = False

    global blocks_to_clone
    blocks_to_clone = []

    global procesed_indirect_jumps
    procesed_indirect_jumps = {}

    global name
    name = ""

    global param_abs
    param_abs = ("","")

    global scc_unary
    scc_unary = []

    global public_fields
    public_fields = []

    global getter_blocks
    getter_blocks = []

    global has_invalid
    has_invalid = []

    global invalid_option
    invalid_option = ""


    global push_jump_relations
    push_jump_relations = {}

    global jump_addresses
    jump_addresses = []

    #Added by AHC
    
    global block_cont
    block_cont = {}
    
    global mapping_state_variables
    mapping_state_variables = {}

    global update_fields
    update_fields = {}
    
def is_testing_evm():
    return global_params.UNIT_TEST != 0

def compare_storage_and_gas_unit_test(global_state, analysis):
    unit_test = pickle.load(open(PICKLE_PATH, 'rb'))
    test_status = unit_test.compare_with_symExec_result(global_state, analysis)
    exit(test_status)

def change_format(evm_version):
    with open(g_disasm_file) as disasm_file:
        file_contents = disasm_file.readlines()
        i = 0
        firstLine = file_contents[0].strip('\n')
        for line in file_contents:
            line = line.replace('SELFDESTRUCT', 'SUICIDE')
            line = line.replace('Missing opcode 0xfd', 'REVERT')
            line = line.replace('Missing opcode 0xfe', 'ASSERTFAIL')
            line = line.replace('Missing opcode', 'INVALID')
            line = line.replace(':', '')
            lineParts = line.split(' ')
            try: # removing initial zeroes
                # if evm_version:
                #     lineParts[0] = str(int(lineParts[0],16))
                # else:
                #     lineParts[0] = str(int(lineParts[0]))
                lineParts[0] = str(int(lineParts[0],16))
            except:
                lineParts[0] = lineParts[0]
            lineParts[-1] = lineParts[-1].strip('\n')
            try: # adding arrow if last is a number
                lastInt = lineParts[-1]
                if(int(lastInt, 16) or int(lastInt, 16) == 0) and len(lineParts) > 2 and (not ("=>" in lineParts)):
                    lineParts[-1] = "=>"
                    lineParts.append(lastInt)
            except Exception:
                pass
            file_contents[i] = ' '.join(lineParts)
            i = i + 1
        file_contents[0] = firstLine
        file_contents[-1] += '\n'

    with open(g_disasm_file, 'w') as disasm_file:
        disasm_file.write("\n".join(file_contents))

        
def build_cfg_and_analyze(evm_version):
    change_format(evm_version)
    with open(g_disasm_file, 'r') as disasm_file:
        disasm_file.readline()  # Remove first line
        tokens = tokenize.generate_tokens(disasm_file.readline)
        collect_vertices(tokens)
        construct_bb()
        # if ebso_opt:
        #     get_evm_block()
        construct_static_edges()
        #print_cfg()
        full_sym_exec()  # jump targets are constructed on the fly

    #print mapping_state_variables
    if g_src_map:
        correct_map_fields1(mapping_state_variables,g_src_map._get_var_names())
    #print mapping_state_variables
    
    delete_uncalled()
    update_block_info()
    build_push_jump_relations()

    if debug_info:
        print "*****************************"
        print "Graph"
        show_graph(vertices)
        print "Is Graph consistent?"
        print check_graph_consistency(vertices)


#Added by Pablo Gordillo
def update_block_info():
    global blocks_to_clone
    
    vert = sorted(vertices.values(), key = getKey)
    if debug_info:
        print "Updating block info"
        print vertices.keys()
        
    for block in vert:    
        block.compute_list_jump(edges[block.get_start_address()])
        c = block.compute_cloning()
        if c:
            blocks_to_clone.append(block)
        block.set_calldataload_values(calldataload_values[block.get_start_address()])
        block.set_stack_info(stack_h[block.get_start_address()])
        block.update_instr()

def compute_transitive_mstore_value():
    for block in vertices.values():
        spawn_unknown_mstore(block)
        
        
def spawn_unknown_mstore(block):
    if block.is_mstore_unknown():
        t = block.get_block_type()
        if t == "conditional":
            jump = block.get_jump_target()
            falls = block.get_falls_to()
            l = [jump]
            propagate_mstore_unknown(jump,l)
            propagate_mstore_unknown(falls,l)
        elif  t == "unconditional":
            jump = block.get_jump_target()
            propagate_mstore_unknown(jump,[jump])
        elif t == "falls_to":
            falls = block.get_falls_to()
            propagate_mstore_unknown(falls,[falls])
            
def propagate_mstore_unknown(block_addr,visited):
    block = vertices[block_addr]
    block.act_trans_mstore()
    if block.get_block_type() == "terminal":
        visited.append(block)
    elif block.get_block_type() == "conditional":
        jump = block.get_jump_target()
        if jump not in visited:
            visited.append(jump)
            propagate_mstore_unknown(jump,visited)

        falls = block.get_falls_to()
        if falls not in visited:
            visited.append(falls)
            propagate_mstore_unknown(falls,visited)
            
    elif block.get_block_type() == "unconditional":
        jump = block.get_jump_target()
        if jump not in visited:
            visited.append(jump)
            propagate_mstore_unknown(jump,visited)

    elif block.get_block_type() == "falls_to":
        falls = block.get_falls_to()
        if falls not in visited:
            visited.append(falls)
            propagate_mstore_unknown(falls,visited)

#Added by Pablo Gordillo

def build_push_jump_relations():
    global push_jump_relations

    old_dict = push_jump_relations
    push_jump_relations = {}

    for block in blocks_to_clone:
        rel = old_dict[block.get_start_address()]
        for jump_address in rel.keys():
            push_jump_relations[jump_address] = rel[jump_address]

def print_cfg():
    vert = sorted(vertices.values(), key = getKey)
    for block in vert:
        block.display()
        print ("COMES FROM")
        print (block.get_comes_from())
    log.debug(str(edges))
    
def mapping_push_instruction(current_line_content, current_ins_address, idx, positions, length):
    global g_src_map

    while (idx < length):
        if not positions[idx]:
            return idx + 1
        name = positions[idx]['name']
        if name.startswith("tag"):
            idx += 1
        else:
            if name.startswith("PUSH"):
                if name == "PUSH":
                    value = positions[idx]['value']
                    instr_value = current_line_content.split(" ")[1]
                    if int(value, 16) == int(instr_value, 16):
                        g_src_map.instr_positions[current_ins_address] = g_src_map.positions[idx]
                        idx += 1
                        break;
                    else:
                        raise Exception("Source map error")
                else:
                    g_src_map.instr_positions[current_ins_address] = g_src_map.positions[idx]
                    idx += 1
                    break;
            else:
                raise Exception("Source map error")
    return idx

def mapping_non_push_instruction(current_line_content, current_ins_address, idx, positions, length):
    global g_src_map

    while (idx < length):
        if not positions[idx]:
            return idx + 1
        name = positions[idx]['name']
        if name.startswith("tag"):
            idx += 1
        else:
            instr_name = current_line_content.split(" ")[0]
            if name == instr_name or name == "INVALID" and instr_name == "ASSERTFAIL" or name == "KECCAK256" and instr_name == "SHA3" or name == "SELFDESTRUCT" and instr_name == "SUICIDE":
                g_src_map.instr_positions[current_ins_address] = g_src_map.positions[idx]
                idx += 1
                break;
            else:
                raise Exception("Source map error")
    return idx

# 1. Parse the disassembled file
# 2. Then identify each basic block (i.e. one-in, one-out)
# 3. Store them in vertices
def collect_vertices(tokens):
    global g_src_map
    if g_src_map:
        idx = 0
        positions = g_src_map.positions
        length = len(positions)
    global end_ins_dict
    global instructions
    global jump_type

    current_ins_address = 0
    last_ins_address = 0
    is_new_line = True
    current_block = 0
    current_line_content = ""
    wait_for_push = False
    is_new_block = False

    for tok_type, tok_string, (srow, scol), _, line_number in tokens:
        if wait_for_push is True:
            push_val = ""
            for ptok_type, ptok_string, _, _, _ in tokens:
                if ptok_type == NEWLINE:
                    is_new_line = True
                    current_line_content += push_val + ' '
                    instructions[current_ins_address] = current_line_content
                    idx = mapping_push_instruction(current_line_content, current_ins_address, idx, positions, length) if g_src_map else None
                    log.debug(current_line_content)
                    current_line_content = ""
                    wait_for_push = False
                    break
                try:
                    int(ptok_string, 16)
                    push_val += ptok_string
                except ValueError:
                    pass

            continue
        elif is_new_line is True and tok_type == NUMBER:  # looking for a line number
            last_ins_address = current_ins_address
            try:
                current_ins_address = int(tok_string)
            except ValueError:
                log.critical("ERROR when parsing row %d col %d", srow, scol)
                quit()
            is_new_line = False
            if is_new_block:
                current_block = current_ins_address
                is_new_block = False
            continue
        elif tok_type == NEWLINE:
            is_new_line = True
            log.debug(current_line_content)
            instructions[current_ins_address] = current_line_content
            idx = mapping_non_push_instruction(current_line_content, current_ins_address, idx, positions, length) if g_src_map else None
            current_line_content = ""
            continue
        elif tok_type == NAME:
            if tok_string == "JUMPDEST":
                if last_ins_address not in end_ins_dict:
                    end_ins_dict[current_block] = last_ins_address
                current_block = current_ins_address
                is_new_block = False
            elif tok_string == "STOP" or tok_string == "RETURN" or tok_string == "SUICIDE" or tok_string == "REVERT" or tok_string == "ASSERTFAIL":
                jump_type[current_block] = "terminal"
                end_ins_dict[current_block] = current_ins_address
            elif tok_string == "JUMP":
                jump_type[current_block] = "unconditional"
                end_ins_dict[current_block] = current_ins_address
                is_new_block = True
            elif tok_string == "JUMPI":
                jump_type[current_block] = "conditional"
                end_ins_dict[current_block] = current_ins_address
                is_new_block = True
            elif tok_string.startswith('PUSH', 0):
                wait_for_push = True
            is_new_line = False
        if tok_string != "=" and tok_string != ">":
            current_line_content += tok_string + " "

    if current_block not in end_ins_dict:
        log.debug("current block: %d", current_block)
        log.debug("last line: %d", current_ins_address)
        end_ins_dict[current_block] = current_ins_address

    if current_block not in jump_type:
        jump_type[current_block] = "terminal"

    for key in end_ins_dict:
        if key not in jump_type:
            jump_type[key] = "falls_to"

#Modified by Pablo Gordillo
def construct_bb():
    global vertices
    global edges
    global stack_h
    global calldataload_values
    global string_getter
    
    sorted_addresses = sorted(instructions.keys())
    size = len(sorted_addresses)
    for key in end_ins_dict:
        end_address = end_ins_dict[key]
        block = BasicBlock(key, end_address)

        if key not in instructions:
            continue
        stack_h[key] = [float("inf"),float("inf")]
        calldataload_values[key] = []
        block.add_instruction(instructions[key])
        i = sorted_addresses.index(key) + 1
        while i < size and sorted_addresses[i] <= end_address:
            block.add_instruction(instructions[sorted_addresses[i]])
            i += 1
        block.set_block_type(jump_type[key])
        vertices[key] = block
        edges[key] = []
        look_for_string_pattern(block)

def check_div_invalid_pattern(block,path):
    div_pattern = ["DUP2","ISZERO","ISZERO","PUSH","JUMPI"]
    instructions = vertices[block].get_instructions()[-5:]
    end = len(div_pattern)
    if len(instructions)>=end:
        pattern = True
        for i in range(end):
            pattern = pattern and instructions[i].startswith(div_pattern[i])
            i = i+1

        if pattern:
            jump = vertices[block].get_jump_target()
            falls = vertices[block].get_falls_to()

            jumps_instr = vertices[jump].get_instructions()
            falls_instr = vertices[falls].get_instructions()
            
            if (falls_instr[0].startswith("ASSERTFAIL")) and (check_div_invalid_bytecode(jumps_instr[1])):
                vertices[falls].activate_div_invalid_pattern()
                if invalid_option == "div0":
                    annotate_invalid(path)

def check_div_invalid_bytecode(instr):
    r =  instr.startswith("DIV") or instr.startswith("MOD") or instr.startswith("SDIV") or instr.startswith("SMOD") or instr.startswith("ADDMOD") or instr.startswith("MULMOD")
    return r
                    
def is_getter_function(path):
    blocks = map(lambda x: x[0],path)
    is_getter_function = filter(lambda x: x in blocks,getter_blocks)
    return len(is_getter_function)>0

def annotate_invalid(path):
    global has_invalid
    
    blocks = map(lambda x: x[0], path)
    functions_blocks = function_block_map.values()
    bs = map(lambda x: x[0], functions_blocks)
    annotate_invalids = filter(lambda x: x in bs,blocks)

    if len(annotate_invalids)>0 and (annotate_invalids[0] not in has_invalid):
        has_invalid.append(annotate_invalids[0])

def remove_getters_has_invalid():
    global has_invalid

    has_invalid = filter(lambda x: x not in getter_blocks,has_invalid)
        
def construct_static_edges():
    add_falls_to()  # these edges are static


def add_falls_to():
    global vertices
    global edges
    key_list = sorted(jump_type.keys())
    length = len(key_list)
    for i, key in enumerate(key_list):
        if jump_type[key] != "terminal" and jump_type[key] != "unconditional" and i+1 < length:
            target = key_list[i+1]
            edges[key].append(target)
            vertices[key].set_falls_to(target)


def get_init_global_state(path_conditions_and_vars):
    global_state = {"balance" : {}, "pc": 0}
    init_is = init_ia = deposited_value = sender_address = receiver_address = gas_price = origin = currentCoinbase = currentNumber = currentDifficulty = currentGasLimit = callData = None

    if global_params.INPUT_STATE:
        with open('state.json') as f:
            state = json.loads(f.read())
            if state["Is"]["balance"]:
                init_is = int(state["Is"]["balance"], 16)
            if state["Ia"]["balance"]:
                init_ia = int(state["Ia"]["balance"], 16)
            if state["exec"]["value"]:
                deposited_value = 0
            if state["Is"]["address"]:
                sender_address = int(state["Is"]["address"], 16)
            if state["Ia"]["address"]:
                receiver_address = int(state["Ia"]["address"], 16)
            if state["exec"]["gasPrice"]:
                gas_price = int(state["exec"]["gasPrice"], 16)
            if state["exec"]["origin"]:
                origin = int(state["exec"]["origin"], 16)
            if state["env"]["currentCoinbase"]:
                currentCoinbase = int(state["env"]["currentCoinbase"], 16)
            if state["env"]["currentNumber"]:
                currentNumber = int(state["env"]["currentNumber"], 16)
            if state["env"]["currentDifficulty"]:
                currentDifficulty = int(state["env"]["currentDifficulty"], 16)
            if state["env"]["currentGasLimit"]:
                currentGasLimit = int(state["env"]["currentGasLimit"], 16)

    # for some weird reason these 3 vars are stored in path_conditions insteaad of global_state
    else:
        sender_address = BitVec("Is", 256)
        receiver_address = BitVec("Ia", 256)
        deposited_value = BitVec("Iv", 256)
        init_is = BitVec("init_Is", 256)
        init_ia = BitVec("init_Ia", 256)

    path_conditions_and_vars["Is"] = sender_address
    path_conditions_and_vars["Ia"] = receiver_address
    path_conditions_and_vars["Iv"] = deposited_value

    constraint = (deposited_value >= BitVecVal(0, 256))
    path_conditions_and_vars["path_condition"].append(constraint)
    constraint = (init_is >= deposited_value)
    path_conditions_and_vars["path_condition"].append(constraint)
    constraint = (init_ia >= BitVecVal(0, 256))
    path_conditions_and_vars["path_condition"].append(constraint)

    # update the balances of the "caller" and "callee"

    global_state["balance"]["Is"] = (init_is - deposited_value)
    global_state["balance"]["Ia"] = (init_ia + deposited_value)

    if not gas_price:
        new_var_name = gen.gen_gas_price_var()
        gas_price = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = gas_price

    if not origin:
        new_var_name = gen.gen_origin_var()
        origin = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = origin

    if not currentCoinbase:
        new_var_name = "IH_c"
        currentCoinbase = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = currentCoinbase

    if not currentNumber:
        new_var_name = "IH_i"
        currentNumber = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = currentNumber

    if not currentDifficulty:
        new_var_name = "IH_d"
        currentDifficulty = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = currentDifficulty

    if not currentGasLimit:
        new_var_name = "IH_l"
        currentGasLimit = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = currentGasLimit

    new_var_name = "IH_s"
    currentTimestamp = BitVec(new_var_name, 256)
    path_conditions_and_vars[new_var_name] = currentTimestamp

    # the state of the current current contract
    if "Ia" not in global_state:
        global_state["Ia"] = {}
    global_state["miu_i"] = 0
    global_state["value"] = deposited_value
    global_state["sender_address"] = sender_address
    global_state["receiver_address"] = receiver_address
    global_state["gas_price"] = gas_price
    global_state["origin"] = origin
    global_state["currentCoinbase"] = currentCoinbase
    global_state["currentTimestamp"] = currentTimestamp
    global_state["currentNumber"] = currentNumber
    global_state["currentDifficulty"] = currentDifficulty
    global_state["currentGasLimit"] = currentGasLimit

    return global_state

# Added by Pablo Gordillo
def update_stack_heigh(block,h,pos):
    global stack_h
    l = stack_h[block]
    if(l[pos]>h):
        l.pop(pos)
        l.insert(pos,h)
        stack_h[block]=l

def updateCallDataValues(block,var_name):
    global calldataload_values

    laux = calldataload_values[block]
    l = laux+[var_name]
    calldataload_values[block] = l


def compute_loop_scc(block):
    b = vertices[block]

    r = False
    
    jump_to = b.get_jump_target()
    falls = b.get_falls_to()

    if jump_to != 0:
        r = block == jump_to

    if falls != None:
        r = r or (block == falls)

    return r
    
def full_sym_exec():
    # executing, starting from beginning
    path_conditions_and_vars = {"path_condition" : []}
    global_state = get_init_global_state(path_conditions_and_vars)
    analysis = init_analysis()
    params = Parameter(path_conditions_and_vars=path_conditions_and_vars, global_state=global_state, analysis=analysis)

    #vertices[0].set_cost(vertices[0].get_block_gas())
    return sym_exec_block(params, 0, 0, 0, -1, 0,[(0,0)])


# Symbolically executing a block from the start address
def sym_exec_block(params, block, pre_block, depth, func_call,level,path):
    global solver
    global visited_edges
    global money_flow_all_paths
    global path_conditions
    global global_problematic_pcs
    global all_gs
    global results
    global g_src_map
    global visited_blocks
    global blocks_to_create
    global ls_cont
    global potential_jump
    global procesed_indirect_jumps
    global function_info
    global param_abs
    global scc_unary
    global getter_blocks
    global block_stack
    global block_cont
    global edges
    global stack_h
    global calldataload_values
    global jump_type

    visited = params.visited
    stack = params.stack
    stack_old = list(params.stack)
    mem = params.mem
    memory = params.memory
    global_state = params.global_state
    sha3_list = params.sha3_list
    path_conditions_and_vars = params.path_conditions_and_vars
    analysis = params.analysis
    calls = params.calls
    param_abs = ("","")
    
    vertices[block].add_stack(list(stack))
    vertices[block].add_path(path)
    
    if debug_info:
        print ("\nBLOCK "+ str(block))
        print ("PATH")
        print (path)
        print ("STACK")
        print (stack)

    update_stack_heigh(block,len(stack),0)
    Edge = namedtuple("Edge", ["v1", "v2"]) # Factory Function for tuples is used as dictionary key
    if block < 0:
        log.debug("UNKNOWN JUMP ADDRESS. TERMINATING THIS PATH")
        return ["ERROR"]

    log.debug("Reach block address %d \n", block)
    if block not in visited_blocks:
        visited_blocks.append(block)
    
    current_edge = Edge(pre_block, block)
    # print "CURRENT EDGE"+str(current_edge)
    if current_edge in visited_edges:
        updated_count_number = visited_edges[current_edge] + 1
        visited_edges.update({current_edge: updated_count_number})
    else:
        visited_edges.update({current_edge: 1})

    # if visited_edges[current_edge] > global_params.LOOP_LIMIT:
    #     if debug_info :
    #         print ("LOOP LIMIT REACHED")
    #         print current_edge
            
    #     #log.debug("Overcome a number of loop limit. Terminating this path ...")
    #     return stack

    # current_gas_used = analysis["gas"]
    # if current_gas_used > global_params.GAS_LIMIT:
    #     log.debug("Run out of gas. Terminating this path ... ")
    #     return stack

    # Execute every instruction, one at a time
    try:
        block_ins = vertices[block].get_instructions()
        block_level = vertices[block].get_depth_level()
        if block_level > level:
            current_level = block_level
        else:
            current_level = level
        vertices[block].set_depth_level(level)
    except KeyError:
        log.debug("This path results in an exception, possibly an invalid jump address")
        return ["ERROR"]

    #Added by PG
    ls_cont = [0,0,0,0]

    #Access to array
    fake_stack = []
    sha_identify = False
    result = False
    instr_index = 0


    bl = vertices[block]

    for instr in block_ins:
        if not bl.get_pcs_stored():
            bl.add_pc(hex(global_state["pc"]))
        
        sym_exec_ins(params, block, instr, func_call,stack_old,instr_index)
        instr_index+=1
        if sha_identify and not result:
            result =  access_array_sim(instr.strip(),fake_stack)

        if instr.startswith("SHA3",0):
            # print block
            sha_identify = True
            fake_stack.insert(0,1)

        if debug_info:
            print ("Stack despues de la ejecucion de la instruccion "+ instr)
            print (stack)

    if not bl.get_pcs_stored():
        bl.set_pcs_stored(True)


    if result:

        falls = vertices[pre_block].get_falls_to()
        jump = vertices[pre_block].get_jump_target()
        invalid_block = 0

        if jump != block and jump != None:
            ins = vertices[jump].get_instructions()
            invalid_block = jump
        elif falls != None: #falls_to
            # print "AQUI"
            ins = vertices[falls].get_instructions()
            invalid_block = falls
            # print ins
        else:
            ins = []

        if ("ASSERTFAIL " in ins) and (not (check_div_invalid_bytecode(block_ins[1]))):
            if is_getter_function(path):
                vertices[invalid_block].activate_assertfail_in_getter()
            else:

                vertices[invalid_block].activate_access_array()
                if invalid_option == "array":
                    annotate_invalid(path)


                
    if invalid_option == "all" and "ASSERTFAIL " in block_ins:
        annotate_invalid(path)

    check_div_invalid_pattern(block,path)
        
    # Mark that this basic block in the visited blocks
    visited.append(block)

    depth += 1

    update_stack_heigh(block,len(stack),1)
    #vertices[block].add_path(path)
    
    if block == 0:
        s0 = vertices[block].get_block_gas()
        vertices[block].set_cost(s0)
        
    if (function_info[0] and jump_type[block] == "conditional"):
        signature = function_info[1]
        open_idx = signature.find("(")
        name = signature[:open_idx]
        ch_block = vertices[block].get_jump_target()
        if name in public_fields and ch_block not in getter_blocks:
            getter_blocks.append(ch_block)
        s = vertices[block].get_block_gas()+vertices[pre_block].get_cost()
        vertices[block].set_cost(s)
        
        function_block_map[signature]=(ch_block,s)
#        function_block_map[name]=vertices[block].get_jump_target()
        function_info = (False,"")
    
    # Go to next Basic Block(s)
    if jump_type[block] == "terminal" or depth > global_params.DEPTH_LIMIT:
        #vertices[block].add_new_path(path)
        #if debug_info and depth > global_params.DEPTH_LIMIT:
        if depth > global_params.DEPTH_LIMIT:
            print ("DEPTH LIMIT REACHED")
        global total_no_of_paths
        global no_of_test_cases

        total_no_of_paths += 1

    elif jump_type[block] == "unconditional":  # executing "JUMP"
        successor = vertices[block].get_jump_target()
        new_params = params.copy()
        new_params.global_state["pc"] = get_initial_block_address(successor)
        if g_src_map:
            source_code = g_src_map.get_source_code(global_state['pc'])
            if source_code in g_src_map.func_call_names:
                func_call = global_state['pc']
                
        analyze_next_block(block, successor, stack, path, func_call, depth, current_level, new_params, "jump_target")
                
    elif jump_type[block] == "falls_to":  # just follow to the next basic block
        successor = vertices[block].get_falls_to()

        new_params = params.copy()
        new_params.global_state["pc"] = get_initial_block_address(successor)

        analyze_next_block(block, successor, stack, path, func_call, depth, current_level, new_params, "falls_to")

            
    elif jump_type[block] == "conditional":  # executing "JUMPI"

        # A choice point, we proceed with depth first search

        left_branch = vertices[block].get_jump_target()


        new_params = params.copy()
        new_params.global_state["pc"] = get_initial_block_address(left_branch)
        #new_params.path_conditions_and_vars["path_condition"].append(branch_expression)
        last_idx = len(new_params.path_conditions_and_vars["path_condition"]) - 1
                #new_params.analysis["time_dependency_bug"][last_idx] = global_state["pc"]

        analyze_next_block(block, left_branch, stack, path, func_call, depth, current_level, new_params, jump_type)

        # solver.pop()  # POP SOLVER CONTEXT

        # solver.push()  # SET A BOUNDARY FOR SOLVER
        # negated_branch_expression = Not(branch_expression)
        # solver.add(negated_branch_expression)

        # log.debug("Negated branch expression: " + str(negated_branch_expression))

        # try:
        #     if solver.check() == unsat:
        #         # Note that this check can be optimized. I.e. if the previous check succeeds,
        #         # no need to check for the negated condition, but we can immediately go into
        #         # the else branch
        #         log.debug("INFEASIBLE PATH DETECTED")
        #     else:
        right_branch = vertices[block].get_falls_to()

        
        new_params = params.copy()
        new_params.global_state["pc"] = get_initial_block_address(right_branch) 
        #new_params.path_conditions_and_vars["path_condition"].append(negated_branch_expression)
        last_idx = len(new_params.path_conditions_and_vars["path_condition"]) - 1
        #new_params.analysis["time_dependency_bug"][last_idx] = global_state["pc"]
        # print right_branch
        # print path
        # print "\n"
        analyze_next_block(block, right_branch, stack, path, func_call, depth, current_level, new_params, "falls_to")
        # solver.pop()  # POP SOLVER CONTEXT
        updated_count_number = visited_edges[current_edge] - 1
        visited_edges.update({current_edge: updated_count_number})
    else:
        updated_count_number = visited_edges[current_edge] - 1
        visited_edges.update({current_edge: updated_count_number})
        raise Exception('Unknown Jump-Type')

    r = compute_loop_scc(block)
    if r and block not in scc_unary:
        scc_unary.append(block)



# Given a block and current stack, returns all blocks that share same initial name
# and has the same stack (it's supposed to be at most one)
def get_all_blocks_with_same_stack(successor, stack):
    global vertices

    # We just search for those nodes that share initial name with our successor
    all_successor_copies = filter(lambda x: get_initial_block_address(x) == get_initial_block_address(successor), vertices)
    same_stack_successors = []
    
    for found_successor in all_successor_copies:
        list_stacks = vertices[found_successor].get_stacks()

        # If there's no stack in the node, we must check if our stack is empty, or doesn't contain jump values info.
        if list_stacks == [[]]:
            if filter(lambda x: isinstance(x,tuple) and (x[0] in vertices) and x[0]!=0,stack) == []:
                same_stack_successors.append(found_successor)
        else:
            # Otherwise, we check every path to see if they're esentially the same
            for found_stack in list_stacks:
                if check_if_same_stack(found_stack,stack,vertices):
                    same_stack_successors.append(found_successor)
                    break
    return same_stack_successors

# Given a block, its successor, and another successor already visited that shares same stack,
# updates info from matching successor and block, to preserve info without cloning.
def update_matching_successor(successor, matching_successor, block, t):
    global vertices
    global edges
    
    #If it's already cloned, we just have to update info
    vertices[matching_successor].add_origin(block)
    if t == "falls_to":
        vertices[block].set_falls_to(matching_successor)
    else:
        vertices[block].set_jump_target(matching_successor, True)
        
    old_edges = filter(lambda x: x!= successor, edges[block])
    old_edges.append(matching_successor)
    edges[block] = old_edges
    
# Copies an already visited node, as there's no other node with same initial name with the same stack
def copy_already_visited_node(successor, new_params, block, depth, func_call,current_level,path, t):
    global vertices
    global block_cont
    global stack_h
    global calldataload_values
    global edges
    global jump_type
    
    # We make a copy for the successor
    new_successor = vertices[successor].copy()

    # We obtain new index from block_cont and update the value
    original_successor = get_initial_block_address(successor)
    idx = block_cont.get(original_successor, 0)
    block_cont[original_successor] = idx + 1

    # Once we know the index, we just add it to the base address from the succesor
    # and update the start address from the copy
    new_successor_address = str(get_initial_block_address(successor)) + "_" + str(idx)
    new_successor.set_start_address(new_successor_address)

    # We update info related to blocks: new successor comes from block,
    # block jumps to new successor and we store new successor in vertices
    new_successor.set_comes_from([block])
    vertices[new_successor_address] = new_successor
    if t == "falls_to":
        vertices[block].set_falls_to(new_successor_address)
    else:
        vertices[block].set_jump_target(new_successor_address, True)
        
    # This maps have already been initialized for each block,
    # therefore we initilize them for new blocks, using info from successor (not neccesary)
    stack_h[new_successor_address] = [float("inf"),float("inf")]
    calldataload_values[new_successor_address] = calldataload_values[successor]

    # Edges must be initialized to None, as it doesn't share the same list as the original node
    edges[new_successor_address] = []
    old_edges = filter(lambda x: x!= successor, edges[block])
    old_edges.append(new_successor_address)
    edges[block] = old_edges
    
    jump_type[new_successor_address] = jump_type[successor]
                
    # Finally, we keep on cloning
    path.append((block, new_successor_address))

    if debug_info:
        print "LLegue aqui con" + str(new_successor_address)
        print block
    sym_exec_block(new_params, new_successor_address, block, depth, func_call,current_level+1,path)
    path.pop()
        
        
# Symbolically executing an instruction
def sym_exec_ins(params, block, instr, func_call,stack_first,instr_index):
    global MSIZE
    global visited_pcs
    global solver
    global vertices
    global edges
    global g_src_map
    global calls_affect_state
    global data_source
    global ls_cont
    global function_block_map
    global function_info
    global potential_jump
    global indirect_jump
    global param_abs
    global mapping_state_variables
    global update_fields
    global push_jump_relations
    global jump_addresses

    
    stack = params.stack
    mem = params.mem
    memory = params.memory
    global_state = params.global_state
    sha3_list = params.sha3_list
    path_conditions_and_vars = params.path_conditions_and_vars
    analysis = params.analysis
    calls = params.calls

    visited_pcs.add(global_state["pc"])

    instr_parts = str.split(instr, ' ')
    opcode = instr_parts[0]

    if opcode == "INVALID":
        return
    elif opcode == "ASSERTFAIL":
        
        # if g_src_map:
        #     source_code = g_src_map.get_source_code(global_state['pc'])
        #     source_code = source_code.split("(")[0]
        #     func_name = source_code.strip()
        #     if check_sat(solver, False) != unsat:
        #         model = solver.model()
        #     if func_name == "assert":
        #         global_problematic_pcs["assertion_failure"].append(Assertion(global_state["pc"], model))
        #     elif func_call != -1:
        #         global_problematic_pcs["assertion_failure"].append(Assertion(func_call, model))
        return

    # collecting the analysis result by calling this skeletal function
    # this should be done before symbolically executing the instruction,
    # since SE will modify the stack and mem
    #update_analysis(analysis, opcode, stack, mem, global_state, path_conditions_and_vars, solver)
    # if opcode == "CALL" and analysis["reentrancy_bug"] and analysis["reentrancy_bug"][-1]:
    #     global_problematic_pcs["reentrancy_bug"].append(global_state["pc"])

    log.debug("==============================")
    log.debug("EXECUTING: " + instr)

    #
    #  0s: Stop and Arithmetic Operations
    #
    if opcode == "STOP":
        global_state["pc"] = global_state["pc"] + 1
        return
    elif opcode == "ADD":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            # Type conversion is needed when they are mismatched
            if isReal(first) and isSymbolic(second):
                first = BitVecVal(first, 256)
                computed = first + second
            elif isSymbolic(first) and isReal(second):
                second = BitVecVal(second, 256)
                computed = first + second
            else:
                # both are real and we need to manually modulus with 2 ** 256
                # if both are symbolic z3 takes care of modulus automatically
                computed = (first + second) % (2 ** 256)
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MUL":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isReal(first) and isSymbolic(second):
                first = BitVecVal(first, 256)
            elif isSymbolic(first) and isReal(second):
                second = BitVecVal(second, 256)
            computed = first * second & UNSIGNED_BOUND_NUMBER
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SUB":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isReal(first) and isSymbolic(second):
                first = BitVecVal(first, 256)
                computed = first - second
            elif isSymbolic(first) and isReal(second):
                second = BitVecVal(second, 256)
                computed = first - second
            else:
                computed = (first - second) % (2 ** 256)
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "DIV":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                if second == 0:
                    computed = 0
                else:
                    first = to_unsigned(first)
                    second = to_unsigned(second)
                    computed = first / second
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                # solver.push()
                # solver.add( Not (second == 0) )
                # if check_sat(solver) == unsat:
                #     computed = 0
                # else:
                computed = UDiv(first, second)
                #solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SDIV":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                first = to_signed(first)
                second = to_signed(second)
                if second == 0:
                    computed = 0
                elif first == -2**255 and second == -1:
                    computed = -2**255
                else:
                    sign = -1 if (first / second) < 0 else 1
                    computed = sign * ( abs(first) / abs(second) )
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                # solver.push()
                # solver.add(Not(second == 0))
                if second == 0:
                    computed = 0
                else:
                    # solver.push()
                    # solver.add( Not( And(first == -2**255, second == -1 ) ))
                    # if check_sat(solver) == unsat:
                    #     computed = -2**255
                    # else:
                    #     solver.push()
                    #     solver.add(first / second < 0)
                    #     sign = -1 if check_sat(solver) == sat else 1
                    #     z3_abs = lambda x: If(x >= 0, x, -x)
                    #     first = z3_abs(first)
                    #     second = z3_abs(second)
                    computed = first / second
                #     solver.pop()
                #     solver.pop()
                # solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MOD":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)

            if isAllReal(first, second):
                if second == 0:
                    computed = 0
                else:
                    first = to_unsigned(first)
                    second = to_unsigned(second)
                    computed = first % second & UNSIGNED_BOUND_NUMBER

            else:
                first = to_symbolic(first)
                second = to_symbolic(second)

                # solver.push()
                # solver.add(Not(second == 0))
                # if check_sat(solver) == unsat:
                #     # it is provable that second is indeed equal to zero
                #     computed = 0
                # else:
                computed = URem(first, second)
                #solver.pop()

            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SMOD":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                if second == 0:
                    computed = 0
                else:
                    first = to_signed(first)
                    second = to_signed(second)
                    sign = -1 if first < 0 else 1
                    computed = sign * (abs(first) % abs(second))
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)


                computed = (first % second)

            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "ADDMOD":
        if len(stack) > 2:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
            third = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            third = get_push_value(third)
            
            if isAllReal(first, second, third):
                if third == 0:
                    computed = 0
                else:
                    computed = (first + second) % third
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                # solver.push()
                # solver.add( Not(third == 0) )
                #if third == unsat:
                if isReal(third) and third == 0:
                    computed = 0
                else:
                    # first = ZeroExt(256, first)
                    # second = ZeroExt(256, second)
                    # third = ZeroExt(256, third)
                    computed = (first + second) % third
                    computed = Extract(255, 0, computed)
                #solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MULMOD":
        if len(stack) > 2:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
            third = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            third = get_push_value(third)
            
            if isAllReal(first, second, third):
                if third == 0:
                    computed = 0
                else:
                    computed = (first * second) % third
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                if third == 0:
                    computed = 0
                else:
                    # first = ZeroExt(256, first)
                    # second = ZeroExt(256, second)
                    # third = ZeroExt(256, third)
                    computed = (first*second)%third#URem(first * second, third)
                    computed = Extract(255, 0, computed)
                # solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "EXP":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            base = stack.pop(0)
            exponent = stack.pop(0)

            base = get_push_value(base)
            exponent = get_push_value(exponent)
            
            # Type conversion is needed when they are mismatched
            if isAllReal(base, exponent):
                computed = pow(base, exponent, 2**256)
            else:
                # The computed value is unknown, this is because power is
                # not supported in bit-vector theory
                new_var_name = gen.gen_arbitrary_var()
                computed = BitVec(new_var_name, 256)
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SIGNEXTEND":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                if first >= 32 or first < 0:
                    computed = second
                else:
                    signbit_index_from_right = 8 * first + 7
                    if second & (1 << signbit_index_from_right):
                        computed = second | (2 ** 256 - (1 << signbit_index_from_right))
                    else:
                        computed = second & ((1 << signbit_index_from_right) - 1 )
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                # solver.push()
                # solver.add( Not( Or(first >= 32, first < 0 ) ) )
                # if check_sat(solver) == unsat:
                #     computed = second
                # else:
                signbit_index_from_right = 8 * first + 7
                    # solver.push()
                    # solver.add(second & (1 << signbit_index_from_right) == 0)
                    # if check_sat(solver) == unsat:
                    #     computed = second | (2 ** 256 - (1 << signbit_index_from_right))
                    # else:
                computed = second & ((1 << signbit_index_from_right) - 1)
                #     solver.pop()
                # solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    #
    #  10s: Comparison and Bitwise Logic Operations
    #
    elif opcode == "LT":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                first = to_unsigned(first)
                second = to_unsigned(second)
                if first < second:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(ULT(first, second), BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "GT":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                first = to_unsigned(first)
                second = to_unsigned(second)
                if first > second:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(UGT(first, second), BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SLT":  # Not fully faithful to signed comparison
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                first = to_signed(first)
                second = to_signed(second)
                if first < second:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(first < second, BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SGT":  # Not fully faithful to signed comparison
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)
            
            if isAllReal(first, second):
                first = to_signed(first)
                second = to_signed(second)
                if first > second:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(first > second, BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "EQ":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)

            if isAllReal(first, second):
                if first == second:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(first == second, BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "ISZERO":
        # Tricky: this instruction works on both boolean and integer,
        # when we have a symbolic expression, type error might occur
        # Currently handled by try and catch
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)

            first = get_push_value(first)

            if isReal(first):
                if first == 0:
                    computed = 1
                else:
                    computed = 0
            else:
                computed = If(first == 0, BitVecVal(1, 256), BitVecVal(0, 256))
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "AND":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
            
            first_aux = get_push_value(first)
            second_aux = get_push_value(second)
            
            computed = first_aux & second_aux

            if computed == first_aux:
                computed = first
            elif computed == second_aux:
                computed = second
            
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "OR":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first_aux = get_push_value(first)
            second_aux = get_push_value(second)
            
            computed = first_aux | second_aux

            if computed == first_aux:
                computed = first
            elif computed == second_aux:
                computed = second
                
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)

        else:
            raise ValueError('STACK underflow')
    elif opcode == "XOR":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first_aux = get_push_value(first)
            second_aux = get_push_value(second)

            computed = first_aux ^ second_aux

            if computed == first_aux:
                computed = first
            elif computed == second_aux:
                computed = second
            
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)

        else:
            raise ValueError('STACK underflow')
    elif opcode == "NOT":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)

            first = get_push_value(first)
            
            computed = (~first) & UNSIGNED_BOUND_NUMBER
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "BYTE":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)

            first = get_push_value(first)
            
            byte_index = 32 - first - 1
            second = stack.pop(0)

            second = get_push_value(second)
            
            if isAllReal(first, second):
                if first >= 32 or first < 0 or byte_index < 0:
                    computed = 0
                else:
                    computed = second & (255 << (8 * byte_index))
                    computed = computed >> (8 * byte_index)
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                # solver.push()
                # solver.add( Not (Or( first >= 32, first < 0 ) ) )
                if byte_index < 0:
                    computed = 0
                else:
                    computed = second & (255 << (8 * byte_index))
                    computed = computed >> (8 * byte_index)
                #solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
        
    # 20s: SHA3
    #
    elif opcode == "SHA3":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            s0 = stack.pop(0)
            s1 = stack.pop(0)

            s0 = get_push_value(s0)
            s1 = get_push_value(s1)
            
            # if isAllReal(s0, s1):
            #     # simulate the hashing of sha3
            #     data = [str(x) for x in memory[s0: s0 + s1]]
            #     position = ''.join(data)
            #     position = re.sub('[\s+]', '', position)
            #     position = zlib.compress(six.b(position), 9)
            #     position = base64.b64encode(position)
            #     position = position.decode()
            #     if position in sha3_list:
            #         stack.insert(0, sha3_list[position])
            #     else:
            #         new_var_name = gen.gen_arbitrary_var()
            #         new_var = BitVec(new_var_name, 256)
            #         sha3_list[position] = new_var
            #         stack.insert(0, new_var)
            # else:
                # push into the execution a fresh symbolic variable
            new_var_name = gen.gen_arbitrary_var()
            new_var = BitVec(new_var_name, 256)
                # path_conditions_and_vars[new_var_name] = new_var
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    #
    # 30s: Environment Information
    #
    elif opcode == "ADDRESS":  # get address of currently executing account
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, path_conditions_and_vars["Ia"])
    elif opcode == "BALANCE":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            address = stack.pop(0)
            address = get_push_value(address)
            
            if isReal(address) and global_params.USE_GLOBAL_BLOCKCHAIN:
                new_var = data_source.getBalance(address)
            else:
                new_var_name = gen.gen_balance_var()
                if new_var_name in path_conditions_and_vars:
                    new_var = path_conditions_and_vars[new_var_name]
                else:
                    new_var = BitVec(new_var_name, 256)
                    path_conditions_and_vars[new_var_name] = new_var
            if isReal(address):
                hashed_address = "concrete_address_" + str(address)
            else:
                hashed_address = str(address)
            global_state["balance"][hashed_address] = new_var
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "CALLER":  # get caller address
        # that is directly responsible for this execution
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["sender_address"])
    elif opcode == "ORIGIN":  # get execution origination address
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["origin"])
    elif opcode == "CALLVALUE":  # get value of this transaction
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["value"])
    elif opcode == "CALLDATALOAD":  # from input data from environment
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            position = stack.pop(0)

            position = get_push_value(position)
            
            if g_src_map:
                source_code = g_src_map.get_source_code(global_state['pc'] - 1)
                if source_code.startswith("function") and isReal(position):
                    #Delete commment blocks
                    idx1_cb = source_code.find("/*")
                    idx2_cb = source_code.find("*/")
                    
                    while (idx1_cb !=-1 and idx2_cb != -1):
                        source_code = source_code[:idx1_cb]+source_code[idx2_cb+2:]
                        idx1_cb = source_code.find("/*")
                        idx2_cb = source_code.find("*/")
                    
                    idx1 = source_code.index("(") + 1
                    idx2 = source_code.index(")")
                    params = source_code[idx1:idx2]

                    if params.find("//")!=-1:
                        p = params.split("\n")
                        params = []
                        for e in p:
                            idx = e.find("//")
                            if idx != -1:
                                params.append(e[:idx])
                                
                            else:
                                params.append(e)
                        params = ",".join(params)
                        
                    params_list = params.split(",")
                    params_list_aux = []
                    for param in params_list:
                        comments = param.split("\n")
                        params_list_aux+= filter(lambda x: (not x.strip().startswith("//")) and x != "",comments)

                    params_list_aux = filter(lambda x: x.strip() != "",params_list_aux)
                  
                    params_list = [param.split("//")[0].rstrip().rstrip("\n").split(" ")[-1] for param in params_list_aux]
                    param_idx = (position - 4) // 32
                    new_var_name = params_list[param_idx]
                    g_src_map.var_names.append(new_var_name)
                    param_abs = (block,new_var_name)
                else:
                    if param_abs[1] != "":
                        new_var_name = param_abs[1]
                    else:
                        new_var_name = gen.gen_data_var(position)
            else:
                new_var_name = gen.gen_data_var(position)
            if new_var_name in path_conditions_and_vars:
                new_var = path_conditions_and_vars[new_var_name]
            else:
                new_var = BitVec(new_var_name, 256)
                path_conditions_and_vars[new_var_name] = new_var

            updateCallDataValues(block,new_var_name)
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "CALLDATASIZE":
        global_state["pc"] = global_state["pc"] + 1
        new_var_name = gen.gen_data_size()
        if new_var_name in path_conditions_and_vars:
            new_var = path_conditions_and_vars[new_var_name]
        else:
            new_var = BitVec(new_var_name, 256)
            path_conditions_and_vars[new_var_name] = new_var
        stack.insert(0, new_var)
    elif opcode == "CALLDATACOPY":  # Copy input data to memory
        #  TODO: Don't know how to simulate this yet
        if len(stack) > 2:
            global_state["pc"] = global_state["pc"] + 1
            stack.pop(0)
            stack.pop(0)
            stack.pop(0)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "CODESIZE":
        if g_disasm_file.endswith('.disasm'):
            evm_file_name = g_disasm_file[:-7]
        else:
            evm_file_name = g_disasm_file
        with open(evm_file_name, 'r') as evm_file:
            evm = evm_file.read()[:-1]
            code_size = len(evm)/2
            stack.insert(0, code_size)
    elif opcode == "CODECOPY":
        if len(stack) > 2:
           
            global_state["pc"] = global_state["pc"] + 1
            mem_location = stack.pop(0)
            code_from = stack.pop(0)
            no_bytes = stack.pop(0)

            mem_location = get_push_value(mem_location)
            code_from = get_push_value(code_from)
            no_bytes = get_push_value(no_bytes)
            
            current_miu_i = global_state["miu_i"]

            if isAllReal(mem_location, current_miu_i, code_from, no_bytes):
                if six.PY2:
                    temp = long(math.ceil((mem_location + no_bytes) / float(32)))
                else:
                    temp = int(math.ceil((mem_location + no_bytes) / float(32)))

                if temp > current_miu_i:
                    current_miu_i = temp

                if g_disasm_file.endswith('.disasm'):
                    evm_file_name = g_disasm_file[:-7]
                else:
                    evm_file_name = g_disasm_file
                with open(evm_file_name, 'r') as evm_file:
                    evm = evm_file.read()[:-1]
                    start = code_from * 2
                    end = start + no_bytes * 2
                    code = evm[start: end]

                if code != '':
                    mem[mem_location] = int(code, 16)
            else:
                new_var_name = gen.gen_code_var("Ia", code_from, no_bytes)
                if new_var_name in path_conditions_and_vars:
                    new_var = path_conditions_and_vars[new_var_name]
                else:
                    new_var = BitVec(new_var_name, 256)
                    path_conditions_and_vars[new_var_name] = new_var

                temp = ((mem_location + no_bytes) / 32) + 1
                current_miu_i = to_symbolic(current_miu_i)
                expression = current_miu_i < temp
                # solver.push()
                # solver.add(expression)
                if MSIZE:
                    # if check_sat(solver) != unsat:
                    current_miu_i = If(expression, temp, current_miu_i)
                #solver.pop()
                mem.clear() # very conservative
                mem[str(mem_location)] = new_var
            global_state["miu_i"] = current_miu_i
        else:
            raise ValueError('STACK underflow')
    elif opcode == "RETURNDATACOPY":
        if len(stack) > 2:
            global_state["pc"] += 1
            stack.pop(0)
            stack.pop(0)
            stack.pop(0)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "RETURNDATASIZE":
        global_state["pc"] += 1
        new_var_name = gen.gen_arbitrary_var()
        new_var = BitVec(new_var_name, 256)
        stack.insert(0, new_var)
    elif opcode == "GASPRICE":
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["gas_price"])
    elif opcode == "EXTCODESIZE":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            address = stack.pop(0)

            address = get_push_value(address)
            
            if isReal(address) and global_params.USE_GLOBAL_BLOCKCHAIN:
                code = data_source.getCode(address)
                stack.insert(0, len(code)/2)
            else:
                #not handled yet
                new_var_name = gen.gen_code_size_var(address)
                if new_var_name in path_conditions_and_vars:
                    new_var = path_conditions_and_vars[new_var_name]
                else:
                    new_var = BitVec(new_var_name, 256)
                    # new_var = new_var_name
                    path_conditions_and_vars[new_var_name] = new_var
                stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "EXTCODECOPY":
        if len(stack) > 3:
            global_state["pc"] = global_state["pc"] + 1
            address = stack.pop(0)
            mem_location = stack.pop(0)
            code_from = stack.pop(0)
            no_bytes = stack.pop(0)

            address = get_push_value(address)
            mem_location = get_push_value(mem_location)
            code_from = get_push_value(code_from)
            no_bytes = get_push_value(no_bytes)
            
            current_miu_i = global_state["miu_i"]

            if isAllReal(address, mem_location, current_miu_i, code_from, no_bytes) and USE_GLOBAL_BLOCKCHAIN:
                if six.PY2:
                    temp = long(math.ceil((mem_location + no_bytes) / float(32)))
                else:
                    temp = int(math.ceil((mem_location + no_bytes) / float(32)))
                if temp > current_miu_i:
                    current_miu_i = temp

                evm = data_source.getCode(address)
                start = code_from * 2
                end = start + no_bytes * 2
                code = evm[start: end]
                if code != '':
                    mem[mem_location] = int(code, 16)
            else:
                new_var_name = gen.gen_code_var(address, code_from, no_bytes)
                if new_var_name in path_conditions_and_vars:
                    new_var = path_conditions_and_vars[new_var_name]
                else:
                    new_var = BitVec(new_var_name, 256)
                    path_conditions_and_vars[new_var_name] = new_var

                temp = ((mem_location + no_bytes) / 32) + 1
                current_miu_i = to_symbolic(current_miu_i)
                expression = current_miu_i < temp
                # solver.push()
                # solver.add(expression)
                if MSIZE:
                    # if check_sat(solver) != unsat:
                    current_miu_i = If(expression, temp, current_miu_i)
                #solver.pop()
                mem.clear() # very conservative
                mem[str(mem_location)] = new_var
            global_state["miu_i"] = current_miu_i
        else:
            raise ValueError('STACK underflow')
    #
    #  40s: Block Information
    #
    elif opcode == "BLOCKHASH":  # information from block header
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            stack.pop(0)
            new_var_name = "IH_blockhash"
            if new_var_name in path_conditions_and_vars:
                new_var = path_conditions_and_vars[new_var_name]
            else:
                new_var = BitVec(new_var_name, 256)
                path_conditions_and_vars[new_var_name] = new_var
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "COINBASE":  # information from block header
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["currentCoinbase"])
    elif opcode == "TIMESTAMP":  # information from block header
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["currentTimestamp"])
    elif opcode == "NUMBER":  # information from block header
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["currentNumber"])
    elif opcode == "DIFFICULTY":  # information from block header
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["currentDifficulty"])
    elif opcode == "GASLIMIT":  # information from block header
        global_state["pc"] = global_state["pc"] + 1
        stack.insert(0, global_state["currentGasLimit"])
    #
    #  50s: Stack, Memory, Storage, and Flow Information
    #
    elif opcode == "POP":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            stack.pop(0)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MLOAD":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            address = stack.pop(0)

            address = get_push_value(address)
            
            #Added by Pablo Gordillo
            vertices[block].add_ls_value("mload",ls_cont[0],address)
            ls_cont[0]+=1
            current_miu_i = global_state["miu_i"]
            if isAllReal(address, current_miu_i) and address in mem:
                if six.PY2:
                    temp = long(math.ceil((address + 32) / float(32)))
                else:
                    temp = int(math.ceil((address + 32) / float(32)))
                if temp > current_miu_i:
                    current_miu_i = temp
                value = mem[address]
                stack.insert(0, value)
            else:
                temp = ((address + 31) / 32) + 1
                current_miu_i = to_symbolic(current_miu_i)
                expression = current_miu_i < temp
                # solver.push()
                # solver.add(expression)
                if MSIZE:
                    # if check_sat(solver) != unsat:
                        # this means that it is possibly that current_miu_i < temp
                    current_miu_i = If(expression,temp,current_miu_i)
                #solver.pop()
                new_var_name = gen.gen_mem_var(address)
                if new_var_name in path_conditions_and_vars:
                    new_var = path_conditions_and_vars[new_var_name]
                else:
                    new_var = BitVec(new_var_name, 256)
                    path_conditions_and_vars[new_var_name] = new_var
                stack.insert(0, new_var)
                if isReal(address):
                    mem[address] = new_var
                else:
                    mem[str(address)] = new_var
            global_state["miu_i"] = current_miu_i
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MSTORE":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            stored_address = stack.pop(0)
            stored_value = stack.pop(0)

            stored_address = get_push_value(stored_address)
            stored_value = get_push_value(stored_value)
            
            #Added by Pablo Gordillo
            vertices[block].add_ls_value("mstore",ls_cont[1],stored_address)
            ls_cont[1]+=1
            current_miu_i = global_state["miu_i"]
            if isReal(stored_address):
                # preparing data for hashing later
                old_size = len(memory) // 32
                new_size = ceil32(stored_address + 32) // 32
                mem_extend = (new_size - old_size) * 32
                try:
                    memory.extend([0] * mem_extend)
                    value = stored_value
                    for i in range(31, -1, -1):
                        memory[stored_address + i] = value % 256
                        value /= 256
                except:
                    value = stored_value
                    for i in range(31, -1, -1):
                        mem[str(stored_address + i)] = value % 256
                        value /= 256
            if isAllReal(stored_address, current_miu_i):
                if six.PY2:
                    temp = long(math.ceil((stored_address + 32) / float(32)))
                else:
                    temp = int(math.ceil((stored_address + 32) / float(32)))
                if temp > current_miu_i:
                    current_miu_i = temp
                mem[stored_address] = stored_value  # note that the stored_value could be symbolic
            else:
                temp = ((stored_address + 31) / 32) + 1
                expression = current_miu_i < temp
                # solver.push()
                # solver.add(expression)
                if MSIZE:
#                    if check_sat(solver) != unsat:
                        # this means that it is possibly that current_miu_i < temp
                    current_miu_i = If(expression,temp,current_miu_i)
                #solver.pop()
                mem.clear()  # very conservative
                mem[str(stored_address)] = stored_value
            global_state["miu_i"] = current_miu_i
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MSTORE8":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            stored_address = stack.pop(0)
            temp_value = stack.pop(0)

            stored_address = get_push_value(stored_address)
            temp_value = get_push_value(temp_value)
            
            stored_value = temp_value % 256  # get the least byte
     
            vertices[block].add_ls_value("mstore",ls_cont[1],stored_address)
            ls_cont[1]+=1
            
            current_miu_i = global_state["miu_i"]
            if isAllReal(stored_address, current_miu_i):
                if six.PY2:
                    temp = long(math.ceil((stored_address + 1) / float(32)))
                else:
                    temp = int(math.ceil((stored_address + 1) / float(32)))
                if temp > current_miu_i:
                    current_miu_i = temp
                mem[stored_address] = stored_value  # note that the stored_value could be symbolic
            else:
                temp = (stored_address / 32) + 1
                if isReal(current_miu_i):
                    current_miu_i = BitVecVal(current_miu_i, 256)
                expression = current_miu_i < temp
                # solver.push()
                # solver.add(expression)
                if MSIZE:
                #    if check_sat(solver) != unsat:
                        # this means that it is possibly that current_miu_i < temp
                    current_miu_i = If(expression,temp,current_miu_i)
                #solver.pop()
                mem.clear()  # very conservative
                mem[str(stored_address)] = stored_value
            global_state["miu_i"] = current_miu_i
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SLOAD":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1

            p_s,v = check_sload_fragment_pattern(vertices[block],instr_index,stack)
            
            position = stack.pop(0)
            position = get_push_value(position)
            
            #Added by PG
            try:    
                val = int(position)
                if g_src_map:
                    p = g_src_map._get_var_names()
                    statevar_name_original =  p[val]
            except:
               statevar_name_original = ""
               
            #Added by Pablo Gordillo
            if p_s:
                vertices[block].add_ls_value("sload",ls_cont[2],str(position)+"_"+str(v))

            else:
                vertices[block].add_ls_value("sload",ls_cont[2],position)

            if g_src_map:
                new_var_name = g_src_map.get_source_code(global_state['pc'] - 1)          
                operators = '[-+*/%|&^!><=]'
                line = re.compile(operators).split(new_var_name)[0].strip()
            
            ls_cont[2]+=1
            statevar_name = ""
            if isReal(position) and position in global_state["Ia"]:
                value = global_state["Ia"][position]
                stack.insert(0, value)
                
            elif global_params.USE_GLOBAL_STORAGE and isReal(position) and position not in global_state["Ia"]:
                value = data_source.getStorageAt(position)
                global_state["Ia"][position] = value
                stack.insert(0, value)
            else:
                if str(position) in global_state["Ia"]:
                    value = global_state["Ia"][str(position)]
                    stack.insert(0, value)

                else:
                    if is_expr(position):
                        position = simplify(position)
                    if g_src_map:
                        new_var_name = g_src_map.get_source_code(global_state['pc'] - 1)
                        
                        operators = '[-+*/%|&^!><=]'
                        new_var_name = re.compile(operators).split(new_var_name)[0].strip()
                        statevar_name = new_var_name
                        
                        if g_src_map.is_a_parameter_or_state_variable(new_var_name):
                            new_var_name = "Ia_store" + "-" + str(position) + "-" + new_var_name
                        else:
                            new_var_name = gen.gen_owner_store_var(position)
                        
                    else:
                        new_var_name = gen.gen_owner_store_var(position)
                        statevar_name = new_var_name
                        
                    if new_var_name in path_conditions_and_vars:
                        new_var = path_conditions_and_vars[new_var_name]
                    else:
                        new_var = BitVec(new_var_name, 256)
                        path_conditions_and_vars[new_var_name] = new_var
                    stack.insert(0, new_var)

                    if isReal(position):
                        global_state["Ia"][position] = new_var
                    else:
                        global_state["Ia"][str(position)] = new_var
            if g_src_map:
                statevar_name = statevar_name if statevar_name != "" else line
                r_val = update_sstore_map(mapping_state_variables,statevar_name_original,statevar_name,p_s,position,v,g_src_map._get_var_names())
                if r_val:
                    update_fields[position] = r_val
                
        else:
            raise ValueError('STACK underflow')

    elif opcode == "SSTORE":
        if len(stack) > 1:
            for call_pc in calls:
                calls_affect_state[call_pc] = True
            global_state["pc"] = global_state["pc"] + 1
            stored_address = stack.pop(0)
            stored_value = stack.pop(0)

            stored_address = get_push_value(stored_address)
            stored_value = get_push_value(stored_value)
            
            # print stored_address
            # print stored_value
             
            #PG
            #print new_var_name
            #Added by Pablo Gordillo
            if g_src_map:
                new_var_name = g_src_map.get_source_code(global_state['pc'] - 1)        
                operators = '[-+*/%|&^!><=]'
                new_var_name = re.compile(operators).split(new_var_name)[0].strip()
                statevar_name_compressed = new_var_name

                p = g_src_map._get_var_names()
                
            p_s, v = sstore_fragment(vertices[block],instr_index)
            
            if p_s:
                vertices[block].add_ls_value("sstore",ls_cont[3],str(stored_address)+"_"+str(v))
            else:
                vertices[block].add_ls_value("sstore",ls_cont[3],stored_address)
            ls_cont[3]+=1
            if isReal(stored_address):
                # note that the stored_value could be unknown
                global_state["Ia"][stored_address] = stored_value
            else:
                # note that the stored_value could be unknown
                global_state["Ia"][str(stored_address)] = stored_value

            try:
                val = int(stored_address)
                statevar_name_original =  p[val]
                
            except:
                statevar_name_original = ""

            if g_src_map:
               r_val = update_sstore_map(mapping_state_variables,statevar_name_original,statevar_name_compressed,p_s,stored_address,v,g_src_map._get_var_names())
               if r_val:
                    update_fields[stored_address] = r_val
        else:
            raise ValueError('STACK underflow')
    elif opcode == "JUMP":
        if len(stack) > 0:
            push_address = stack.pop(0)
            target_address,push_block = push_address

            jump_addresses.append(target_address)
            
            #Define push-jump relations for cloning
            rel = push_jump_relations.get(block,{})
            addresses = rel.get(target_address,[])
            if addresses != []:
                if push_block not in addresses:
                    rel[target_address] = addresses.append(push_block)
            else:
                rel[target_address] = [push_block]

            push_jump_relations[block] = rel

            vertices[block].set_jump_target(target_address)

            if target_address not in edges[block]:
                edges[block].append(target_address)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "JUMPI":
        # We need to prepare two branches
        if len(stack) > 1:
            target_address = stack.pop(0)
            target_address = get_push_value(target_address)

            if isSymbolic(target_address):
                try:
                    target_address = int(str(simplify(target_address)))
                except:
                    raise TypeError("Target address must be an integer")
            vertices[block].set_jump_target(target_address)
            flag = stack.pop(0)
            branch_expression = (BitVecVal(0, 1) == BitVecVal(1, 1))
            if isReal(flag):
                if flag != 0:
                    branch_expression = True
            else:
                branch_expression = (flag != 0)

            vertices[block].set_branch_expression(branch_expression)
            if target_address not in edges[block]:
                edges[block].append(target_address)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "PC":
        stack.insert(0, global_state["pc"])
        global_state["pc"] = global_state["pc"] + 1
    elif opcode == "MSIZE":
        global_state["pc"] = global_state["pc"] + 1
        msize = 32 * global_state["miu_i"]
        stack.insert(0, msize)
    elif opcode == "GAS":
        # In general, we do not have this precisely. It depends on both
        # the initial gas and the amount has been depleted
        # we need o think about this in the future, in case precise gas
        # can be tracked
        global_state["pc"] = global_state["pc"] + 1
        new_var_name = gen.gen_gas_var()
        new_var = BitVec(new_var_name, 256)
        path_conditions_and_vars[new_var_name] = new_var
        stack.insert(0, new_var)
    elif opcode == "JUMPDEST":
        # Literally do nothing
        global_state["pc"] = global_state["pc"] + 1
    #
    #  60s & 70s: Push Operations
    #
    elif opcode.startswith('PUSH', 0):  # this is a push instruction
        position = int(opcode[4:], 10)
        if debug_info:
            print global_state["pc"]

        global_state["pc"] = global_state["pc"] + 1 + position
        hs = str(instr_parts[1])[2:] #To delete 0x...
        if f_hashes and hs in f_hashes :
            name = f_hashes[hs]
            function_info = (True,name)
            

        
        pushed_value = int(instr_parts[1], 16)
        stack.insert(0, (pushed_value,block))
        if global_params.UNIT_TEST == 3: # test evm symbolic
            stack[0] = BitVecVal(stack[0], 256)
    #
    #  80s: Duplication Operations
    #
    elif opcode.startswith("DUP", 0):
        global_state["pc"] = global_state["pc"] + 1
        position = int(opcode[3:], 10) - 1
        if len(stack) > position:
            duplicate = stack[position]
            stack.insert(0, duplicate)
        else:
            raise ValueError('STACK underflow')

    #
    #  90s: Swap Operations
    #
    elif opcode.startswith("SWAP", 0):
        global_state["pc"] = global_state["pc"] + 1
        position = int(opcode[4:], 10)
        if len(stack) > position:
            temp = stack[position]
            stack[position] = stack[0]
            stack[0] = temp
        else:
            raise ValueError('STACK underflow')

    #
    #  a0s: Logging Operations
    #
    elif opcode in ("LOG0", "LOG1", "LOG2", "LOG3", "LOG4"):
        global_state["pc"] = global_state["pc"] + 1
        # We do not simulate these log operations
        num_of_pops = 2 + int(opcode[3:])
        while num_of_pops > 0:
            stack.pop(0)
            num_of_pops -= 1

    #
    #  f0s: System Operations
    #
    elif opcode == "CREATE":
        if len(stack) > 2:
            global_state["pc"] += 1
            stack.pop(0)
            stack.pop(0)
            stack.pop(0)
            new_var_name = gen.gen_arbitrary_var()
            new_var = BitVec(new_var_name, 256)
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "CALL":
        # TODO: Need to handle miu_i
        if len(stack) > 6:
            calls.append(global_state["pc"])
            for call_pc in calls:
                if call_pc not in calls_affect_state:
                    calls_affect_state[call_pc] = False
            global_state["pc"] = global_state["pc"] + 1
            outgas = stack.pop(0)
            recipient = stack.pop(0)
            transfer_amount = stack.pop(0)
            start_data_input = stack.pop(0)
            size_data_input = stack.pop(0)
            start_data_output = stack.pop(0)
            size_data_ouput = stack.pop(0)

            outgas = get_push_value(outgas)
            recipient = get_push_value(recipient)
            transfer_amount = get_push_value(transfer_amount)
            start_data_input = get_push_value(start_data_input)
            size_data_input = get_push_value(size_data_input)
            start_data_output = get_push_value(start_data_output)
            size_data_ouput = get_push_value(size_data_ouput)
            
            # in the paper, it is shaky when the size of data output is
            # min of stack[6] and the | o |

            if isReal(transfer_amount):
                if transfer_amount == 0:
                    stack.insert(0, 1)   # x = 0
                    return

            # Let us ignore the call depth
            balance_ia = global_state["balance"]["Ia"]
            is_enough_fund = (transfer_amount <= balance_ia)
            # solver.push()
            # solver.add(is_enough_fund)

            # if check_sat(solver) == unsat:
            #     # this means not enough fund, thus the execution will result in exception
            #     solver.pop()
            #     stack.insert(0, 0)   # x = 0
            if False:
                pass
            else:
                # the execution is possibly okay
                stack.insert(0, 1)   # x = 1
                # solver.pop()
                # solver.add(is_enough_fund)
                # path_conditions_and_vars["path_condition"].append(is_enough_fund)
                last_idx = len(path_conditions_and_vars["path_condition"]) - 1
                #analysis["time_dependency_bug"][last_idx] = global_state["pc"] - 1
                new_balance_ia = (balance_ia - transfer_amount)
                global_state["balance"]["Ia"] = new_balance_ia
                address_is = path_conditions_and_vars["Is"]
                address_is = (address_is & CONSTANT_ONES_159)
                boolean_expression = (recipient != address_is)
                # solver.push()
                # solver.add(boolean_expression)
                #if check_sat(solver) == unsat:
                    # solver.pop()
                    # new_balance_is = (global_state["balance"]["Is"] + transfer_amount)
                    # global_state["balance"]["Is"] = new_balance_is
                if False:
                    pass
                else:
                    #solver.pop()
                    if isReal(recipient):
                        new_address_name = "concrete_address_" + str(recipient)
                    else:
                        new_address_name = gen.gen_arbitrary_address_var()
                    old_balance_name = gen.gen_arbitrary_var()
                    old_balance = BitVec(old_balance_name, 256)
                    path_conditions_and_vars[old_balance_name] = old_balance
                    constraint = (old_balance >= 0)
                    # solver.add(constraint)
                    path_conditions_and_vars["path_condition"].append(constraint)
                    new_balance = (old_balance + transfer_amount)
                    global_state["balance"][new_address_name] = new_balance
        else:
            raise ValueError('STACK underflow')
    elif opcode == "CALLCODE":
        # TODO: Need to handle miu_i
        if len(stack) > 6:
            calls.append(global_state["pc"])
            for call_pc in calls:
                if call_pc not in calls_affect_state:
                    calls_affect_state[call_pc] = False
            global_state["pc"] = global_state["pc"] + 1
            outgas = stack.pop(0)
            recipient = stack.pop(0) # this is not used as recipient

            outgas = get_push_value(outgas)
            recipient = get_push_value(recipient)
            
            if global_params.USE_GLOBAL_STORAGE:
                if isReal(recipient):
                    recipient = hex(recipient)
                    if recipient[-1] == "L":
                        recipient = recipient[:-1]
                    recipients.add(recipient)
                else:
                    recipients.add(None)

            transfer_amount = stack.pop(0)
            start_data_input = stack.pop(0)
            size_data_input = stack.pop(0)
            start_data_output = stack.pop(0)
            size_data_ouput = stack.pop(0)

            transfer_amount = get_push_value(transfer_amount)
            start_data_input = get_push_value(start_data_input)
            size_data_input = get_push_value(size_data_input)
            start_data_output = get_push_value(start_data_output)
            size_data_output = get_push_value(size_data_output)
            # in the paper, it is shaky when the size of data output is
            # min of stack[6] and the | o |

            # if isReal(transfer_amount):
            #     if transfer_amount == 0:
            #         stack.insert(0, 1)   # x = 0
            #         return

            # Let us ignore the call depth
            balance_ia = global_state["balance"]["Ia"]
            is_enough_fund = (transfer_amount <= balance_ia)
            # solver.push()
            # solver.add(is_enough_fund)

            #if check_sat(solver) == unsat:
                # this means not enough fund, thus the execution will result in exception
            #    solver.pop()
            #    stack.insert(0, 0)   # x = 0
            if False:
                pass
            else:
                # the execution is possibly okay
                stack.insert(0, 1)   # x = 1
                # solver.pop()
                # solver.add(is_enough_fund)
                path_conditions_and_vars["path_condition"].append(is_enough_fund)
                last_idx = len(path_conditions_and_vars["path_condition"]) - 1
                #analysis["time_dependency_bug"][last_idx] = global_state["pc"] - 1
        else:
            raise ValueError('STACK underflow')
    elif opcode in ("DELEGATECALL", "STATICCALL"):
        if len(stack) > 5:
            global_state["pc"] += 1
            stack.pop(0)
            recipient = stack.pop(0)

            recipient = get_push_value(recipient)
            
            if global_params.USE_GLOBAL_STORAGE:
                if isReal(recipient):
                    recipient = hex(recipient)
                    if recipient[-1] == "L":
                        recipient = recipient[:-1]
                    recipients.add(recipient)
                else:
                    recipients.add(None)

            stack.pop(0)
            stack.pop(0)
            stack.pop(0)
            stack.pop(0)
            new_var_name = gen.gen_arbitrary_var()
            new_var = BitVec(new_var_name, 256)
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')
    elif opcode in ("RETURN", "REVERT"):
        # TODO: Need to handle miu_i
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            stack.pop(0)
            stack.pop(0)
            # TODO
            pass
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SUICIDE":
        global_state["pc"] = global_state["pc"] + 1
        recipient = stack.pop(0)

        recipient = get_push_value(recipient)
        
        transfer_amount = global_state["balance"]["Ia"]
        global_state["balance"]["Ia"] = 0
        if isReal(recipient):
            new_address_name = "concrete_address_" + str(recipient)
        else:
            new_address_name = gen.gen_arbitrary_address_var()
        old_balance_name = gen.gen_arbitrary_var()
        old_balance = BitVec(old_balance_name, 256)
        path_conditions_and_vars[old_balance_name] = old_balance
        constraint = (old_balance >= 0)
        #solver.add(constraint)
        path_conditions_and_vars["path_condition"].append(constraint)
        new_balance = (old_balance + transfer_amount)
        global_state["balance"][new_address_name] = new_balance
        # TODO
        return


    elif opcode == "SHL":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            first = get_push_value(first)
            second = get_push_value(second)

            # Type conversion is needed when they are mismatched
            if isReal(first) and isReal(second):
                first = to_unsigned(first)
                second = to_unsigned(second)
                computed = second*(2**first) % (2**256)
            else:
                computed = "shl("+str(first)+","+str(second)+")"
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
            
        else:
            raise ValueError('STACK underflow')
    elif opcode == "SHR":
        if len(stack) > 1:

            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
            
            first = get_push_value(first)
            second = get_push_value(second)
            # Type conversion is needed when they are mismatched
            if isReal(first) and isReal(second):
                first = to_unsigned(first)
                second = to_unsigned(second)

                #computed = second >> first
                computed = math.floor(second/(2**first))
            else:
                computed = "shr("+str(first)+","+str(second)+")"
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
            
        else:
            raise ValueError('STACK underflow')

    elif opcode == "SAR":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
            
            first = get_push_value(first)
            second = get_push_value(second)
            # Type conversion is needed when they are mismatched
            if isReal(first) and isReal(second):
                #computed = second >> first
                computed = math.floor(second/(2**first))
            else:
                computed = "shr("+str(first)+","+str(second)+")"
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
            
        else:
            raise ValueError('STACK underflow')


    elif opcode == "EXTCODEHASH":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            s0 = stack.pop(0)

            s0 = get_push_value(s0)
            
            new_var_name = gen.gen_arbitrary_var()
            new_var = BitVec(new_var_name, 256)
                # path_conditions_and_vars[new_var_name] = new_var
            stack.insert(0, new_var)
        else:
            raise ValueError('STACK underflow')

        
    else:
        log.debug("UNKNOWN INSTRUCTION: " + opcode)
        # if global_params.UNIT_TEST == 2 or global_params.UNIT_TEST == 3:
        #     log.critical("Unknown instruction: %s" % opcode)
        #     exit(UNKNOWN_INSTRUCTION)
        raise Exception('UNKNOWN INSTRUCTION: ' + opcode)


def analyze_next_block(block, successor, stack, path, func_call, depth, current_level, new_params, jump_type):
    global visited_blocks
    global vertices
    global blocks_to_create

    if successor in visited_blocks:
        # We filter all nodes with same beginning, and check if there's one of those
        # nodes with same stack. Notice that one block may contain several stacks

        same_stack_successors = get_all_blocks_with_same_stack(successor, stack)

        if len(same_stack_successors) > 0:
            update_matching_successor(successor, same_stack_successors[0], block, jump_type)
        else:
            copy_already_visited_node(successor, new_params, block, depth, func_call,current_level,path, jump_type)

    elif successor in vertices:

        vertices[successor].add_origin(block) #to compute which are the blocks that leads to successor

        path.append((block,successor))
        sym_exec_block(new_params, successor, block, depth, func_call,current_level+1,path)
        path.pop()
            # else:
            #     if vertices[successor].get_depth_level()<(current_level+1): 
            #         vertices[successor].set_depth_level(current_level+1)
            #         update_depth_level(successor,current_level+1,[])

    else:
        if successor not in blocks_to_create:
            blocks_to_create.append(successor)

    

def access_array_sim(opcode_ins,fake_stack):
    end = False
    # print "BEGIN"
    # print opcode
    # print fake_stack
    opcode = opcode_ins.strip()
    
    if opcode == "ADD":
        if len(fake_stack)>1:
            elem1 = fake_stack.pop(0)
            elem2 = fake_stack.pop(0)
        else:
            elem1 = fake_stack.pop(0)
            elem2 = 0
        if elem1 == 1 or elem2 == 1:
            fake_stack.insert(0,1)
            end = True
        else:
            fake_stack.insert(0,0)
            
    elif opcode.startswith("DUP",0):
        position = int(opcode[3:], 10) - 1
        if len(fake_stack) > position:
            duplicate = fake_stack[position]
            fake_stack.insert(0, duplicate)
        else:
            fake_stack.insert(0,0)
    
    elif opcode.startswith("SWAP",0):
        position = int(opcode[4:], 10)
        if len(fake_stack) > position:
            temp = fake_stack[position]
            fake_stack[position] = fake_stack[0]
            fake_stack[0] = temp
        else:
            for _ in range(position):
                fake_stack.insert(0,0) 

    else:
        op = opcode.split(" ")[0]
        ret = get_opcode(op)
        consume = ret[1]
        gen = ret[2]
        if len(fake_stack)>=consume:
            for _ in range(0,consume):
                fake_stack.pop(0)
        else:
            fake_stack = []
        if gen == 1:
            fake_stack.insert(0,0)

    # print fake_stack
    return end


class TimeoutError(Exception):
    pass

class Timeout:
   """Timeout class using ALARM signal."""

   def __init__(self, sec=10, error_message=os.strerror(errno.ETIME)):
       self.sec = sec
       self.error_message = error_message

   def __enter__(self):
       signal.signal(signal.SIGALRM, self._handle_timeout)
       signal.alarm(self.sec)

   def __exit__(self, *args):
       signal.alarm(0)    # disable alarm

   def _handle_timeout(self, signum, frame):
       raise TimeoutError(self.error_message)

def do_nothing():
    raise Exception("Oyente Timeout",2)

def run_build_cfg_and_analyze(evm_v = False,timeout_cb=do_nothing):
    global g_timeout

    if not debug_info:
        global_params.GLOBAL_TIMEOUT = 180
        
    try:
        with Timeout(sec=global_params.GLOBAL_TIMEOUT):
            build_cfg_and_analyze(evm_v)
        log.debug('Done Symbolic execution')
    except TimeoutError:
        g_timeout = True
        timeout_cb()

def get_recipients(disasm_file, contract_address):
    global recipients
    global data_source
    global g_src_map
    global g_disasm_file
    global g_source_file

    g_src_map = None
    g_disasm_file = disasm_file
    g_source_file = None
    data_source = EthereumData(contract_address)
    recipients = set()

    evm_code_coverage = float(len(visited_pcs)) / len(instructions.keys())

    run_build_cfg_and_analyze()

    return {
        'addrs': list(recipients),
        'evm_code_coverage': evm_code_coverage,
        'timeout': g_timeout
    }


def update_scc_unary(scc_unary,blocks):
    blocks_ids = blocks.keys()
    new_scc_unary = []
    for e in scc_unary:
        if e not in blocks_ids:
            l = filter(lambda x: str(x).startswith(str(e)),blocks)
            new_scc_unary +=l
        else:
            new_scc_unary.append(e)
    return new_scc_unary

def analyze(evm_version):
    def timeout_cb():
        if global_params.DEBUG_MODE:
            traceback.print_exc()
            print ("Timeout reached")
        raise Exception("Oyente Timeout",2)
    
    run_build_cfg_and_analyze(evm_v = evm_version,timeout_cb=timeout_cb)

def delete_uncalled():
    global vertices
    global stack_h
    global calldataload_values

    blocks = vertices.keys()
    uncalled = get_uncalled_blocks(blocks,visited_blocks)
    for b in uncalled:
            vertices.pop(b)
            stack_h.pop(b)
            edges.pop(b)
            calldataload_values.pop(b)

def update_edges(blocks,edges):
    b_keys = blocks.keys()
    e_keys = edges.keys()
    
    for b in blocks.keys():
        if b not in e_keys:
            old_block = int(b.split("_")[0])
            edges.pop(old_block,-1)
            block = blocks[b]

            edges[b] = []
            jump = block.get_jump_target()
            falls = block.get_falls_to()
            if jump != 0:
                edges[b].append(jump)
            if falls != None:
                edges[b].append(falls)

        else: #Although ir appears in edges, the successor may have changed.
            block = blocks[b]

            jump = block.get_jump_target()
            falls = block.get_falls_to()
            if jump != 0 :
                parts = str(jump).split("_")
                if len(parts) > 1:
                    b_old = int(parts[0])
                    idx = edges[b].index(b_old)
                    edges[b].pop(idx)
                    edges[b].append(jump)

            if falls != None:
                parts = str(falls).split("_")
                if len(parts) > 1:
                    b_old = int(parts[0])
                    idx = edges[b].index(b_old)
                    edges[b].pop(idx)
                    edges[b].append(jump)
                
def compute_component_of_cfg():
    global component_of_blocks

    component_of_blocks = {}
    
    for block in vertices.keys():
        comp = component_of(block)
        component_of_blocks[block] = comp
            
def component_of(block):
    return component_of_aux(block,[])

def component_of_aux(block,visited):
    #print vertices[block].get_start_address()
    blocks_conn = vertices[block].get_comes_from()
    for elem in blocks_conn:
        if elem not in visited:
            visited.append(elem)
            component_of_aux(elem,visited)
    return visited
            
def generate_saco_config_file(cname):
    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)
        
    if cname == None:
        name = costabs_path+"config_block.config"
    else:
        name = costabs_path+cname+".config"

    with open(name,"w") as f:
        elems = map(lambda (x,y): "("+process_argument_function(x)+";"+str(y[0])+";"+str(y[1])+")", function_block_map.items())
        elems2write = "\n".join(elems)
        f.write(elems2write)
    f.close()

def process_argument_function(arg):
    posInit = arg.find("(")
    posEnd = arg.find(")")
    args_string = arg[posInit+1:posEnd]
    args = args_string.split(",")
    new_args = []
    for e in args:
        pos = e.find("storage")
        if pos !=-1:
            new_args.append(e[:pos].strip())

        else:
            pos = e.find("memory")
            if pos !=-1:
                new_args.append(e[:pos].strip())
            else:
                new_args.append(e)
                
    return arg[:posInit+1]+",".join(new_args)+")"
    
def generate_verify_config_file(cname):
    to_write = []
    remove_getters_has_invalid()
    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)
        
    if cname == None:
        name = costabs_path+"config_block.config"
    else:
        name = costabs_path+cname+".config"
    with open(name,"w") as f:
        for elem in function_block_map.items():
            block_fun = elem[1][0]
            fun_arg = process_argument_function(elem[0])
            if block_fun in has_invalid:
                to_write.append("("+fun_arg+";"+str(elem[1][0])+"; YES)")
            else:
                to_write.append("("+fun_arg+";"+str(elem[1][0])+"; NO)")
        elems2write = "\n".join(to_write)
        f.write(elems2write)
    f.close()
    
def check_cfg_option(cfg,cname,execution, cloned = False, blocks_to_clone = None):
    if cfg and (not cloned):
        if cname == None:
            write_cfg(execution,vertices)
            cfg_dot(execution,vertices)

        else:
            write_cfg(execution,vertices,name = cname)
            cfg_dot(execution,vertices,name = cname)

    elif cfg and cloned:
        if blocks_to_clone != []:
            if cname == None:
                write_cfg(execution,vertices,cloned = True)
                cfg_dot(execution,vertices,cloned = True)

            else:
                write_cfg(execution,vertices,name = cname,cloned = True)
                cfg_dot(execution, vertices, name = cname, cloned = True)

def get_scc(edges):
    g = Graph_SCC(edges)
    scc_multiple = g.getSCCs()
    scc_multiple = filter(lambda x: len(x)>1,scc_multiple)
    scc_multiple = get_entry_all(scc_multiple,vertices)

    if scc_multiple == {}:
        return scc_multiple
    else:
        new_edges = filter_nested_scc(edges,scc_multiple)
        scc = get_scc(new_edges)
        scc_multiple.update(scc)
        return scc_multiple
        
def run(disasm_file=None,disasm_file_init=None, source_map=None , source_file=None, cfg=None, saco = None, execution = None,cname = None, hashes = None, debug = None,ms_unknown=False,evm_version = False,cfile = None,svc = None,go = None,opt = None,source_name = None):    
    global g_disasm_file
    global g_source_file
    global g_src_map
    global results
    global f_hashes
    global debug_info
    global vertices
    global stack_h
    global name
    global public_fields
    global invalid_option

    g_disasm_file = disasm_file
    g_source_file = source_file
    g_src_map = source_map

    initGlobalVars()

    source_info = {}
    
    name = cname

    if source_name != None:
        s_name = source_name.split("/")[-1].split(".")[0]
    else:
        s_name = source_name
        
    if hashes != None:
        f_hashes = hashes

    
        
    if cname != None:
        print("File: "+str(cname))

    if debug :
        debug_info = debug

    invalid_option = svc.get("invalid",False)
    verify = svc.get("verify",False)
        
    begin = dtimer()

    if source_file != None and verify:
        public_fields = get_public_fields(source_file)

    analyze(evm_version)

    end = dtimer()
    print("Build CFG: "+str(end-begin)+"s")

    check_cfg_option(cfg,cname,execution)
        
    blocks2clone = sorted(blocks_to_clone, key = getLevel)
    # for e in blocks2clone:
    #     update_depth_level(e.get_start_address(),e.get_depth_level(),[],True)


    compute_component_of_cfg()
    
    # if len(blocks_to_clone)!=0:
    #     try:
    #         print blocks_to_clone[0].get_start_address()
    #         compute_cloning(blocks_to_clone,vertices,stack_h,component_of_blocks)
    #     except:
    #         traceback.print_exc()
    #         raise Exception("Error in clonning process",3)
        
    
    # check_cfg_option(cfg,cname,execution,True,blocks_to_clone)
    
    begin1 = dtimer()
    compute_component_of_cfg()
    
    #compute_transitive_mstore_value()
    
    end = dtimer()
    oyente_t = end-begin
    print("OYENTE tool: "+str(oyente_t)+"s")

    #update_edges(vertices, edges)

    scc = {}
    if go:
        try:
            scc_multiple = get_scc(edges)
            scc_unary_new = update_scc_unary(scc_unary,vertices)

            scc["unary"] = scc_unary_new
            scc["multiple"] = scc_multiple
            # g = Graph_SCC(edges)
            # scc_multiple = g.getSCCs()
            # scc_multiple = filter(lambda x: len(x)>1,scc_multiple)
            # scc_multiple = get_entry_all(scc_multiple,vertices)

            # scc["unary"] = scc_unary
            # scc["multiple"] = scc_multiple
            
        except:
            #traceback.print_exc()
            raise Exception("Error in SCC generation",7)

    if function_block_map != {}:
        val = function_block_map.values()
        f2blocks = map(lambda x: x[0],val)
    else:
        f2blocks = []

    try:

        source_info["source_map"] = source_map
        source_info["name_state_variables"] = mapping_state_variables

        rbr_rules = rbr.evm2rbr_compiler(blocks_input = vertices,stack_info = stack_h, block_unbuild = blocks_to_create,saco_rbr = saco,c_rbr = cfile, exe = execution, contract_name = cname, component = component_of_blocks, oyente_time = oyente_t,scc = scc,svc_labels = svc,gotos = go,fbm = f2blocks, source_info = source_info)

        if opt!= None:
        # fields = ["field1","field2"]
        # block = 70
            # print function_block_map
            f = opt['block']
            #block = function_block_map[f]
            gasol.optimize_solidity(int(opt["block"]),source_map,opt["fields"],opt["c_source"],rbr_rules,component_of_blocks)

    except Exception as e:
        traceback.print_exc()
        raise e
    
    if hashes != None:
        if saco != None and not(verify): #Hashes is != None only if source file is solidity
            generate_saco_config_file(cname)

        elif verify and not(saco):
            generate_verify_config_file(cname)

        ##Add when both are != None
  
    return [], 0

def get_evm_block():
    blocks = {}
    str_b = ""
    for b in vertices:
        instructions = vertices[b].get_instructions()
        str_b = ""
        for i in instructions:
            i_aux = i.split()[0]
            c = get_opcode(i_aux)
           # print c
            hex_val = str(c[0])
            if hex_val.startswith("0x"):
                op_val = hex_val[2:]
               
            else:
                op_val = hex(int(hex_val))[2:]

                if (int(op_val,16)<12):
                    op_val = "0"+str(op_val)
                    
            if i.startswith("PUSH"):
                num = i.split()[1][2:]
            else:
                num = ""
            str_b = str_b+op_val+num
        blocks[b] = str_b

    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)
    if "blocks" not in os.listdir(costabs_path):
        os.mkdir(ebso_path)
    for b in blocks:
        bl_path = ebso_path+"/block"+str(b)
        os.mkdir(bl_path)
        f = open(bl_path+"/block_"+str(b)+".bl","w")
        f.write(blocks[b])
        f.close()
        
