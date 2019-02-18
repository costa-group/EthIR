import shlex
import subprocess
import os
import csv
import sys
from shutil import copyfile

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
        l = name.split("_saco")[0]
        config_name = l+".config"
        f = open(config_name,"r")
        signature = f.readlines()
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),signature)
        return blocks
    else:
        return -1

def saco(direc, block):
    ub_m = "Timeout"
    ub_g = "Timeout"
    r = {}
    
    FNULL = open(os.devnull, 'w')
    cmd = "/home/costa/Systems/costa/costabs/src/interfaces/shell/costabs "+direc+" -entries block"+block+" -cost_model gas -ethir yes"
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE,stderr=FNULL, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    size_time = 0
    crs_time = 0
    pubs_time = 0
    r["memory"]=(size_time,crs_time,pubs_time)
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
    if "result_all.csv" not in files:
        f = open("result_all.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["File Name", "Contract Name", "Function Name", "Memory Bound", "Gas Bound"])
        f.close()

def check_timefile_exist():
    files = os.listdir(".")
    if "time_all" not in files:
        f = open("time_all.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["Contract Name","Function Name","CFG Gen(ms)","RBR Gen(ms)","Size Analysis(ms)", "CRS Memory(ms)", "PUBS Memory(ms)", "CRS Opcodes(ms)","PUBS Opcodes(ms)"])
        f.close()
        
def get_rbr_files():
    f = open("result_all.csv","r")
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

def get_times_ethir(cfile):
    files = os.listdir("/home/pabgordi/ethereum/gastap/ethir_OK/"+cfile+"/")
    if "times.csv" in files:
        f = open("/home/pabgordi/ethereum/gastap/ethir_OK/"+cfile+"/times.csv","r")
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

    f = open("time_all.csv","a")
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
    
    f = open("time_all.csv","a")
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

    if exp.find("timeout")!=-1 or exp.find("Timeout")!=-1:
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

    if exp.find("timeout")!=-1 or exp.find("Timeout")!=-1:
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

def generate_report(index = None):
    if index == None:
        f = open("report_all.txt","w")
    else:
        f = open("report_all_"+str(index)+".txt","w")
        
    total_time = oyente+ethir+size_analysis+crs_mem+crs_gas+pubs_mem+pubs_gas
    total_time = total_time/1000
    
    f.write("Artifact Results\n")

    f.write("RESULTS\n")
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
    f.write("\t CFG Generation (OYENTE*):"+str(oyente/1000)+"s\n")
    f.write("\t RBR Generation (EthIR*):"+str(ethir/1000)+"s\n")
    f.write("\t Size Analysis (SACO):"+str(size_analysis/1000)+"s\n")
    f.write("\t Generation of gas equations (Memory):"+str(crs_mem/1000)+"s\n")
    f.write("\t Generation of gas equations (Opcodes):"+str(crs_gas/1000)+"s\n")
    f.write("\t Solving of gas equations (PUBS)(Memory):"+str(pubs_mem/1000)+"s\n")
    f.write("\t Solving of gas equations (PUBS)(Opcodes):"+str(pubs_gas/1000)+"s\n")
    f.write("\t Total time GASTAP:"+str(total_time)+"s\n")

    f.close()
def compute_contract(cfile):
    global contracts
    global functions
#    cfile = sys.argv[1] #"four_functions.sol"
    
    f = open("result_all.csv","a")
    fp = csv.writer(f, delimiter=',')

    files = os.listdir("/home/pabgordi/ethereum/gastap/ethir_OK/"+cfile+"/")
    files_rbr = filter(lambda x: x.split("_")[-1]=="saco.rbr",files)

    contracts = contracts + len(files_rbr)
    
    t_ethir = get_times_ethir(cfile)
    i = 0
    for rbr in files_rbr:
        d = "/home/pabgordi/ethereum/gastap/ethir_OK/"+cfile+"/"+rbr
        v =  get_num_blocks(d)
        functions = functions+len(v)
        if t_ethir!=-1:
            write_times_ethir(rbr,t_ethir[i])
        if v != -1:
            print "\nExecuting GASTAP on "+rbr
            for b in v:
                print "Analyzing "+str(b[0])
                times, result = saco(d,b[1])
                statistics(cfile,rbr,b,result,fp)
                write_time(b[0],times)
        i = i+1

    f.close()

def copy_files(index):
    path = "/home/pabgordi/ethereum/EthIR/ethir/test/gastap/"
    copyfile(path+"time_all.csv",path+"time_all"+str(index)+".csv")
    copyfile(path+"result_all.csv",path+"result_all"+str(index)+".csv")
    
if __name__ == "__main__":
    global files

    init_globals()
    
    l = os.listdir(".")
    if "time_all.csv" in l:
        os.remove("time_all.csv")
    if "result_all.csv" in l:
        os.remove("result_all.csv")
    if "report_all.txt" in l:
        os.remove("report_all.txt")

    check_csvfile_exist()
    check_timefile_exist()
    
    path = "/home/pabgordi/ethereum/gastap/ethir_OK/"
    sol_dir = os.listdir(path)
#    ethir_path = "/home/tacas19/EthIR/ethir/"	
#    sol_files = os.listdir("/home/tacas19/Desktop/examples/tacas19/")
    files = len(sol_dir)

    index = 0
    i = 0
    for f in sol_dir:

        print "\nAnalyzing file "+str(f)
        # cmd = "python "+ethir_path+"oyente-ethir.py -s"+path+str(f)+" -cfg -saco -eop"
        # result = subprocess.Popen([cmd], stdout = subprocess.PIPE, shell = True)
        # a = result.communicate()[0].decode()
        # print a
        #python ../oyente-ethir.py -s ../../examples/code/prueba/$contract -saco -eop -cfg
        compute_contract(f)
        i = i+1
        if i%500 == 0:
            generate_report(index)
            copy_files(index)
            index = index+1
            
    generate_report()
            
