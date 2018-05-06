import rbr_rule
import os

#rbr contains a list of lists
def rbr2saco(rbr,execution):
    new_rules = []
    for rules in rbr:
        for rule in rules:
            new_rule = process_rule_saco(rule)
            new_rules.append(new_rule)

    write(new_rules,execution)

    
def build_head(rule):
    head = rule.get_rule_name()
    input_vars = rule.vars_to_string("input")
    local_vars = rule.build_local_vars()
    local_vars_string = ", ".join(local_vars)
    gv_aux = get_field_vars(rule)
    if(len(gv_aux)> 0 ):
        gv = ", ".join(gv_aux)
    else:
        gv = ""

    cv_aux = get_contract_vars(rule)
    if(len(cv_aux)>0):
        cv = ", ".join(cv_aux)

    else:
        cv = ""
        
    if (input_vars == ""):
            if(gv == ""):
                d_vars = ""+local_vars_string
            else:
                d_vars = gv+", "+local_vars_string
    else:
        d_vars = input_vars
        if(gv != ""):
            d_vars = d_vars+", "+gv+", "+local_vars_string

    if (cv != ""):
        d_vars = d_vars+", "+cv

    return head+"("+d_vars+")=>"



def process_rule_saco(rule):
    new_rule = ""
    head = build_head(rule)
    new_rule = new_rule+head+"\n"
    if rule.get_guard()!="":
        new_rule = new_rule+"\t"+rule.get_guard()+"\n"

    instr_aux = process_instructions(rule)
    instr = filter(lambda x: x !="",instr_aux)
    for ins in instr:
        new_rule = new_rule+"\t"+ins+"\n"

    return new_rule
    

def get_contract_vars(rule):
    bc = rule.get_bc()
    new = map(lambda x: "l("+x+")",bc)
    return new

def get_field_vars(rule):
    gv = rule.get_global_arg()
    new = map(lambda x: "field("+x+")",gv)
    return new

def process_instructions(rule):
    cont = rule.get_fresh_index()+1
    contract_vars = rule.get_bc()
    instructions = rule.get_instructions()
    new_instructions = []
    for instr in instructions:
        if instr.find("call(",0)!=-1:
            pos_head = instr.find("(",5) #It is a call. It starts with call(__( 
            pos0 = instr.find("s(0)",0)
            pos1 = instr.find("g(",0)

            local_vars = rule.build_local_vars()
            local_vars_string = ", ".join(local_vars)

            if pos1 != -1:
                gv = get_field_vars(rule)
                fv = ", ".join(gv)
            else:
                fv = ""
                
            cv_aux = get_contract_vars(rule)
            if len(cv_aux)>0:
                cv =", ".join(cv_aux)
            else:
                cv = ""

                          
            if fv != "":
                if pos0 != -1:
                    if cv!="":
                        new = instr[:pos0+4]+", "+fv+", "+local_vars_string+", "+cv+"))"
                    else:
                        new = instr[:pos0+4]+", "+fv+", "+local_vars_string+"))"
                else:
                    if cv!="":
                        new = instr[:pos_head+1]+fv+", "+local_vars_string+", "+cv+"))"
                    else:
                        new = instr[:pos_head+1]+fv+", "+local_vars_string+"))"
            else:
                if pos0 != -1: #there is a 
                    if cv!="":
                        new = instr[:pos0+4]+","+local_vars_string+", "+cv+"))"
                    else:
                        new = instr[:pos0+4]+","+local_vars_string+"))"
                else:
                    if cv!="":
                        new = instr[:pos_head+1]+local_vars_string+", "+cv+"))"
                    else:
                        new = instr[:pos_head+1]+local_vars_string+"))"
        elif instr.find("and",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("or",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("not",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("xor",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("gs(",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+") "+instr[pos:]
        elif instr.find("gl =",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+") "+instr[pos:]
        elif instr.find("ls(",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+") "+instr[pos:]
        elif instr.find("ll =",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+") "+instr[pos:]        
        elif instr.find("fresh",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("= eq",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("= lt",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("= gt",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif instr.find("g(",0)!=-1:
            pos = instr.find("=",0)
            posI = instr.find("g(",0)
            if posI <pos: #field var in the left
                new = "field("+instr[posI+2:]
            else:
                new = instr[:pos+1]+" field("+instr[posI+2:]
        elif instr.find("^",0)!=-1:
            pos = instr.find("=",0)
            new = instr[:pos+1]+" s("+str(cont)+")"
            cont+=1
        elif len(instr.split("=")) > 1:
            slices = instr.split("=")
            name = slices[1].strip()
            if(name in contract_vars or name[:name.find("(")] in contract_vars):
                new = slices[0]+"= l("+name+")"
            else:
                new = instr
        elif instr.find("skip")!=-1:
            new = ""
        else:
            new = instr
        new_instructions.append(new)

    return new_instructions

def write(rules,execution):
    # print "EMPEZAMOS"
    # for rule in rules:
    #     print rule
    if "costabs" not in os.listdir("/tmp/"):
        os.mkdir("/tmp/costabs/")

    if execution == None:
        name = "/tmp/costabs/rbr.rbr"
    else:
        name = "/tmp/costabs/rbr"+str(execution)+".rbr"
        
    with open(name,"w") as f:
        for rule in rules:
            f.write(rule+"\n")

    f.close()