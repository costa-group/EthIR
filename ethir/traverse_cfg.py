

def traverse_cfg(entry_point, scc_components, join_relation, vertices, property_information, result, end_point = -1):
    if entry_point in scc_components["unary"]:
         r1 = translate_block_property(entry_point, property_information)
         if r1 != None:
             r = ["r",r1]
             result.append(r)
             
         left_block = vertices[entry_point].get_jump_target()
         rigth_block = vertices[entry_point].falls_to()

         next_block = left_block if left_block != entry_point else rigth_block
         traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, result)
         #result.append(r1)
         
    elif entry_point in scc_components["multiple"]:
        r1 = translate_block_property(entry_point, property_information)
        if r1 != None:
            r = [r1]
        else:
            r = []
            
        block = vertices[entry_point]

        left_block = vertices[entry_point].get_jump_target()
        rigth_block = vertices[entry_point].falls_to()
        
        next_block = left_block if left_block in scc_components["multiple"][entry_point] else rigth_block
        out_block = left_block if left_block not in scc_components["multiple"][entry_point] else rigth_block
        r_scc = traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, [], entry_point)
        r_total = r+r_scc
        
        r = ["r",r_total]
        result.append(r)
        traverse_cfg(out_block, scc_components, join_relation, vertices, property_information, result)
        
    else:
        if entry_point != end_point:
            r = translate_block_property(entry_point, property_information)
            if r != None:
                result.append(r)

            block = vertices[entry_point]
            end_point = -1
            if block.get_block_type() == "unconditional":
                next_block = block.get_jump_target()
                r = traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result)

            elif block.get_block_type() == "conditional":
                end_point = join_relation[entry_point]
                left_block = block.get_jump_target()
                right_block = block.get_falls_to()
                r1 = traverse_cfg(left_block,scc_components, join_relation, vertices, property_information, [], end_point)
                r2 = traverse_cfg(right_block,scc_components, join_relation, vertices, property_information, [], end_point)
                r = ["c",[r1,r2]]
        
            elif block.get_block_type() == "falls_to":
                next_block = block.get_falls_to()
                r = traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result)

            result.append(r)
    
            if end_point != -1:
                r = traverse_cfg(end_point,scc_components, join_relation, vertices, property_information, result)
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
        result = None
        
    return result
    
