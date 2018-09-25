import shlex
import subprocess
import os
import csv
import sys

def run_command(cmd):
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen([cmd], stdout=subprocess.PIPE, stderr=FNULL)
    return solc_p.communicate()[0].decode()


def get_num_blocks(name):
    l = name.split("_")[0]
    config_name = l+".config"
    f = open(config_name,"r")
    signature = f.readlines()
    blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()[:-1]),signature)
    return blocks

def saco(name, block):
    r = ""
    
    cmd = "/home/pablo/Systems/costa/costabs/src/interfaces/shell/costabs "+"/tmp/costabs/"+name+" -entries block"+block+" -cost_model gas -ethir yes -backend cofloco"
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    for l in lines:
        if l != "":
            words = l.split()
            if words[0] == "UB":
                r = l
    return r
    
def check_csvfile_exist():
    files = os.listdir(".")
    if "result.csv" not in files:
        f = open("result.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["File Name", "Contract Name", "Function Name", "Num Block", "Bound"])
        f.close()

def get_rbr_files():
    f = open("result.csv","r")
    lines = f.readlines()[1:]
    contract_files = map(lambda x: (x.split(",")[0].strip(),x.split(",")[2].strip()), lines)
    f.close()
    return contract_files

def statistics(contract_file,name,block,bound,fp):
    if bound == "":
        ub = No
    else :
        ub = bound
        
    fp.writerow([contract_file, name, block[0], block[1], ub])
    
if __name__ == '__main__':

    cfile = sys.argv[1] #"four_functions.sol"
    name = sys.argv[2] #"Sum_saco.rbr"
    check_csvfile_exist()

    contract_files = get_rbr_files()

    f = open("result.csv","a")
    fp = csv.writer(f, delimiter=',')

    d = "/tmp/costabs/"+name
    if name != "cfg":
        v =  get_num_blocks(d)

        
        for b in v:
            if (cfile,b[0]) not in contract_files:
                result = saco(name,b[1])
                statistics(cfile,name,b,result,fp)

            else:
                fp.writerow(["ALREADY","ALREADY","","","ALREADY","ALREADY"])
        fp.writerow(["","","","","",""])

    f.close()
