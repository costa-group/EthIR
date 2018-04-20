import six

class BasicBlock:
    def __init__(self, start_address, end_address):
        self.start = start_address
        self.end = end_address
        self.instructions = []  # each instruction is a string
        self.jump_target = 0
        self.falls_to= None

        self.list_jumps = []
        self.ls_values = {} #load and store values. It is needed for rbr representation
        self.ls_values["mload"] = []
        self.ls_values["mstore"] = []
        self.ls_values["sload"] = []
        self.ls_values["sstore"] = []
        self.ls_values_computed = False
        self.calldatavalues = []
        self.stack_info = []
        self.ret_val = -1
        self.currentId = 0

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
            if (el != self.end+1) and (el!=self.falls_to):
                self.list_jumps.append(el)

    def set_calldataload_values(self,l):
        self.calldatavalues=l

    def get_load_store_values(self):
        return self.ls_values

    def get_load_store_values(self, ls_type):
        return self.ls_values[ls_type]

    def add_ls_value(self,ls_type,val):
        laux = self.ls_values[ls_type]
        l = laux+[val]
        self.ls_values[ls_type] = l

    def get_ls_values_computed(self):
        return self.ls_values_computed

    def act_ls_values(self):
        self.ls_values_computed = True


    def get_ret_val(self):
        return self.ret_val

    def set_ret_val(self, val):
        self.ret_val = val

    def _get_concrete_load_store(self,ls_type):
        try:
            return str(self.ls_values[ls_type].pop(0))
        except IndexError:
            ident = self.currentId
            self.currentId+=1
            return ls_type+str(self.start)+"_"+str(self.currentId)

    def _get_calldatavalue(self):
        try:
            return str(self.calldatavalues.pop(0))
            
        except IndexError:
            ident = self.currentId
            self.currentId+=1
            return "calldataload"+str(self.start)+"_"+str(self.currentId)
        
    def update_instr(self):
        new_instructions = []
    
        for instr in self.instructions:
            instr = instr.strip(" ")
            if(instr == "CALLDATALOAD"):
                new_instr = instr + " " +  str(self.calldatavalues.pop(0))
            elif instr == "MLOAD":
                new_instr = instr + " " + self._get_concrete_load_store("mload")
            elif instr == "MSTORE":
                new_instr = instr + " " + self._get_concrete_load_store("mstore")
            elif instr == "SLOAD":
                new_instr = instr + " " + self._get_concrete_load_store("sload")
            elif instr == "SSTORE":
                new_instr = instr + " " + self._get_concrete_load_store("sstore")
            elif instr == "RETURN":
                new_instr = instr + " " + str(self.ret_val)
            else:
                new_instr = instr
                
            new_instructions.append(new_instr)
        
        self.instructions = new_instructions

    def get_stack_info(self):
        return self.stack_info

    def set_stack_info(self,stack_info):
        self.stack_info = stack_info
        
    def display(self):
        six.print_("================")
        six.print_("start address: %d" % self.start)
        six.print_("end address: %d" % self.end)
        six.print_("end statement type: " + self.type)

        if self.list_jumps == []:
            self.list_jumps =[2]

        six.print_("jump target: " + " ".join(str(x) for x in self.list_jumps))
        # six.print_("jump target: %d" %self.jump_target)
        if(self.falls_to != None):
            six.print_("falls to: %d" %self.falls_to)
        for instr in self.instructions:
            # if(instr.strip(" ") == "CALLDATALOAD"):
            #     six.print_(instr+"("+self.calldatavalues.pop(0)+")")
            # else:
            six.print_(instr)
