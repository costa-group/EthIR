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
    if name.split(".")[1] == "rbr":
        l = name.split("_saco")[0]
        config_name = l+".config"
        f = open(config_name,"r")
        signature = f.readlines()
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),signature)
        return blocks
    else:
        return -1

def saco(name, block):
    ub_m = "Timeout"
    ub_g = "Timeout"
    r = {}
    
    FNULL = open(os.devnull, 'w')
    cmd = "/home/tacas19/Systems/costa/costabs/src/interfaces/shell/costabs "+"/tmp/costabs/"+name+" -entries block"+block+" -cost_model gas -ethir yes"
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE,stderr = FNULL, shell = True)
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
    if "result.csv" not in files:
        f = open("result.csv","a")
        fp = csv.writer(f, delimiter=',')
        fp.writerow(["File Name", "Contract Name", "Function Name", "Num Block", "Memory Bound", "Gas Bound"])
        f.close()
        
def statistics(contract_file,name,block,bound,fp):
    bound_m = bound[0]
    bound_g = bound[1]
    
    if bound_m == "":
        ub_m = "No"
    elif bound_m.find("maximize_failed")!=-1:
	ub_m = "maixmize_failed"
    elif bound_m.find("unknown")!=-1:
	ub_m = "maximize_failed"
    else :
        ub_m = bound_m

    if bound_g == "":
        ub_g = "No"
    elif bound_g.find("maximize_failed")!=-1:
	ub_g = "maixmize_failed"
    elif bound_g.find("unknown")!=-1:
	ub_g = "maximize_failed"
    else :
        ub_g = bound_g
    
    fp.write("Function name: "+str(block[0])+"\n\n")
    fp.write("Memory Bound: "+str(ub_m)+"\n\n")
    fp.write("Opcode Bound: "+str(ub_g)+"\n\n")
    fp.write("*********************************\n")   
#fp.writerow([contract_file, name, block[0], block[1], ub_m, ub_g])
    
if __name__ == '__main__':
    
  #  check_csvfile_exist()
    
    f = open("results.txt","w")
    cfile = sys.argv[1]
    name = sys.argv[2]
    #name = "EthereumPot_saco.rbr"
    #cfile = "pot_tacas19.sol"
    d = "/tmp/costabs/"+name
    if name != "cfg":
        v =  get_num_blocks(d)
        if v != -1:
            
            for b in v:
    	    	print "\nExecuting GASTAP for " +str(b[0])		
		times, result = saco(name,b[1])
                statistics(cfile,name,b,result,f)
            # os.rename(dir_cfile+cfile,new_dir+cfile)
                
	print "The results are stored in the file results.txt"
    f.close()
