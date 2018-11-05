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
