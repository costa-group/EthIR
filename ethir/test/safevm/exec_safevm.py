import shlex
import subprocess
import os
import csv
import sys

global costabs_path
costabs_path = "/tmp/costabs/"

global cpa_path
cpa_path = "/home/pablo/Descargas/CPAchecker-1.8-unix/scripts/cpa.sh"

global ethir_path
ethir_path = "/home/pablo/Repositorios/ethereum/oyente-cost/ethir/"
global func_verified
func_verified = []


def run_command(cmd):
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen([cmd], stdout=subprocess.PIPE, stderr=FNULL)
    return solc_p.communicate()[0].decode()


def exec_ethir(options):
    evm = False
    gotos = False

    FNULL = open(os.devnull, 'w')
    
    sol = options.get("sol",False)
    if not sol:
        sol = options.get("evm")
        evm = True

    invalid_op = options.get("i","all")
    
    if evm:
        cmd = "-b "
    else:
        cmd = ""

    cmd = cmd+"-c -v cpa -i "+invalid_op

    cmd = "python "+ethir_path+"oyente-ethir.py -s "+sol+" "+cmd
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE, shell = True)
    a = result.communicate()[0].decode()
    print a

def get_num_blocks(name):
    config_name = name+".config"
    if config_name in os.listdir("/tmp/costabs/"):
        f = open(costabs_path+config_name,"r")
        signature = f.readlines()
        functions2verify = filter(lambda x: x.split(";")[2].strip()[:-1] == "YES",signature)
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),functions2verify)
        return blocks
    else:
        return -1

def get_all_num_blocks(name):
    config_name = name+".config"
    if config_name in os.listdir("/tmp/costabs/"):
        f = open(costabs_path+config_name,"r")
        signature = f.readlines()
 #       functions2verify = filter(lambda x: x.split(";")[2].strip()[:-1] == "YES",signature)
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),signature)
        return blocks
    else:
        return -1
    
def cpa(name, block):
    
    FNULL = open(os.devnull, 'w')
    cmd = cpa_path + " -svcomp19 -noout "+ costabs_path + name + ".c -entryfunction block"+str(block)
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE,stderr = FNULL, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    for l in lines:
        if l.startswith("Verification result:"):
            result = l

    if result.split(".")[0].find("TRUE")==-1:
        func_verified.append(block)
        
    return result.split(".")[0]


def flags_parser(args):
    cname = args[0]
    options = {}
    if cname == "-s":
        if args[1].split(".")[-1].strip() != "sol":
            print "ERROR: The file specified does not contain a .sol extension."
            print "In order to analyze a solidity file, include the flag -s."
            return
        else:
            options["sol"] = args[1]
            flags = args[2:]
    else:
        if cname.split(".")[-1].strip() != "evm":
            print "ERROR: The file specified does not contain a .evm extension."
            return
        else:
            options["evm"] = cname
            flags = args[1:]
    i = 0
    while(i < len(flags)): 
        fl = flags[i]

        if fl == "-i":
            try:
                if flags[i+1] not in ["all","div0","array"]:
                    print "ERROR: Flag -i takes value all, div0 or array"
                    return
                options["i"] = flags[i+1]
                i = i+2
            except:
                print "ERROR: Flag -i takes value all, div0 or array"
                return
            
        elif fl == "-c":
            try:
                if flags[i+1] == "":
                    print "ERROR: You have to specify a contract name"
                    return
                options["cname"]= flags[i+1]
                i = i+2
            except:
                 print "ERROR: You have to specify a contract name"
                 return
        elif fl == "-f":
            try:
                if flags[i+1] == "":
                    print "ERROR: You have to specify a function name"
                    return
                options["fname"]= flags[i+1]
                i = i+2
            except:
                 print "ERROR: You have to specify a function name"
                 return
        else:
            print "Incorrect flag."
            print "The format required has the following structure:"
            print "./safevm SolidityFile [-i {all,div0,array}] [-c ContractName] [-f FunctionName]"
            return
    return options

def check_dependencies(options):
    evm = options.get("evm",False)
    if evm:
        cname = options.get("cname",False)
        fname = options.get("fname",False)
        if cname or fname:
            print "WARNING: SAFEVM will analyze all the functions of the EVM File specified"

    cname = options.get("cname",False)
    fname = options.get("fname",False)
    if fname != False:
        r = cname != False
        if not r:
            print "ERROR: Specify the name of the contract."
        return r
    else:
        return True

def check_contract_file(cname):
    if "costabs" in os.listdir("/tmp/"):
        files = os.listdir(costabs_path)
        decompilation_correct = cname+str(".c") in files
        return decompilation_correct

    else:
        return False
    
def exec_all_functions(cname,invalid_type):
    r = check_contract_file(cname)

    if not r:
        print "ERROR: The contract "+cname+" does not exist."
    else:
        blocks = get_num_blocks(cname)
        if blocks == []:
            print "There is not any INVALID pattern to be verified in the contract "+cname+".\n"
        else:
            for b in blocks:
                print "Analyzing "+str(b[0])+". INVALID option: "+invalid_type
                result_cpa = cpa(cname,b[1])
                print "\t"+result_cpa+"\n"

            if func_verified == []:
                if invalid_type == "all":
                    print "All functions verified correctly."
                elif invalid_type == "array":
                    print "Array accesses verified correctly for all public functions defined in "+str(cname)+"."
                elif invalid_type == "div0":
                    print "Divisions verified correctly for all public functions defined in "+str(cname)+"."

def exec_all_contracts(invalid_option):
    files = os.listdir(costabs_path)
    c_files = filter(lambda x: x[::-1].startswith("c."),files)
    for f in c_files:
        print "\n******************************************"
        print "Contract "+f+".\n"
        print "******************************************"
        exec_all_functions(f[:-2],invalid_option)

def exec_function(contract,function,invalid_type):
    r = check_contract_file(contract)
    if not r:
        print "ERROR: The contract "+contract+" does not exist."
    else:
        blocks = get_all_num_blocks(contract)
        is_func = filter(lambda x: x[0].startswith(function+"("),blocks)
        if is_func == []:
            print "ERROR: Function "+function+" is not defined in the contract "+contract+"."
        else:
            blocks = get_num_blocks(contract)
        if blocks == []:
            print "There is not any INVALID pattern to be verified in the contract "+contract+".\n"
        else:
            bs = filter(lambda x: x[0].startswith(function+"("),blocks)
            if bs == []:
                print "Function "+function+" does not contain INVALID patterns."
            else:
                print "Analyzing "+function+". INVALID option: "+invalid_type
                results_cpa = cpa(contract,bs[0][1])
                print "\t"+results_cpa+"\n"
            
def exec_cpa(contract,function,invalid_option):
    if contract == "all":
        exec_all_contracts(invalid_option)
    else:
        if function == "all":
            exec_all_functions(contract,invalid_option)
        else:
            exec_function(contract,function,invalid_option)
    
if __name__ == '__main__':
    
    args = sys.argv
    options = flags_parser(args[1:])
    if options != None and check_dependencies(options):
        exec_ethir(options)

        contract = options.get("cname","all")
        function = options.get("fname","all")
        invalid = options.get("i","all")

        exec_cpa(contract,function,invalid)
        

            
    # verifier = sys.argv[2]
    # function = sys.argv[3]
    # options = sys.argv[4]
