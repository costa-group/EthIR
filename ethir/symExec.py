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

from vargenerator import *
from ethereum_data import *
from basicblock import BasicBlock
from analysis import *
# from test_evm.global_test_params import (TIME_OUT, UNKNOWN_INSTRUCTION,
#                                          EXCEPTION, PICKLE_PATH)
from vulnerability import CallStack, TimeDependency, MoneyConcurrency, Reentrancy, AssertionFailure, ParityMultisigBug2
import global_params

import rbr
from clone import compute_cloning
from utils import cfg_dot, write_cfg, update_map, get_public_fields, getLevel
from opcodes import get_opcode
from graph_scc import Graph_SCC, get_entry_all


log = logging.getLogger(__name__)

UNSIGNED_BOUND_NUMBER = 2**256 - 1
CONSTANT_ONES_159 = BitVecVal((1 << 160) - 1, 256)

Assertion = namedtuple('Assertion', ['pc', 'model'])

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

    global pattern
    pattern = ["JUMPDEST","PUSH1 0x00","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","PUSH1 0x1f","ADD","PUSH1 0x20","DUP1","SWAP2","DIV","MUL","PUSH1 0x20","ADD","PUSH1 0x40","MLOAD","SWAP1","DUP2","ADD","PUSH1 0x40","MSTORE","DUP1","SWAP3","SWAP2","SWAP1","DUP2","DUP2","MSTORE","PUSH1 0x20","ADD","DUP3","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","ISZERO"]

    global sub_pattern
    sub_pattern = ["PUSH1 0x01",
                   "DUP2",
                   "PUSH1 0x01",
                   "AND",
                   "ISZERO",
                   "PUSH2 0x0100",
                   "MUL",
                   "SUB",
                   "AND",
                   "PUSH1 0x02",
                   "SWAP1",
                   "DIV"]
    global name
    name = ""

    global param_abs
    param_abs = ("","")
    
    global tacas_ex
    tacas_ex = ""

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
        construct_static_edges()
        full_sym_exec()  # jump targets are constructed on the fly

    delete_uncalled()
    update_block_info()


#Added by Pablo Gordillo
def update_block_info():
    global blocks_to_clone
    
    vert = sorted(vertices.values(), key = getKey)
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
        ins_aux = block.get_instructions()[:-2]
        if len(ins_aux)>=len(pattern):
            ins = map(lambda x: x.strip(),ins_aux)
            p = check_string_pattern(ins)
            if p :
                block.activate_string_getter()
                #write_pattern(key,name)

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
                    
def check_string_pattern(instructions):
    pat = False
    if instructions[0] == pattern[0]:
        i = 1
        correct = True
        while(i<len(instructions) and instructions[i]!="DUP1"):
            if instructions[i].split()[0][:-1]!="PUSH":
                correct = False
            i = i+1
        if correct:
            pat = instructions[i:] == pattern[2:]
    return pat

def write_pattern(key,cname):
    if "costabs" not in os.listdir("/tmp/"):
        os.mkdir("/tmp/costabs/")
        

    name = "/tmp/costabs/pattern.pattern"
    with open(name,"a") as f:
        string = tacas_ex+" "+cname+" "+str(key)+"\n"
        f.write(string)
    f.close()

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
    if debug_info:
        print ("\nBLOCK "+ str(block))
        print ("PATH")
        print (path)

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
    
    for instr in block_ins:
        sym_exec_ins(params, block, instr, func_call,stack_old)
        if sha_identify and not result:
            result =  access_array_sim(instr.strip(),fake_stack)

        if instr.startswith("SHA3",0):
            # print block
            sha_identify = True
            fake_stack.insert(0,1)

        if debug_info:
            print ("Stack despues de la ejecucion de la instruccion "+ instr)
            print (stack)

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
    vertices[block].add_path(path)
    
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
        new_params.global_state["pc"] = successor
        if g_src_map:
            source_code = g_src_map.get_source_code(global_state['pc'])
            if source_code in g_src_map.func_call_names:
                func_call = global_state['pc']
                
        
        if successor in vertices:

            vertices[successor].add_origin(block) #to compute which are the blocks that leads to successor
            proc = procesed_indirect_jumps.get(successor,[])

            if not(vertices[successor].known_stack(list(stack))):
                path.append((block,successor))
                sym_exec_block(new_params, successor, block, depth, func_call,current_level+1,path)
                procesed_indirect_jumps = update_map(procesed_indirect_jumps,block,successor)
                path.pop()
            else:
                if vertices[successor].get_depth_level()<(current_level+1): 
                    vertices[successor].set_depth_level(current_level+1)
                    update_depth_level(successor,current_level+1,[])
                # if ((block,successor) not in path):
            #     # if potential_jump:
            #     #     potential_jump = False
            #     path.append((block,successor))
            #     sym_exec_block(new_params, successor, block, depth, func_call,level+1,path)
            #     procesed_indirect_jumps = update_map(procesed_indirect_jumps,block,successor)
            #     path.pop()
            # else : #the pair is in the path
            #     if not(vertices[successor].known_stack(list(stack))):
            #     # if not potential_jump:
            #     #     potential_jump = True
            #         path.append((block,successor))
            #         sym_exec_block(new_params, successor, block, depth, func_call,level+1,path)
            #         path.pop()
                # else:
                #     print "PASO"
                # else:
            
                #     potential_jump = False
                #     if not(vertices[successor].is_direct_block()):
                #         print "ENTRARIA con"+str(successor)
                #         if stack[indirect_jump[successor]] not in proc:
                #             path.append((block,successor))
                #             sym_exec_block(new_params, successor, block, depth, func_call,level+1,path)
                #             path.pop()
                    #if stack[indirect_jump[successor]] not in proc:
                    
        else:
            if successor not in blocks_to_create:
                blocks_to_create.append(successor)
                
    elif jump_type[block] == "falls_to":  # just follow to the next basic block
        successor = vertices[block].get_falls_to()

        vertices[successor].add_origin(block) #to compute which are the blocks that leads to successor
        new_params = params.copy()
        new_params.global_state["pc"] = successor
        if not(vertices[successor].known_stack(list(stack))):
            path.append((block,successor))
            sym_exec_block(new_params, successor, block, depth, func_call,current_level+1,path)
            path.pop()
        else:

            if vertices[successor].get_depth_level()<(current_level+1):
                vertices[successor].set_depth_level(current_level+1)
                update_depth_level(successor,current_level+1,[])
            # if (((block,successor) not in path)):
        #     if potential_jump:
        #         potential_jump = False
        #     path.append((block,successor))
        #     sym_exec_block(new_params, successor, block, depth, func_call,level+1,path)
        #     path.pop()
        # else:
        #     # if not potential_jump:
        #     #     potential_jump = True
        #     if not(vertices[successor].known_stack(list(stack))):
        #         path.append((block,successor))
        #         sym_exec_block(new_params, successor, block, depth, func_call,level+1,path)
        #         path.pop()
        #     # else:
        #     #     print "PASO"
        #     # else:
        #     #     potential_jump = False
    elif jump_type[block] == "conditional":  # executing "JUMPI"

        # A choice point, we proceed with depth first search

        left_branch = vertices[block].get_jump_target()


        new_params = params.copy()
        new_params.global_state["pc"] = left_branch
        #new_params.path_conditions_and_vars["path_condition"].append(branch_expression)
        last_idx = len(new_params.path_conditions_and_vars["path_condition"]) - 1
                #new_params.analysis["time_dependency_bug"][last_idx] = global_state["pc"]
        if left_branch in vertices:
            vertices[left_branch].add_origin(block) #to compute which are the blocks that leads to successor
            if not(vertices[left_branch].known_stack(list(stack))):
            # if (((block,left_branch) not in path)):
            #     if potential_jump:
            #         potential_jump = False
                path.append((block,left_branch))
                sym_exec_block(new_params, left_branch, block, depth, func_call,current_level+1,path)
                path.pop()
            else:
                if vertices[left_branch].get_depth_level() < (current_level+1):
                    vertices[left_branch].set_depth_level(current_level+1)
                    update_depth_level(left_branch,current_level+1,[])
                # else:
            #     # if not potential_jump:
            #     #     potential_jump = True
            #     if not(vertices[left_branch].known_stack(list(stack))):
            #         path.append((block,left_branch))
            #         sym_exec_block(new_params, left_branch, block, depth, func_call,level+1,path)
            #         path.pop()
            #     # else:
            #     #     print "PASO"
            #     # else:
            #     #     potential_jump = False
        else:
            if left_branch not in blocks_to_create:
                blocks_to_create.append(left_branch)

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
        new_params.global_state["pc"] = right_branch
        #new_params.path_conditions_and_vars["path_condition"].append(negated_branch_expression)
        last_idx = len(new_params.path_conditions_and_vars["path_condition"]) - 1
        #new_params.analysis["time_dependency_bug"][last_idx] = global_state["pc"]
        # print right_branch
        # print path
        # print "\n"
        if right_branch in vertices:
            vertices[right_branch].add_origin(block)
            # if ((block,right_branch) not in path):
            #     if potential_jump:
            #         potential_jump = False
            #     path.append((block,right_branch))
            #     sym_exec_block(new_params, right_branch, block, depth, func_call,level+1,path)
            #     path.pop()
            # else:
            #     # if not potential_jump:
            #     #     potential_jump = True
            if not(vertices[right_branch].known_stack(list(stack))):
                path.append((block,right_branch))
                sym_exec_block(new_params, right_branch, block, depth, func_call,current_level+1,path)
                path.pop()
                # else:
                #     print "PASO"
                # else:
                #     potential_jump = False
            else:
                if vertices[right_branch].get_depth_level < (current_level+1):
                    vertices[right_branch].set_depth_level(current_level+1)
                    update_depth_level(right_branch,current_level+1,[])
        else:
            if right_branch not in blocks_to_create:
                blocks_to_create.append(right_branch)
        # except TimeoutError:
        #     raise
        # except Exception as e:
        #     if global_params.DEBUG_MODE:
        #         traceback.print_exc()
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
    
# Symbolically executing an instruction
def sym_exec_ins(params, block, instr, func_call,stack_first):
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
                solver.push()
                solver.add(Not(second == 0))
                if check_sat(solver) == unsat:
                    computed = 0
                else:
                    solver.push()
                    solver.add( Not( And(first == -2**255, second == -1 ) ))
                    if check_sat(solver) == unsat:
                        computed = -2**255
                    else:
                        solver.push()
                        solver.add(first / second < 0)
                        sign = -1 if check_sat(solver) == sat else 1
                        z3_abs = lambda x: If(x >= 0, x, -x)
                        first = z3_abs(first)
                        second = z3_abs(second)
                        computed = sign * (first / second)
                        solver.pop()
                    solver.pop()
                solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "MOD":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)
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

                solver.push()
                solver.add(Not(second == 0))
                if check_sat(solver) == unsat:
                    # it is provable that second is indeed equal to zero
                    computed = 0
                else:

                    solver.push()
                    solver.add(first < 0) # check sign of first element
                    sign = BitVecVal(-1, 256) if check_sat(solver) == sat \
                        else BitVecVal(1, 256)
                    solver.pop()

                    z3_abs = lambda x: If(x >= 0, x, -x)
                    first = z3_abs(first)
                    second = z3_abs(second)

                    computed = sign * (first % second)
                solver.pop()

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

            if isAllReal(first, second, third):
                if third == 0:
                    computed = 0
                else:
                    computed = (first + second) % third
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                solver.push()
                solver.add( Not(third == 0) )
                if check_sat(solver) == unsat:
                    computed = 0
                else:
                    first = ZeroExt(256, first)
                    second = ZeroExt(256, second)
                    third = ZeroExt(256, third)
                    computed = (first + second) % third
                    computed = Extract(255, 0, computed)
                solver.pop()
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

            if isAllReal(first, second, third):
                if third == 0:
                    computed = 0
                else:
                    computed = (first * second) % third
            else:
                first = to_symbolic(first)
                second = to_symbolic(second)
                solver.push()
                solver.add( Not(third == 0) )
                if check_sat(solver) == unsat:
                    computed = 0
                else:
                    first = ZeroExt(256, first)
                    second = ZeroExt(256, second)
                    third = ZeroExt(256, third)
                    computed = URem(first * second, third)
                    computed = Extract(255, 0, computed)
                solver.pop()
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "EXP":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            base = stack.pop(0)
            exponent = stack.pop(0)
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
            computed = first & second
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "OR":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            computed = first | second
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)

        else:
            raise ValueError('STACK underflow')
    elif opcode == "XOR":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            second = stack.pop(0)

            computed = first ^ second
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)

        else:
            raise ValueError('STACK underflow')
    elif opcode == "NOT":
        if len(stack) > 0:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            computed = (~first) & UNSIGNED_BOUND_NUMBER
            #computed = simplify(computed) if is_expr(computed) else computed
            stack.insert(0, computed)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "BYTE":
        if len(stack) > 1:
            global_state["pc"] = global_state["pc"] + 1
            first = stack.pop(0)
            byte_index = 32 - first - 1
            second = stack.pop(0)

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
            if g_src_map:
                source_code = g_src_map.get_source_code(global_state['pc'] - 1)
                if source_code.startswith("function") and isReal(position):
                    idx1 = source_code.index("(") + 1
                    idx2 = source_code.index(")")
                    params = source_code[idx1:idx2]
                    params_list = params.split(",")
                    params_list = [param.rstrip().rstrip("\n").split(" ")[-1] for param in params_list]
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

            #Added by Pablo Gordillo
            vertices[block].add_ls_value("mstore",ls_cont[1],stored_address)
            ls_cont[1]+=1
            current_miu_i = global_state["miu_i"]
            if isReal(stored_address):
                # preparing data for hashing later
                old_size = len(memory) // 32
                new_size = ceil32(stored_address + 32) // 32
                mem_extend = (new_size - old_size) * 32
                memory.extend([0] * mem_extend)
                value = stored_value
                for i in range(31, -1, -1):
                    memory[stored_address + i] = value % 256
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
            position = stack.pop(0)

            #Added by Pablo Gordillo
            vertices[block].add_ls_value("sload",ls_cont[2],position)
            ls_cont[2]+=1
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
                        if g_src_map.is_a_parameter_or_state_variable(new_var_name):
                            new_var_name = "Ia_store" + "-" + str(position) + "-" + new_var_name
                        else:
                            new_var_name = gen.gen_owner_store_var(position)
                    else:
                        new_var_name = gen.gen_owner_store_var(position)

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
        else:
            raise ValueError('STACK underflow')

    elif opcode == "SSTORE":
        if len(stack) > 1:
            for call_pc in calls:
                calls_affect_state[call_pc] = True
            global_state["pc"] = global_state["pc"] + 1
            stored_address = stack.pop(0)
            stored_value = stack.pop(0)

            #Added by Pablo Gordillo
            vertices[block].add_ls_value("sstore",ls_cont[3],stored_address)
            ls_cont[3]+=1
            if isReal(stored_address):
                # note that the stored_value could be unknown
                global_state["Ia"][stored_address] = stored_value
            else:
                # note that the stored_value could be unknown
                global_state["Ia"][str(stored_address)] = stored_value
        else:
            raise ValueError('STACK underflow')
    elif opcode == "JUMP":
        if len(stack) > 0:
            target_address = stack.pop(0)

            vertices[block].set_jump_target(target_address)

            if target_address not in edges[block]:
                edges[block].append(target_address)
        else:
            raise ValueError('STACK underflow')
    elif opcode == "JUMPI":
        # We need to prepare two branches
        if len(stack) > 1:
            target_address = stack.pop(0)
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
            # if (function_info[0]):
            #     name = function_info[1]
            #     function_block_map[name]=target_address
            #     function_info = (False,"")
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
        global_state["pc"] = global_state["pc"] + 1 + position
        hs = str(instr_parts[1])[2:] #To delete 0x...
        if f_hashes and hs in f_hashes :
            name = f_hashes[hs]
            function_info = (True,name)
            

        
        pushed_value = int(instr_parts[1], 16)
        stack.insert(0, pushed_value)
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

    else:
        log.debug("UNKNOWN INSTRUCTION: " + opcode)
        # if global_params.UNIT_TEST == 2 or global_params.UNIT_TEST == 3:
        #     log.critical("Unknown instruction: %s" % opcode)
        #     exit(UNKNOWN_INSTRUCTION)
        raise Exception('UNKNOWN INSTRUCTION: ' + opcode)

def update_depth_level(b,level,updated,list_jumps = False):
    # print "BLOCK: "+str(b)+" LEVEL: "+str(level)
    if b not in updated:
        updated.append(b)
        vertices[b].set_depth_level(level)
        jump = vertices[b].get_jump_target()
        falls = vertices[b].get_falls_to()
        l_jumps = vertices[b].get_list_jumps()
        # print "JUMP: "+str(jump)
        # print "FALLS: "+str(falls)
        # print "MAS: "+str(vertices[b].get_list_jumps())

        if not list_jumps:
            if jump != 0 and vertices[jump].get_depth_level()<(level+1):
                update_depth_level(jump,level+1,updated)

        else:
            for l in l_jumps:
                update_depth_level(l,level+1,updated)
                    
        if falls != None and vertices[falls].get_depth_level()<(level+1):

            update_depth_level(falls,level+1,updated)
        # if jump == 0 and falls == None:
        #     print "TERMINAL"

    

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

# Detect if a money flow depends on the timestamp
def detect_time_dependency():
    global results
    global g_src_map
    global time_dependency

    TIMESTAMP_VAR = "IH_s"
    is_dependant = False
    pcs = []
    if global_params.PRINT_PATHS:
        log.info("ALL PATH CONDITIONS")
    for i, cond in enumerate(path_conditions):
        if global_params.PRINT_PATHS:
            log.info("PATH " + str(i + 1) + ": " + str(cond))
        for j, expr in enumerate(cond):
            if is_expr(expr):
                if TIMESTAMP_VAR in str(expr) and j in global_problematic_pcs["time_dependency_bug"][i]:
                    pcs.append(global_problematic_pcs["time_dependency_bug"][i][j])
                    is_dependant = True
                    continue

    time_dependency = TimeDependency(g_src_map, pcs)

    if g_src_map:
        results['vulnerabilities']['time_dependency'] = time_dependency.get_warnings()
    else:
        results['vulnerabilities']['time_dependency'] = time_dependency.is_vulnerable()
    log.info('\t  Timestamp Dependency: \t\t %s', time_dependency.is_vulnerable())

    if global_params.REPORT_MODE:
        file_name = g_disasm_file.split("/")[len(g_disasm_file.split("/"))-1].split(".")[0]
        report_file = file_name + '.report'
        with open(report_file, 'w') as rfile:
            if is_dependant:
                rfile.write("yes\n")
            else:
                rfile.write("no\n")


# detect if two paths send money to different people
def detect_money_concurrency():
    global results
    global g_src_map
    global money_concurrency

    n = len(money_flow_all_paths)
    for i in range(n):
        log.debug("Path " + str(i) + ": " + str(money_flow_all_paths[i]))
        log.debug(all_gs[i])
    i = 0
    false_positive = []
    concurrency_paths = []
    flows = []
    for flow in money_flow_all_paths:
        i += 1
        if len(flow) == 1:
            continue  # pass all flows which do not do anything with money
        for j in range(i, n):
            jflow = money_flow_all_paths[j]
            if len(jflow) == 1:
                continue
            if is_diff(flow, jflow):
                flows.append(global_problematic_pcs["money_concurrency_bug"][i-1])
                flows.append(global_problematic_pcs["money_concurrency_bug"][j])
                concurrency_paths.append([i-1, j])
                if global_params.CHECK_CONCURRENCY_FP and \
                        is_false_positive(i-1, j, all_gs, path_conditions) and \
                        is_false_positive(j, i-1, all_gs, path_conditions):
                    false_positive.append([i-1, j])
                break
        if flows:
            break

    money_concurrency = MoneyConcurrency(g_src_map, flows)

    if g_src_map:
        results['vulnerabilities']['money_concurrency'] = money_concurrency.get_warnings_of_flows()
    else:
        results['vulnerabilities']['money_concurrency'] = money_concurrency.is_vulnerable()
    log.info('\t  Transaction-Ordering Dependence (TOD): %s', money_concurrency.is_vulnerable())

    # if PRINT_MODE: print "All false positive cases: ", false_positive
    log.debug("Concurrency in paths: ")
    if global_params.REPORT_MODE:
        rfile.write("number of path: " + str(n) + "\n")
        # number of FP detected
        rfile.write(str(len(false_positive)) + "\n")
        rfile.write(str(false_positive) + "\n")
        # number of total races
        rfile.write(str(len(concurrency_paths)) + "\n")
        # all the races
        rfile.write(str(concurrency_paths) + "\n")

def detect_parity_multisig_bug_2():
    global g_src_map
    global results
    global parity_multisig_bug_2

    parity_multisig_bug_2 = ParityMultisigBug2(g_src_map)

    results['vulnerabilities']['parity_multisig_bug_2'] = parity_multisig_bug_2.get_warnings()
    s = "\t  Parity Multisig Bug 2: \t\t %s" % parity_multisig_bug_2.is_vulnerable()
    log.info(s)

def check_callstack_attack(disasm):
    problematic_instructions = ['CALL', 'CALLCODE']
    pcs = []
    for i in range(0, len(disasm)):
        instruction = disasm[i]
        if instruction[1] in problematic_instructions:
            try:
                pc = int(instruction[0])
                if not disasm[i+1][1] == 'SWAP':
                    continue
                swap_num = int(disasm[i+1][2])
                if not all(disasm[i+j+2][1] == 'POP' for j in range(swap_num)):
                    continue
            except IndexError:
                continue

            try:
                opcode1 = disasm[i + swap_num + 2][1]
                opcode2 = disasm[i + swap_num + 3][1]
                opcode3 = disasm[i + swap_num + 4][1]
                if opcode1 == "ISZERO" \
                    or opcode1 == "DUP" and opcode2 == "ISZERO" \
                    or opcode1 == "JUMPDEST" and opcode2 == "ISZERO" \
                    or opcode1 == "JUMPDEST" and opcode2 == "DUP" and opcode3 == "ISZERO":
                        pass
                else:
                    pcs.append(pc)
            except IndexError:
                pcs.append(pc)
    return pcs


def detect_callstack_attack():
    global results
    global g_src_map
    global calls_affect_state
    global callstack

    disasm_data = open(g_disasm_file).read()
    instr_pattern = r"([\d]+) ([A-Z]+)([\d]+)?(?: => 0x)?(\S+)?"
    instr = re.findall(instr_pattern, disasm_data)
    pcs = check_callstack_attack(instr)

    callstack = CallStack(g_src_map, pcs, calls_affect_state)

    if g_src_map:
        results['vulnerabilities']['callstack'] = callstack.get_warnings()
    else:
        results['vulnerabilities']['callstack'] = callstack.is_vulnerable()
    log.info('\t  Callstack Depth Attack Vulnerability:  %s', callstack.is_vulnerable())

def detect_reentrancy():
    global g_src_map
    global results
    global reentrancy

    pcs = global_problematic_pcs["reentrancy_bug"]
    reentrancy = Reentrancy(g_src_map, pcs)

    if g_src_map:
        results['vulnerabilities']['reentrancy'] = reentrancy.get_warnings()
    else:
        results['vulnerabilities']['reentrancy'] = reentrancy.is_vulnerable()
    log.info("\t  Re-Entrancy Vulnerability: \t\t %s", reentrancy.is_vulnerable())

def detect_assertion_failure():
    global g_src_map
    global results
    global assertion_failure

    assertion_failure = AssertionFailure(g_src_map, global_problematic_pcs['assertion_failure'])

    results['vulnerabilities']['assertion_failure'] = assertion_failure.get_warnings()
    s = "\t  Assertion Failure: \t\t\t %s" % assertion_failure.is_vulnerable()
    log.info(s)

def detect_vulnerabilities():
    global results
    global g_src_map
    global visited_pcs
    global global_problematic_pcs
    global begin

    if instructions:
        evm_code_coverage = float(len(visited_pcs)) / len(instructions.keys()) * 100
        log.info("\t  EVM Code Coverage: \t\t\t %s%%", round(evm_code_coverage, 1))
        results["evm_code_coverage"] = str(round(evm_code_coverage, 1))

        if g_src_map:
            detect_parity_multisig_bug_2()

        log.debug("Checking for Callstack attack...")
        detect_callstack_attack()

        if global_params.REPORT_MODE:
            rfile.write(str(total_no_of_paths) + "\n")

        detect_money_concurrency()
        detect_time_dependency()

        stop = time.time()
        if global_params.REPORT_MODE:
            rfile.write(str(stop-begin))
            rfile.close()

        log.debug("Results for Reentrancy Bug: " + str(reentrancy_all_paths))
        detect_reentrancy()

        if global_params.CHECK_ASSERTIONS:
            if g_src_map:
                detect_assertion_failure()
            else:
                raise Exception("Assertion checks need a Source Map")

        if g_src_map:
            log_info()

    else:
        log.info("\t  EVM code coverage: \t 0/0")
        log.info("\t  Callstack bug: \t False")
        log.info("\t  Money concurrency bug: False")
        log.info("\t  Time dependency bug: \t False")
        log.info("\t  Reentrancy bug: \t False")
        if global_params.CHECK_ASSERTIONS:
            log.info("\t  Assertion failure: \t False")
        results["evm_code_coverage"] = "0/0"

    return results, vulnerability_found()

def log_info():
    global g_src_map
    global time_dependency
    global callstack
    global money_concurrency
    global reentrancy
    global assertion_failure
    global parity_multisig_bug_2

    vulnerabilities = [callstack, money_concurrency, time_dependency, reentrancy]
    if g_src_map and global_params.CHECK_ASSERTIONS:
        vulnerabilities.append(assertion_failure)
        vulnerabilities.append(parity_multisig_bug_2)

    for vul in vulnerabilities:
        s = str(vul)
        if s:
            log.info(s)

def vulnerability_found():
    global g_src_map
    global time_dependency
    global callstack
    global money_concurrency
    global reentrancy
    global assertion_failure
    global parity_multisig_bug_2

    vulnerabilities = [callstack, money_concurrency, time_dependency, reentrancy]

    if g_src_map and global_params.CHECK_ASSERTIONS:
        vulnerabilities.append(assertion_failure)
        vulnerabilities.append(parity_multisig_bug_2)

    for vul in vulnerabilities:
        if vul.is_vulnerable():
            return 1
    return 0

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
    if "costabs" not in os.listdir("/tmp/"):
        os.mkdir("/tmp/costabs/")
        
    if cname == None:
        name = "/tmp/costabs/config_block.config"
    else:
        name = "/tmp/costabs/"+cname+".config"
    with open(name,"w") as f:
        elems = map(lambda (x,y): "("+str(x)+";"+str(y[0])+";"+str(y[1])+")", function_block_map.items())
        elems2write = "\n".join(elems)
        f.write(elems2write)
    f.close()

def generate_verify_config_file(cname):
    to_write = []
    remove_getters_has_invalid()
    if "costabs" not in os.listdir("/tmp/"):
        os.mkdir("/tmp/costabs/")
        
    if cname == None:
        name = "/tmp/costabs/config_block.config"
    else:
        name = "/tmp/costabs/"+cname+".config"
    with open(name,"w") as f:
        for elem in function_block_map.items():
            block_fun = elem[1][0]
            if block_fun in has_invalid:
                to_write.append("("+str(elem[0])+";"+str(elem[1][0])+"; YES)")
            else:
                to_write.append("("+str(elem[0])+";"+str(elem[1][0])+"; NO)")
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

def run(disasm_file=None, source_file=None, source_map=None, cfg=None, saco = None, execution = None,cname = None, hashes = None, debug = None,t_exs = None,ms_unknown=False,evm_version = False,cfile = None,svc = None,go = None):
    global g_disasm_file
    global g_source_file
    global g_src_map
    global results
    global f_hashes
    global debug_info
    global vertices
    global stack_h
    global name
    global tacas_ex
    global public_fields
    global invalid_option
                            
    g_disasm_file = disasm_file
    g_source_file = source_file
    g_src_map = source_map

    initGlobalVars()

    name = cname
    if t_exs != None:
        tacas_ex = t_exs
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

    # for e in blocks_to_clone:
    #     print e.get_start_address()
    #     print e.get_depth_level()

        
    blocks2clone = sorted(blocks_to_clone, key = getLevel)
    for e in blocks2clone:
        update_depth_level(e.get_start_address(),e.get_depth_level(),[],True)


    compute_component_of_cfg()
    # try:
    #     compute_cloning(blocks_to_clone,vertices,stack_h)
    # except:
    #     raise Exception("Error in clonning process",3)
    
    if len(blocks_to_clone)!=0:
        try:
            compute_cloning(blocks_to_clone,vertices,stack_h,component_of_blocks)
        except:
            raise Exception("Error in clonning process",3)
        
    check_cfg_option(cfg,cname,execution,True,blocks_to_clone)
    
    begin1 = dtimer()
    compute_component_of_cfg()
    
    compute_transitive_mstore_value()
    # end = dtimer()
    # print("Component performance: "+str(end-begin1)+"s")
    
    end = dtimer()
    oyente_t = end-begin
    print("OYENTE tool: "+str(oyente_t)+"s")

    update_edges(vertices, edges)


    try:
        g = Graph_SCC(edges)
        scc_multiple = g.getSCCs()
        scc_multiple = filter(lambda x: len(x)>1,scc_multiple)
        scc_multiple = get_entry_all(scc_multiple,vertices)
    except:
        raise Exception("Error in SCC generation",7)
    
    scc = {}
    scc["unary"] = scc_unary
    scc["multiple"] = scc_multiple

    if function_block_map != {}:
        val = function_block_map.values()
        f2blocks = map(lambda x: x[0],val)
    else:
        f2blocks = []
        
    try:
        rbr.evm2rbr_compiler(blocks_input = vertices,stack_info = stack_h, block_unbuild = blocks_to_create,saco_rbr = saco,c_rbr = cfile, exe = execution, contract_name = cname, component = component_of_blocks, oyente_time = oyente_t,scc = scc,svc_labels = svc,gotos = go,fbm = f2blocks)

    except Exception as e:
        raise e
    
    if hashes != None:
        if saco != None and not(verify): #Hashes is != None only if source file is solidity
            generate_saco_config_file(cname)

        elif verify and not(saco):
            generate_verify_config_file(cname)

        ##Add when both are != None
            
    return [], 0
