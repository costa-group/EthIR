#Pablo Gordillo

from utils import toInt
'''
RBRRule class. It represents the rules of the transaction system.
Each rule contains:
- blockId: It is the same that the id of the block translated.
- rule_name: name that identifies the rbr.
- arg_input: top stack index.
- arg_global: list containing the field index known.
- arg_local: index of the top most local variable.
- guard: It contains the guard of the jump rbr.
- instr: list of instructions translated.
- rbr_type: block or jump depending on the type of the rbr generated.
- bc: list of the contract variables used by the program analyzed.
- fresh_index: index to generate new fresh variables.
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
        self.arg_local = []
        self.guard=""
        self.instr=[]
        self.rbr_type = typeBlock
        self.bc = []
        self.fresh_index = 0
        self.call_to = -1
        self.call_to_info = None
    
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

    def get_index_invars(self):
        return self.arg_input

    def set_index_input(self,num):
        self.arg_input = num

    def get_args_local(self):
        return self.arg_local

    def set_args_local(self,ls):
        self.arg_local = ls

    def update_local_arg(self,l):
        self.arg_local = list(set(self.arg_local+l))

    def set_global_vars(self,l):
        self.arg_global = sorted(l,key= toInt)[::-1]
        

    def get_global_arg(self):
        return sorted(self.arg_global,key = toInt)[::-1]

    def update_global_arg(self,l):
        aux = self.arg_global+l
        self.arg_global = list(set(aux))
        
    def set_bc(self,bc_used):
        self.bc = bc_used

    def get_bc(self):
        return sorted(self.bc)

    def update_bc(self,l):
        aux = self.bc+l
        self.bc = list(set(aux))

    def set_fresh_index(self,val):
        self.fresh_index = val

    def get_fresh_index(self):
        return self.fresh_index

    def get_call_to(self):
        return self.call_to

    def set_call_to(self,blockId):
        self.call_to = blockId

    def get_call_to_info(self):
        return self.call_to_info

    def set_call_to_info(self, info):
        self.call_to_info = info
        
    '''
    It generates the stack variables using the arg_input attribute. 
   It returns a list with the stack variables.
    '''
    def build_input_vars(self):
        in_vars = []
        for i in xrange(self.arg_input-1,-1,-1):
            var = "s("+str(i)+")"
            in_vars.append(var)
        return in_vars

    '''
    It generates the field variables using the indexes in the list arg_global.
    It returns a list with the field variables.
    '''
    def build_field_vars(self):
        field_vars = []
        ordered = sorted(self.arg_global,key= toInt)[::-1]
        for i in ordered:
            var = "g("+ str(i)+")"
            field_vars.append(var)
        return field_vars

    '''
    It generates the local variables using the arg_local attribute.
    It returns a list with the local variables.
    '''
    def build_local_vars(self):
        local_vars = []
        ordered = sorted(self.arg_local)[::-1]
        for i in ordered:
            var = "l("+str(i)+")"
            local_vars.append(var)
        return local_vars

    '''
    It generates the final call instruction.
    '''
    def update_calls(self):
        instructions = []
        
        for elem in self.instr:
            
            posCall = elem.find("call(")

            if posCall != -1:
                posBra = elem.find("(",posCall+5)
                posInit = elem.find("global",0)
                if self.call_to_info!=None:
                    gv_aux, bc, local_vars = self.call_to_info #local_vars
                else:
                    gv_aux = self.build_field_vars()
                    bc = self.vars_to_string("data")
                    local_vars = self.build_local_vars()
                    
                gv = ", ".join(gv_aux)
                local_vars_string = ", ".join(local_vars)
                                    
                if gv != "":
                    new_instr = elem[:posInit]+gv#+", "+local_vars_string#+", "+bc+"))"
                else:
                    new_instr = elem[:posBra+1]
                    new_instr = new_instr+elem[posBra+1:posInit-1]#+local_vars_string#+", "+bc+"))"
                
                if local_vars_string != "":
                    new_instr = new_instr+", "+local_vars_string
                
                if bc != "":
                    new_instr = new_instr+", "+bc+"))"
                else:
                    new_instr = new_instr+"))"
            else:
                new_instr = elem
                
            instructions.append(new_instr)
        self.instr = instructions

    '''
    It returns a string that contains the variables specified in types.
    '''
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
                string_vars = ", ".join(sorted(self.bc))
                
        return string_vars

    '''
    It builds a string that represent the rbr.
    '''
    def rule2string(self):
        rule = ""
        
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

        if d_vars == "" and local_vars != []:
            d_vars = ", ".join(local_vars)
        elif d_vars != "" and local_vars !=[]:
            d_vars = d_vars+", "+ ", ".join(local_vars)
            
        if d_vars != "" and bc_input != "":
            d_vars = d_vars+", "+bc_input

        elif d_vars == "" and bc_input !="":
            d_vars = bc_input
            
        rule = rule + self.rule_name+"("+d_vars+")=>\n"

        if self.guard != "" :
            rule = rule + "\t"+self.guard+"\n"

        for instr in new_instr:
            rule = rule + "\t"+instr+"\n"

        return rule

    def display(self):
        print (self.rule2string())
