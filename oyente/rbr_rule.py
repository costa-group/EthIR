#Pablo Gordillo

from utils import toInt
'''
RBRRule class represents the rules of the transaction system.
Each rule contains:
 * identifier

'''

class RBRRule:
    def __init__(self,blockId,typeBlock):
        self.blockId = blockId

        if typeBlock == "block":
            self.rule_name = "block"+str(blockId)
        else:
            self.rule_name = "jump"+str(blockId)

        self.arg_input = 0
        self.arg_global = []
        self.arg_local = 0
        self.guard=""
        self.instr=[]
        self.rbr_type = typeBlock
        self.bc = []
        self.fresh_index = 0
        # self.bc = ["address","balance","origin","caller","callvalue","calldataload","calldatasize","calldatacopy",
        #            "codesize","codecopy","gasprice","extcodesize","extcodecopy","mcopy","blockhash","coinbase",
        #            "number","difficulty",
        #            "gaslimit","gas"] #To be extended
        
    def get_guard(self):
        return self.guard

    def set_guard(self, guard):
        self.guard = guard

    def get_Id(self):
        return self.blockId

    def set_Id(self, b_id):
        self.blockId = b_id

    def get_instructions(self):
        return self.instr

    def set_instructions(self, instr):
        self.instr = instr

    def add_instr(self, instr):
        self.instr.append(instr)

    def get_type(self):
        return self.rbr_type

    def get_rule_name(self):
        return self.rule_name

    def write_rule(self, fd):
        pass

    def get_index_invars(self):
        return self.arg_input

    def set_index_input(self,num):
        self.arg_input = num

    def get_args_local(self):
        return self.arg_local

    def set_args_local(self,ls):
        self.arg_local = ls

    def set_global_vars(self,l):
        self.arg_global = sorted(l,key= toInt)[::-1]
        

    def get_global_arg(self):
        return self.arg_global

    def set_bc(self,bc_used):
        self.bc = bc_used

    def get_bc(self):
        return self.bc

    def set_fresh_index(self,val):
        self.fresh_index = val

    def get_fresh_index(self):
        return self.fresh_index
    

    def build_input_vars(self):
        in_vars = []
        for i in xrange(self.arg_input-1,-1,-1):
            var = "s("+str(i)+")"
            in_vars.append(var)
        return in_vars

    def build_field_vars(self):
        field_vars = []
        for i in self.arg_global:
            var = "g("+ str(i)+")"
            field_vars.append(var)
        return field_vars

    def build_local_vars(self):
        local_vars = []
        for i in xrange(self.arg_local-1,-1,-1):
            var = "l(m"+str(i)+")"
            local_vars.append(var)
        return local_vars

    def update_calls(self):
        if "call(" in self.instr[-1]:
            call = self.instr.pop()
            posInit = call.find("global",0)

            gv_aux = self.build_field_vars()
            local_vars = self.build_local_vars()
            local_vars_string = ", ".join(local_vars)
            if (len(gv_aux)==0):
                gv = ""
            else:
                gv = ", ".join(gv_aux)
            if gv != "":
                new_instr = call[:posInit]+gv+", "+local_vars_string+", "+self.vars_to_string("data")+"))"
            else:
                new_instr = call[:posInit]+local_vars_string+", "+self.vars_to_string("data")+"))"
            self.instr.append(new_instr)

    def vars_to_string(self,types):
        if types == "input":
            in_aux = self.build_input_vars()
            if len(in_aux) ==0:
                string_vars = ""
            else:
                string_vars = ", ".join(in_aux)
        elif types == "global":
            gv_aux = self.build_field_vars()
            if (len(gv_aux)==0):
                string_vars = ""
            else:
                string_vars = ", ".join(gv_aux)
        else: #contract vars
            if len(self.bc) == 0:
                string_vars = ""
            else:
                string_vars = ", ".join(self.bc)
                
        return string_vars

    
    def display(self):
        
        new_instr = filter(lambda x: x !="",self.instr) #clean instructions ""
        new_instr = ["skip"] if new_instr == [] else new_instr
        in_aux = self.build_input_vars()
        local_vars = self.build_local_vars()
        
        in_vars = self.vars_to_string("input")
        gv = self.vars_to_string("global")
        bc_input = self.vars_to_string("data")
        
        if (in_vars == ""):
            if(gv == ""):
                d_vars = ""
            else:
                d_vars = gv
        else:
            d_vars = in_vars
            if(gv != ""):
                d_vars = d_vars+", "+gv

        if d_vars == "":
            d_vars = ", ".join(local_vars)
        else:
            d_vars = d_vars+", "+ ", ".join(local_vars)
            
        if (bc_input != ""):
            d_vars = d_vars+", "+bc_input

        print self.rule_name+"("+d_vars+")=>"
            # print self.rule_name+"("+gv+", "+ bc_input+")=>"
        # else:
        #     print self.rule_name+"(" +  + ", " + gv + ", " + bc_input+")=>"

        if self.guard != "" :
            print "\t"+self.guard

        for instr in new_instr:
            print "\t"+instr
