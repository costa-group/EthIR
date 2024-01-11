import re

from sympy import Function, symbols


class SRA_UB_manager: 
    
    def __init__(self, ubs, params, sccs) -> None:
        ## Ubs per public function identified by block id
        self.ubs = ubs
        self.params = params

        self.sccs = sccs
        self.ubs_info = {}
        self.__compute_ubs()
        print(str(self))

    def __compute_ubs(self): 
        for function in self.ubs: 
            print("Procesando UBs de " + str(function))
            ubinfo = UB_info()
            ubinfo.process_ubs(self.ubs[function], self.params[function], self.sccs)

            self.ubs_info[function] = ubinfo

    def __repr__(self) -> str:
        res = ""
        for bl in self.ubs_info: 
            res += "UB information from block: {}\n".format(str(bl))
            res += str(self.ubs_info[bl]) + "\n"

        return res
    

class UB_info: 

    def __init__(self) -> None:
        self.gas_ub = "unknown"
        self.ubscc = {}

    def process_ubs(self,origub,params,sccs): 

        self.gas_ub = self.__eval_gas_ub(origub, params)

        for type in sccs:
            for scc in sccs[type]:  
                ub = self.__eval_niter_ub(origub, params, scc)
                self.ubscc[scc] = ub

    def get_gas_ub(self): 
        return self.gasub

    def __eval_gas_ub (self, origub, params): 
        ## Computing gas ub
        ub = origub.replace("c(g)","1")
        print("UB: " + str(ub))
        ub = re.sub('(c\(.*?\))','0',ub)
        ub = ub.replace("max", "mymax")
        ub = ub.replace("[","")
        ub = ub.replace("]","")

        params = symbols(self.__filter_variables(params))
        nat = Function("nat")
        param_dict = {str(p): p for p in params}
        locals().update(param_dict)

        ub = eval(ub)
        ub = str(ub).replace("maxub","max")
        print("UB: " + str(ub))
        return ub

    def __eval_niter_ub(self, origub, params, scc): 
        ntimesub = self.__eval_ub_cc(origub, params, "t_"+str(scc))
        print("   Ntimes UB[{}]: {}".format(scc,ntimesub))
        ncallsub = self.__eval_ub_cc(origub, params, "f_"+str(scc))
        print("   NCalls UB[{}]: {}".format(scc,ncallsub))

        params = symbols(self.__filter_variables(params))
        param_dict = {str(p): p for p in params}
        locals().update(param_dict)

        ub = "{}/{}".format(ntimesub,ncallsub)
        ub = eval(ub)
        return str(ub)

    def __eval_ub_cc(self,origub,params,cc): 

        ub = origub.replace("c(g)","0")
        ub = ub.replace("c(" + cc + ")","1")
        ub = re.sub('(c\(.*?\))','0',ub)

        ub = ub.replace("max", "mymax")
        ub = ub.replace("[","")
        ub = ub.replace("]","")

        params = symbols(self.__filter_variables(params))
        param_dict = {str(p): p for p in params}
        locals().update(param_dict)

        ub = eval(ub)
        ub = str(ub).replace("maxub","max")
        return ub


    def __filter_variables(self, params): 
        # splited = params.split(',')
        params = list(filter(is_variable, params.split(",")))
        return params

    def __repr__(self) -> str:
        res = "   UB_gas: {} \n".format(self.gas_ub)
        res += "   UB_SCC: {} \n".format(self.ubscc)

        return res
    

def is_variable(elem): 
    return not elem.isnumeric()

def nat (n): 
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



