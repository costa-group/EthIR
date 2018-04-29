import rbr_rule

#rbr contains a list of lists
def rbr2saco(rbr):
    new_rules = []
    for rules in rbr:
        for rule in rules:
            new_rule = process_rule_saco(rule)
            new_rules.append(new_rule)

    wirte(new_rules)


def process_rule_saco(rule):
    pass

def get_contract_vars(rule):
    bc = rule.get_bc()
    new = map(lambda x: "l("+x+")",bc)
    return new

def get_field_vars(rule):
    gv = rule.get_global_arg()
    new = map(lambda x: "field("+x+")",gv)
    return new

def process_instructions(rule):
    cont = rule.get_fresh_index()
    instructions = rule.get_instructions()
    new_instructions = []
    for instr in instructions:
        if instr.find("and",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("or",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("not",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("xor",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("gs",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+")"+instr[pos:]
        elif instr.find("gl",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+")"+instr[pos:]
        elif instr.find("ls",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+")"+instr[pos:]
        elif instr.find("ll",0)!=-1:
            pos = instr.find("=")
            new = "l("+instr[:pos].strip()+")"+instr[pos:]
        elif instr.find("call",0)!=-1:
            pass
        elif instr.find("fresh",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("= eq",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("= lt",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        elif instr.find("= gt",0)!=-1:
            pos = instr.find("=")
            new = instr[:pos+1]+"s("+cont+")"
            cont+=1
        else:
            new = instr
        new_instructions.append(new)


def write(rules):
    with open("/tmp/costa/rbr.rbr","w") as f:
        for rule in rules:
            f.write(rule)
