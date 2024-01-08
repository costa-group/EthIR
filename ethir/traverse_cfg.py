

def traverse_cfg(entry_point, scc_components, join_relation, vertices, property_information, result, end_point):
    if entry_point in scc_components["unary"]:
         r1 = translate_block_property(entry_point, property_information)
         if r1 != []:
             r = ["r",r1]
             result.append(r)
             
         left_block = vertices[entry_point].get_jump_target()
         rigth_block = vertices[entry_point].falls_to()

         next_block = left_block if left_block != entry_point else rigth_block
         traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, result, -1)
         #result.append(r1)
         
    elif entry_point in scc_components["multiple"] and entry_point!=end_point:
        print("HOLA MULTIPLE")
        r1 = translate_block_property(entry_point, property_information)
        if r1 != []:
            r = [r1]
        else:
            r = []

        block = vertices[entry_point]
        print(r)
        left_block = block.get_jump_target()
        rigth_block = block.get_falls_to()
        
        next_block = left_block if left_block in scc_components["multiple"][entry_point] else rigth_block
        out_block = left_block if left_block not in scc_components["multiple"][entry_point] else rigth_block
        result_scc = []
        traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, result_scc, entry_point)

        print("SCC")
        print(result_scc)
        print(r)
        r_total = r+result_scc
        print(r_total)
        
        r = ["r",r_total]
        result.append(r)
        traverse_cfg(out_block, scc_components, join_relation, vertices, property_information, result, -1)
        
    else:
        print("ENTRY:" + str(entry_point))
        print("END: "+str(end_point))
        if entry_point != end_point:
            print(entry_point)
            #print(result)
            r = translate_block_property(entry_point, property_information)
            if r != []:
                result+=r

            block = vertices[entry_point]
            if block.get_block_type() == "unconditional":
                print("uncond")
                next_block = block.get_jump_target()
                print(next_block)
                traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, end_point)
                print("R de uncond")
                print(result)
                
            elif block.get_block_type() == "conditional":
                print(join_relation)
                end_point_join = join_relation[entry_point]
                left_block = block.get_jump_target()
                right_block = block.get_falls_to()
                print("cond")

                result_r1 = []
                result_r2 = []
                
                traverse_cfg(left_block,scc_components, join_relation, vertices, property_information, result_r1, end_point_join)
                traverse_cfg(right_block,scc_components, join_relation, vertices, property_information, result_r2, end_point_join)
                
                if result_r1 != [] and result_r2 != []:
                    r = ["c",[result_r1,result_r2]]
                elif result_r1 != []:
                    r = ["c",[result_r1]]
                else:
                    r = ["c",[result_r2]]

                result.append(r)

                print("RESULT COND")
                print(result)
                
                if end_point_join not in scc_components["multiple"]:
                    traverse_cfg(end_point_join,scc_components, join_relation, vertices, property_information, result, -1)
                    
            elif block.get_block_type() == "falls_to":
                next_block = block.get_falls_to()
                print("falls_to")
                print(end_point)
                traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, end_point)
                print(result)
                

def translate_block_property(block, property_information):
    info = property_information.get_storage_analysis_info(str(block))
    if info != []:
        result = []
        for i in info:
            elem = ["a",i[1]]
            result.append(elem)
    else:
        result = []
        
    return result
    
