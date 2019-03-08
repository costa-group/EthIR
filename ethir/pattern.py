
pattern = ["JUMPDEST","PUSH1 0x00","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","PUSH1 0x1f","ADD","PUSH1 0x20","DUP1","SWAP2","DIV","MUL","PUSH1 0x20","ADD","PUSH1 0x40","MLOAD","SWAP1","DUP2","ADD","PUSH1 0x40","MSTORE","DUP1","SWAP3","SWAP2","SWAP1","DUP2","DUP2","MSTORE","PUSH1 0x20","ADD","DUP3","DUP1","SLOAD","PUSH1 0x01","DUP2","PUSH1 0x01","AND","ISZERO","PUSH2 0x0100","MUL","SUB","AND","PUSH1 0x02","SWAP1","DIV","DUP1","ISZERO"]

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


pre_pattern_sstore = ["PUSH","DUP","PUSH","EXP","DUP"]
post_pattern_sstore = ["DUP","PUSH","MUL","NOT","AND","SWAP","DUP","PUSH","AND","MUL","OR","SWAP"]

pre_pattern_sload = ["PUSH","PUSH","SWAP",]
post_pattern_sload = ["SWAP","PUSH","EXP","SWAP","DIV","PUSH"]
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

def sload_sstore_fragment(block,i):
       
    instructions = block.get_instructions()
    prev_ins = instructions[:i]
    post_ins = instructions[i+1:]

    if len(prev_ins)< 5:
        return False,-1

    if len(post_ins)< 12:
        return False,-1

    cmp_prev_ins = prev_ins[len(prev_ins)-len(pre_pattern_sstore):]

    p = True

    first = cmp_prev_ins.pop(0)
    val = -1

    p = p and first.startswith(pre_pattern_sstore[0])
    
    if p:
        second = cmp_prev_ins.pop(0)
        if (not second.startswith("DUP")) and (not second.startswith("PUSH")):
            p = False
            
        else:

            if second.startswith("PUSH"):
                val = int(second.split()[-1],16)
            elif second.startswith("DUP"):
                val = int(first.split()[-1],16)

            i = 2
            while i <len(cmp_prev_ins) and p:
                current = cmp_prev_ins.pop(0)
                p = p and current.startswith(pre_pattern_sstore[i])
                i+=1

            i = 0
            try:
                s_ext = post_ins.index("SIGNEXTEND ")
            except:
                s_ext = -1

            if s_ext !=-1:
                post_ins = post_ins[:s_ext-1]+post_ins[s_ext+1:]
                
            while i < len(post_pattern_sstore) and p:
                current = post_ins[i]
                p = p and current.startswith(post_pattern_sstore[i])
                i+=1
                
    return p, val

def sstore_fragment(block,i):
    instructions = block.get_instructions()
    prev_ins = instructions[:i]
    if len(prev_ins)<18:
        return False, -1
    try:
        prev_ins.index("SIGNEXTEND ")
        s_ext = True
    except:
        s_ext = False

    if s_ext:
        start_index = len(prev_ins)-(len(pre_pattern_sstore)+len(post_pattern_sstore)+3) #The patterns don't take into account the SLOAD
    else:
        start_index = len(prev_ins)-(len(pre_pattern_sstore)+len(post_pattern_sstore)+1)
        
    ins = prev_ins[start_index:]
    
    p = True
    
    p = p and ins[0].startswith(pre_pattern_sstore[0])
    second_p = ins[1].startswith(pre_pattern_sstore[1]) or ins[1].startswith("PUSH")
    p = p and second_p
    i = 2
    
    while i<len(pre_pattern_sstore) and p:
        p = p and ins[i].startswith(pre_pattern_sstore[i])
        i+=1

    p = p and ins[i].startswith("SLOAD")
    i+=1

    idx = i
    while i<len(post_pattern_sstore) and p:
        if ins[i].startswith("PUSH") and ins[i+1].startswith("SIGNEXTEND"):
            i+=2
        
        p = p and ins[i].startswith(post_pattern_sstore[i-idx])
        i+=1
    
    if p:
        first = ins[0]
        second = ins[1]
        if second.startswith("PUSH"):
            val = int(second.split()[-1],16)
        else: #DUP case because p = True
            val = int(first.split()[-1],16)
    else:
        val = -1

    return p,val
                   
def sload_fragment(block,i,stack):
    instructions = block.get_instructions()
    prev_ins = instructions[:i]
    post_ins = instructions[i+1:]

    if len(prev_ins) < 3:
        return False,-1

    if len(post_ins) < 7:
        return False,-1

    cmp_prev_ins = prev_ins[len(prev_ins)-len(pre_pattern_sload):]

    p = True

    first = cmp_prev_ins.pop(0)
    val = -1

    is_first = first.startswith(pre_pattern_sstore[0]) or first.startswith("DUP")
    p = p and is_first

    if p:
        second = cmp_prev_ins.pop(0)

        if (not second.startswith("PUSH")) and (not second.startswith("DUP")): #second element of pattern
            p = False
        else:
            if second.startswith("PUSH"):
                val = int(second.split()[-1],16)
            else: #it is dup
                if first.startswith(pre_pattern_sstore[0]): #first =  push
                    val = int(first.split()[-1],16)
    
    third = cmp_prev_ins.pop(0)                
    p = p and third.startswith(pre_pattern_sload[2])

    if p and val == -1:
        pos = int(third.strip()[-1],10)
        val = stack[pos]
    
    i = 0
    while p and i<len(post_pattern_sload):
        p = p and post_ins[i].startswith(post_pattern_sload[i])
        i+=1

    return p,val

def check_sload_fragment_pattern(block,i,stack):
    p_s,v = sload_sstore_fragment(block,i)

    if not p_s:
        p_s,v = sload_fragment(block,i,stack)
    return p_s,v

