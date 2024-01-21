#!/usr/bin/python
from z3 import *
import sys
import json
import os

#
# Use calling with a file
# python cold.py "file-name|folder-name"
#

#
# Use calling directly the funcition with a list of lists like the contents of the json file
# (a,b) = compute_accesses(ojson)
# if a == -1 means the result is not valid
# othewise
# a is the number of cold acceses
# b is the number of does access that are a store
# Assuming sloads have been assigned cost 100 (warmaccess) and sstores cost 100 (reset2, i.e. warmaccess)
# Therefore sload have already payed 100 and sstores nothing as part of the access
# total additional cost for accesses: a * 2000 + b * 100
#

def var (i):
    return "v_"+str(i)

def bvar (i):
    return "b_"+str(i)

def ovar (i):
    return "o_"+str(i)

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

################################
# global functions to simplify the problem
################################

def simplify_positions(pos,ending):
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
                aux = simplify_positions(c,pos+ending)
#                print('after',aux)
                if len(aux) > 0:
                    lc.append(aux)
            #print(lc)
            if len(lc) == 1 and no_load_store_change(lc[0],pos+ending):
                pos = lc[0] + pos         
            elif len(lc) > 0: 
                npos.append([e[0],lc])
        else:
            aux = simplify_positions(e[1],pos+ending)
            if len(aux) > 0:
                npos.append([e[0],aux])
    return npos

def mult_list(l):
    p = l[0]
    for m in l[1:]:
        p *= m
    return p

def evalue_if_num(e):
    if isinstance(e,int):
        return e
    assert(isinstance(e,list))
    if len(e) == 1:
        return int(e[0])
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
        if len(exp) ==1 and isinstance(exp[0],int):
            return True
    return False

def get_constant(exp):
    if isinstance(exp,int):
        return exp
    if isinstance(exp,list):
        if len(exp) ==1 and isinstance(exp[0],int):
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
                if e[0][1] == n:
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
                return ['max']+lc
            else:
                assert(isinstance(c,int))
        return max(lc)
    else:
        assert(pos[0][0] == 'r')
        num = longest_seq_access_list(pos[1])
        if isinstance(num,list) or isinstance(pos[0][1],list):
            #At least one of btoh is not a number
            return ['*',num,pos[0][1]]
        else:
            assert(isinstance(num,int))
            assert(isinstance(pos[0][1],int))
            return num * pos[0][1]

def longest_seq_access_list(pos):
    npos = []
    for e in pos:
        npos.append(longest_seq_access(e))
    for e in npos:
        if isinstance(e,list): #Someone is not a number
            retrun ['+']+npos
        else:
            assert(isinstance(e,int))
    return sum(npos)

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

def flatten_all(lins):
    flat = []
    for e in lins:
        flat += flatten_one(e)
    return flat

def flatten_one(ins):
    assert(isinstance(ins,list))
    assert(len(ins))
    if ins[0][0] == 'r':
        return flatten_all(ins[2])
    elif ins[0][0] == 'c':
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

        self.pos2storevars ={}
        self.pos2vars = {}
        self.posvars = []
        self.boolvars = []
        self.optionvars = []

    #def get_orig_var(name):
    #    origvars.append(Int("o_"+name))
    #    return origvars[-1]

    def get_var(self):
        self.posvars.append(Bool(var(self.nvars)))
        self.nvars += 1
        return self.posvars[-1]

    def get_bool_var(self):
        self.boolvars.append(Bool(bvar(self.bvars)))
        self.bvars += 1
        return self.boolvars[-1]

    def get_option_var(self):
        self.optionvars.append(Bool(ovar(self.ovars)))
        self.ovars += 1
        return self.optionvars[-1]

    def get_expression(self,exp):
        if isinstance(exp,int):
            return exp
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
            if is_constant(ins[0][1]):
                self.generate_unbounded_repetition(v,ins[1])
            else:
                self.generate_bounded_repetition(v,get_constant(ins[0][1]),ins[1])        
        elif ins[0][0] == 'c':
            assert(ins[0][1] == 1)
            self.generate_conditional(v,ins[1])
        else:
            assert(ins[0][0]== 'a')
            assert(ins[0][1] == 1)
            self.generate_poslist(v,ins[0][2],ins[1])

    def generate_unbounded_repetition(self,v,rep):
        flat = flatten_all(rep)
        # returns a sequence of accesses
        self.generate_sequence(v,flat)
        # revise for stores (put them first if possible)

    def generate_bounded_repetition(self,v,n,rep):
        assert(false)
    
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
        if sl == 's':
            #add weighted clauses as being first access
            assert(True) #To be modified
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
        e = evalue_if_num(pos[0][1])
        return [[pos[0][0],e],get_numbered_positions_list(pos[1],spos2npos)]
    
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
    mpos = check_multipos(positions)
    #print(positions,maxseq)
    #opositions = positions.copy()
    sim_pos = simplify_positions(positions, []) #initially the continuations are empty
    new_maxseq = longest_seq_access_list(sim_pos)
    smpos = check_multipos(sim_pos)
    #print(sim_pos,new_maxseq)
    #print(len(spos2npos),maxseq,new_maxseq)

    try:
        (c,sc) = ap.get_worse_case_cold(sim_pos)
        if verbose:
            res = ''
            if c >= 0 :
                res = 'sat'
            print(os.path.basename(f),len(spos2npos),maxseq,mpos,new_maxseq,smpos,c,sc,res)
        return (c,sc)
    except:
        return (-1,0)
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
        assert(False,'The argument must be an existing file name or a folder name')

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
        compute_accesses(spositions,True)

    exit(0)
