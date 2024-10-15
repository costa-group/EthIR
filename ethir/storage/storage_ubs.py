import json
import traceback
import sympy
from traverse_cfg import traverse_cfg
from storage.cold import compute_stores, compute_stores_final
from storage.sra_ub_manager import SRA_UB_manager
from utils import get_function_hash, run_gastap
from timeit import default_timer as dtimer
from storage.cold import compute_accesses as compute_accesses_cold, compute_stores, compute_stores_final
import global_params_ethir

def compute_sstore_cost(result, smt_option, initial_value):

    if initial_value == "zero":
        store_correction = 9950
    else: 
        store_correction = 1400
    warm_correction = 100

    try:
        if smt_option == "final":
            a = compute_stores_final(result)
            if a == -1:
                raise Exception()
            cost = sympy.simplify(a * store_correction)
        elif smt_option == "complete":
            if str(result).find("['r',") != -1:
                a = compute_stores_final(result)
                if (a == -1):
                    raise Exception()
                cost = sympy.simplify(a * store_correction)
            else:
                (a, b) = compute_stores(result)
                if (a == -1):
                    raise Exception()
                cost = sympy.simplify(a * (store_correction+warm_correction) + b * store_correction)
        else:
            raise Exception("UNKNOWN option for sstore costs")
    
    except Exception as e:
        print("GASTAPERROR: Error in sstore cost")
        a = b = 0
        cost = 0
        
    return cost
    


def compute_entry_functions_with_storage_instructions(input_blocks_aux, has_storage, component_of_blocks):
    input_blocks = set()
    for b in has_storage:
        c = component_of_blocks[b]
        candidates = set(c).intersection(set(input_blocks_aux)) 
        if(len(candidates) != 0):
            input_blocks = input_blocks.union(candidates)

    input_blocks = sorted(list(input_blocks))
    return input_blocks

def compute_cost_with_storage_analysis(saco,cname,source_file,storage_analysis,storage_accesses,scc,rel, function_block_map, has_storage, component_of_blocks, vertices, f_hashes):

    gastap_op = saco[1]
    smt_option = saco[2] # it could be complete or final
    timeoutvalue = saco[3]      
    initial_storage = saco[4]

    print(f"Tengo initial storage a {initial_storage}")

    input_blocks_aux = list(map(lambda x: function_block_map[x][0], function_block_map.keys()))

    input_blocks = compute_entry_functions_with_storage_instructions(input_blocks_aux, has_storage, component_of_blocks)
    
    outputs, ubs, params, times = run_gastap(cname, input_blocks, storage_analysis, gastap_op, source_file=source_file, timeoutval=timeoutvalue)

    items = list(function_block_map.items())
            
    # for b in ubs:
    #     for i in items:
    #         if b == i[1][0]:
    #             function_name = i[0]
            
    # set_identifiers = list(rbr.set_identifiers.keys())

    ubmanager = SRA_UB_manager(ubs, params, scc, component_of_blocks)

    result_sat = {}
    for i in input_blocks:
                
        result = []
        ub_info = ubmanager.get_ub_info(i)

        colds = 0
        warms = 0
        cost_sstores = 0

        cold_time = 0
        storage_time = 0
        
        for ii in items:
            if i == ii[1][0]:
                function_name = ii[0]
                function_hash = get_function_hash(f_hashes,function_name)
               
        # print("Vamos a ver que pasa " + str(ub_info.allOK))
        allOK = ub_info.allOK

        if allOK : 
            #gas_ub.startswith("Non maximixed expression") and 
            #not ub_info.gas_ub.startswith("non terminating") and 
            #not ub_info.gas_ub.startswith("unknown") and
            #not ub_info.gas_ub.startswith("timeout")):

            try:
                traverse_cfg(i, scc, rel, vertices, storage_accesses, result, ub_info.ubscclist, [])
                        
                result_sat[i] = result
                   
                if result != []:
                    source_file_path = source_file.split("/")[-1].strip(".sol")
                    with open(global_params_ethir.costabs_path+"/costabs/"+source_file_path+"_"+cname+"_block"+str(i)+".smt","w") as json_file:
                        json.dump(result,json_file)
                            
                    try:
                        x = dtimer()
                        (colds, warms) = compute_accesses_cold(result)
                        y = dtimer()
                        cold_time = y-x
                        if colds == -1:
                            raise Exception()
                    except Exception as e:
                        colds = "error" 
                        warms = "error"
                        allOK = False
                        print("GASTAPERROR: Error in COLD cost computation")

                    try:
                        x = dtimer()

                        cost_sstores = compute_sstore_cost(result,smt_option, initial_storage)

                        y = dtimer()

                        storage_time = y-x
                        
                    except Exception as e:
                        traceback.print_exc()
                        allOK = False
                        cost_sstores = "error"
                        print("GASTAPERROR: Error in sstore cost")
                else:
                    colds = 0 
                    warms = 0
                    cost_sstores = 0

                    
            except Exception as e:
                print("GASTAPERROR: Error in TRAVERSE")
                traceback.print_exc()
                colds = "error" 
                warms = "error"
                cost_sstores = "error"
                allOK = False


        # print("TENGO UB " + ub_info.gas_ub+" +"+str(colds*2000+warms*100)+" +"+str(cost_sstores))
        if allOK: 
            final_ub = sympy.simplify(ub_info.gas_ub+" +"+str(colds*2000+warms*100)+" +"+str(cost_sstores))
        else: 
            final_ub = ub_info.gas_ub

        # else:
        #     final_ub = ub_info.gas_ub
        #     colds = 0 
        #     warms = 0 
        #     cost_sstores = 0

        if gastap_op == "all":
            memory_ub = ub_info.memory_ub.strip()
        else:
            memory_ub = 0

        if allOK:     
            print("GASTAPRES: "+str(source_file)+"_"+str(cname)+"_"+ str(function_name)+";"+str(source_file)+";"+str(cname)+";"+ str(function_name)+";0x"+str(function_hash)+";block"+str(i)+";"+str("ok")+";"+str(final_ub)+";"+str(memory_ub)+";"+str(ub_info.sstore_accesses)+";"+str(ub_info.sload_accesses)+";"+str(colds*2000+warms*100)+";"+str(cost_sstores)+";"+str(round(times[i],3))+";"+str(round(cold_time,3))+";"+str(round(storage_time,3)))
        else: 
            print("GASTAPRES: "+str(source_file)+"_"+str(cname)+"_"+ str(function_name)+";"+str(source_file)+";"+str(cname)+";"+ str(function_name)+";0x"+str(function_hash)+";block"+str(i)+";"+str("uberror")+";"+str(final_ub)+";"+str(memory_ub)+";"+str(ub_info.sstore_accesses)+";"+str(ub_info.sload_accesses)+";"+str(colds)+";"+str(cost_sstores)+";"+str(round(times[i],3))+";"+str(round(cold_time,3))+";"+str(round(storage_time,3)))


def compute_cost_without_storage_analysis(cname,source_file,storage_analysis,saco, function_block_map, f_hashes):
    gastap_op = saco[1]
    timeoutvalue = saco[3]


    input_blocks_aux = list(map(lambda x: function_block_map[x][0], function_block_map.keys()))

    # input_blocks = compute_entry_functions_with_storage_instructions(input_blocks_aux)
    input_blocks = input_blocks_aux
    
    outputs, ubs, params, times = run_gastap(cname, input_blocks, storage_analysis, gastap_op, source_file=source_file, timeoutval=timeoutvalue)
    
    items = list(function_block_map.items())
    
    for b in ubs:
        for ii in items:
            if b == ii[1][0]:
                function_name = ii[0]
                function_hash = get_function_hash(f_hashes,function_name)


        (memory_ub, opcode_ub) = ubs[b]

        if gastap_op == "mem":
            memory_ub = memory_ub.strip()
            opcode_ub = 0
        elif gastap_op == "op":
            memory_ub = 0
            opcode_ub = opcode_ub.strip()
        else:
            memory_ub = memory_ub.strip()
            opcode_ub = opcode_ub.strip()

        res = "ok"
        if opcode_ub in ["unknown","execerror","timeout"]:
            res = "uberror"

        print("GASTAPRES: "+str(source_file)+"_"+str(cname)+"_"+ str(function_name)+"_block"+str(b)+";"+str(source_file)+";"+str(cname)+";"+ str(function_name)+";0x"+str(function_hash)+";block"+str(b)+";"+str(res)+";"+str(opcode_ub)+";"+str(memory_ub)+";"+str(0)+";"+str(0)+";"+str(0)+";"+str(0)+";"+str(round(times[b],3))+";"+str(0)+";"+str(0))
