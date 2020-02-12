import six
from dot_tree import Tree
from opcodes import get_ins_cost

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
        self.depth = -1
        self.clone = False
        self.string_getter = False
        self.cost = 0
        self.access_array = False
        self.assertfail_in_getter = False
        self.div_invalid_pattern = False
        self.stacks_old = []
        self.path = []

        self.pcs = []
        self.pcs_stored = False

        
    def get_start_address(self):
        return self.start

    def set_start_address(self,address):
        self.start = address

        
    def get_end_address(self):
        return self.end

    def add_instruction(self, instruction):
        self.instructions.append(instruction)

    def get_instructions(self):
        return self.instructions

    def set_instructions(self,l):
        self.instructions = l
    
    def set_block_type(self, type):
        self.type = type

    def get_block_type(self):
        return self.type

    def set_falls_to(self, address):
        self.falls_to = address

    def get_falls_to(self):
        return self.falls_to

    def set_jump_target(self, address, cloning = None):
        
        if isinstance(address, six.integer_types) and cloning == None:
            self.jump_target = address
        elif cloning:
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

    # def remove_node_from_path(self):
    #     self.path.pop()
    
    def set_depth_level(self, l):
        if self.depth == -1:
            self.depth = l
        else:
            if self.depth < l:
                self.depth = l

    def get_depth_level(self):
        return self.depth

    
    def get_list_jumps(self):
        return self.list_jumps

    def set_list_jump(self,l):
        self.list_jumps = l
        
    def compute_list_jump(self,edges):
        for el in edges:
            if (el!=self.falls_to):
                self.list_jumps.append(el)

    def update_list_jump_cloned(self,val):
        num = val.split("_")
        if len(num) == 2:
            numI = int(num[0])
            if numI in self.list_jumps:
                i = self.list_jumps.index(numI)
                self.list_jumps[i]=val
        elif len(num)>2:
            numI = num[:-1]
            address = "_".join(numI)
            if address in self.list_jumps:
                i = self.list_jumps.index(address)
                self.list_jumps[i]=val

    def set_comes_from(self, new_comes_from):
        self.comes_from = new_comes_from

    def add_jump(self, val):
        if val not in self.list_jumps:
            self.list_jumps.append(val)
                
    def set_cloning(self, c):
        self.clone = c

    def get_cloning(self):
        return self.clone
    
    def compute_cloning(self):
        if self.falls_to == None and self.jump_target != 0: #case when it is unconditional
            if len(self.list_jumps)>1:
                self.clone = True
        return self.clone

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

    def _set_mload_values(self,val):
        self.mload_values = val

    def _set_mstore_values(self,val):
        self.mstore_values = val

    def _set_sload_values(self,val):
        self.sload_values = val

    def _set_sstore_values(self,val):
        self.sstore_values = val

    def _set_caldata_values(self,val):
        self.calldatavalues = val
    
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
        fragment = str(elem).split("_")
        try:
            if len(fragment) == 2:
                int(fragment[0])
                int(fragment[1])
                val = elem
            else:
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

    def set_comes_from(self,l):
        self.comes_from = list(l)
        
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
                val = self._get_concrete_value("mstore",mstore)
                # if val == "?":
                #     self.unknown_mstore = True
                new_instr = instr + " " + val
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

    # def is_mstore_unknown(self):
    #     return self.unknown_mstore

    # def set_unknown_mstore(self,val):
    #     self.unknown_mstore = val
        
    # def act_trans_mstore(self):
    #     self.transitive_mstore = True

    # def get_trans_mstore(self):
    #     return self.transitive_mstore

    # def set_trans_mstore(self,val):
    #     self.transitive_mstore = val
        
    def get_stack_info(self):
        return self.stack_info

    def set_stack_info(self,stack_info):
        self.stack_info = list(stack_info)

    def set_stack_info_pos(self,value,pos):
        self.stack_info[pos] = value

    def get_string_getter(self):
        return self.string_getter
        
    def set_string_getter(self,val):
        self.string_getter = val

    def activate_string_getter(self):
        self.string_getter = True

    def get_access_array(self):
        return self.access_array

    def set_access_array(self,val):
        self.access_array = val

    def activate_access_array(self):
        self.access_array = True

    def get_assertfail_in_getter(self):
        return self.assertfail_in_getter

    def set_assertfail_in_getter(self,val):
        self.assertfail_in_getter = val

    def activate_assertfail_in_getter(self):
        self.assertfail_in_getter = True

    def get_div_invalid_pattern(self):
        return self.div_invalid_pattern

    def set_div_invalid_pattern(self,val):
        self.div_invalid_pattern = val

    def activate_div_invalid_pattern(self):
        self.div_invalid_pattern = True
    
    def add_stack(self,s):
        is_in = self._is_in_old_stacks(s)
        if not(is_in):
            self.stacks_old.append(s)
            
    def known_stack(self,s):
        s_aux = filter(lambda x: isinstance(x,tuple),s)
        is_in = self._is_in_old_stacks(s_aux)
        return is_in

    def _is_in_old_stacks(self,stack):
        # jump_addresses = map(lambda x: x[0],stack)
        # old_stacks_addresses = map(lambda x: map(lambda y:y[0],x),self.stacks_old)
        # return jump_addresses in old_stacks_addresses
        return stack in self.stacks_old
    

    def get_stacks(self):
        return self.stacks_old

    def set_stacks(self,val):
        self.stacks_old = val
    
    def get_paths(self):
        return self.path

    def add_path(self,p):
        if p not in self.path:
            end = map(lambda x: x[1],p)
            self.path.append(end)

    
    def set_paths(self,p):
        self.path = p
            
    def copy(self):
        
        new_obj =  BasicBlock(self.start, self.end)
        new_obj.set_instructions(list(self.instructions))
        new_obj.set_jump_target(self.jump_target,True)

        if self.falls_to != None:
            new_obj.set_falls_to(self.falls_to)
            
        new_obj.set_list_jump([])
        new_obj._set_mload_values(self.mload_values.copy())
        new_obj._set_mstore_values(self.mstore_values.copy())
        new_obj._set_sload_values(self.sload_values.copy())
        new_obj._set_sstore_values(self.sstore_values.copy())
        new_obj.set_calldataload_values(list(self.calldatavalues))
        new_obj.set_comes_from([])
        new_obj.set_block_type(self.type)
        new_obj.set_depth_level(self.depth)
        new_obj.set_stack_info(list(self.stack_info))
        new_obj.set_cloning(self.clone)
        new_obj.set_string_getter(self.string_getter)
        # new_obj.set_unknown_mstore(self.unknown_mstore)
        # new_obj.set_trans_mstore(self.transitive_mstore)
        new_obj.set_paths(self.path)
        new_obj.set_access_array(self.access_array)
        new_obj.set_div_invalid_pattern(self.div_invalid_pattern)
        new_obj.set_assertfail_in_getter(self.assertfail_in_getter)
        
        #AHC: When we copy, we just forget about old stacks
        new_obj.set_stacks([])
        
        return new_obj

    def is_direct_block(self):
        if self.type == "falls_to":
            return True
        if self._isPUSH_JUMP_Instruction():
            return True
        else:
            return False

    def _isPUSH_JUMP_Instruction(self):
        if self.instructions[-1].strip() in ["JUMP","JUMPI"]:
            push = self.instructions[-2].split(" ")[0]
            if push[0:4] == "PUSH":
                return True
            else:
                return False
        else:
            return False
    def get_block_gas(self):
        s = 0
        for e in self.instructions:
            s = s+get_ins_cost(e.strip())
        return s

    def set_cost(self,s):
        self.cost = s

    def get_cost(self):
        return self.cost


    def get_pcs(self):
        return self.pcs

    def set_pcs(self,pcs_list):
        self.pcs = pcs_list

    def add_pc(self,val):
        self.pcs.append(val)

    def get_pcs_stored(self):
        return self.pcs_stored
        
    def set_pcs_stored(self,val):
        self.pcs_stored = val

        
    def display(self):
        six.print_("================")

        if type(self.start)==int:
            six.print_("start address: %d" % self.start)
        else:
            six.print_("start address: "+self.start)
            
        six.print_("end address: %d" % self.end)
        six.print_("end statement type: " + self.type)


        if self.list_jumps == []:
            self.list_jumps =[-1]

        six.print_("jump target: " + " ".join(str(x) for x in self.list_jumps))
        # six.print_("jump target: %d" %self.jump_target)
        if(self.falls_to != None):
            six.print_("falls to: " + str(self.falls_to))
        for instr in self.instructions:
            # if(instr.strip(" ") == "CALLDATALOAD"):
            #     six.print_(instr+"("+self.calldatavalues.pop(0)+")")
            # else:
            six.print_(instr)
        
    def getTree(self):
        return Tree(self.start,self.start,self.start)
        
