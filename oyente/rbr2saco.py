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
    
def write(rules):
    with open("/tmp/costa/rbr.rbr","w") as f:
        for rule in rules:
            f.write(rule)
