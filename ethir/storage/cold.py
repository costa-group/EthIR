#!/usr/bin/python
from z3 import *
import sys
import json
import os

#
# Use calling with a file
# python cold.py "file-name|folder-name" cold|store|final
#

#
# Use calling directly the funcition that compute accesses with a list of lists like the contents of the json file
# (a,b) = compute_accesses(ojson)
# if a == -1 means the result is not valid
# othewise
# a is the number of cold acceses
# b is the number of does access that are a store
# Assuming sloads have been assigned cost 100 (warmaccess) and sstores cost 0 or 10050 ((sset+reset2)/2, i.e. (sset+warmaccess)/2)
# Therefore sload have already payed 100 and sstores nothing as part of the access
# total additional cost for accesses: a * 2000 + b * 100
#

#
# Use calling directly print(f"POS[0][2]: {pos[0][2]} {type(pos[0][2])}")the funcition that compute total sstore cost (the result may be wrong if there are loops)
# with a list of lists like the contents of the json file
# (a,b) = compute_stores(ojson)
# if a == -1 means the result is not valid
# othewise
# a is the number of store acceses
# b is the number of odd store accesses
# Assuming sstores have been assigned cost 0 
# total additional cost for sstores: a * 10050 + b * 9950
#

#
# Use calling directly the funcition that compute final cost of sstores (it means only the odd stores)
# with a list of lists like the contents of the json file
# a = compute_stores_final(ojson)
# if a == -1 means the result is not valid
# othewise
# a is the number of odd store accesses
# Assuming sstores have been assigned cost 10050 
# total additional cost for sstores: a * 9950
#


def var (i):
    return "v_"+str(i)

def tvar (i):
    return "t_"+str(i)

def bvar (i):
    return "b_"+str(i)

def ovar (i):
    return "o_"+str(i)

def pvar (i):
    return "k_"+str(i)

def bool2int(b):
    return If(b, 1, 0)

def addexists(a):
    if len(a) == 0:
        return False
    exp = a[0]
    for y in a[1:]:
       exp = Or(y,exp)
    return exp

def addforall(a):
    if len(a) == 0:
        return True
    exp = a[0]
    for y in a[1:]:
       exp = And(y,exp)
    return exp

def addsum(a):
    if len(a) == 0:
        return 0
    exp = a[0]
    for x in a[1:]:
       exp = x + exp
    return exp

def addsumBool(a):
    if len(a) == 0:
        return 0
    exp = a[0]
    for x in a[1:]:
       exp = If(x, 1, 0) + exp
    return exp

def addprod(a):
    if len(a) == 0:
        return 1
    exp = a[0]
    for x in a[1:]:
       exp = x * exp
    return exp

################################
# global functions to simplify the problem
################################

def simplify_positions_cold(pos,ending):
    #pos is the current sequence instructions to be simplified
    #ending is the instruction sequence that will be performed after pos
    npos = []
    while len(pos) > 0:
        e = pos.pop(0)
        if e[0][0] == 'a':
#            print('here a',e[1])
            if len(e[1]) == 1:
                remove_list(e[1][0],pos)
            if len(e[1]) > 0:
                npos.append(e)
        elif e[0][0] == 'c':
#            print('here c',e[1])
            lc = []
            for c in e[1]:
#                print('before',c)
                aux = simplify_positions_cold(c,pos+ending)
#                print('after',aux)
                if len(aux) > 0:
                    lc.append(aux)
            #print(lc)
            if len(lc) == 1 and no_load_store_change(lc[0],pos+ending):
                pos = lc[0] + pos         
            elif len(lc) > 0: 
                npos.append([e[0],lc])
        else:
            aux = simplify_positions_cold(e[1],pos+ending)
            if len(aux) > 0:
                npos.append([e[0],aux])
    return npos

def simplify_positions_store(pos):
    #pos is the current sequence of instructions to be simplified
    npos = []
    while len(pos) > 0:
        e = pos.pop(0)
        if e[0][0] == 'a':
#            print('here a',e[1])
            if e[0][2] == 's':
                npos.append(e)
        elif e[0][0] == 'c':
#            print('here c',e[1])
            lc = []
            for c in e[1]:
#                print('before',c)
                aux = simplify_positions_store(c)
#                print('after',aux)
                if len(aux) > 0:
                    lc.append(aux)
            #print(lc)
            if len(lc) == 1:
                pos = lc[0] + pos         
            elif len(lc) > 0: 
                npos.append([e[0],lc])
        else:
            aux = simplify_positions_store(e[1])
            if len(aux) > 0:
                npos.append([e[0],aux])
    return npos

def mult_list(l):
    p = l[0]
    for m in l[1:]:
        p *= m
    return p

def is_int(e):
    try:
        int(e)
        return True
    except:
        return False
    
def evalue_if_num(e):
    if is_int(e):
        return int(e)
    if isinstance(e,str):
        return e
    assert(isinstance(e,list))
    if len(e) == 1:
        aux = evalue_if_num(e[0])
        if isinstance(aux,str):
            return [aux]
        else:
            # assert(isinstance(aux,str))
            return aux
    if e[0] == '-':
        assert(len(e) <= 3)
        if (len(e) == 2):
            aux = evalue_if_num(e[1])
            if isinstance(aux,int):
                return -aux
            else:
                return ['-',aux]
        else:
            aux1 = evalue_if_num(e[1])
            aux2 = evalue_if_num(e[2])
            if isinstance(aux1,int) and isinstance(aux2,int):
                return aux1 - aux2
            else:
                return ['-',aux1,aux2]
    largs_num = []
    largs_exp = []        
    for a in e[1:]:
        aux = evalue_if_num(a)
        if isinstance(aux,int):
            largs_num.append(aux)
        else:
            largs_exp.append(aux)
    if e[0] == '+':
        if len(largs_exp) == 0:
            return sum(largs_num)
        else:
            if len(largs_num) > 0:
                return ['+',sum(largs_num)] + largs_exp
            else:
                return ['+'] + largs_exp
    elif e[0] == '*':
        if len(largs_exp) == 0:
            return mult_list(largs_num)
        else:
            if len(largs_num) > 0:
                return ['*',mult_list(largs_num)] + largs_exp
            else:
                return ['*'] + largs_exp
    elif e[0] == 'max':
        if len(largs_exp) == 0:
            return max(largs_num)
        else:
            if len(largs_num) > 0:
                return ['max',max(largs_num)] + largs_exp
            else:
                return ['max'] + largs_exp
    else:
         return [e[0]] + largs_num + largs_exp

def is_constant(exp):
    if isinstance(exp,int):
        return True
    if isinstance(exp,list):
        if len(exp) == 1 and isinstance(exp[0],int):
            return True
    return False

def get_constant(exp):
    if isinstance(exp,int):
        return exp
    if isinstance(exp,list):
        if len(exp) == 1 and isinstance(exp[0],int):
            return exp[0]
    assert(False)

def remove(n,e):
    if e[0][0] == 'a':
        if n in e[1]:
            e[1].remove(n)
            assert(n not in e[1])
    elif e[0][0] == 'c':
        for i in range(len(e[1])):
            remove_list(n,e[1][i])
    else:
        remove_list(n,e[1])

def remove_list(n,pos):
    for i in range(len(pos)):
        remove(n,pos[i])

def some_first_store(n,end):
    aux = end.copy()
    while len(aux) >0:
        e = aux.pop()
        if e[0][0] == 'a':
                if n in e[1]:
                    return  e[0][2] == 's'
        elif e[0][0] == 'c':
            for c in e[1]:
                if some_first_store(n,c+aux):
                    return True
        else:
            if some_first_store(n,e[1]+aux):
                    return True
    return False
    
def no_load_store_change(ins,end):
    # print(ins)
    for e in ins:
        if e[0][0] == 'a':
            if e[0][2] == 'l':
                for n in e[1]:
                    if some_first_store(n,end):
                        return False
        elif e[0][0] == 'c':
            for c in e[1]:
                if not no_load_store_change(c,end):
                    return False
        else:
            if not no_load_store_change(e[1],end):
                    return False
    return True

################################
# utils
################################

def longest_seq_access(pos):
    if pos[0][0] == 'a':
        return 1
    elif pos[0][0] == 'c':
        lc = []
        for c in pos[1]:
            lc.append(longest_seq_access_list(c))
        for c in lc:
            if isinstance(c,list):#Someone is not a number
                if len(lc) > 1:
                    return ['max']+lc
                else:
                    return lc
            else:
                assert(isinstance(c,int))
        return max(lc)
    else:
        assert(pos[0][0] == 'r')
        num = longest_seq_access_list(pos[1])
        if isinstance(num,list) or isinstance(pos[0][2],list):
            #At least one of btoh is not a number
            return ['*',num,pos[0][2]]
        else:
            assert(isinstance(num,int))
            assert(isinstance(pos[0][2],int))
            return num * pos[0][2]

def longest_seq_access_list(pos):
    npos = []
    for e in pos:
        npos.append(longest_seq_access(e))
    for e in npos:
        if isinstance(e,list): #Someone is not a number
            if len(npos) > 1:
                return ['+']+npos
            else:
                return npos
        else:
            assert(isinstance(e,int))
    return sum(npos)

def longest_seq_store(pos):
    if pos[0][0] == 'a':
        return 1
    elif pos[0][0] == 'c':
        lc = []
        for c in pos[1]:
            lc.append(longest_seq_store_list(c))
        for c in lc:
            if isinstance(c,list):#Someone is not a number
                return ['max']+lc
            else:
                assert(isinstance(c,int))
        return max(lc)
    else:
        assert(pos[0][0] == 'r')
        num = longest_seq_store_list(pos[1])
        if isinstance(num,list) or isinstance(pos[0][2],list):
            #At least one of btoh is not a number
            return ['*',num,pos[0][2]]
        else:
            assert(isinstance(num,int))
            assert(isinstance(pos[0][2],int))
            return num * pos[0][2]

def longest_seq_store_list(pos):
    npos = []
    for e in pos:
        npos.append(longest_seq_store(e))
    for e in npos:
        if isinstance(e,list): #Someone is not a number
            if len(npos) > 1:
                return ['+']+npos
            else:
                return npos
        else:
            assert(isinstance(e,int))
    return sum(npos)

def check_stores(ins):
    d = {}
    return check_stores_aux(ins,d)
    
def check_stores_aux(ins, s2p):
    for e in ins:
        if e[0][0] == 'a':
            for i in e[1]:
                if i in s2p:
                    s2p[i] += 1
                else:
                    s2p[i] = 1
        elif e[0][0] == 'c':
            s2pcmax = {}
            for c in e[1]:
                s2pc = {}
                check_stores_aux(c,s2pc)
                for i in s2pc:
                    if i in s2pcmax:
                        s2pcmax[i] = max([s2pcmax[i],s2pc[i]])
                    else:
                        s2pcmax[i] = s2pc[i]
            for i in s2pcmax:
                if i in s2p:
                    s2p[i] = s2pcmax[i] + s2p[i]
                else:
                    s2p[i] = s2pcmax[i]
        else:
            check_stores_aux(e[1],s2p)
    if len(s2p.values()) > 0:
        return max(s2p.values())
    else:
        return 0

def check_multipos(ins):
    for e in ins:
        if e[0][0] == 'a':
            if len(e[1]) > 1:
                return True
        elif e[0][0] == 'c':
            for c in e[1]:
                if check_multipos(c):
                    return True
        else:
            if check_multipos(e[1]):
                return True
    return False

def times_to_flatten_all(lins):
    if len(lins) == 0:
        return 0
    n = 1
    for e in lins:
        n = max(n,times_to_flatten_one(e))
    return n

def times_to_flatten_one(ins):
    assert(ins[0][0] != 'r')
    if ins[0][0] == 'c':
        n = 0
        for e in ins[1]:
            n += times_to_flatten_all(e) 
        return n
    else:
        return len(ins[1])

def flatten_or_unroll_all(lins):
    flat = []
    for e in lins:
        flat += flatten_or_unroll_one(e)
    return flat

def flatten_or_unroll_one(ins):
    if ins[0][0] == 'r':
        if is_constant(ins[0][2]):
            n = get_constant(ins[0][2])
            floops = flatten_or_unroll_loops_all(ins[1])
            if  n <= times_to_flatten_all(floops):
                return flatten_all(floops) #there are no loops
            else:
                return flatten_all(floops)*n #there are no loops
        else:
            return flatten_all(ins[1])
    elif ins[0][0] == 'c':
        # revise for stores (put them first when possible)
        lf = []
        for e in ins[1]:
            lf += flatten_all(e) 
        return lf
    else:
        assert(ins[0][0] == 'a')
        return list(map(lambda x: [ins[0],[x]],ins[1]))

def flatten_or_unroll_loops_all(lins):
    flat = []
    for e in lins:
        flat.append(flatten_or_unroll_loops(e))
    return flat

def flatten_or_unroll_loops(ins):
    if ins[0][0] == 'r':
        return flatten_or_unroll_one(ins)
    elif ins[0][0] == 'c':
        # revise for stores (put them first when possible)
        lf = []
        for e in ins[1]:
            lf.append(flatten_or_unroll_loops_all(e)) 
        return [ins[0],lf]
    else:
        return ins

def flatten_all(lins):
    flat = []
    for e in lins:
        flat += flatten_one(e)
    return flat

def flatten_one(ins):
    if ins[0][0] == 'r':
        return flatten_all(ins[1])
    elif ins[0][0] == 'c':
        # revise for stores (put them first when possible)
        lf = []
        for e in ins[1]:
            lf += flatten_all(e) 
        return lf
    else:
        assert(ins[0][0] == 'a')
        return list(map(lambda x: [ins[0],[x]],ins[1]))

################################
# SAT generation class
################################

class Access_Problem:

    def __init__(self):
        #self.origvars = [];
        self.s = Optimize()

        self.nvars = 0
        self.bvars = 0
        self.ovars = 0
        
        self.tvars = 0
#        self.uvars = 0
        self.pvars = 0

        self.pos2storevars ={}
        self.pos2vars = {}
        self.posvars = []
        self.boolvars = []
        self.optionvars = []
        self.origvars = [];
        self.timesvars = [];
#        self.usedvars = []
        self.parityvars = []

    def get_var(self):
        self.posvars.append(Bool(var(self.nvars)))
        self.nvars += 1
        return self.posvars[-1]

    def get_ivar(self):
        self.posvars.append(Int(var(self.nvars)))
        self.nvars += 1
        return self.posvars[-1]

    def get_times_var(self):
        self.timesvars.append(Int(tvar(self.tvars)))
        self.tvars += 1
        return self.timesvars[-1]

    def get_bool_var(self):
        self.boolvars.append(Bool(bvar(self.bvars)))
        self.bvars += 1
        return self.boolvars[-1]

    def get_option_var(self):
        self.optionvars.append(Bool(ovar(self.ovars)))
        self.ovars += 1
        return self.optionvars[-1]

    def get_orig_var(self,name):
        self.origvars.append(Int("o_"+name))
        return self.origvars[-1]

#    def get_used_var():
#        self.usedvars.append(Bool(uvar(uvars)))
#        self.uvars += 1
#        return self.usedvars[-1]

    def get_parity_var(self):
        self.parityvars.append(Int(pvar(self.pvars)))
        self.pvars += 1
        return self.parityvars[-1]

    def get_expression(self,exp):
        if isinstance(exp,int):
            return IntVal(exp)
        elif isinstance(exp,str):
            return self.get_orig_var(exp)
        else:
            assert(isinstance(exp,list))
            assert(len(exp))
            if len(exp) > 1:
                assert(isinstance(exp[0],str))
                assert(exp[0] == '+' or exp[0] == '*')
                args = list(map(lambda x: self.get_expression(x),exp[1:]))
                if exp[0] == '+':
                    return addsum(args)
                else:
                    return addprod(args)
            else:
                return self.get_expression(exp[0])

    def generate_sequence(self,v,lins):
        assert(isinstance(lins,list))
        #seq_vars = []
        for se in lins:
            o = self.get_option_var()
            self.s.add(v == o)
            #seq_vars.append(o)
            self.generate_instruction(o,se)

    def generate_instruction(self,v,ins):
        assert(isinstance(ins,list))
        assert(len(ins))
        if ins[0][0] == 'r':
            flat = flatten_or_unroll_one(ins)
            # returns a sequence of accesses
            self.generate_sequence(v,flat)
        elif ins[0][0] == 'c':
            assert(ins[0][1] == 1 or ins[0][1][0] == 1)
            self.generate_conditional(v,ins[1])
        else:
            assert(ins[0][0]== 'a')
            assert(ins[0][1] == 1 or ins[0][1][0] == 1)
            self.generate_poslist(v,ins[0][2],ins[1])

    def generate_conditional(self,v,cond):
        assert(isinstance(cond,list))
        #    if not isinstance(cond[0],list):
        #        generate_poslist(v,cond)
        #        return
        cond_vars = []
        for c in cond:
            o = self.get_option_var()
            cond_vars.append(o)
            self.generate_sequence(o,c)
        self.addAtMostOne(cond_vars)
        self.s.add(v == addexists(cond_vars))

    def generate_poslist(self,v,sl,poslist):
        myvars = []
        for e in poslist:
            pv = self.get_var()
            if e in self.pos2vars:
                self.pos2vars[e].append(pv)
            else:
                self.pos2vars[e] = [pv]
            if sl == 's':
                if e in self.pos2storevars:
                    self.pos2storevars[e].append(pv)
                else:
                    self.pos2storevars[e] = [pv]
            myvars.append(pv)
        self.addAtMostOne(myvars)
        self.s.add(v == addexists(myvars))

    def addAtMostOne(self,lvar):
        for i in range(len(lvar)):
            for j in range(i+1,len(lvar)):
                self.s.add(Implies(lvar[i],Not(lvar[j])))

    def get_worse_case_cold(self,lins):
        o0 = self.get_option_var()
        self.s.add(o0)
        self.generate_sequence(o0,lins)

        for p in self.pos2vars:
            ors = addexists(self.pos2vars[p])
            b = self.get_bool_var()
            self.s.add( b == ors )
            self.s.add_soft( b, 21 )

        for p in self.pos2storevars:
            for  v in self.pos2storevars[p]:
                i = self.pos2vars[p].index(v)
                if i == 0:
                    self.s.add_soft( v, 1 )
                else:
                    self.s.add_soft(And(Not(addexists(self.pos2vars[p][:i])),v),1)
        #print(self.s.to_smt2())
        #print(self.s.assertions())

        #self.s.set("timeout",300)
        res = self.s.check()
        #print(self.s.statistics())
        #print(res)
        if res == sat:
            #print(self.s.model())

            colds = 0
            for x in self.boolvars:
                if self.s.model().eval(x) == True:
                    colds += 1
                #    print(self.s.model().eval(x))
            scolds = 0
            for p in self.pos2storevars:
                for  v in self.pos2storevars[p]:
                    i = self.pos2vars[p].index(v)
                    for x in self.pos2vars[p][:i]:
                        if self.s.model().eval(x) == True:
                            break
                    else:
                        if self.s.model().eval(v) == True:
                            scolds += 1
            return (colds,scolds)
        else:
            return (-1,0)

    def poslist2sum(self,poslist):
        myvars = []
        for e in poslist:
            v = self.get_ivar()
            if e in self.pos2vars:
                self.pos2vars[e].append(v)
            else:
                self.pos2vars[e] = [v]
            myvars.append(v)
        return addsum(myvars)

    def generate_sequence_store(self,v,seq):
        for e in seq:
            if e[0][0] == "r":
                self.generate_repetition_store(v,e)
            elif e[0][0] == "c":
                self.generate_conditional_store(v,e)
            else:
                assert(e[0][0] == "a")
                self.generate_access_store(v,e)

    def generate_conditional_store(self,v,cond):
        times = self.get_expression(cond[0][1]) * v
        tlist = []
        for c in cond[1]:
            k = self.get_times_var()
            tlist.append(k)
            self.generate_sequence_store(k,c)
        suma = addsum(tlist)
        self.s.add( suma == times)

    def generate_repetition_store(self,v,rep):
        times = self.get_expression(rep[0][2]) * v
        self.generate_sequence_store(times,rep[1])

    def generate_access_store(self,v,acc):
        times = self.get_expression(acc[0][1]) * v
        suma = self.poslist2sum(acc[1])
        self.s.add( suma == times)

    def get_worse_case_store(self,lins):
        self.generate_sequence_store(IntVal(1),lins)
        for v in self.pos2vars:
            suma = addsum(self.pos2vars[v])
            k = self.get_parity_var()
            b = self.get_bool_var()
            self.s.add( b == (suma == 2*k + 1) )
            self.s.add_soft( b, 1 )
        for v in self.posvars:
            self.s.add( v >= 0 )
            self.s.add_soft( v > 0, 1 )
        for v in self.parityvars:
            self.s.add(v >= 0)
        for v in self.origvars:
            self.s.add(v >= 0)
        for v in self.timesvars:
            self.s.add(v >= 0)
        res = self.s.check()
        #print(self.s.statistics())
        #print(res)
        if res == sat:
            sets = 0
            for x in self.boolvars: #check parity
                if self.s.model().eval(x) == True:
                    sets += 1
            nstores = 0
            for x in self.posvars:
#                print(type(self.s.model().eval(x)))
                if self.s.model().eval(x).as_long() > 0:
                    nstores += 1
            return (nstores,sets) 
        else:
            return (-1,0)
        
    def get_worse_case_store_final(self,lins):
        self.generate_sequence_store(IntVal(1),lins)
        for v in self.pos2vars:
            suma = addsum(self.pos2vars[v])
            k = self.get_parity_var()
            b = self.get_bool_var()
            self.s.add( b == (suma == 2*k + 1) )
            self.s.add_soft( b, 1 )
        for v in self.posvars:
            self.s.add( v >= 0 )
        for v in self.parityvars:
            self.s.add(v >= 0)
        for v in self.origvars:
            self.s.add(v >= 0)
        for v in self.timesvars:
            self.s.add(v >= 0)
        res = self.s.check()
        #print(self.s.statistics())
        #print(res)
        if res == sat:
            sets = 0
            for x in self.boolvars: #check parity
                if self.s.model().eval(x) == True:
                    sets += 1
            return sets 
        else:
            return -1

################################################
# Preprocess functions to replace postion string names by numbered positions
################################################

def get_numbered_positions(pos,spos2npos):
    if pos[0][0] == 'a':
        lp = []
        for p in pos[1]:
            if p not in spos2npos:
                n =len(spos2npos)
                spos2npos[p] = n
            lp.append(spos2npos[p])
        return [pos[0],lp]
    elif pos[0][0] == 'c':
        #if len(pos[1]) > 1: print('morethanone')
        #if len(pos[1]) > 2: print('morethantwo')
        lc = []
        for c in pos[1]:
            lc.append(get_numbered_positions_list(c,spos2npos))
        return [pos[0],lc]
    else:
        assert(pos[0][0] == 'r')
        e = evalue_if_num(pos[0][2])
        return [[pos[0][0],pos[0][1],e],get_numbered_positions_list(pos[1],spos2npos)]
    
def get_numbered_positions_list(pos,spos2npos):
    npos = []
    for e in pos:
        npos.append(get_numbered_positions(e,spos2npos))
    return npos

################################################
# function to deal with a json
################################################

def compute_accesses(spositions,verbose = False):
    assert(isinstance(spositions,list))

    ap = Access_Problem()
    spos2npos = {}
    #print(sys.argv[1])
    #print(spositions)
    positions = get_numbered_positions_list(spositions,spos2npos)
    maxseq = longest_seq_access_list(positions)
    #mpos = check_multipos(positions)
    #print(positions,maxseq)
    #opositions = positions.copy()
    sim_pos = simplify_positions_cold(positions, []) #initially the continuations are empty
    new_maxseq = longest_seq_access_list(sim_pos)
    #smpos = check_multipos(sim_pos)
    #print(sim_pos,new_maxseq)
    #print(len(spos2npos),maxseq,new_maxseq)
    #(c,sc) = ap.get_worse_case_cold(sim_pos)
    try:
        (c,sc) = ap.get_worse_case_cold(sim_pos)
        if verbose:
            res = ''
            if c >= 0 :
                res = 'sat'
            print(os.path.basename(f),len(spos2npos),maxseq,new_maxseq,c,sc,res)
        return (c,sc)
    except:
        if verbose:
            print(os.path.basename(f),'Error')
        return (-1,0)

def compute_stores(spositions,verbose = False):
    assert(isinstance(spositions,list))

    ap = Access_Problem()
    spos2npos = {}
    positions = get_numbered_positions_list(spositions,spos2npos)
    #print(sys.argv[1])
    #print(spositions)
    #print(positions,maxseq)
    #opositions = positions.copy()
    sim_pos = simplify_positions_store(positions) #initially the continuations are empty
    new_maxseq = longest_seq_store_list(sim_pos)
    smpos = check_stores(sim_pos)
    #print(sim_pos,new_maxseq)
    #print(len(spos2npos),maxseq,new_maxseq)
    try:
        (s,es) = ap.get_worse_case_store(sim_pos)
        if verbose:
            res = ''
            if s >= 0 :
                res = 'sat'
            print(os.path.basename(f),new_maxseq,smpos,s,es,res)
        return (s,es)
    except:
        if verbose:
            print(os.path.basename(f),'Error')
        return (-1,0)

def compute_stores_final(spositions,verbose = False):
    assert(isinstance(spositions,list))

    ap = Access_Problem()
    spos2npos = {}
    positions = get_numbered_positions_list(spositions,spos2npos)
    #print(sys.argv[1])
    #print(spositions)
    #print(positions,maxseq)
    #opositions = positions.copy()
    sim_pos = simplify_positions_store(positions) #initially the continuations are empty
    #print(sim_pos,es)
    try:
        es = ap.get_worse_case_store_final(sim_pos)
        if verbose:
            res = ''
            if es >= 0 :
                res = 'sat'
            print(os.path.basename(f),es,res)
        return es
    except:
        if verbose:
            print(os.path.basename(f),'Error')
        return -1

######################################
# main
######################################

if __name__ == '__main__':
    
    if len(sys.argv) < 2:
        print('A json file name or a folder name is needed')
        exit(1)

    name = ' '
    if os.path.exists(sys.argv[1]):
        name = os.path.abspath(sys.argv[1])
    else:
        assert(False,'The first argument must be an existing file name or a folder name')

    action = 'cold'
    if len(sys.argv) == 3:
        action = sys.argv[2]

    assert action in ['cold','store','final'], 'the second argument can only be cold (default), store or final'

    myfiles = []
    if os.path.isdir(name):
        myfiles =  [name+'/'+f for f in os.listdir(name)]
        myfiles.sort()
    elif os.path.isfile(name):
        myfiles =  [name]
    else:
        assert False , 'The argument must be a file name or a folder name'
    
    #print(len(myfiles))

    for f in myfiles: 
        myfile = open(f)
        spositions = json.load(myfile)
        if action == 'store':
            compute_stores(spositions,True)
#            (s,es1) = compute_stores(spositions)
#            es2 = compute_stores_final(spositions)
#            print(os.path.basename(f),s,es1,es2)
        elif action == 'final':
            compute_stores_final(spositions,True)
        else:
            compute_accesses(spositions,True)
    exit(0)
