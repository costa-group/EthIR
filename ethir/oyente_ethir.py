#!/usr/bin/env python

import os
import re
import six
import json
import symExec
import logging
#import requests
import argparse
import subprocess
import global_params_ethir
from timeit import default_timer as dtimer
from utils import run_command, process_hashes, set_solc_executable
from input_helper import InputHelper
import traceback

import sys
sys.setrecursionlimit(5000)

sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/analysis/")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/memory/")
sys.path.append(os.path.dirname(os.path.realpath(__file__))+"/storage/")

def cmd_exists(cmd):
    return subprocess.call("type " + cmd, shell=True,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE) == 0

def compare_versions(version1, version2):
    def normalize(v):
        return [int(x) for x in re.sub(r'(\.0+)*$','', v).split(".")]
    version1 = normalize(version1)
    version2 = normalize(version2)
    if six.PY2:
        return cmp(version1, version2)
    else:
        return (version1 > version2) - (version1 < version2)

def has_dependencies_installed():
    global evm_version_modifications
    evm_version_modifications = False
    #try:
    #     import z3
    #     import z3.z3util
    #     z3_version =  z3.get_version_string()
    #     tested_z3_version = '4.5.1'
    #     if compare_versions(z3_version, tested_z3_version) > 0:
    #         logging.warning("You are using an untested version of z3. %s is the officially tested version" % tested_z3_version)
    # except:
    #     logging.critical("Z3 is not available. Please install z3 from https://github.com/Z3Prover/z3.")
    #     return False

    if not cmd_exists("evm"):
        logging.critical("Please install evm from go-ethereum and make sure it is in the path.")
        return False
    else:
        cmd = "evm --version"
        out = run_command(cmd).strip()
        evm_version = re.findall(r"evm version (\d*.\d*.\d*)", out)[0]
        tested_evm_version = '1.9.23'
        if compare_versions(evm_version, tested_evm_version) > 0:
            evm_version_modifications = True
            logging.warning("You are using evm version %s. The supported version is %s" % (evm_version, tested_evm_version))

    if not cmd_exists("solc") and not cmd_exists("solcv5"):
        logging.critical("solc is missing. Please install the solidity compiler and make sure solc is in the path.")
        return False
    else:
        cmd = "solcv8 --version"
        out = run_command(cmd).strip()
        solc_version = re.findall(r"Version: (\d*.\d*.\d*)", out)[0]
        tested_solc_version = '0.8.24'
        if compare_versions(solc_version, tested_solc_version) > 0:
            logging.warning("You are using solc version %s, The latest supported version is %s" % (solc_version, tested_solc_version))

    return True

def clean_dir():
    
    ext = ["rbr","cfg","txt","config","dot","csv","c","pl","log","sol","bl","ethirui"]
    if "costabs" in os.listdir(global_params_ethir.costabs_path):
        for elem in os.listdir(global_params_ethir.costabs_path+"/costabs"):
            last = elem.split(".")[-1]
            if last in ext:
                os.remove(global_params_ethir.costabs_path+"/costabs/"+elem)


'''
The flag -i has to be used with the flag -v
'''            
def check_vi_dependency():
    if args.verify == None:

        return not args.invalid
    else:
        return True
                
'''
The flag -v has to be used with the flag -c
'''
def check_cv_dependency():
    if args.cfile == None:
        return not args.verify
    else:
        return True

'''
The flag -g has to be used with the flag -c
'''    
def check_cg_dependency():
    if args.cfile == None:
        return not args.goto
    else:
        return True


'''
The flag -a has to be used with the flag -c
'''    
def check_ca_dependency():
    if args.cfile == None:
        return not args.args
    else:
        return True

def check_cexec_dependency():
    if args.cfile == None:
        return not args.c_executable
    else:
        return True

    

def check_c_translation_dependencies():
    r = check_cv_dependency()
    r = r and check_vi_dependency()
    r = r and check_cg_dependency()
    r = r and check_ca_dependency()
    r = r and check_cexec_dependency()
    
    return r

def check_optimize_dependencies():
    c1 = args.optimize == True
    c2 = args.fields != None
    c3 = args.contract_name != ""
    c4 = args.block != None
    r = (c1 and c2) and (c3 and c4)

    return r

def check_standard_json_input():
    #It echsk that no optimization options are enabled when standard-json options has been selected
    
    return not args.optimize_run and args.run == -1 and not args.via_ir
    

#Added by Pablo Gordillo 
'''
We believe that source is a dissasembly evm file
'''
def analyze_disasm_bytecode():
    global args

    r = check_c_translation_dependencies()
    
    if r:
        svc_options={}
        if args.verify:
            svc_options["verify"]=args.verify
        if args.invalid:
            svc_options["invalid"]=args.invalid

        if args.c_executable:
            svc_options["exec"]=args.c_executable

        c_translation_opt = {}
        c_translation_opt["gotos"] = args.goto
        c_translation_opt["args"] = args.args


        result, exit_code = symExec.run(disasm_file=args.source,
                                        cfg = args.control_flow_graph,
                                        saco = (args.saco,False,None,None,None),
                                        debug = args.debug,
                                        evm_version = evm_version_modifications,
                                        cfile = args.cfile,
                                        svc=svc_options,
                                        go = c_translation_opt,
                                        mem_abs = args.mem_interval,
                                        sto=args.storage_arrays, 
                                        mem_analysis = args.mem_analysis, 
                                        storage_analysis = args.storage_analysis, 
                                        sra_analysis = args.sra_analysis, 
                                        compact_clones = args.compact_clones)
    else:
        exit_code = -1
        print("Option Error: --verify, --goto or --invalid options are only applied to c translation.\n")
    if global_params_ethir.WEB:
        six.print_(json.dumps(result))

    return exit_code

def analyze_bytecode():
    global args

    x = dtimer()
    helper = InputHelper(InputHelper.BYTECODE, source=args.source,evm = args.evm)
    inp = helper.get_inputs()[0]
    y = dtimer()
    print("*************************************************************")
    print("Compilation time: "+str(y-x)+"s")
    print("*************************************************************")

    r = check_c_translation_dependencies()
    
    if r:
        svc_options={}
        if args.verify:
            svc_options["verify"]=args.verify
        if args.invalid:
            svc_options["invalid"]=args.invalid
        if args.c_executable:
            svc_options["exec"]=args.c_executable


            
        c_translation_opt = {}
        c_translation_opt["gotos"] = args.goto
        c_translation_opt["args"] = args.args
          

        result, exit_code = symExec.run(disasm_file=inp['disasm_file'],
                                        cfg = args.control_flow_graph,
                                        saco = (args.saco,False, None, None, None),
                                        debug = args.debug,
                                        evm_version = evm_version_modifications,
                                        cfile = args.cfile,
                                        svc=svc_options,
                                        go = c_translation_opt,
                                        mem_abs = args.mem_interval,
                                        sto=args.storage_arrays,
                                        mem_analysis = args.mem_analysis, 
                                        storage_analysis = args.storage_analysis, 
                                        sra_analysis = args.sra_analysis, 
                                        compact_clones = args.compact_clones)
        
        helper.rm_tmp_files()
    else:
        exit_code = -1
        print("Option Error: --verify option is only applied to c translation.\n")
    if global_params_ethir.WEB:
        six.print_(json.dumps(result))

    return exit_code

def run_solidity_analysis(inputs,hashes):
    results = {}
    exit_code = 0
    returns = []
    
    i = 0
    r = check_c_translation_dependencies()
    svc_options={}
    if args.verify:
        svc_options["verify"]=args.verify
    if args.invalid:
        svc_options["invalid"]=args.invalid

    svc_options["exec"]=args.c_executable
    
    c_translation_opt = {}
    c_translation_opt["gotos"] = args.goto
    c_translation_opt["args"] = args.args

    nonzero_vars = args.sto_nonzero.split(",") if args.sto_nonzero != "" else []
   
    if len(inputs) == 1 and r:
        inp = inputs[0]
        function_names = hashes[inp["c_name"]]
        # result, return_code = symExec.run(disasm_file=inp['disasm_file'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,saco = args.saco,execution = 0, cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = evm_version_modifications,cfile = args.cfile,svc=svc_options,go = args.goto)

        contract_name = inp["c_name"]
        if (args.ub_filter == None) or (contract_name.startswith(args.ub_filter)):
        
            try:
                result, return_code = symExec.run(disasm_file=inp['disasm_file'], 
                                                  disasm_file_init = inp['disasm_file_init'], 
                                                  source_map=inp['source_map'], 
                                                  source_file=inp['source'],
                                                  cfg = args.control_flow_graph,
                                                  saco = (args.saco,args.gastap, args.smt_stores, args.gastap_timeout, args.initial_storage),
                                                  execution = 0, 
                                                  cname = inp["c_name"],
                                                  hashes = function_names,
                                                  debug = args.debug,
                                                  evm_version = evm_version_modifications,
                                                  cfile = args.cfile,svc=svc_options,
                                                  go = c_translation_opt,
                                                  mem_abs = args.mem_interval,
                                                  sto=args.storage_arrays,
                                                  opt_bytecode = (args.optimize_run or args.via_ir), 
                                                  mem_analysis = args.mem_analysis, 
                                                  storage_analysis = args.storage_analysis, 
                                                  sra_analysis = args.sra_analysis,
                                                  nonzero_variables = nonzero_vars,
                                                  compact_clones = args.compact_clones)
            
            except Exception as e:
                traceback.print_exc()

                if len(e.args)>1:
                    return_code = e.args[1]
                else:
                    return_code = 1
                result = []
                #return_code = -1
                print ("\n Exception: "+str(return_code)+"\n")
                exit_code = return_code
            
    elif len(inputs)>1 and r:
        for inp in inputs:
            #print hashes[inp["c_name"]]
            function_names = hashes[inp["c_name"]]
            #logging.info("contract %s:", inp['contract'])

            contract_name = inp["c_name"]

            if (contract_name == None) or (contract_name.startswith(args.ub_filter)):

                try:            
                    result, return_code = symExec.run(disasm_file=inp['disasm_file'], 
                                                      disasm_file_init = inp['disasm_file_init'], 
                                                      source_map=inp['source_map'], 
                                                      source_file=inp['source'],
                                                      cfg = args.control_flow_graph,
                                                      saco = (args.saco,args.gastap, args.smt_stores, args.gastap_timeout, args.initial_storage),
                                                      execution = i,
                                                      cname = inp["c_name"],
                                                      hashes = function_names,
                                                      debug = args.debug,
                                                      evm_version = evm_version_modifications,
                                                      cfile = args.cfile,
                                                      svc=svc_options,
                                                      go = c_translation_opt,
                                                      mem_abs = args.mem_interval,
                                                      sto=args.storage_arrays,
                                                      opt_bytecode = (args.optimize_run or args.via_ir), 
                                                      mem_analysis = args.mem_analysis, 
                                                      storage_analysis = args.storage_analysis, 
                                                      sra_analysis = args.sra_analysis,
                                                      nonzero_variables = nonzero_vars,
                                                      compact_clones = args.compact_clones)
                
                except Exception as e:
                    traceback.print_exc()
                    if len(e.args)>1:
                        return_code = e.args[1]
                    else:
                        return_code = 1
                    
                    result = []
                    # return_code = -1
                    print ("\n Exception: "+str(return_code)+"\n")
                    # result, return_code = symExec.run(disasm_file=inp['disasm_file'], source_map=inp['source_map'], source_file=inp['source'],cfg = args.control_flow_graph,saco = args.saco,execution = i,cname = inp["c_name"],hashes = function_names,debug = args.debug,evm_version = evm_version_modifications,cfile = args.cfile,svc=svc_options,go = args.goto)
                i+=1
                returns.append(return_code)
                try:
                    c_source = inp['c_source']
                    c_name = inp['c_name']
                    results[c_source][c_name] = result
                except:
                    results[c_source] = {c_name: result}

                if return_code == 1:
                    exit_code = 1
    else:
        exit_code = 1
        print("Option Error: --verify option is only applied to c translation. Use -c flag\n")


    '''
    Exception management:
    1- Oyente Error
    2- Oyente TimeOut
    3- Cloning Error
    4- RBR generation Error
    5- SACO Error
    6- C Error
    '''
        
    if (1 in returns):
        exit_code = 1
    elif (2 in returns):
        exit_code = 2
    elif (3 in returns):
        exit_code = 3
    elif (7 in returns):
        exit_code = 7
    elif (4 in returns):
        exit_code = 4
    elif (5 in returns):
        exit_code = 5
    elif (6 in returns):
        exit_code = 6

    symExec.print_daos()
        
#    print exit_code
    return results, exit_code


def run_solidity_analysis_optimized(inp,hashes):
    results = {}
    exit_code = 0

    opt_info = {}
    svc_opt = {}
    opt_info["block"] = args.block
    
    fields = process_fields(inp['source_map'])
    
    opt_info["fields"] = fields

    opt_info["c_source"] = inp['c_source'].split("/")[-1]

    # print fields
    # print opt_info["c_source"]
    
    function_names = hashes[inp["c_name"]]
    
    try:
        result, return_code = symExec.run(disasm_file=inp['disasm_file'], 
                                          source_map=inp['source_map'], 
                                          source_file=inp['source'],
                                          cfg = args.control_flow_graph,
                                          saco = (args.saco,False, None, None, None),
                                          execution = 0, 
                                          cname = inp["c_name"],
                                          hashes = function_names,
                                          debug = args.debug,
                                          evm_version = evm_version_modifications,
                                          cfile = args.cfile,
                                          svc=svc_opt,
                                          go = args.goto,
                                          opt= opt_info, 
                                          mem_analysis = args.mem_analysis, 
                                          compact_clones = args.compact_clones)

        try:
            c_source = inp['c_source']
            c_name = inp['c_name']
            results[c_source][c_name] = result
        except:
            results[c_source] = {c_name: result}
        
    except Exception as e:
        traceback.print_exc()

        if len(e.args)>1:
            return_code = e.args[1]
        else:
            return_code = 1

        result = []
            #return_code = -1
        print ("\n Exception: "+str(return_code)+"\n")
        exit_code = return_code
            
    return results, exit_code

def analyze_solidity(input_type='solidity'):
    global args

    x = dtimer()
    is_runtime = not(args.init)

    compiler_opt = {}
    compiler_opt["optimize"] = args.optimize_run
    compiler_opt["no-yul"] = args.no_yul_opt
    compiler_opt["runs"] = args.run
    compiler_opt["via-ir"] = args.via_ir

    if args.solc_compiler: 
        set_solc_executable(args.solc_compiler)

    if input_type == 'solidity':
        print(f"Args = {args}")
        helper = InputHelper(InputHelper.SOLIDITY, 
                             source=args.source,
                             evm = args.evm,
                             runtime=is_runtime,
                             opt_options = compiler_opt, solc_compiler = args.solc_compiler)
    elif input_type == 'standard_json':
        helper = InputHelper(InputHelper.STANDARD_JSON, source=args.source,evm=args.evm, allow_paths=args.allow_paths)
    elif input_type == 'standard_json_output':
        helper = InputHelper(InputHelper.STANDARD_JSON_OUTPUT, source=args.source,evm=args.evm)
    inputs = helper.get_inputs()

    

    solc_version = helper.get_solidity_version()

    hashes = process_hashes(args.source,solc_version)

    global_params_ethir.costabs_path = global_params_ethir.tmp_path+helper.aux_path
    
    y = dtimer()
    print("*************************************************************")
    print("Compilation time: "+str(y-x)+"s")
    print("*************************************************************")

    if check_optimize_dependencies():
        i = 0
        found = False
        while(i<len(inputs) and (not found)):
            if inputs[i]["c_name"]==args.contract_name:
                inp = inputs[i]
                found = True
            i+=1
        results, exit_code = run_solidity_analysis_optimized(inp,hashes)
    else:
        results, exit_code = run_solidity_analysis(inputs,hashes)
        helper.rm_tmp_files()

    if global_params_ethir.WEB:
        six.print_(json.dumps(results))
    return exit_code

def hashes_cond(args):
    return args.hashes and (not args.disassembly and not args.evm)

def process_name(fname):
    name = str(fname)
    pos = name.find("(")
    if pos!=-1 and name[pos+1]==")":
        new_name = name[:pos]
    else :
        new_name = name.replace("(",":").replace(")","")

    return new_name

def process_fields(src_map):
    fields = {}
    field_names = args.fields.split(",") 
    for f in field_names:
        t = src_map.get_type_state_variable(f)
        if t.find("contract ")!=-1:
            t = t.split("contract")[-1]
        t = t.strip()
        fields[f] = t
    return fields

def generate_saco_hashes_file(dicc):
    with open(global_params_ethir.costabs_path+"/costabs/"+"solidity_functions.txt", "w") as f:
        for name in dicc:
            f_names = dicc[name].values()
            cf_names1 = list(map(process_name,f_names))
            cf_names = list(map(lambda x: name+"."+x,cf_names1))
            new_names = "\n".join(cf_names)+"\n" if cf_names!=[] else ""
            f.write(new_names)
    f.close()

def main():
    # TODO: Implement -o switch.
    
    global args

    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)

    group.add_argument("-s",  "--source",    type=str, help="local source file name. Solidity by default. Use -b to process evm instead. Use stdin to read from stdin.")
    
    # parser.add_argument("--version", action="version", version="EthIR version 1.0.7 - Commonwealth")
    parser.add_argument("-glt", "--global-timeout", help="Timeout for symbolic execution", action="store", dest="global_timeout", type=int)
    parser.add_argument( "-e",   "--evm",                    help="Do not remove the .evm file.", action="store_true")
    parser.add_argument( "-b",   "--bytecode",               help="read bytecode in source instead of solidity file", action="store_true")
    parser.add_argument( "-standard-json", "--standard-json",                 help="read standard-json file instead of solidity file", action="store_true")
    parser.add_argument( "-allow-paths", "--allow-paths",                 help="Allow a given path for imports in standard-json-mode", action="store", default = "")

    #Added by Pablo Gordillo
    parser.add_argument( "-disasm", "--disassembly",        help="Consider a dissasembly evm file directly", action="store_true")
    parser.add_argument( "-in", "--init",        help="Consider the initialization of the fields", action="store_true")
    parser.add_argument( "-d", "--debug",                   help="Display the status of the stack after each opcode", action = "store_true")
    parser.add_argument( "-cfg", "--control-flow-graph",    help="Store the CFG", choices=["normal","memory", "storage", "all"])
    # parser.add_argument( "-mcfg", "--memory-control-flow-graph",    help="Store the Memory CFG", action="store_true")
    # parser.add_argument( "-eop", "--evm-opcodes",           help="Include the EVM opcodes in the translation", action="store_true")
    parser.add_argument( "-saco", "--saco",                 help="Translate EthIR RBR to SACO RBR", action="store_true")
    parser.add_argument( "-gastap", "--gastap",                 help="Calls to GASTAP directly from EthIR", choices = ["op","mem","all"])    #action="store_true")
    parser.add_argument( "-c", "--cfile",                 help="Translate EthIR RBR to SACO RBR", choices = ["int","uint","uint256"])
    parser.add_argument("-v", "--verify",             help="Applies abstraction depending on the verifier (CPAchecker, VeryMax or SeaHorn). Use with flag -c", choices = ["cpa","verymax","seahorn"])
    parser.add_argument("-i", "--invalid",             help="Translate the specified invalid bytecodes into SV-COMP error labels. Use with flag -c", choices = ["array","div0","all"])
    parser.add_argument("-g", "--goto",             help="Transform recursive rules into iterative rules using gotos. Use with flag -c", choices = ["iterative","recursive"])
    parser.add_argument("-a", "--args",             help="Transform of the parameters of the rules. Use with flag -c", choices = ["local","global","mix"])
    parser.add_argument("-mem", "--mem_interval",             help="Translate the memory into an interval representation. Use with flag -c", choices = ["length","arrays"], default="length")
    parser.add_argument("-storage", "--storage_arrays", help="Translate storage arrays into arrays representation. Use with flag -c", choices = ["length","arrays"], default="length")
    parser.add_argument("-cexec", "--c-executable", help="Generate a C program that can be executed. Use with flag -c",action = "store_true")
    parser.add_argument("-opt", "--optimize",             help="Fields to be optimized by Gasol", action="store_true")
    parser.add_argument("-optimize-run", "--optimize-run",             help="Enable optimization flag in solc compiler", action="store_true")
    parser.add_argument("-run", "--run",             help="Set for how many contract runs to optimize (200 by default if --optimize-run)", default=-1,action="store",type=int)
    parser.add_argument("-no-yul-opt", "--no-yul-opt",             help="Disable yul optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument("-via-ir", "--via-ir",             help="via-ir optimization in solc compiler (when possible)", action="store_true")
    parser.add_argument("-f", "--fields", type=str, help="Fields to be optimized by Gasol")
    parser.add_argument("-cname", "--contract_name", type=str, help="Name of the contract that is going to be optimized")
    parser.add_argument("-bl", "--block", type=str, help="block to be optimized")
    parser.add_argument( "-hashes", "--hashes",             help="Generate a file that contains the functions of the solidity file", action="store_true")
    parser.add_argument( "-out", "--out",             help="Generate a file that contains the functions of the solidity file", action="store", dest="path_out",type=str)
    parser.add_argument("-mem-analysis", "--mem-analysis",             help="Executes memory analysis. baseref runs the basic analysis where it only identifies the base refences. Offset runs baseref+offset option", choices = ["baseref","offset"])
    parser.add_argument("-storage-analysis", "--storage-analysis",             help="Executes storage analysis", action="store_true")
    parser.add_argument("-sra-analysis", "--sra-analysis",             help="Executes storage analysis", choices = ["nopaths","allpaths","smtsolver"])
    parser.add_argument("-compact-clones", "--compact-clones",             help="Intersect blocks cloned before invoking GASOL superoptimizer", action="store_true")
    parser.add_argument("-smt-stores","--smt-stores", help="SMT function to be executed for the cost bound to an sstore", choices = ["complete","final"], default= "final")
    parser.add_argument("-gastap-timeout","--gastap-timeout", help="Gastap invocation timeout", default= "60")
    parser.add_argument("-initial-storage","--initial-storage", help="Initial value of storage locations for gas estimation",  type=str , default= "zero")
    parser.add_argument("-sto-nonzero","--sto-nonzero", help="Variables that are set to nonzero values initially for saco and storage analysis",  type=str , default= "")
    parser.add_argument("-solc-compiler","--solc-compiler", help="Executable path of the solc compiler to be used",  type=str)
    parser.add_argument("-ub-filter","--ub-filter", help="String used to select the UBs to be computed",  type=str, dest="ub_filter", default = "")

    args = parser.parse_args()
    # if args.root_path:
    #     if args.root_path[-1] != '/':
    #         args.root_path += '/'
    # else:
    #     args.root_path = ""

    # if args.timeout:
    #     global_params.TIMEOUT = args.timeout

    # if args.verbose:
    #     logging.basicConfig(level=logging.DEBUG)
    # else:
    #     logging.basicConfig(level=logging.INFO)
    
    global_params_ethir.PRINT_PATHS = 0 #1 if args.paths else 0
    global_params_ethir.REPORT_MODE = 0 #1  if args.report else 0
    global_params_ethir.USE_GLOBAL_BLOCKCHAIN = 0#1 if args.globalblockchain else 0
    global_params_ethir.INPUT_STATE = 0#1 if args.state else 0
    global_params_ethir.WEB = 0#1 if args.web else 0
    global_params_ethir.STORE_RESULT = 0#1 if args.json else 0
    global_params_ethir.CHECK_ASSERTIONS = 0#1 if args.assertion else 0
    global_params_ethir.DEBUG_MODE = 0#1 if args.debug else 0
    global_params_ethir.GENERATE_TEST_CASES = 0#1 if args.generate_test_cases else 0
    global_params_ethir.PARALLEL = 0#1 if args.parallel else 0

    # if args.depth_limit:
    #     global_params.DEPTH_LIMIT = args.depth_limit
    # # if args.gas_limit:
    # #     global_params.GAS_LIMIT = args.gas_limit
    # if args.loop_limit:
    #     global_params.LOOP_LIMIT = args.loop_limit
    # if global_params.WEB:
    #     if args.global_timeout and args.global_timeout < global_params.GLOBAL_TIMEOUT:
    #         global_params.GLOBAL_TIMEOUT = args.global_timeout
    # else:
    #     if args.global_timeout:
    #         global_params.GLOBAL_TIMEOUT = args.global_timeout


    if args.path_out:
        global_params_ethir.tmp_path = args.path_out
        #global_params_ethir.costabs_path = global_params_ethir.tmp_path+"costabs/"

        
    if not has_dependencies_installed():
        return

    # if args.remote_URL:
    #     r = requests.get(args.remote_URL)
    #     code = r.text
    #     filename = "remote_contract.evm" if args.bytecode else "remote_contract.sol"
    #     args.source = filename
    #     with open(filename, 'w') as f:
    #         f.write(code)

    # exit_code = 0

    #clean_dir()

    #Added by Pablo Gordillo
    if args.disassembly:
        exit_code = analyze_disasm_bytecode()
    elif args.bytecode:
        exit_code = analyze_bytecode()
    elif args.standard_json:
        valid = check_standard_json_input()
        if not valid:
            print("[ERROR]: Optimization options has to be specified in standard-json-format")
            exit(1)
        exit_code = analyze_solidity(input_type='standard_json')
    # elif args.standard_json_output:
    #     exit_code = analyze_solidity(input_type='standard_json_output')
    elif hashes_cond(args):

        is_runtime = not(args.init)

        compiler_opt = {}
        compiler_opt["optimize"] = args.optimize_run
        compiler_opt["no-yul"] = args.no_yul_opt
        compiler_opt["runs"] = args.run
        compiler_opt["via-ir"] = args.via_ir
        helper = InputHelper(InputHelper.SOLIDITY, source=args.source,evm =args.evm,runtime=is_runtime,opt_options = compiler_opt)
        solc_version = helper.get_solidity_version()
                
        mp = process_hashes(args.source, solc_version)
        generate_saco_hashes_file(mp)
        exit_code = 0
        
    else:
        exit_code = analyze_solidity()
    six.print_("The files generated by EthIR are stored in the following directory: "+global_params_ethir.costabs_path)

    exit(exit_code)


def get_memory_opt_blocks():
    return symExec.get_memory_opt_block()
    

if __name__ == '__main__':
    main()
