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

def get_ub_type_mem(ub):
    global max_error_mem
    global no_rf_mem
    global cover_point_mem
    global constant_mem
    global param_mem
    global timeout_mem

    exp = ub.strip()

    if exp.find("timeout")!=-1 or exp.find("Timeout")!=-1:
        timeout_mem = timeout_mem+1
    elif exp.find("maximize_failed")!=-1 or exp.find("unknown")!=-1:
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

    exp = ub.strip()

    if exp.find("timeout")!=-1 or exp.find("Timeout")!=-1:
        timeout_gas = timeout_gas+1
    elif exp.find("maximize_failed")!=-1 or exp.find("unknown")!=-1:
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
    f = open("report_all.txt","w")
    total_time = oyente+ethir+size_analysis+crs_mem+crs_gas+pubs_mem+pubs_gas
    total_time = total_time/1000
    
    f.write("RESULTS\n")
    f.write("\tSolidity files analyzed: "+str(files)+"\n")
    f.write("\tContracts analyzed: "+str(contracts)+"\n")
    f.write("\tPublic functions analyzed: "+str(functions)+"\n\n")

    f.write("MEMORY GAS RESULTS\n")
    f.write("\tConstant bounds:"+str(constant_mem)+"\n")
    f.write("\tParametric bounds:"+str(param_mem)+"\n")
    f.write("\tFinite gas bound (maximization error):"+str(max_error_mem)+"\n")
    f.write("\tTermination unknown (ranking function error):"+str(no_rf_mem)+"\n")
    f.write("\tAnalysis Time out:"+str(timeout_mem)+"\n")
    f.write("\tComplex control flow (cover point error):"+str(cover_point_mem)+"\n")

    f.write("OPCODE GAS RESULTS\n")
    f.write("\tConstant bounds:"+str(constant_gas)+"\n")
    f.write("\tParametric bounds:"+str(param_gas)+"\n")
    f.write("\tFinite gas bound (maximization error):"+str(max_error_gas)+"\n")
    f.write("\tTermination unknown (ranking function error):"+str(no_rf_gas)+"\n")
    f.write("\tAnalysis Time out:"+str(timeout_gas)+"\n")
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

def process_results(lines):
    global timeout_mem
    global timeout_gas
    global size_analysis
    global crs_mem
    global pubs_mem
    global crs_gas
    global pubs_gas

    
    i = 0
    an = 0
    
    gas = False
    mem_ub = False
    gas_ub = False

    while i < len(lines):

        gas = False
        mem_ub = False
        gas_ub = False
        analysis = False

        while i<len(lines) and (lines[i].find("folder")==-1 and lines[i].find("ethir_OK")==-1 and lines[i].find("config")==-1):
            analysis = True
            if lines[i].find("Cost eq")!=-1 and (not gas):
                data = lines[i].split()
                eq_mem_time = int(data[-2])
            
            elif lines[i].find("PUBS")!=-1 and (not gas):
                data = lines[i].split()
                pubs_mem_time = int(data[-2])

            elif lines[i].find("GASTAP Gas Model")!=-1:
                gas = True

            elif lines[i].find("Cost eq")!=-1 and gas:
                data = lines[i].split()
                eq_gas_time = int(data[-2])
            elif lines[i].find("PUBS")!=-1 and gas:
                data = lines[i].split()
                pubs_gas_time = int(data[-2])
            elif lines[i].find("Size")!= -1:
                data = lines[i].split()
                size_time = int(data[-2])
            elif lines[i].find("UB for memory")!=-1:
                data = lines[i].split(":")
                get_ub_type_mem(data[-1])
                mem_ub = True
            elif lines[i].find("UB for block")!=-1:
                data = lines[i].split(" = ")
                get_ub_type_gas(data[-1])
                gas_ub = True
            i = i+1
        
        if analysis:
            an +=1
            if mem_ub and gas_ub:
                crs_mem +=eq_mem_time
                crs_gas +=eq_gas_time
                size_analysis += size_time
                pubs_mem += pubs_mem_time
                pubs_gas += pubs_gas_time

            else:
                if mem_ub:
                    timeout_gas+=1
                    

                else:
                    timeout_mem+=1
                    timeout_gas+=1
        else:
            if lines[i].find("ERROR")!=-1:
                timeout_mem+=1
                timeout_gas+=1
            i = i+1

def process_time_lines(lines):
    global oyente
    global ethir

    for l in lines:
        data = l.split(",")
        oyente+=float(data[1])
        ethir+=float(data[3])
            
def get_time():
    path = "/home/pablo/prueba/ethir_OK/"
    sol_dirs = os.listdir(path)
    for sol_dir in sol_dirs:
        new_path = path+sol_dir+"/"
        f = open(new_path+"times.csv","r")
        lines = f.readlines()
        process_time_lines(lines)
        f.close()
        
if __name__ == "__main__":
    global files
    global contracts
    global functions
    
    init_globals()
    
    l = os.listdir(".")
    if "report_all.txt" in l:
        os.remove("report_all.txt")

    get_time()
        
    path = "/home/pablo/prueba/"
    f = open(path+"outputgastap2.org","r")
    l = f.readlines()
    files = len(filter(lambda x: x.find("folder")!=-1,l))
    contracts = len(filter(lambda x: x.find("config")!=-1,l))
    fun_analyzed = filter(lambda x: x.find("ethir_OK")!=-1,l)
    functions = len(fun_analyzed)

    time = process_results(l)
#    print l
    
    generate_report()
    f.close()
