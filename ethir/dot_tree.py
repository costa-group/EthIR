##Added by Pablo Gordillo

class Tree:
    def __init__(self) :
        self.root = None
        self.children = []
        self.tag = None
        self.id = 0
        self.block_type = None
        
    def __init__(self,root,tag,id,type_block):
        self.root = root
        self.tag = tag
        self.id = id
        self.children = []
        self.type_block = type_block


    def setId(self, new_id):
        self.id = new_id

    def getId(self):
        return self.id
        
    def get_children(self):
        return self.children

    def set_children(self,children):
        self.children = children

    def add_child(self,child):
        self.children.append(child)
        
    def isLeaf(self):
        return self.children == []
    
    def generatedot(self,fo):
        fo.write("digraph id3{ \n")
        self.generategraph(fo,0)
        fo.write("}")
        
    def generategraph(self,fo,level):
        if self.type_block == "terminal" :
            fo.write("n_%s [style=diagonals,color=green,label=\"%s\"];\n"%(self.id,self.root))
        else :
            if self.type_block == "conditional":
                fo.write("n_%s [style=solid,color=blue,label=\"%s\"];\n"%(self.id,self.root))
            elif self.type_block == "unconditional":
                fo.write("n_%s [style=solid,color=orange,label=\"%s\"];\n"%(self.id,self.root))
            else:
                fo.write("n_%s [style=solid,color=red,label=\"%s\"];\n"%(self.id,self.root))
                
            i = 0
            for child in self.children:
                new_level = i
                fo.write("n_%s -> n_%s [label=\"%s\"];\n"%(self.id,child.id,child.tag))
                child.generategraph(fo,new_level);
                i += 1


    def __eq__(self, obj):
        ig = False
        if isinstance(obj,Tree):
            ig = self.id == obj.getId()
        return ig


def build_tree(block,visited,block_input,condTrue = "t"):
    
    start = block.get_start_address()   
    falls_to = block.get_falls_to()
    list_jumps = block.get_list_jumps()
    # print "BUILD TREE"
    # print start
    # print falls_to
    # print list_jumps
    
    type_block = block.get_block_type()

    if condTrue == "u":
        r = Tree(start,"",start,type_block)        
    else:
        r = Tree(start,condTrue,start,type_block)
        
    for block_id in list_jumps:
        if (start,block_id) not in visited:
            visited.append((start,block_id))
            if type_block == "conditional":
                ch = build_tree(block_input.get(block_id),visited,block_input)
            else:
                ch = build_tree(block_input.get(block_id),visited,block_input,"u")
            if ch not in r.get_children():
                r.add_child(ch)

    falls_to = block.get_falls_to()
    if (falls_to != None) and (start,falls_to) not in visited:
        visited.append((start,falls_to))
        if type_block == "falls_to":
            ch = build_tree(block_input.get(falls_to),visited,block_input,"")
        else:
            ch = build_tree(block_input.get(falls_to),visited,block_input,"f")
        if ch not in r.get_children():
            r.add_child(ch)
        
    return r


def build_tree_hex(block,visited,block_input,condTrue = "t"):

    start_addr, end_addr, jump_addr, falls_addr = compute_hex_vals_cfg(block)

    
    start = block.get_start_address()   
    falls_to = block.get_falls_to()
    list_jumps = block.get_list_jumps()
    # print "BUILD TREE"
    # print start
    # print falls_to
    # print list_jumps
    
    type_block = block.get_block_type()

    if condTrue == "u":
        r = Tree(start_addr,"",start,type_block)        
    else:
        r = Tree(start_addr,condTrue,start,type_block)
        
    for block_id in list_jumps:
        if (start,block_id) not in visited:
            visited.append((start,block_id))
            if type_block == "conditional":
                ch = build_tree(block_input.get(block_id),visited,block_input)
            else:
                ch = build_tree(block_input.get(block_id),visited,block_input,"u")
            if ch not in r.get_children():
                r.add_child(ch)

    falls_to = block.get_falls_to()
    if (falls_to != None) and (start,falls_to) not in visited:
        visited.append((start,falls_to))
        if type_block == "falls_to":
            ch = build_tree(block_input.get(falls_to),visited,block_input,"")
        else:
            ch = build_tree(block_input.get(falls_to),visited,block_input,"f")
        if ch not in r.get_children():
            r.add_child(ch)
        
    return r

def compute_hex_vals_cfg(block):
    start_addr = ""
    end_addr = ""
    jump_addrs = ""
    falls_addr = ""

    
    start = str(block.get_start_address()).split("_")
    end = str(block.get_end_address()).split("_")
    
    if len(start)>1:
        start0 = hex(int(start[0]))[2:]
        start_addr = start0+"_"+start[1]
    else:
        start_addr = hex(int(start[0]))[2:]

    if len(end)>1:
        end0 = hex(int(end[0]))[2:]
        end_addr = end0+"_"+end[1]
    else:
        end_addr = hex(int(end[0]))[2:]

    jumps_hex = []
    for jump in  block.get_list_jumps():
        elems = str(jump).split("_")
        if len(elems)>1:
            jump0 = hex(int(elems[0]))[2:]
            jump_addr = jump0+"_"+elems[1]
        else:
            jump_addr = hex(int(elems[0]))[2:]
        jumps_hex.append(jump_addr)
        
    jump_addrs = " ".join(jumps_hex)

    falls = str(block.get_falls_to()).split("_")

    if falls!=['None']:
        if len(falls)>1:
            falls0 = hex(int(falls[0]))[2:]
            falls_addr = falls0+"_"+falls[1]
        else:
            falls_addr = hex(int(falls[0]))[2:]
    else:
        falls_addr = None


    return start_addr,end_addr,jump_addrs,falls_addr
