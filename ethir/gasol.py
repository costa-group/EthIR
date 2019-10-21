
from rbr_rule import RBRRule
import os
from utils import compute_ccomponent
# CONSTANTS
costabs_path = "/tmp/costabs/" 
tmp_path = "/tmp/"

def print_methods(rbr,source_map,contract_name) :
    
    for rules in rbr:
        for rule in rules:
            if 'block' in rule.get_rule_name(): 
                nBq = get_block_id(rule)
                print("********************************** : "+ str(rule.get_rule_name()) + " " + str(nBq))
                source = source_map.get_source_code(nBq)
                print("   " + str(source))
    # print(get_field_getters("hola"))
    # print(get_field_setters("hola"))
    # print(get_field_functions("hola"))

def get_block_id(rule) :
    nBq = str(rule.get_Id())
    pos = nBq.find("_")
    if pos == -1:
        return int(nBq)
    else:
        return int(nBq[0:pos])
    # if '_' in str(nBq): #Caso con _X
    #     i = 0
    #     while nBq[i] != '_' :
    #         bq = bq + nBq[i]
    #         i = i+1
    #     nBq = bq
    # return nBq


def optimize_solidity (block,source_map,fields_map,cname,rbr,component_of):
    # global args
    # fields = args.fields

    print("Tengo estos fields " + str(fields_map.keys()))
    solidityFile = source_map.source.content

    ##print("SOLIDITY FILE: *************\n" + solidityFile + "\n*****************")


    print block
    print fields_map
    print cname

    ccomponent = compute_ccomponent(component_of, block)

    fields_written =  is_written(rbr,ccomponent)
    
    optimized = get_optimize_method(block,source_map,fields_map,fields_written)
    initPos = source_map.get_init_pos(block)
    endPos = source_map.get_end_pos(block)

    solidityOptimized = solidityFile[:initPos] + optimized + solidityFile[endPos:]

    print("********************************************* \n\n" + solidityOptimized)

    write_file(solidityOptimized,cname)


def get_optimize_method (block,source_map,fields,fields_written):


    # print generate_getters(fields.keys())
    # print ("*******************")
    # print generate_setters(fields.keys())
    # print ("*******************")
    # print generate_functions(fields)
    # print ("*******************")
    # print declare_local_variables(fields)
    # print ("*******************")
    
    source = source_map.get_source_code(int(block))
    print("SOURCE CODE: *************\n" + source + "\n*****************")

    source = source.replace("{","{{")
    source = source.replace("}","}}")

    pos_init = source.find("{{") + 2


    defs = declare_local_variables(fields)
    
    source = source[:pos_init] + '\n'+defs+'     {0}\n' + source[pos_init:]
    lastBracePos = source.rfind("}}")
    source = source[:lastBracePos] + '\n     {1}\n' + source[lastBracePos:]

    returnPos = source.find("return ")
    if returnPos <> -1 :
        splitRes = source.split("return ")

        res = splitRes[0]
        del splitRes[0]
        for part in splitRes: 
            print("Iterando para avanzar 2")
            res = res + "\n     {1}\n     return " + part
        source = res    


    getters = generate_getters(fields.keys())
    setters = generate_setters(fields.keys(),fields_written)
    functions = generate_functions(fields)
    
    source = source.format(getters,setters)
    source = source + "\n\n" + functions

    return source


def generate_getters (fields) :
    res = ""
    for field in fields:
        res = res + get_field_getter(field) + "\n     "
    return res

def generate_setters (fields,fields_written) :
    res = ""
    for field in fields:
        if field in fields_written:
            res = res + get_field_setter(field) + "\n     "

    return res

def generate_functions (fields_map) :
    res = ""
    for field in fields_map.keys():
        field_type = fields_map[field]
        res = res + get_field_functions(field,field_type) + "\n"
    return res

def get_field_getter(field) :
    return "     {0} = get_field_{0}(); ".format(field)

def get_field_setter(field) :
    return "     set_field_{0}({0}); ".format(field)

def get_field_functions(field,field_type) :
    res = "     function get_field_{0}() private returns ({1}) {{ return {0}; }} \n"
    res = res + "     function set_field_{0}({1} val) private {{ {0} = val; }}"
    return res.format(field,field_type)


def declare_local_variables(fields_map):
    res = ""
    for field in fields_map.keys():
        field_type = fields_map[field]
        res = res + declare_local_variable(field,field_type) + "\n"

    return res

        
def declare_local_variable(field,type_field):
    res = "     {0} {1};"
    return res.format(type_field,field)


def write_file(optimized,cname = None):
    if "costabs" not in os.listdir(tmp_path):
        os.mkdir(costabs_path)

    name = costabs_path+cname[0:-4]+"_opt.sol"
    with open(name,"w") as f:
        f.write(optimized)

    f.close()

def is_written(rbr,conected_component):
    is_written = []
    for b in conected_component:
        block_name = "block"+str(b)
        [rule] = rbr[block_name]
        instrs = rule.get_instructions()
        for i in instrs:
            eq_index = i.find("=")
            field_index = i.find("g(")
            if (eq_index !=-1 and field_index !=-1) and (field_index <eq_index):
                field_sstore = i[:eq_index].strip()
                if not field_index in is_written:
                    is_written.append(field_sstore)

    fields_written = map(lambda x: x.lstrip("g(").rstrip(")"),is_written)
    return fields_written

    


