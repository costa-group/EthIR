from rbr_rule import RBRRule

def print_methods(rbr,source_map,contract_name) :
    
    # for rules in rbr:
    #     for rule in rules:
    #         if 'block' in rule.get_rule_name(): 
    #             nBq = get_block_id(rule)
    #             print("********************************** : "+ str(rule.get_rule_name()) + " " + str(nBq))
    #             source = source_map.get_source_code(nBq)
    #             print("   " + str(source))
    # print(get_field_getters("hola"))
    # print(get_field_setters("hola"))
    # print(get_field_functions("hola"))
    optimize_method('block68',source_map)

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

def get_field_getters(field) :
    return "     {0} = getField_{0}(); ".format(field)

def get_field_setters(field) :
    return "     setField_{0} ({0}); ".format(field)

def get_field_functions(field) :
    res = "     function get_field_{0} () private returns (uint) {{ return {0} }}; \n"
    res = res + "     function set_field_{0} (uint val) private {{ {0} = val; }}"
    return res.format(field)

def optimize_method (block,source_map):
    solidityFile = source_map.get_source_code(0)

    print("SOLIDITY FILE: *************\n" + solidityFile + "\n*****************")

    source = source_map.get_source_code(70)

    source = source.replace("{","{{")
    source = source.replace("}","}}")

    pos_init = source.find("{{") + 2

    print("SOURCE ORIG CODE: *************\n" + source + "\n*****************")
    source = source[:pos_init] + '\n     {0}\n' + source[pos_init:]

    returnPos = source.find("return ")
    if returnPos != -1 :
        splitRes = source.split("return ")

        res = splitRes[0]
        splitRes.remove(0)
        # for part in splitRes: 
        #     res = res + part + "\n     {{1}}\n     return "
    
    print("RES " + res)
    source = res

    print("SOURCE CODE: *************\n" + source + "\n*****************")





    





