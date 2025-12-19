import re
import ast
import traceback
from  utils import isReal
from sympy import Function, symbols

class SRA_UB_manager: 
    
    def __init__(self, ubs, params, sccs, come_from, sto_init_cost, gastap_params) -> None:
        ## Ubs per public function identified by block id
        self.ubs = ubs
        self.params = params
        self.come_from = come_from

        self.sccs = sccs
        self.ubs_info = {}
        self.__compute_ubs(sto_init_cost)

        print(str(self))

    def __compute_ubs(self, sto_init_cost, gastap_params): 
        for function in self.ubs: 
            ubinfo = UB_info()

            sccsfun = list()
            for type in self.sccs:
                for scc in self.sccs[type]:  
                    if function not in self.come_from[scc]: 
                        continue
                    sccsfun.append(scc)

            ubinfo.process_ubs(self.ubs[function], self.params[function], sccsfun, function, sto_init_cost, gastap_params)

            self.ubs_info[function] = ubinfo

    def get_ub_info(self,function): 
        return self.ubs_info.get(function, UB_info)

    def __repr__(self) -> str:
        res = ""
        for bl in self.ubs_info: 
            res += "UB information from block: {}\n".format(str(bl))
            res += str(self.ubs_info[bl]) + "\n"

        return res
    
op_map = {
    # binary
    ast.Add: "+",
    ast.Sub: "-",
    ast.Div: "/",
    ast.Mult: "*",
    # unary
    ast.UAdd: "",
    ast.USub: "-",
}

class UB_info: 

    def __init__(self) -> None:
        self.allOK = True
        self.gas_ub = "unknown"
        self.memory_ub = "unknown"
        self.storage_accesses = "unknown"
        self.sstore_accesses = "unknown"
        self.sload_accesses = "unknown"
        self.ubscc = {}
        self.ubscclist = {}

    def process_ubs(self,origub,params,sccs, function, sto_init_cost, gastap_params): 
        
        self.memory_ub = origub[0]
        origub = origub[1]
        
        #Some special cases treatment
        if origub.find("execerror") != -1 and gastap_params != "memory":
            print("UB WARN: Error running costabs " + str(function))
            self.gas_ub = "execerror"
            self.allOK = False
            return

        if origub.find("maximize_failed") != -1 and gastap_params != "memory":
            print("UB Warn: Non maximixed expression ")
            self.gas_ub = "maximize_failed"
            self.allOK = False
            return

        if origub.find("no_rf") != -1 and gastap_params != "memory": 
            failed = re.search(r'\(failed(.*?)\)',origub).group(1)[1:]
            print("UB WARN Non terminating loop found: " + str(failed))
            self.gas_ub = "nontermin"
            self.allOK = False
            return

        if origub.find("cover_point") != -1 and gastap_params != "memory": 
            failed = re.search(r'\(failed(.*?)\)',origub).group(1)[1:]
            print("UB WARN No cover point found: " + str(failed))
            self.gas_ub = "nocoverpoint"
            self.allOK = False
            return

        if origub.find("unknown") != -1 and gastap_params != "memory": 
            print("UB WARN:** Unknown UB for function " + str(function))
            self.gas_ub = "unknown"
            self.allOK = False
            return

        if origub.find("timeout") != -1 and gastap_params != "memory": 
            print("UB WARN: Timeout UB for function " + str(function))
            self.gas_ub = "timeout"
            self.allOK = False
            return

        try: 
            self.gas_ub = self.__eval_gas_ub(origub, params, function, sto_init_cost)
            self.storage_accesses = self.__eval_stoacceses_ub(origub, params, function, sto_init_cost)
            self.sstore_accesses = self.__eval_sstore_ub(origub, params, function, sto_init_cost)
            self.sload_accesses = self.__eval_sload_ub(origub,params, function, sto_init_cost)
            
            for scc in sccs:  
                ub = self.__eval_niter_ub(origub, params, str(scc),function, sto_init_cost)
                ub = ub.strip()
                self.ubscc[scc] = ub
                ub_as_list = self.__compute(ast.parse(ub, mode="eval").body)
                if not isinstance(ub_as_list,list):
                    try:
                        ub_as_list = [int(float(ub_as_list))]
                    except:
                        ub_as_list = [ub_as_list]

                self.ubscclist[scc] = ub_as_list
        except Exception as exc: 
            self.allOK = False
            print(f"WARN: Error processing SCC {scc} with UB -> {str(exc)}") 

    def __compute(self,expr):
        match expr:
            case ast.Constant(value=value):
                return str(value)
            case ast.Name(id=id):
                return str(id)
            case ast.UnaryOp(op=op, operand=value): 
                try:
                    v = ""+op_map[type(op)] + self.__compute(value)
                    return v
                except KeyError:
                    raise SyntaxError(f"Unknown operation {ast.unparse(expr)}")
            case ast.BinOp(op=op, left=left, right=right):
                try:
                    return [op_map[type(op)], self.__compute(left), self.__compute(right)]
                except KeyError:
                    raise SyntaxError(f"Unknown operation {ast.unparse(expr)}")
            case x:
                raise SyntaxError(f"Invalid Node {ast.dump(x)}")

    def get_gas_ub(self): 
        return self.gas_ub

    def get_mem_ub(self): 
        return self.mem_ub

    
    def __eval_sstore_ub (self, origub, params, function, sto_init_cost): 

        # sto_val_cc = "c(stofinalzero)" if sto_init_cost == "zero" else "c(stofinalnonzero)"
        # sto_val_cold_cc = "c(stocoldzero)" if sto_init_cost == "zero" else "c(stocoldnonzero)"

        sto_val_cc = "c(stofinalcost)"
        sto_val_cold_cc = "c(stocoldcost)"

        sto_val_set_cc = "c(stofinalset)"
        sto_val_reset_cc = "c(stofinalreset)"
        sto_val_set_cold_cc = "c(stosetcoldcost)"
        sto_val_reset_cold_cc = "c(storesetcoldcost)"
        
        try:
            ## Computing gas ub
            ub = origub.replace("c(g)","0")
            ub = ub.replace(sto_val_cc,"0")
            ub = ub.replace(sto_val_cold_cc, "0")
            ub = ub.replace(sto_val_set_cc,"0")
            ub = ub.replace(sto_val_set_cold_cc, "0")
            ub = ub.replace(sto_val_reset_cc,"0")
            ub = ub.replace(sto_val_reset_cold_cc, "0")
            ub = re.sub('(c\([ft].*?\))','0',ub)
            ub = re.sub('(c\(store.*?\))','1',ub)
            ub = re.sub('(c\(load.*?\))','0',ub)
            ub = re.sub('(c\(set.*?\))','0',ub)
            ub = ub.replace("max", "mymax")
            ub = ub.replace("[","")
            ub = ub.replace("]","")

            params = symbols(self.__filter_variables(params))
            nat = Function("nat")
            field = Function("f")
            l = Function("l") 
            c = Function("")
            param_dict = {str(p): p for p in params}
            
            locals().update(param_dict)

            ub = eval(ub)
            ub = str(ub).replace("maxub","max")
        except:
            print(f"WARN: Error in evaluating UB (sstore) of {function}: {origub}")
            ub = origub
        return ub


    def __eval_sload_ub (self, origub, params, function, sto_init_cost): 

        # sto_val_cc = "c(stofinalzero)" if sto_init_cost == "zero" else "c(stofinalnonzero)"
        # sto_val_cold_cc = "c(stocoldzero)" if sto_init_cost == "zero" else "c(stocoldnonzero)"

        sto_val_cc = "c(stofinalcost)"
        sto_val_cold_cc = "c(stocoldcost)"
        
        sto_val_set_cc = "c(stofinalset)"
        sto_val_reset_cc = "c(stofinalreset)"
        sto_val_set_cold_cc = "c(stosetcoldcost)"
        sto_val_reset_cold_cc = "c(storesetcoldcost)"

        
        try:
            ## Computing gas ub
            ub = origub.replace("c(g)","0")
            ub = ub.replace(sto_val_cc,"0")
            ub = ub.replace(sto_val_cold_cc, "0")
            ub = ub.replace(sto_val_set_cc,"0")
            ub = ub.replace(sto_val_set_cold_cc, "0")
            ub = ub.replace(sto_val_reset_cc,"0")
            ub = ub.replace(sto_val_reset_cold_cc, "0")
            ub = re.sub('(c\([ft].*?\))','0',ub)
            ub = re.sub('(c\(store.*?\))','0',ub)
            ub = re.sub('(c\(load.*?\))','1',ub)
            ub = re.sub('(c\(set.*?\))','0',ub)
            ub = ub.replace("max", "mymax")
            ub = ub.replace("[","")
            ub = ub.replace("]","")
            
            params = symbols(self.__filter_variables(params))
            nat = Function("nat")
            field = Function("f")
            l = Function("l") 
            c = Function("")
            param_dict = {str(p): p for p in params}
            
            locals().update(param_dict)

            ub = eval(ub)
            ub = str(ub).replace("maxub","max")
        except: 
            print(f"WARN: Error in evaluating UB (sload) of {function}: {origub}")
            ub = origub
        return ub

    def __eval_stoacceses_ub (self, origub, params, function, sto_init_cost): 

        # sto_val_cc = "c(stofinalzero)" if sto_init_cost == "zero" else "c(stofinalnonzero)"
        # sto_val_cold_cc = "c(stocoldzero)" if sto_init_cost == "zero" else "c(stocoldnonzero)"

        sto_val_cc = "c(stofinalcost)"
        sto_val_cold_cc = "c(stocoldcost)"

        sto_val_set_cc = "c(stofinalset)"
        sto_val_reset_cc = "c(stofinalreset)"
        sto_val_set_cold_cc = "c(stosetcoldcost)"
        sto_val_reset_cold_cc = "c(storesetcoldcost)"
        
        try:
            ## Computing gas ub
            ub = origub.replace("c(g)","0")
            ub = ub.replace(sto_val_cc,"0")
            ub = ub.replace(sto_val_cold_cc, "0")
            ub = ub.replace(sto_val_set_cc,"0")
            ub = ub.replace(sto_val_set_cold_cc, "0")
            ub = ub.replace(sto_val_reset_cc,"0")
            ub = ub.replace(sto_val_reset_cold_cc, "0")
            ub = re.sub('(c\([ft].*?\))','0',ub)
            ub = re.sub('(c\(store.*?\))','0',ub)
            ub = re.sub('(c\(load.*?\))','0',ub)
            ub = re.sub('(c\(set.*?\))','1',ub)
            ub = ub.replace("max", "mymax")
            ub = ub.replace("[","")
            ub = ub.replace("]","")

            params = symbols(self.__filter_variables(params))
            nat = Function("nat")
            field = Function("f")
            l = Function("l") 
            c = Function("")
            param_dict = {str(p): p for p in params}
            
            locals().update(param_dict)

            ub = eval(ub)
            ub = str(ub).replace("maxub","max")
        except:
            traceback.print_exc()
            print(f"WARN: Error in evaluating UB (stoaccess) of {function}: {origub}")
            ub = origub

        return ub

    def __eval_gas_ub (self, origub, params, function, sto_init_cost):

        sto_val_set = "10050" 
        sto_val_reset = "1500"
        # sto_val_cc = "c(stofinalzero)" if sto_init_cost == "zero" else "c(stofinalnonzero)"
        sto_val_set_cc = "c(stofinalset)"
        sto_val_reset_cc = "c(stofinalreset)"
        
        stocold_val_set = "22100"
        stocold_val_reset = "3000"
        # sto_val_cold_cc = "c(stocoldzero)" if sto_init_cost == "zero" else "c(stocoldnonzero)"
        sto_val_cold_set_cc = "c(stosetcoldcost)"
        sto_val_cold_reset_cc = "c(storesetcoldcost)"
        
        try:
            ## Computing gas ub
            ub = origub.replace("c(g)","1")
            ub = ub.replace(sto_val_set_cc, sto_val_set)
            ub = ub.replace(sto_val_reset_cc, sto_val_reset)
            ub = ub.replace(sto_val_cold_set_cc, stocold_val_set)
            ub = ub.replace(sto_val_cold_reset_cc, stocold_val_reset)
            ub = re.sub('(c\([fstl].*?\))','0',ub)
            ub = ub.replace("max", "mymax")
            ub = ub.replace("[","")
            ub = ub.replace("]","")

            
            if params == "":
                params = []
            else:
                params = symbols(self.__filter_variables(params))
                
            nat = Function("nat")
            field = Function("f")
            l = Function("l") 
            c = Function("")
            param_dict = {str(p): p for p in params}
            
            locals().update(param_dict)

            ub = eval(ub)
            ub = str(ub).replace("maxub","max")
        except: 
            print(f"WARN: Error in evaluating UB (gas) of {function}: {origub}")
            ub = origub
        
        return ub

    

    
    def __eval_niter_ub(self, origub, params, scc, function, sto_init_cost): 

        # sto_val_cc = "c(stofinalzero)" if sto_init_cost == "zero" else "c(stofinalnonzero)"
        # sto_val_cold_cc = "c(stocoldzero)" if sto_init_cost == "zero" else "c(stocoldnonzero)"

        sto_val_set_cc = "c(stofinalset)"
        sto_val_reset_cc = "c(stofinalreset)"
        sto_val_cold_set_cc = "c(stosetcoldcost)"
        sto_val_cold_reset_cc = "c(storesetcoldcost)"

        try:
            scc_rep = scc.replace("_","")
            ntimesub = self.__eval_ub_cc(origub, params, "t_"+scc_rep, (sto_val_set_cc, sto_val_reset_cc), (sto_val_cold_set_cc, sto_val_cold_reset_cc), "-1")
            ncallsub = self.__eval_ub_cc(origub, params, "f_"+scc_rep, (sto_val_set_cc, sto_val_reset_cc), (sto_val_cold_set_cc, sto_val_cold_reset_cc))
            params = symbols(self.__filter_variables(params))
            param_dict = {str(p): p for p in params}
            locals().update(param_dict)

            ub = "({})/({})".format(ntimesub,ncallsub)
            # try:

            ub = eval(ub)
            # except:
            #     print("GASTAPERROR: ERROR in eval ub")
            #     ub = 0
        except:
            traceback.print_exc()
            print(f"WARN: Error in evaluating UB (niter) of {function}: {origub}")
            ub = "unknown"

        return str(ub)

    def __eval_ub_cc(self,origub,params,cc, sto_val_cc, sto_val_cold_cc, addtoub=""): 
#        try: 
        ub = origub.replace("c(g)","0")
        for cc_sto in sto_val_cc:
            ub = ub.replace(cc_sto, "0")

        print(ub)
            
        for cc_sto in sto_val_cold_cc:
            ub = ub.replace(cc_sto, "0")

        ub = ub.replace("c(" + cc + ")","1")
        ub = re.sub('(c\([fstl].*?\))','0',ub)

        ub = ub.replace("max", "mymax")
        ub = ub.replace("[","")
        ub = ub.replace("]","")

        params = symbols(self.__filter_variables(params))
        param_dict = {str(p): p for p in params}
        locals().update(param_dict)

        ub = eval(ub + addtoub)
        ub = str(ub).replace("maxub","max")
        # except: 
        #     print(f"WARN: Error in evaluating UB (ub_cc) of {function} with cc {cc}: {origub}")
        #     ub = origub
        return ub


    def __filter_variables(self, params): 
        # splited = params.split(',')
        params = list(filter(is_variable, params.split(",")))
        return params

    def __repr__(self) -> str:
        res = "   UB_gas: {} \n".format(self.gas_ub)
        res += "   UB_memory: {} \n".format(self.memory_ub)
        res += "   UB_storage_acceses: {} \n".format(self.storage_accesses)
        res += "   UB_sstore_acceses: {} \n".format(self.sstore_accesses)
        res += "   UB_sload_acceses: {} \n".format(self.sload_accesses)
        res += "   UB_SCC: {} \n".format(self.ubscc)
        res += "   UB_SCC_LIST: {} \n".format(self.ubscclist)


        return res
    
def is_variable(elem): 
    return not elem.isnumeric()

def nat (n): 
    return n 

def field(f): 
    return f

def l (n): 
    return n

def c (n): 
    return n

maxub = Function("maxub")

def mymax (*expr): 
    maxval = 0
    nonumbers = set()
    for exp in expr: 
        if str(exp).isnumeric(): 
            maxval = max(maxval,exp)
        else: 
            nonumbers.add(exp)
    
    nlen = len(nonumbers)
    if maxval == 0 and nlen == 0:
        return 0
    elif maxval > 0 and nlen == 0:
        return maxval
    elif maxval == 0 and nlen == 1: 
        return nonumbers.pop()
    elif maxval == 0 and nlen > 1: 
        return maxub(*nonumbers) 
    else: 
        return maxub(maxval,*nonumbers)    
    
