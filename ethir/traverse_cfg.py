

def traverse_cfg(entry_point, scc_components, join_relation, vertices, property_information, result, end_point):
    if entry_point in scc_components["unary"]:
         r1 = translate_block_property(entry_point, property_information)
         if r1 != []:
             r = ["r",r1]
             result+=r
             
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
        r_scc = traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, [], entry_point)

        print("SCC")
        print(r_scc)
        print(r)
        r_total = r+r_scc
        print(r_total)
        
        r = ["r",r_total]
        result+=r
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
                r = traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, end_point)
                print("R de uncond")
                print(r)
                
            elif block.get_block_type() == "conditional":
                print(join_relation)
                end_point_join = join_relation[entry_point]
                left_block = block.get_jump_target()
                right_block = block.get_falls_to()
                print("cond")
                
                r1 = traverse_cfg(left_block,scc_components, join_relation, vertices, property_information, [], end_point_join)
                r2 = traverse_cfg(right_block,scc_components, join_relation, vertices, property_information, [], end_point_join)

                print(r1)
                print(r2)
                
                if r1 != [] and r2 != []:
                    r = ["c",[r1,r2]]
                elif r1 != []:
                    r = ["c",[r1]]
                else:
                    r = ["c",[r2]]

            elif block.get_block_type() == "falls_to":
                next_block = block.get_falls_to()
                print("falls_to")
                print(end_point)
                r = traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, end_point)
                print(r)
                
            if r != []:
                result=r
    
            if end_point != -1 and end_point not in scc_components["multiple"]:
                r = traverse_cfg(end_point,scc_components, join_relation, vertices, property_information, result, -1)
                #result.append(r)
            
    return result

def translate_block_property(block, property_information):
    info = property_information.get_storage_analysis_info(str(block))
    if info != []:
        result = []
        for i in info:
            elem = ["a",i.split(":")[-1]]
            result.append(elem)
    else:
        result = []
        
    return result
    
