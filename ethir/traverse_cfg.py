

def traverse_cfg(entry_point, scc_components, join_relation, vertices, property_information, result, repetitions, end_points):
    if entry_point in scc_components["unary"]:
         r1 = translate_block_property(entry_point, property_information)
         if r1 != []:
             rep = repetitions.get(entry_point,1)
             r = [["r",rep],r1]
             result.append(r)
             
         left_block = vertices[entry_point].get_jump_target()
         rigth_block = vertices[entry_point].falls_to()

         next_block = left_block if left_block != entry_point else rigth_block
         traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, result, repetitions, end_points)
         #result.append(r1)
         
    elif entry_point in scc_components["multiple"] and (end_points == [] or entry_point not in end_points):
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
        end_points.append(entry_point)
        traverse_cfg(next_block, scc_components, join_relation, vertices, property_information, result_scc, repetitions, end_points)

        print("SCC")
        print(result_scc)
        print(r)
        r_total = r+result_scc
        print(r_total)

        rep = repetitions.get(entry_point,1)
        if r_total != []:
            r = [["r",rep],r_total]
            result.append(r)
        traverse_cfg(out_block, scc_components, join_relation, vertices, property_information, result, repetitions, end_points)
        
    else:
        print("ENTRY:" + str(entry_point))
        print("END: "+str(end_points))
        if end_points == [] or entry_point not in end_points:
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
                traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, repetitions, end_points)
                print("R de uncond")
                print(result)
                
            elif block.get_block_type() == "conditional":
                print(join_relation)
                end_point_join = join_relation[entry_point]
                left_block = block.get_jump_target()
                right_block = block.get_falls_to()
                print("COND")
                print(entry_point)
                result_r1 = []
                result_r2 = []
                
                end_points.append(end_point_join)
                traverse_cfg(left_block,scc_components, join_relation, vertices, property_information, result_r1, repetitions, end_points)

                end_points.append(end_point_join)
                traverse_cfg(right_block,scc_components, join_relation, vertices, property_information, result_r2, repetitions, end_points)

                print(result_r1)
                print(result_r2)
                
                if result_r1 != [] and result_r2 != []:
                    print("HOLA1")
                    r = [["c",1],[result_r1,result_r2]]
                elif result_r1 != []:
                    print("HOLA2")
                    r = [["c",1],[result_r1]]
                elif result_r2 != []:
                    print("HOLA3")
                    r = [["c",1],[result_r2]]
                else:
                    r = []

                if r != []:
                    result.append(r)

                print("RESULT COND")
                print(result)
                
                if end_point_join not in scc_components["multiple"]:
                    traverse_cfg(end_point_join,scc_components, join_relation, vertices, property_information, result, repetitions, end_points)
                    
            elif block.get_block_type() == "falls_to":
                next_block = block.get_falls_to()
                print("falls_to")
                print(end_points)
                traverse_cfg(next_block,scc_components, join_relation, vertices, property_information, result, repetitions, end_points)
                print(result)
        elif len(end_points)>0 and entry_point in end_points:
            end_points.pop()
                

def translate_block_property(block, property_information):
    info = property_information.get_storage_analysis_info(str(block))
    if info != []:
        result = []
        for i in info:
            first_elem = ["a",1,i[2]]
            if i[2] == "s" and i[3] == "z":
                first_elem.append("z")

            if str(i[1]).find("*")==-1:
                new_set = list(map(lambda x: str(x),i[1]))
                elem = [first_elem,new_set]
                result.append(elem)
    else:
        result = []
        
    return result
    
