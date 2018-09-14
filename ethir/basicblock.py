import six

class BasicBlock:
    def __init__(self, start_address, end_address):
        self.start = start_address
        self.end = end_address
        self.instructions = []  # each instruction is a string
        self.jump_target = 0
        self.falls_to= None

        self.list_jumps = []
        #It stores de value of each load/store instructions to know if it is constant.
        #keys-> number of instructions inside a block
        #value-> its value
        #It is needed for rbr representation.
        self.mload_values = {} 
        self.mstore_values = {}
        self.sload_values = {}
        self.sstore_values = {}
        self.calldatavalues = []
        self.stack_info = []
        self.ret_val = -1
        self.currentId = 0

        self.comes_from = []
        
    def get_start_address(self):
        return self.start

    def get_end_address(self):
        return self.end

    def add_instruction(self, instruction):
        self.instructions.append(instruction)

    def get_instructions(self):
        return self.instructions

    def set_block_type(self, type):
        self.type = type

    def get_block_type(self):
        return self.type

    def set_falls_to(self, address):
        self.falls_to = address

    def get_falls_to(self):
        return self.falls_to

    def set_jump_target(self, address):
        if isinstance(address, six.integer_types):
            self.jump_target = address
        else:
            self.jump_target = -1

    def get_jump_target(self):
        return self.jump_target

    def set_branch_expression(self, branch):
        self.branch_expression = branch

    def get_branch_expression(self):
        return self.branch_expression

    #Added by Pablo Gordillo
    def get_list_jumps(self):
        return self.list_jumps

    def compute_list_jump(self,edges):
        for el in edges:
            if (el!=self.falls_to):
                self.list_jumps.append(el)

    def set_calldataload_values(self,l):
        self.calldatavalues=list(l)

    def get_load_store_values(self,type_value):
        if type_value == "mload":
            result = self.mload_values
        elif type_value == "mstore":
            result = self.mstore_values
        elif type_value == "sload":
            result = self.sload_values
        elif type_value == "sstore":
            result = self.sstore_values
        else:
            result = "Error"
        return result

    def add_ls_value(self,type_value,key,val):
        if type_value == "mload":
            l = self.mload_values.get(key,-1)
            if l == -1:
                self.mload_values[key] = [val]
            else:
                l.append(val)
        elif type_value == "mstore":
            l = self.mstore_values.get(key,-1)
            if l == -1:
                self.mstore_values[key] = [val]
            else:
                l.append(val)
        elif type_value == "sload":
            l = self.sload_values.get(key,-1)
            if l == -1:
                self.sload_values[key] = [val]
            else:
                l.append(val)
        elif type_value == "sstore":
            l = self.sstore_values.get(key,-1)
            if l == -1:
                self.sstore_values[key] = [val]
            else:
                l.append(val)
        else:
            raise Exception("Error when adding "+type_value+" value to block: "+ str(self.start_address))

    def get_ret_val(self):
        return self.ret_val

    def set_ret_val(self, val):
        self.ret_val = val


    def _is_numerical(self,elem):
        try:
            int(elem)
            val = elem
        except:
            val = "?"
        return val
        
    def _check_same_elem(self,l,elem):
        list_aux = list(filter(lambda x: str(x)!=elem,l))
        if len(list_aux) == 0: #All the elements are the same (and numerical)
            val = self._is_numerical(elem)
        else:
            val = "?"
        return val
    
    def _get_concrete_value(self,type_value,cont):
        
        if type_value == "mload":
            l = self.mload_values.get(cont,-1)
            if len(l) == 1:
                val = self._is_numerical(l[0])
            else:
                val = self._check_same_elem(l[1:],str(l[0]))

        elif type_value == "mstore":
            l = self.mstore_values.get(cont,-1)
            if len(l) == 1:
                val = self._is_numerical(l[0])
            else:
                val = self._check_same_elem(l[1:],str(l[0]))

        elif type_value == "sload":
            l = self.sload_values.get(cont,-1)
            if len(l) == 1:
                val = self._is_numerical(l[0])
            else:
                val = self._check_same_elem(l[1:],str(l[0]))

        else:    #sstore 
            l = self.sstore_values.get(cont,-1)
            if len(l) == 1:
                val = self._is_numerical(l[0])
            else:
                val = self._check_same_elem(l[1:],str(l[0]))

        return str(val)

    def _get_calldatavalue(self):
        try:
            return str(self.calldatavalues.pop(0))
            
        except IndexError:
            ident = self.currentId
            self.currentId+=1
            return "calldataload"+str(self.start)+"_"+str(self.currentId)


    def add_origin(self,block):
        if block not in self.comes_from:
            self.comes_from.append(block)

    def get_comes_from(self):
        return self.comes_from
    
    def update_instr(self):
        new_instructions = []
        mload = 0
        mstore = 0
        sstore = 0
        sload = 0
        
        for instr in self.instructions:
            instr = instr.strip(" ")
            if(instr == "CALLDATALOAD"):
                new_instr = instr + " " +  self._get_calldatavalue()
            elif instr == "MLOAD":
                new_instr = instr + " " + self._get_concrete_value("mload",mload)
                mload +=1
            elif instr[:6] == "MSTORE": #MSTORE8
                new_instr = instr + " " + self._get_concrete_value("mstore",mstore)
                mstore+=1
            elif instr == "SLOAD":
                new_instr = instr + " " + self._get_concrete_value("sload",sload)
                sload+=1
            elif instr == "SSTORE":
                new_instr = instr + " " + self._get_concrete_value("sstore",sstore)
                sstore+=1
            #For the moment we don't annotate return evm 
            # elif instr == "RETURN":
            #     new_instr = instr + " " + str(self.ret_val)
            else:
                new_instr = instr
                
            new_instructions.append(new_instr)
        
        self.instructions = new_instructions

    def get_stack_info(self):
        return self.stack_info

    def set_stack_info(self,stack_info):
        self.stack_info = list(stack_info)
        
    def display(self):
        six.print_("================")
        six.print_("start address: %d" % self.start)
        six.print_("end address: %d" % self.end)
        six.print_("end statement type: " + self.type)


        if self.list_jumps == []:
            self.list_jumps =[-1]

        six.print_("jump target: " + " ".join(str(x) for x in self.list_jumps))
        # six.print_("jump target: %d" %self.jump_target)
        if(self.falls_to != None):
            six.print_("falls to: %d" %self.falls_to)
        for instr in self.instructions:
            # if(instr.strip(" ") == "CALLDATALOAD"):
            #     six.print_(instr+"("+self.calldatavalues.pop(0)+")")
            # else:
            six.print_(instr)

    def getTree(self):
        return Tree(self.start,self.start,self.start)
        
            
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
                fo.write("n_%s [style=solid,color=yellow,label=\"%s\"];\n"%(self.id,self.root))
                
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
