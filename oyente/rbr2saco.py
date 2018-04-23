import rbr_rule

def rbr2saco(rbr):
    with open("/tmp/evm/rbr.rbr","w") as f:
        for rule in rbr:
            new_rule = process_instructions_saco(rule)
            write(new_rule,f)
    f.close()


def process_instructions_saco(rule):
    pass
    
def write(new_rule,f):
    pass
