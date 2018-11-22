import shlex
import subprocess
import os
import csv
import sys

def init_globals():
    global oyente
    oyente = 0
    global ethir
    ethir = 0
    global size_analysis
    size_analysis = 0
    global crs_mem
    crs_mem = 0
    global pubs_mem
    pubs_mem = 0
    global crs_gas
    crs_gas = 0
    global pubs_gas
    pubs_gas = 0
    
    global max_error_mem
    max_error_mem = 0
    global no_rf_mem
    no_rf_mem = 0
    global cover_point_mem
    cover_point_mem = 0
    global constant_mem
    constant_mem = 0
    global param_mem
    param_mem = 0
    global timeout_mem
    timeout_mem = 0

    global max_error_gas
    max_error_gas = 0
    global no_rf_gas
    no_rf_gas = 0
    global cover_point_gas
    cover_point_gas = 0
    global constant_gas
    constant_gas = 0
    global param_gas
    param_gas = 0
    global timeout_gas
    timeout_gas = 0

    global functions
    functions = 0
    global files
    files = 0
    global contracts
    contracts = 0

def run_command(cmd):
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen([cmd], stdout=subprocess.PIPE, stderr=FNULL)
    return solc_p.communicate()[0].decode()


def get_num_blocks(name):
    if name.split(".")[1] == "rbr":
        l = name.split("_")[0]
        config_name = l+".config"
        f = open(config_name,"r")
        signature = f.readlines()
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),signature)
        return blocks
    else:
        return -1

def saco(name, block):
    ub_m = "Oyente fails"
    ub_g = "Oyente fails"
    r = {}
    
    cmd = "/home/pablo/Systems/costa/costabs/src/interfaces/shell/costabs "+"/tmp/costabs/"+name+" -entries block"+block+" -cost_model gas -ethir yes"
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    size_time = 0
    crs_time = 0
    pubs_time = 0
    for l in lines:
        if l != "":
            words = l.split()

            if words[0] == "GASTAP" and words[1] == "Gas":
                r["memory"]=(size_time,crs_time,pubs_time)
            elif words[0] == "Size" and words[1] == "analysis":
                size_time = words[-2]
            elif words[0] == "Cost" and words[1] == "equations":
                crs_time = words[-2]
            elif "PUBS" in words:
                pubs_time = words[-2]
            elif words[0] == "UB" and words[2] == "memory":
                ub_m = l
            elif words[0] == "UB" and words[2] != "memory":
                ub_g = l
    r["gas"] = (size_time,crs_time,pubs_time)
    return r,(ub_m,ub_g)
    
def check_csvfile_exist():
    files = os.listdir(".")
    if "result_subset.csv" not in files:
        f = open("result_subset.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["File Name", "Contract Name", "Function Name", "Memory Bound", "Gas Bound"])
        f.close()

def check_timefile_exist():
    files = os.listdir(".")
    if "times_subset" not in files:
        f = open("times_subset.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["Contract Name","Function Name","CFG Gen(ms)","RBR Gen(ms)","Size Analysis(ms)", "CRS Memory(ms)", "PUBS Memory(ms)", "CRS Opcodes(ms)","PUBS Opcodes(ms)"])
        f.close()
        
def get_rbr_files():
    f = open("result_subset.csv","r")
    lines = f.readlines()[1:]
    contract_files = map(lambda x: (x.split(",")[0].strip(),x.split(",")[2].strip()), lines)
    f.close()
    return contract_files

def statistics(contract_file,name,block,bound,fp):
    bound_m = bound[0]
    bound_g = bound[1]

    get_ub_type_mem(bound_m)
    get_ub_type_gas(bound_g)
    
    if bound_m == "":
        ub_m = "No"
    elif bound_m.find("maximize_failed")!=-1:
        ub_m = "maximize_failed"
    elif bound_m.find("unknown")!=-1:
        ub_m = "maximize_failed"    
    else:
        ub_m = bound_m

    if bound_g == "":
        ub_g = "No"
    elif bound_g.find("maximize_failed")!=-1:
        ub_g = "maximize_failed"
    elif bound_g.find("unknown")!=-1:
        ub_g = "maximize_failed"
    else:
        ub_g = bound_g
        
    fp.writerow([contract_file, name, block[0], ub_m, ub_g])

def get_times_ethir():
    files = os.listdir("/tmp/costabs/")
    if "times.csv" in files:
        f = open("/tmp/costabs/times.csv","r")
        i = 0
        lines = f.readlines()
        t = {}
        for l in lines:
            elements = l.split(",")
            t[i]=(elements[1],elements[3])
            i=i+1
    else:
        t = -1
    return t

def write_times_ethir(name,time):
    global oyente
    global ethir

    f = open("times_subset.csv","a")
    fp = csv.writer(f, delimiter=',')
    cfg = float(time[0])*1000
    rbr = float(time[1])*1000

    oyente = oyente+cfg
    ethir = ethir+rbr
    
    fp.writerow([name," ",cfg,rbr," "," "," "," "," "])
    f.close()

def write_time(function,times):
    global size_analysis
    global crs_mem
    global pubs_mem
    global crs_gas
    global pubs_gas
    
    f = open("times_subset.csv","a")
    fp = csv.writer(f, delimiter=',')
    memory = times["memory"]
    gas = times["gas"]
    
    size_analysis = size_analysis+float(gas[0])
    crs_mem = crs_mem+float(memory[1])
    pubs_mem = pubs_mem+float(memory[2])
    crs_gas = crs_gas+float(gas[1])
    pubs_gas = pubs_gas+float(gas[2])
    
    fp.writerow([" ",function ," "," ",gas[0],memory[1],memory[2],gas[1],gas[2]])
    f.close()

def get_ub_type_mem(ub):
    global max_error_mem
    global no_rf_mem
    global cover_point_mem
    global constant_mem
    global param_mem
    global timeout_mem

    exp = ub.split(":")[-1].strip()

    if exp.find("timeout")!=-1:
        timeout_mem = timeout_mem+1
    elif exp.find("maximize_failed")!=-1:
        max_error_mem = max_error_mem+1
    elif exp.find("no_rf")!=-1:
        no_rf_mem = no_rf_mem +1
    elif exp.find("cover_point")!=-1:
        cover_point_mem = cover_point_mem+1
    elif exp.find("nat(")!=-1 and exp.find("*")!=-1:
        param_mem = param_mem+1
    else:
        constant_mem = constant_mem+1

def get_ub_type_gas(ub):
    global max_error_gas
    global no_rf_gas
    global cover_point_gas
    global constant_gas
    global param_gas
    global timeout_gas

    exp = ub.split(":")[-1].strip()

    if exp.find("timeout")!=-1:
        timeout_gas = timeout_gas+1
    elif exp.find("maximize_failed")!=-1:
        max_error_gas = max_error_gas+1
    elif exp.find("no_rf")!=-1:
        no_rf_gas = no_rf_gas +1
    elif exp.find("cover_point")!=-1:
        cover_point_gas = cover_point_gas+1
    elif exp.find("nat(")!=-1 and exp.find("*")!=-1:
        param_gas = param_gas+1
    else:
        constant_gas = constant_gas+1

def generate_report():
    f = open("result.txt","w")
    total_time = oyente+ethir+size_analysis+crs_mem+crs_gas+pubs_mem+pubs_gas
    total_time = total_time/1000
    
    f.write("TACAS19 Artifact\n")

    f.write("RESULTS\n")
    f.write("\tFiles analyzed: "+str(files)+"\n")
    f.write("\tSmart Contracts analyzed: "+str(contracts)+"\n")
    f.write("\tPublic functions analyzed: "+str(functions)+"\n\n")

    f.write("MEMORY GAS RESULTS\n")
    f.write("\tConstant bounds:"+str(constant_mem)+"\n")
    f.write("\tParametric bounds:"+str(param_mem)+"\n")
    f.write("\tTime out:"+str(timeout_mem)+"\n")
    f.write("\tFinite gas bound (maximization error):"+str(max_error_mem)+"\n")
    f.write("\tTermination unknown (ranking function error):"+str(no_rf_mem)+"\n")
    f.write("\tComplex control flow (cover point error):"+str(cover_point_mem)+"\n")

    f.write("OPCODE GAS RESULTS\n")
    f.write("\tConstant bounds:"+str(constant_gas)+"\n")
    f.write("\tParametric bounds:"+str(param_gas)+"\n")
    f.write("\tTime out:"+str(timeout_gas)+"\n")
    f.write("\tFinite gas bound (maximization error):"+str(max_error_gas)+"\n")
    f.write("\tTermination unknown (ranking function error):"+str(no_rf_gas)+"\n")
    f.write("\tComplex control flow (cover point error):"+str(cover_point_gas)+"\n")

    f.write("TIME RESULTS\n")
    f.write("\t CFG Generation (OYENTE*):"+str(oyente/1000)+"\n")
    f.write("\t RBR Generation (EthIR*):"+str(ethir/1000)+"\n")
    f.write("\t Size Analysis (SACO):"+str(size_analysis/1000)+"\n")
    f.write("\t Generation of gas equations (Memory):"+str(crs_mem/1000)+"\n")
    f.write("\t Generation of gas equations (Opcodes):"+str(crs_gas/1000)+"\n")
    f.write("\t Solving of gas equations (PUBS)(Memory):"+str(pubs_mem/1000)+"\n")
    f.write("\t Solving of gas equations (PUBS)(Opcodes):"+str(pubs_gas/1000)+"\n")
    f.write("\t Total time GASTAP:"+str(total_time)+"\n")
    
def compute_contract(cfile):
    global contracts
    global functions
#    cfile = sys.argv[1] #"four_functions.sol"
    
    f = open("result_subset.csv","a")
    fp = csv.writer(f, delimiter=',')

    files = os.listdir("/tmp/costabs")
    files_rbr = filter(lambda x: x.split("_")[-1]=="saco.rbr",files)

    contracts = contracts + len(files_rbr)
    
    t_ethir = get_times_ethir()
    i = 0
    for rbr in files_rbr:
        d = "/tmp/costabs/"+rbr
        v =  get_num_blocks(d)
        functions = functions+len(v)
        if t_ethir!=-1:
            write_times_ethir(rbr,t_ethir[i])
        if v != -1:
            print "Applying GASTAP to "+rbr
            for b in v:
                print "Analyzing "+str(b[0])
                times, result = saco(rbr,b[1])
                statistics(cfile,rbr,b,result,fp)
                write_time(b[0],times)
        i = i+1

    f.close()

if __name__ == "__main__":
    global files
    
    dir_examples = sys.argv[1]
    init_globals()
    
    l = os.listdir(".")
    if "times_subset.csv" in l:
        os.remove("times_subset.csv")
    if "result_subset.csv" in l:
        os.remove("result_subset.csv")
    if "report_subset.csv" in l:
        os.remove("report_subset.txt")

    check_csvfile_exist()
    check_timefile_exist()
    
    path = "/home/pablo/Repositorios/ethereum/oyente-cost/examples/"+dir_examples
    sol_files = os.listdir(path)
    files = len(sol_files)
    
    for f in sol_files:

        print "\nAnalyzing file "+str(f)
        cmd = "python /home/pablo/Repositorios/ethereum/oyente-cost/ethir/oyente-ethir.py -s"+path+str(f)+" -cfg -saco -eop"
        result = subprocess.Popen([cmd], stdout = subprocess.PIPE, shell = True)
        a = result.communicate()[0].decode()
        print a
        #python ../oyente-ethir.py -s ../../examples/code/prueba/$contract -saco -eop -cfg
        compute_contract(f)

    generate_report()
            
