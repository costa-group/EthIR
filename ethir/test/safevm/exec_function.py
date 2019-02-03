import shlex
import subprocess
import os
import csv
import sys

global d
d = "/tmp/costabs/"

global func_verified
func_verified = []

def run_command(cmd):
    FNULL = open(os.devnull, 'w')
    solc_p = subprocess.Popen([cmd], stdout=subprocess.PIPE, stderr=FNULL)
    return solc_p.communicate()[0].decode()


def get_num_blocks(name):
    config_name = name+".config"
    if config_name in os.listdir("/tmp/costabs/"):
        f = open(d+config_name,"r")
        signature = f.readlines()
        blocks = map(lambda x: (x.split(";")[0].strip()[1:],x.split(";")[1].strip()),signature)
        return blocks
    else:
        return -1

def cpa(name, block):
    
    FNULL = open(os.devnull, 'w')
    cmd = "/home/pablo/Descargas/CPAchecker-1.8-unix/scripts/cpa.sh -svcomp19 "+"/tmp/costabs/"+name+".c -entryfunction block"+str(block)
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE,stderr = FNULL, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    for l in lines:
        if l.startswith("Verification result:"):
            result = l

    if result.split(".")[0].find("TRUE")==-1:
        func_verified.append(block)
        
    return result.split(".")[0]


def verymax(name):
    
    FNULL = open(os.devnull, 'w')
    cmd = "/home/pablo/Descargas/verymax-safety "+"/tmp/costabs/"+name+".c" 
    result = subprocess.Popen([cmd], stdout = subprocess.PIPE,stderr = FNULL, shell = True)
    a = result.communicate()[0].decode()
    lines = a.split("\n")
    for l in lines[-8:]:
        if l.startswith("<result"):
            result = l.split()[1]
    if result == "yes":
        result = "TRUE"
    else:
        result = "FALSE"
        
    return result
    
if __name__ == '__main__':

  # #  check_csvfile_exist()
    
  #   f = open("results.txt","w")
    
    cname = sys.argv[1]
    verifier = sys.argv[2]
    function = sys.argv[3]
    options = sys.argv[4]
    
    if "costabs" in os.listdir("/tmp/"):
        files = os.listdir(d)
        decompilation_correct = cname+str(".c") in files

    if decompilation_correct:
        blocks = get_num_blocks(cname)
        if verifier == "cpa" or verifier == "cpa-all":
            print "\nStarting SAFEVM with CPAChecker\n"
            if function == "all":
                for b in blocks:
                    print "Analyzing "+str(b[0])
                    r = cpa(cname,b[1])
                    print "\t"+r+"\n"
                if func_verified == []:
                    if options == "all":
                        print "All functions verified correctly."
                    elif options == "array":
                        print "Array accesses verified correctly for all public functions defined in "+str(cname)+"." 
                    elif options == "div0":
                        print "Divisions verified correctly for all public functions defined in "+str(cname)+"." 
            else:
                f = function
                bs = filter(lambda x: x[0].startswith(f+"("),blocks)

                if bs == []:
                    print "The function specified does not exist in the contract "+cname
                else:
                    print "Analyzing "+f
                    r = cpa(cname,bs[0][1])
                    print "\t"+r+"\n"
        else:
            print "\nStarting SAFEVM with VeryMax\n"
            r = verymax(cname)
            print "Verification result: "+r
    else:
        print "The file "+str(cname)+".c does not exist."

    # if name != "cfg":
    #     v =  get_num_blocks(d)
    #     if v != -1:
            
    #         for b in v:
    # 	    	print "\nExecuting GASTAP for " +str(b[0])		
    #     	times, result = saco(name,b[1])
    #             statistics(cfile,name,b,result,f)
    #         # os.rename(dir_cfile+cfile,new_dir+cfile)
                
    #     print "The results are stored in the file results.txt"
    # f.close()
