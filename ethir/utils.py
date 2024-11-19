# return true if the two paths have different flows of money
# later on we may want to return more meaningful output: e.g. if the concurrency changes
# the amount of money or the recipient.
import shlex
import subprocess
import json
import mmap
import os
import errno
import signal
import csv
import re
import difflib
import six
import global_params_ethir
from dot_tree import Tree, build_tree, build_tree_memory
import opcodes
from timeit import default_timer as dtimer


def ceil32(x):
    return x if x % 32 == 0 else x + 32 - (x % 32)

def isSymbolic(value):
    int_type = isinstance(value, six.integer_types)
    float_type = isinstance(value,float)
    return (not int_type) and (not float_type)

def isReal(value):
    return isinstance(value, six.integer_types) or isinstance(value,float)

def isAllReal(*args):
    for element in args:
        if isSymbolic(element):
            return False
    return True

def to_symbolic(number):
    if isReal(number):
        # print number
        # print BitVecVal(number, 256)
        return str(number)#BitVecVal(number, 256)
    return number

def to_unsigned(number):
    if number < 0:
        return abs(number)# + 2**256
    return number

def to_signed(number):
    if number > 2**(256 - 1):
        return (2**(256) - number) * (-1)
    else:
        return number

def custom_deepcopy(input):
    output = {}
    for key in input:
        if isinstance(input[key], list):
            output[key] = list(input[key])
        elif isinstance(input[key], dict):
            output[key] = custom_deepcopy(input[key])
        else:
            output[key] = input[key]
    return output

# check if a variable is a storage address in a contract
# currently accept only int addresses in the storage
def is_storage_var(var):
    return isinstance(var, six.integer_types)
    #     return True
    # else:
    #     return isinstance(var, str) and var.startswith("Ia_store_")


# copy only storage values/ variables from a given global state
# TODO: add balance in the future
def copy_global_values(global_state):
    new_gstate = {}

    for var in global_state["Ia"]:
        if is_storage_var(var):
            new_gstate[var] = global_state["Ia"][var]
    return new_gstate


# check if a variable is in an expression
def is_in_expr(var, expr):
    list_vars = get_vars(expr)
    set_vars = set(i.decl().name() for i in list_vars)
    return var in set_vars


# check if an expression has any storage variables
def has_storage_vars(expr, storage_vars):
    list_vars = get_vars(expr)
    for var in list_vars:
        if var in storage_vars:
            return True
    return False


def get_all_vars(list_of_storage_exprs):
    ret_vars = []
    for expr in list_of_storage_exprs:
        ret_vars += get_vars(list_of_storage_exprs[expr])
    return ret_vars


# Rename variables to distinguish variables in two different paths.
# e.g. Ia_store_0 in path i becomes Ia_store_0_old if Ia_store_0 is modified
# else we must keep Ia_store_0 if its not modified
def rename_vars(pcs, global_states):
    ret_pcs = []
    vars_mapping = {}

    for expr in pcs:
        list_vars = get_vars(expr)
        for var in list_vars:
            if var in vars_mapping:
                expr = substitute(expr, (var, vars_mapping[var]))
                continue
            var_name = var.decl().name()
            # check if a var is global
            if var_name.startswith("Ia_store_"):
                position = var_name.split('Ia_store_')[1]
                # if it is not modified then keep the previous name
                if position not in global_states:
                    continue
            # otherwise, change the name of the variable
            new_var_name = var_name + '_old'
            new_var = BitVec(new_var_name, 256)
            vars_mapping[var] = new_var
            expr = substitute(expr, (var, vars_mapping[var]))
        ret_pcs.append(expr)

    ret_gs = {}
    # replace variable in storage expression
    for storage_addr in global_states:
        expr = global_states[storage_addr]
        # z3 4.1 makes me add this line
        if is_expr(expr):
            list_vars = get_vars(expr)
            for var in list_vars:
                if var in vars_mapping:
                    expr = substitute(expr, (var, vars_mapping[var]))
                    continue
                var_name = var.decl().name()
                # check if a var is global
                if var_name.startswith("Ia_store_"):
                    position = int(var_name.split('_')[len(var_name.split('_'))-1])
                    # if it is not modified
                    if position not in global_states:
                        continue
                # otherwise, change the name of the variable
                new_var_name = var_name + '_old'
                new_var = BitVec(new_var_name, 256)
                vars_mapping[var] = new_var
                expr = substitute(expr, (var, vars_mapping[var]))
        ret_gs[storage_addr] = expr

    return ret_pcs, ret_gs


# split a file into smaller files
def split_dicts(filename, nsub = 500):
    with open(filename) as json_file:
        c = json.load(json_file)
        current_file = {}
        file_index = 1
        for u, v in c.iteritems():
            current_file[u] = v
            if len(current_file) == nsub:
                with open(filename.split(".")[0] + "_" + str(file_index) + '.json', 'w') as outfile:
                    json.dump(current_file, outfile)
                    file_index += 1
                    current_file.clear()
        if len(current_file):
            with open(filename.split(".")[0] + "_" + str(file_index) + '.json', 'w') as outfile:
                json.dump(current_file, outfile)
                current_file.clear()


def do_split_dicts():
    for i in range(11):
        split_dicts("contract" + str(i) + ".json")
        os.remove("contract" + str(i) + ".json")


def run_re_file(re_str, fn):
    size = os.stat(fn).st_size
    with open(fn, 'r') as tf:
        data = mmap.mmap(tf.fileno(), size, access=mmap.ACCESS_READ)
        return re.findall(re_str, data)


def get_contract_info(contract_addr):
    six.print_("Getting info for contracts... " + contract_addr)
    file_name1 = "tmp/" + contract_addr + "_txs.html"
    file_name2 = "tmp/" + contract_addr + ".html"
    # get number of txs
    txs = "unknown"
    value = "unknown"
    re_txs_value = r"<span>A total of (.+?) transactions found for address</span>"
    re_str_value = r"<td>ETH Balance:\n<\/td>\n<td>\n(.+?)\n<\/td>"
    try:
        txs = run_re_file(re_txs_value, file_name1)
        value = run_re_file(re_str_value, file_name2)
    except Exception as e:
        try:
            os.system("wget -O %s http://etherscan.io/txs?a=%s" % (file_name1, contract_addr))
            re_txs_value = r"<span>A total of (.+?) transactions found for address</span>"
            txs = run_re_file(re_txs_value, file_name1)

            # get balance
            re_str_value = r"<td>ETH Balance:\n<\/td>\n<td>\n(.+?)\n<\/td>"
            os.system("wget -O %s https://etherscan.io/address/%s" % (file_name2, contract_addr))
            value = run_re_file(re_str_value, file_name2)
        except Exception as e:
            pass
    return txs, value


def get_contract_stats(list_of_contracts):
    with open("concurr.csv", "w") as stats_file:
        fp = csv.writer(stats_file, delimiter=',')
        fp.writerow(["Contract address", "No. of paths", "No. of concurrency pairs", "Balance", "No. of TXs", "Note"])
        with open(list_of_contracts, "r") as f:
            for contract in f.readlines():
                contract_addr = contract.split()[0]
                value, txs = get_contract_info(contract_addr)
                fp.writerow([contract_addr, contract.split()[1], contract.split()[2],
                             value, txs, contract.split()[3:]])


def get_time_dependant_contracts(list_of_contracts):
    with open("time.csv", "w") as stats_file:
        fp = csv.writer(stats_file, delimiter=',')
        fp.writerow(["Contract address", "Balance", "No. of TXs", "Note"])
        with open(list_of_contracts, "r") as f:
            for contract in f.readlines():
                if len(contract.strip()) == 0:
                    continue
                contract_addr = contract.split(".")[0].split("_")[1]
                txs, value = get_contract_info(contract_addr)
                fp.writerow([contract_addr, value, txs])


def get_distinct_contracts(list_of_contracts = "concurr.csv"):
    flag = []
    with open(list_of_contracts, "rb") as csvfile:
        contracts = csvfile.readlines()[1:]
        n = len(contracts)
        for i in range(n):
            flag.append(i) # mark which contract is similar to contract_i
        for i in range(n):
            if flag[i] != i:
                continue
            contract_i = contracts[i].split(",")[0]
            npath_i = int(contracts[i].split(",")[1])
            npair_i = int(contracts[i].split(",")[2])
            file_i = "stats/tmp_" + contract_i + ".evm"
            six.print_(" reading file " + file_i)
            for j in range(i+1, n):
                if flag[j] != j:
                    continue
                contract_j = contracts[j].split(",")[0]
                npath_j = int(contracts[j].split(",")[1])
                npair_j = int(contracts[j].split(",")[2])
                if (npath_i == npath_j) and (npair_i == npair_j):
                    file_j = "stats/tmp_" + contract_j + ".evm"

                    with open(file_i, 'r') as f1, open(file_j, 'r') as f2:
                        code_i = f1.readlines()
                        code_j = f2.readlines()
                        if abs(len(code_i) - len(code_j)) >= 5:
                            continue
                        diff = difflib.ndiff(code_i, code_j)
                        ndiff = 0
                        for line in diff:
                            if line.startswith("+") or line.startswith("-"):
                                ndiff += 1
                        if ndiff < 10:
                            flag[j] = i
    six.print_(flag)

def run_command(cmd):

    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=FNULL)
    return solc_p.communicate()[0].decode()


#Added by PG

def get_uncalled_blocks(blocks, visited_blocks):
    return list(set(blocks).difference(set(visited_blocks)))

'''
It returns the start address of the block received.

'''    
def getKey(block):
    if(str(block.get_start_address()).find("_")==-1):
        val = int(block.get_start_address())
        return (val,0)
    else:
        block,c = block.get_start_address().split("_")
        return (int(block),int(c))
    # return block.get_start_address()

def toInt(a):
    elem = a.split("_")
    if len(elem)>1:
        return int(elem[0])
    else:
        return int(a)

def getLevel(block):
    return block.get_depth_level()
'''
It returns the id of a rbr_rule.
'''
def orderRBR(rbr):
    if str(rbr[0].get_Id()).find("_")==-1:
        val = int(rbr[0].get_Id())
        return (val,0)
    else:
        val,s = rbr[0].get_Id().split("_")
        return (int(val), int(s))

    # return rbr[0].get_Id()

def get_rule_id(rbr):
    block_id = rbr.get_Id()

    if str(block_id).find("_") == -1:
        val = int(block_id)
    else:
        val = block_id

    return val
    

def delete_dup(l):
    r = []
    for e in l:
        if e not in r:
            r.append(e)
    return r

def get_function_names(i,lineas):
    delimiter = "======"
    names = {}
    line = lineas[i]
    while line !="" and line.find(delimiter)==-1:
        parts = line.split(":")
        hash_code = parts[0].strip()
        fun_name = parts[1].strip()
        names[hash_code]=fun_name
        i+=1
        line = lineas[i]

    return i, names

'''
It returns a map that for each contract, it returns a list of pairs (hash, name_function).
Solidity file is a string that contains the name of the solidity file that is going to be analized.
'''
def process_hashes(solidity_file,solidity_version):
    
    solc = get_solc_executable(solidity_version)

    cmd = solc+" --hashes "+str(solidity_file)
        
    delimiter = "======="

    m = {}
    
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=FNULL)
    string = solc_p.communicate()[0].decode()
    lines = string.split("\n")
    i = 0

    while i < len(lines):
        line = lines[i]
        parts = line.strip().split()
        
        if parts!=[] and parts[0] == delimiter:
            if parts[1].find(":")!=-1:
                cname = parts[1].split(":")[1]
            else:
                cname = parts[-2].split(":")[1]
            i, names = get_function_names(i+2,lines)
            m[cname] = names
        else:
            i+=1

    return m


def write_cfg(it,vertices,name = False,cloned = False):
    vert = sorted(vertices.values(), key = getKey)
    if "costabs" not in os.listdir(global_params_ethir.costabs_path):
        os.mkdir(global_params_ethir.costabs_path+"/costabs")

    if not cloned:
        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg_evm.cfg"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg_evm"+str(it)+".cfg"
        else:
            name = global_params_ethir.costabs_path+"/costabs/cfg_"+name+".cfg"

    else:
        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg_cloned_evm.cfg"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg__cloned_evm"+str(it)+".cfg"
        else:
            name = global_params_ethir.costabs_path+"/costabs/cfg_"+name+"_cloned.cfg"
        
    with open(name,"w") as f:
        for block in vert:
            f.write("================\n")
            pcs = list(block.get_pcs())
            start_addr, end_addr, jump_addr, falls_addr = compute_hex_vals_cfg(block)
            
            f.write("start address: "+ str(start_addr)+"\n")

            f.write("end address: "+str(end_addr)+"\n")
            
            f.write("end statement type: " + block.get_block_type()+"\n")

            f.write("jump target: " + str(jump_addr)+"\n")

            f.write("falls to: " +str(falls_addr)+"\n")

            addresses = block.get_pcs()
            i = 0
            count = 0;
            for instr in block.get_instructions():
                f.write(str(pcs.pop(0))+": "+instr+"\n")
                count+=1
                # if not cloned:
                #     f.write(addresses[i][2:]+": "+instr+"\n")
                #     i+=1
                # else:
                #     f.write(instr+"\n")

                if instr.strip() == "STOP":
                    break
    f.close()


def compute_hex_vals_cfg(block):
    start_addr = ""
    end_addr = ""
    jump_addrs = ""
    falls_addr = ""

    
    start = str(block.get_start_address()).split("_")
    end = str(block.get_end_address()).split("_")
    
    if len(start)>1:
        # start0 = hex(int(start[0]))[2:]
        start0 = str(int(start[0]))
        start_addr = start0+"_"+start[1]
    else:
        # start_addr = hex(int(start[0]))[2:]
        start_addr = str(int(start[0]))

    if len(end)>1:
        # end0 = hex(int(end[0]))[2:]
        end0 = str((int(end[0])))
        end_addr = end0+"_"+end[1]
    else:
        # end_addr = hex(int(end[0]))[2:]
        end_addr = str(int(end[0]))

    jumps_hex = []
    for jump in  block.get_list_jumps():
        elems = str(jump).split("_")
        if len(elems)>1:
            # jump0 = hex(int(elems[0]))[2:]
            jump0 = str(int(elems[0]))
            jump_addr = jump0+"_"+elems[1]
        else:
            # jump_addr = hex(int(elems[0]))[2:]
            jump_addr = str(int(elems[0]))
        jumps_hex.append(jump_addr)
        
    jump_addrs = " ".join(jumps_hex)

    falls = str(block.get_falls_to()).split("_")

    if falls!=['None']:
        if len(falls)>1:
            # falls0 = hex(int(falls[0]))[2:]
            falls0 = str((int(falls[0])))
            falls_addr = falls0+"_"+falls[1]
        else:
            # falls_addr = hex(int(falls[0]))[2:]
            falls_addr = str(int(falls[0]))
                         
    else:
        falls_addr = None


    return start_addr,end_addr,jump_addrs,falls_addr
        
def cfg_dot(it,block_input,name = False,cloned = False):
    vert = sorted(block_input.values(), key = getKey)

    if "costabs" not in os.listdir(global_params_ethir.costabs_path):
        os.mkdir(global_params_ethir.costabs_path+"/costabs/")
    
    if not cloned:

        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg.dot"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg"+str(it)+".dot"
        else:
            name = global_params_ethir.costabs_path+"/costabs/"+name+".dot"
    else:

        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg_cloned.dot"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg_cloned_"+str(it)+".dot"
        else:
            name = global_params_ethir.costabs_path+"/costabs/"+name+"_cloned.dot"
        
    f = open(name,"w")
    tree = build_tree(vert[0],[("st",0)],block_input)
    tree.generatedot(f)
    f.close()


def cfg_memory_dot(cfg_type,it,block_input,memory_sets,name = False,cloned = False):
    vert = sorted(block_input.values(), key = getKey)

    if "costabs" not in os.listdir(global_params_ethir.costabs_path):
        os.mkdir(global_params_ethir.costabs_path+"/costabs/")
    
    if not cloned:

        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg.dot"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg"+str(it)+".dot"
        else:
            name = global_params_ethir.costabs_path+"/costabs/"+name+".dot"
    else:

        if it == None:
            name = global_params_ethir.costabs_path+"/costabs/cfg_cloned.dot"
        elif name == False:
            name = global_params_ethir.costabs_path+"/costabs/cfg_cloned_"+str(it)+".dot"
        else:
            name = global_params_ethir.costabs_path+"/costabs/"+name+"_cloned.dot"
        
    f = open(name,"w")
    tree = build_tree_memory(vert[0],[("st",0)],block_input,cfg_type,memory_sets)
    tree.generatedot(f)
    f.close()

    
def update_map(m,key,val):
    l = m.get(key,[])
    l.append(val)
    m[key]=l
    return m

def store_times(oyente_time,ethir_time):
    f = open(global_params_ethir.costabs_path+"/costabs/times.csv","a")
    fp = csv.writer(f, delimiter=',')
    fp.writerow(["Oyente",oyente_time,"EthIR",ethir_time])
    f.close()


def get_public_fields(source_file,arr = True):
    with open(source_file,"r") as f:
        lines = f.readlines()
        good_lines_aux = list(filter(lambda x: x.find("[]")!=-1 and x.find("public")!=-1,lines))
        good_lines = list(map(lambda x: x.split("//")[0],good_lines_aux))
        fields = list(map(lambda x: x.split()[-1].strip().strip(";"),good_lines))
    f.close()
    return fields

def update_sstore_map(state_vars,initial_name,compressed_name,isCompresed,position,compress_index,state):

    r_val = False
    if initial_name != '':
        if not isCompresed:
            #print compressed_name
            if initial_name != compressed_name:
                compressed = get_field_from_string(compressed_name,state)
                nn = compressed_name.split()
                r_val = (initial_name,nn[-1]) if nn != [] else (initial_name,initial_name)  
 
            state_vars[position] = initial_name
        else:
            name = str(position)+"_"+str(compress_index)

            if compress_index == 0:
                state_vars[name] = initial_name
            else:
                exist = state_vars.get(name, False)
                if (not exist) or (exist not in state):
                    st_name = get_field_from_string(compressed_name, state)
                    state_vars[name] = st_name

    return r_val

def compute_ccomponent(inverse_component, block):
    component = []
    for b in inverse_component.keys():
        if block in inverse_component[b]:
            component.append(b)

    return component

def get_field_from_string(string, state_variables):
    parts = string.split()

    i = 0
    st_name = ""
    found = False
    while(i<len(parts) and (not found)):
        if parts[i] in state_variables:
            st_name = parts[i]
            found = True
        i+=1
    return st_name

def correct_map_fields(candidate_fields,fields_map):
    for e in candidate_fields:
        (x,y) = candidate_fields[e]
        elem = fields_map.get(str(e)+"_0",False)
        if elem:
            fields_map[e] = elem
        else:
            pos = search_for_index(x,fields_map)

            if pos ==-1:
                fields_map[e] = x
            else:
                if not(str(pos).startswith(str(e))):
                    val = int(str(pos).split("_")[0])
                    f = y if e>val else x
                    fields_map[e] = f


def correct_map_fields1(fields_map,var_fields):
    correct = True
    i = 0
    offset=0
    fields_map_aux = dict(fields_map)
    for e in fields_map_aux:
        val = fields_map[e]
        del fields_map[e]
        fields_map[str(e)] = val
    
    while(i<len(var_fields) and correct):
        field = var_fields[i]
        pos = search_for_index(field,fields_map)

        if pos ==-1:
            fields_map[str(i)] = field
        else:
            if str(pos).split("_")[0] != str(i):
                correct = False
                offset = offset+1
        i=i+1

    while(i<len(var_fields)):
        number = search_greatter_compacts(pos,fields_map)

        if number !=0:
            offset = offset+number
        field = var_fields[i]

        potential_index = i-offset

        pos = exist_index(potential_index,fields_map)

        fields_map[str(pos)] = field

        i+=1

def search_greatter_compacts(pos,fields_map):
    
    numbers = fields_map.keys()
    pos_int = str(pos).split("_")[0]
    numbers_str = list(filter(lambda x: str(x).startswith(pos_int),numbers))
    end = list(filter(lambda x: str(x)>str(pos),numbers_str))
    if len(end)>0:
        if end[0] == pos_int+"_0":
            fields_map[pos_int+"_0"] = fields_map[pos_int]
            end.pop(0)
        
    return len(end)

def exist_index(potential_index,fields_map):
    numbers = fields_map.keys()
    numbers_str = list(filter(lambda x: str(x).startswith(str(potential_index)), numbers))
    
    if len(numbers_str)== 0:
        return potential_index
    else:
        numbers_str = list(map(lambda x: str(x), numbers_str))
        numbers_str.sort()
        return numbers_str[0]

def search_for_index(field,field_map):
    possible_values = []
    for e in field_map:
        if field == field_map[e]:
            possible_values.append(e)

    vals = list(map(lambda x: str(x), possible_values))
    vals.sort()
    if len(vals)!=0:
        return vals[0]
    else:
        return -1


def is_integer(num):
    if num.find("_") !=-1:
        return -1
    try:
        val = int(num)
    except:
        val = -1

    return val
# '''
# It computes the index of each state variable to know its solidity name
# state variable is a list with the state variables g0..gn
# '''
# def process_name_state_variables(state_variables,source_map):
#     index_state_variables = {}
#     i = 1
#     prev_var = state_variables[0]
#     while(i < len(state_variables)):

def get_push_value(elem):
    if type(elem) != str:
        try:
            push_val, _ = elem
            return push_val
        except:
            return elem
    else:
        return elem    

# Added by AHC

def get_initial_block_address(elem):
    numbers = str(elem).split("_")
    return int(numbers[0])

def get_next_block_address(elem, index_dict):
    numbers = str(elem).split("_")
    idx = str(index_dict[int(numbers[0])])

    if len(numbers) == 1:
        numbers.append(idx)
    else:
        numbers[1] = idx
    return "_".join(numbers)

def check_if_not_cloned_address(elem):
    numbers = str(elem).split("_")
    return len(numbers) == 1

def get_idx_from_address(address):
    parts = address.split("_")
    idx = parts[1]
    return int(idx)

# Two stacks are equivalent if they share the same jump elements in the same positions
# of each stack. This function is used to return the same element if it is a jump element,
# or None otherwise. This is useful for applying a mask to compare two different stacks.
def mask_not_jump_elements(x, blocks_info):
    # An element is a jump element if it is a tuple (which means it comes from a PUSHx instruction),
    # its associated pushed value (x[0]) belongs to the set of blocks and it is not 0, as there's never
    # a jump to block 0 and this value tends to appear really often.
    if isinstance(x, tuple) and (x[0] in blocks_info) and x[0] != 0:
        return x[0]
    else:
        return None

# For checking if they are same stack, we just focus on
# tuples that contains a block address
def check_if_same_stack(stack1, stack2, blocks_info):
    s1_aux = list(map(lambda x: mask_not_jump_elements(x, blocks_info), stack1))
    s2_aux = list(map(lambda x: mask_not_jump_elements(x, blocks_info), stack2))
    # print "S1"
    # print s1_aux
    # print "S2"
    # print s2_aux
    return s1_aux == s2_aux


def show_graph(blocks_input):
    for address in blocks_input:
        print("Bloque: ")
        print(address)
        print("Comes from: ")
        print(blocks_input[address].get_comes_from())
        print("List jump: ")
        print(blocks_input[address].get_list_jumps())
        print("Jump target: ")
        print(blocks_input[address].get_jump_target())
        print("Falls to: ")
        print(blocks_input[address].get_falls_to())
        print("Filtered Stack: ")
        for stack in blocks_input[address].get_stacks():
            print(list(filter(lambda x: isinstance(x,tuple) and (x[0] in blocks_input) and x[0]!=0, stack)))
        print("Real stack:")
        print(blocks_input[address].get_stacks())
        

''' Given a node and where it comes from, checks all relevant info is consistent'''
def check_node_consistency(blocks_dict, initial_address, comes_from_address, visited_nodes):
    
    current_block = blocks_dict[initial_address]

    comes_from = current_block.get_comes_from()

    # List containing all the values checked
    conds = []
    
    # Always same condition: check if previous block is in comes_from list
    conds.append(comes_from_address in comes_from)
    
    if initial_address not in visited_nodes:
        
        t = current_block.get_block_type()

        jumps_to = current_block.get_jump_target()
        falls_to = current_block.get_falls_to()

        visited_nodes.append(initial_address)

        # Conditional jump: check comes_from + falls to node + jump target node
        if t == "conditional":

            conds.append(check_node_consistency(blocks_dict,falls_to, initial_address,visited_nodes))
            conds.append(check_node_consistency(blocks_dict,jumps_to, initial_address,visited_nodes))

            # print("conditional check")

       # Unconditional jump : check length of jump list + comes_from + 
       # jumps target is the element of jump list + jump target node +
       # falls_to == None
        elif t == "unconditional":

            jump_list = current_block.get_list_jumps()
            
            conds.append(len(jump_list) == 1)
            conds.append(jumps_to in jump_list)
            conds.append(check_node_consistency(blocks_dict,jumps_to, initial_address, visited_nodes))
            conds.append(falls_to == None)
            # print("Falls_to")
            # print(falls_to)

            # print("unconditional check")
        
        # Falls to node: check comes_from + next_node + jumps_to == None
        elif t == "falls_to":
            
            conds.append(check_node_consistency(blocks_dict, falls_to, initial_address, visited_nodes))
            conds.append(jumps_to == 0)

            # print("Jumps to")
            # print(jumps_to)

            # print("falls to check")
            
        # Terminal node: only check comes_from

        else:
            pass
            # print("terminal node to check")
        
    # If visited, as we've checked that node before, we just need to make sure
    # comes_from has current node.

    else:
        # print("already checked")
        pass
    # print(initial_address)
    # print(conds)
    return reduce(lambda i,j: i and j, conds)

''' Given a dictionary containing all blocks from graph, checks if all the info
is coherent '''
def check_graph_consistency(blocks_dict, initial_address = 0):
    visited_nodes = [initial_address]
    initial_block = blocks_dict[initial_address]

    t = initial_block.get_block_type()

    jumps_to = initial_block.get_jump_target()
    falls_to = initial_block.get_falls_to()

    conds = []

    # Conditional jump: call check_node with falls_to && jump_target && all visited nodes are blocks
    # are the ones in block_dict
    if t == "conditional":
         
         conds.append(check_node_consistency(blocks_dict,falls_to, initial_address,visited_nodes))
         conds.append(check_node_consistency(blocks_dict,jumps_to, initial_address,visited_nodes))
         
         # print("initial node: conditional")
         
    # Unconditional jump : check length of jump list && comes_from && 
    # jumps target is the element of jump list && jump target node &&
    # falls_to == None
    elif t == "unconditional":
         
         jump_list = current_block.get_list_jumps()
         
         conds.append(len(jumps_list) == 1)
         conds.append(jumps_to in jump_list)
         conds.append(check_node_consistency(blocks_dict,jumps_to, initial_address, visited_nodes))
         conds.append(falls_to == None)

         # print("initial node: unconditional")
         
    # Falls to node: visited nodes == blocks_dict.keys && check  next_node  && jumps_to == None
    elif t == "falls_to":
        
         conds.append(check_node_consistency(blocks_dict, falls_to, initial_address, visited_nodes))
         conds.append(jumps_to == 0)
         
         # print("initial node: falls to")
         
    # Terminal node: only check there's no other block
    else:
         pass
         # print("initial Node: terminal node")

    # Check all visited nodes are the same in the dictionary
    conds.append(visited_nodes.sort() == blocks_dict.keys().sort())

    # print(conds)
    
    return reduce(lambda i,j: i and j, conds)


def process_isolate_block(contract_name):
    
    f = open(contract_name,"r")
    input_stack = f.readline().strip("\n")
    instructions = f.readline()

    initial = 0
    opcodes = []

    ops = instructions.split(" ")
    i = 0
    while(i<len(ops)):
        op = ops[i]
        if not op.startswith("PUSH"):
            opcodes.append(op.strip())
        else:
            val = ops[i+1]
            opcodes.append(op+" "+val)
            i=i+1
        i+=1

    return opcodes,input_stack

def all_integers(variables):
    int_vals = []
    try:
        for v in variables:
            if v.find("_")!=-1:
                return False,variables
            
            x = int(v)
            int_vals.append(x)
        return True, int_vals
    except:
        return False,variables
# '''
# It computes the index of each state variable to know its solidity name
# state variable is a list with the state variables g0..gn
# '''
# def process_name_state_variables(state_variables,source_map):
#     index_state_variables = {}
#     i = 1
#     prev_var = state_variables[0]
#     while(i < len(state_variables)):

# Given a string, returns closing parentheses index that closes first parenthese,
# assuming parentheses are well-placed.
def find_first_closing_parentheses(string):
    idx_ini = string.find("(") + 1
    filtered_string = string[idx_ini:]
    cont = 1
    while cont > 0:
        opening_index = filtered_string.find("(")
        closing_index = filtered_string.find(")")
        if opening_index == -1:
            return idx_ini + closing_index
        elif opening_index < closing_index:
            cont = cont+1
            idx_ini = idx_ini + opening_index + 1
            filtered_string = filtered_string[opening_index+1:]
        else:
            cont = cont-1
            if cont == 0:
                return idx_ini + closing_index
            else:
                idx_ini = idx_ini + closing_index + 1
                filtered_string = filtered_string[closing_index+1:]
    raise ValueError("Parentheses are not consistent")

## Set when the param names "solc-compiler" is received
global solc_compiler
solc_compiler = None

def set_solc_executable(solc_command):
    global solc_compiler

    if not os.path.isfile(solc_command): 
        raise Exception(f"Compiler {solc_command} not found")

    solc_compiler = solc_command

def get_solc_executable(version):
    global solc_compiler
    if solc_compiler: 
        print (f"Compiling using {solc_compiler}")
        return solc_compiler
    
    if version == "v4":
        return "solc"
    elif version == "v5":
        return "solcv5"
    elif version == "v6":
        return "solcv6"
    elif version == "v7":
        return "solcv7"
    elif version == "v8":
        return "solcv8"

def is_executed_by(block,init_blocks,components):
    is_reached_by = set(components[block])
    init_blocks_set = set(init_blocks)

    public_blocks = init_blocks_set.intersection(is_reached_by)
    
    return list(public_blocks)
    

def compute_stack_size(evm_instructions, init_size):
    current_size = init_size
    for op in evm_instructions:
        opcode_info = opcodes.get_opcode(op.strip())

        consumed_elements = opcode_info[1]
        produced_elements = opcode_info[2]
            
        current_size-=consumed_elements
        current_size+=produced_elements
        
    return current_size

def process_cost(opcode):
    if opcode.find("(") == -1:
        return opcodes.get_ins_cost(opcode.strip())

    else:
        pos = opcode.find("(")
        opcode_aux = opcode[:pos]
        gas = opcodes.get_ins_cost(opcode_aux.strip())
        
        args = opcode[pos+1:-1]
        args_aux = args.split(",")
        sum_gas = 0
        for a in args_aux:
            gas_aux=process_cost(a.strip(")"))
            sum_gas+=gas_aux
            
        return gas+sum_gas
        
def compute_gas(vertices):
    gas = 0
    for v in vertices:
        instructions = vertices[v].get_instructions()
        for i in instructions:
            instruction = i.split()
            if len(instruction) > 1:
                ins = instruction[0]
            else:
                ins = i
            gas+=opcodes.get_ins_cost(ins.strip())

    return gas


def run_gastap(contract_name, entry_functions, storage_analysis = False, gastap_op = "all", timeoutval = 90, source_file = None,  sstore_cost = "zero"):

    outputs = []
    ubs = {}
    ub_params = {}
    times = {}

    if gastap_op == "op":
        ethir_mem_op = "no"
    elif gastap_op == "mem":
        ethir_mem_op = "only"
    elif gastap_op == "all":
        ethir_mem_op = "yes"
    else:
        raise Exception("Unrecognized option for GASTAP")
    
    for bl in entry_functions:
        
        # if contract_name != "BrunableCrowdsaleToken" or bl != "block3109":
        #     continue
        sourceparam = ""
        if source_file: 
            sourceparam = "-solfilename " + str(source_file)

        print ("TIMEOUT " + str(timeoutval))
        if storage_analysis:
            cmd = f"timeout {timeoutval}s sh /home/groman/Systems/costa/costabs/src/interfaces/shell/costabs_shell "+global_params_ethir.costabs_path+"/costabs/"+contract_name+"_saco.rbr"+ " -entries "+"block"+str(bl) +" -ethir yes -ethir_mem " +ethir_mem_op+ " -cost_model gas -custom_out_path yes -evmcc star " + sourceparam + " -sto_init_cost "+sstore_cost 
        else:
            cmd = f"timeout {timeoutval}s sh /home/groman/Systems/costa/costabs/src/interfaces/shell/costabs_shell "+global_params_ethir.costabs_path+"/costabs/"+contract_name+"_saco.rbr"+ " -entries "+"block"+str(bl) +" -ethir yes -ethir_mem " +ethir_mem_op+ " -cost_model gas -custom_out_path yes " + sourceparam 
            
        FNULL = open(os.devnull, 'w')
        print(cmd)

        x = dtimer()
        try: 
            solc_p = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=FNULL)
            out = solc_p.communicate()[0].decode()

            if solc_p.returncode == 124:
                raise subprocess.TimeoutExpired("",str(timeoutval))
            elif solc_p.returncode == 2:
                raise Exception("execerror")
            
            y = dtimer()

            times[bl] = y-x

            outputs.append(out)
            ub, params = filter_ub(out)

            if ub == "" or ub == None:
                print("GASTAPERR: Error at cooking the ub expression. "+str(contract_name)+",block"+str(bl))
            else:
                ubs[bl] = ub
                ub_params[bl] = params
        except subprocess.TimeoutExpired:         
            print (f"WARN: Timeout detected in block {bl}")
            ubs[bl] = ("timeout", "timeout")
            ub_params[bl] = None
            times[bl] = 0
        except Exception as e: 
            print (f"WARN: Detected error in block {bl} -> {repr(e)}")
            ubs[bl] = ("execerror","execerror")
            ub_params[bl] = None
            times[bl] = 0

    return outputs, ubs, ub_params, times


# def filter_ub(out):
#     res = re.search("Total UB for .*",out)    
#     if res: 
#         sres = res.group(0).split(":")
#         params = sres[0]
#         params = params[params.find("(")+1:params.find(")")]
#         if params != "":
#             params+=",call,staticcall,delegatecall"
#         else:
#             params+="call,staticcall,delegatecall"
#         ub = sres[1]
#     else: 
#         ub = "unknown"
#         params = ""
#     return ub, params

def filter_ub(out):
    res = re.search("Memory UB for .*",out)    
    if res: 
        sres = res.group(0).split(":")
        params = sres[0]
        params = params[params.find("(")+1:params.find(")")]
        if params != "":
            params+=",call,staticcall,delegatecall"
        else:
            params+="call,staticcall,delegatecall"
        ub_mem = sres[1]
    else: 
        ub_mem = "unknown"
        params = ""


    res = re.search("Opcodes UB for .*",out)    
    if res: 
        sres = res.group(0).split(":")
        params = sres[0]
        params = params[params.find("(")+1:params.find(")")]
        if params != "":
            params+=",call,staticcall,delegatecall"
        else:
            params+="call,staticcall,delegatecall"
        ub = sres[1]

    else:

        res = re.search("Total UB for .*",out)    
        
        if res: 
            sres = res.group(0).split(":")
            params = sres[0]
            params = params[params.find("(")+1:params.find(")")]
            if params != "":
                params+=",call,staticcall,delegatecall"
            else:
                params+="call,staticcall,delegatecall"
            ub = sres[1]
        
        else:
            ub = "unknown"
            params = ""
        
    return (ub_mem, ub), params

        
def get_all_scc_ids(scc_components):
    unary = scc_components["unary"]
    multiple = scc_components["multiple"]
    l = multiple.values()
    scc_ids_multiple = [x for y in l for x in y]
    scc_ids = unary+scc_ids_multiple
    
    return scc_ids

#blocks are the list of blocks of the scc without the entry block
def compute_component_of_cfg_scc(blocks, vertices,s):

    component_of_blocks = {}    
    for block in blocks:
        # print(block)
        comp = component_of(block,vertices,s)
        pos = comp.index(s)
        comp.pop(pos)
        component_of_blocks[block] = comp

        # if block == 5132:
        #     print comp
        #     raise Exception
    return component_of_blocks

#For scc        
def component_of(block, vertices,s):
    r = component_of_aux(block,[s], vertices)
    return r

def component_of_aux(block,visited, vertices):
    #print vertices[block].get_start_address()
    blocks_conn = vertices[block].get_comes_from()
    for elem in blocks_conn:
        if elem not in visited:
            visited.append(elem)
            component_of_aux(elem,visited, vertices)
    return visited


def get_out_of_scc(block, vertices, scc_components):
    m = scc_components["multiple"]
    b = vertices[block]

    
    jump = b.get_jump_target()
    falls = b.get_falls_to()

    
    if jump in m[block] and falls in m[block]:
        print("SCC Entry: "+str(block)+ "has a different exit")
        return -1
    
    if jump in m[block]:
        return falls
    elif falls in m[block]:
        return jump
    
    else:
        raise Exception("Error when searching the exit") 
    


def compute_join_conditionals(vertices,comes_from,scc_components):
    rel = {}

    all_scc = get_all_scc_ids(scc_components)
    multiple = scc_components["multiple"]
    l = multiple.values()
    scc_ids_multiple = [x for y in l for x in y]
    all_scc_multiple = scc_ids_multiple

    
    comes_from_scc = {}
    
    for s in scc_components["multiple"]:
        blocks = scc_components["multiple"][s]
        pos = blocks.index(s)
        blocks.pop(pos)
        r = compute_component_of_cfg_scc(blocks, vertices,s)
        comes_from_scc[s] = r
    # print(comes_from_scc)

    for v in vertices:
        block = vertices[v]
        found = False
        if block.get_block_type() == "conditional" and v not in all_scc:

            prev_blocks = comes_from[v]

            left_branch = block.get_jump_target()
            right_branch = block.get_falls_to()

            if left_branch in comes_from[right_branch]:
                found = True
                c = right_branch

            elif right_branch in comes_from[left_branch]:
                found = True
                c = left_branch

            else:
                
                candidates = list(filter(lambda x: left_branch in comes_from[x] and right_branch in comes_from[x],vertices.keys()))
                i = 0
                found = False
                
                while i < len(candidates) and not found:
                    #print(candidates[i])
                    # el candidate tiene el comes_from de los dos hijos, y el aparece en el comes_from del resto de candidatos
                    l = list(filter(lambda x: candidates[i] in comes_from[x], candidates))
                    l.append(candidates[i])
                    if left_branch in comes_from[candidates[i]] and right_branch in comes_from[candidates[i]] and set(candidates) == set(l):
                        c = candidates[i]
                        found = True
                    i+=1

        elif block.get_block_type() == "conditional" and v in all_scc_multiple and v not in scc_components["multiple"].keys():
            prev_blocks = comes_from[v]

            for scc in scc_components["multiple"]:
                if v in scc_components["multiple"][scc]:
                    entry_scc = scc

            comes_from_entry = comes_from_scc[entry_scc]
            
            left_branch = block.get_jump_target()
            right_branch = block.get_falls_to()

            if right_branch in scc_components["multiple"][entry_scc] and left_branch in comes_from_entry[right_branch]:
                found = True
                c = right_branch
                
            elif left_branch in scc_components["multiple"][entry_scc] and right_branch in comes_from_entry[left_branch]:
                found = True
                c = left_branch
                
            else:
                
                candidates = list(filter(lambda x: left_branch in comes_from_entry[x] and right_branch in comes_from_entry[x], scc_components["multiple"][entry_scc]))
                i = 0
                found = False
                
                while i < len(candidates) and not found:
                    #print(candidates[i])
                    # el candidate tiene el comes_from de los dos hijos, y el aparece en el comes_from del resto de candidatos
                    l = list(filter(lambda x: candidates[i] in comes_from_entry[x], candidates))
                    l.append(candidates[i])
                    if left_branch in comes_from_entry[candidates[i]] and right_branch in comes_from_entry[candidates[i]] and set(candidates) == set(l):
                        c = candidates[i]
                        found = True
                    i+=1
    
        
        if not found:
            # print("NO CIERRA: "+str(v))
            rel[v] = -1
        else:
            rel[v] = c
            found = False
                    
    #print(rel)
    return rel


def get_blocks_per_function(entry_functions, comes_from):
    result = {}
    for b in entry_functions:
        blocks = list(filter(lambda x: b in comes_from[x], comes_from))
        result[b] = blocks

    print(result)

def get_function_hash(function_hashes, function_name):
    l = list(filter(lambda x: x[1]==function_name,function_hashes.items()))
    return l[0][0]


def get_complete_storage_analysis_info(vertices, storage_analysis_result):


    num_total_info = 0
    num_total_zeros = 0
    num_total_zeros_nonconcrete = 0
    
    for block in vertices:

        info = storage_analysis_result.get_storage_analysis_info(str(block))
        if info != []:
            result = []
            
            for i in info:
                num_total_info +=1
                first_elem = ["a",[1],i[2]]
                if i[2] == "s" and i[3] == "z":
                    first_elem.append("z")
                    if (str(i[1]).find("*") == -1):
                        num_total_zeros+=1
                    else: 
                        num_total_zeros_nonconcrete += 1
 
                elif i[2] == "s" and i[3] == "nz":
                    first_elem.append("ukn")
                
                if str(i[1]).find("*")==-1:
                    new_set = list(map(lambda x: str(x),i[1]))
                    elem = [first_elem,new_set]
                    result.append(elem)

                    
        else:
            result = []
    print("ACCESSZERORES: TOTAL ACCESSES -> "+str(num_total_info))
    print("ACCESSZERORES: TOTAL ZERO CONCRETE ACCESSES -> "+str(num_total_zeros))
    print("ACCESSZERORES: TOTAL ZERO NON-CONCRETE ACCESSES -> "+str(num_total_zeros_nonconcrete))
    return result

