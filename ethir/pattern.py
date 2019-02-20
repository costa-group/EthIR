global pattern
pattern = ["JUMPDEST","PUSH1 0x00","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","PUSH1 0x1f","ADD","PUSH1 0x20","DUP1","SWAP2","DIV","MUL","PUSH1 0x20","ADD","PUSH1 0x40","MLOAD","SWAP1","DUP2","ADD","PUSH1 0x40","MSTORE","DUP1","SWAP3","SWAP2","SWAP1","DUP2","DUP2","MSTORE","PUSH1 0x20","ADD","DUP3","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","ISZERO"]

global sub_pattern
sub_pattern = ["PUSH1 0x01",
               "DUP2",
               "PUSH1 0x01",
               "AND",
               "ISZERO",
               "PUSH2 0x0100",
               "MUL",
               "SUB",
               "AND",
               "PUSH1 0x02",
               "SWAP1",
               "DIV"]


## String Pattern
    
def look_for_string_pattern(block):
    ins_aux = block.get_instructions()[:-2]
    if len(ins_aux)>=len(pattern):
        ins = map(lambda x: x.strip(),ins_aux)
        p = check_string_pattern(ins)
        if p :
            block.activate_string_getter()

def check_string_pattern(instructions):
    pat = False
    if instructions[0] == pattern[0]:
        i = 1
        correct = True
        while(i<len(instructions) and instructions[i]!="DUP1"):
            if instructions[i].split()[0][:-1]!="PUSH":
                correct = False
            i = i+1
        if correct:
            pat = instructions[i:] == pattern[2:]
    return pat

def write_pattern(key,cname):
    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)
        

    name = costabs_path+"pattern.pattern"
    with open(name,"a") as f:
        string = tacas_ex+" "+cname+" "+str(key)+"\n"
        f.write(string)
    f.close()
    
## Array Access Pattern

##Refactor (it is in symExec

## Fragment fields

