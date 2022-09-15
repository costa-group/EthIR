from basicblock import BasicBlock
from opcodes import get_opcode

global arithemtic_operations
arithemtic_operations = ["ADD","SUB","MUL","DIV","AND","OR","EXP","SHR","SHL"]

global slots 
slots = None

global memory 
memory = None

global accesses
accesses = None

global debug_info

# If we found a potential access out of a slot
global g_found_outofslot
g_found_outofslot = False

global g_contract_name 
global g_contract_source 
global g_source_map
global g_source_info 
global g_function_block_map
global g_component_of_blocks


class MemoryAccesses: 
    def __init__ (self,readset,writeset,initset,closeset,vertices):
        self.readset = readset
        self.writeset = writeset
        self.initset = initset
        self.closeset = closeset
        self.vertices = vertices
        
    def add_read_access (self,pc,slot): 
        if self.readset.get(pc) is None:
            self.readset[pc] = set([slot])
        else:    
            self.readset[pc].add(slot)

    def add_write_access (self,pc,slot): 
        if self.writeset.get(pc) is None:
            self.writeset[pc] = set([slot])
        else:    
            self.writeset[pc].add(slot)

    def add_allocation_init (self,pc,slot): 
        if self.initset.get(pc) is None:
            self.initset[pc] = set([slot])
        else:    
            self.initset[pc].add(slot)

    def add_allocation_close (self,pc,slot): 
        if self.closeset.get(pc) is None:
            self.closeset[pc] = set([slot])
        else:    
            self.closeset[pc].add(slot)

    def process_free_mstores (self,smap): 

        #print("Evaluating potential optimizations: " + " " + str(self.writeset))
        for writepp in self.writeset:
            for slot in self.writeset[writepp]: 

                # Check write block...

                visited = set({})
                block_id = get_block_id(writepp)
                found,pp = self.search_read(slot, block_id, visited)
                if found: 
                    print("MEMRES: Found read -> " + writepp + " : " + pp)
                elif self.is_for_revert(writepp): 
                    print("MEMRES: Found write for revert -> " + writepp)
                elif not g_found_outofslot:
                    print ("MEMRES poten" + str(g_found_outofslot))
                    func = get_function_from_blockid(writepp)

                    #pc = int(writepp.split(":")[0]) # + int(writepp.split(":")[1])
                    
                    #print("OLEOLE *****************************" + str(pc))
                    #print("OLEOLE " + str(pc) + " -- " + str(smap.get_source_code(pc)) + "--")
                    #print("OLEOLE -----------------------------" + str(pc))
                    print("MEMRES: NOT Found read (potential optimization) -> " + str(slot) + " " + str(writepp) + " : " + str(pp) + " --> " + str(g_contract_source) + " " + str(g_contract_name) + "--" + str(func))

    def is_for_revert(self,writepp): 
        
        block_id = get_block_id(writepp)
        block_info = self.vertices[block_id]
        instr = block_info.get_instructions()[-1]
        return instr == "REVERT"

    
    def search_read(self, slot, block_id, visited): 
        if (block_id in visited): 
            return False, None

        
        filtered = list(filter(lambda x: x.startswith(str(block_id)+":"), self.readset))
        for readblock in filtered: 
            #print("Searching: " + slot + " " + str(block_id) + " ** " + str(self.readset[readblock]))
            if slot in self.readset[readblock]: 
                return True, readblock

        found = False
        pp = None
        visited.add(block_id)
        blockinfo = self.vertices[block_id]
        jump_target = blockinfo.get_jump_target()        
        if jump_target != 0:
           found, pp = self.search_read(slot, jump_target, visited) 

        jump_target = blockinfo.get_falls_to()
        if jump_target != None and not found: 
           found, pp = self.search_read(slot, jump_target, visited) 

        return found, pp

                

    def get_cfg_info (self,block_in): 
        result = []
        self.process_set(block_in,self.initset, "I", result)
        self.process_set(block_in,self.closeset, "C", result)
        self.process_set(block_in,self.readset, "R", result)
        self.process_set(block_in,self.writeset, "W", result)
        
        return sorted(result,key=order_accesses)

    def process_set (self,block_in, set_in, text, result): 
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            #instr = self.vertices[block_in].get_instructions()[offset]
            if block == block_in: 
                #result.append(offset + " " + instr + "[" + text + "] -> " + str(list(set_in[pc]))) 
                result.append(offset + " [" + text + "] -> " + str(list(set_in[pc]))) 

    def __repr__(self):
        return ("INIT ALLOC: " + str(self.initset) +
                "\n\nCLOSE ALLOC:" + str(self.closeset) + 
                "\n\nREAD: " + str(self.readset) + 
                "\n\nWRITE: " + str(self.writeset))


class MemoryAbstractState:
    
    def __init__(self,stack_pos,stack,memory):
        self.stack_pos = stack_pos
        self.stack = stack
        self.memory = memory

    def get_stack_pos (self): 
        return self.stack_pos

    def get_stack (self): 
        return self.stack

    def get_memory (self): 
        return self.memory

    def leq (self,state): 
        for skey in self.get_stack(): 
            if (skey not in state.stack or 
                not (set(self.get_stack()[skey]) <= set(state.stack[skey]))):
                return False

        for mkey in self.get_memory(): 
            if (mkey not in state.memory or 
                not (set(self.get_memory()[mkey]) <= set(state.memory[mkey]))):
                return False
        
        return True

    def lub (self,state): 
        if self.stack_pos != state.get_stack_pos(): 
            print("MEM ANALYSIS WARNING: Different stacks in lub !!! ")
            print("MEM ANALYSIS WARNING: " + str(self))
            print("MEM ANALYSIS WARNING: " + str(state))


        res_stack = self.stack.copy(); 
        res_memory = self.memory.copy();

        for skey in state.get_stack(): 
            if skey in res_stack: 
                res_stack[skey] = list(set(res_stack[skey] + state.get_stack()[skey]))
            else:
                res_stack[skey] = state.get_stack()[skey]

        for mkey in state.get_memory(): 
            if mkey in res_memory: 
                res_memory[mkey] = list(set(res_memory[mkey] + state.get_memory()[mkey]))
            else:
                res_memory[mkey] = state.get_memory()[mkey]

        return MemoryAbstractState(self.stack_pos, res_stack, res_memory)


    def process_instruction (self,instr,pc):
        global accesses
        global slots
        global g_found_outofslot
        
        op_code = instr.split()[0]

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        # We save in the stack special memory addresses        
        if is_mload(instr,"64"):
            accesses.add_read_access(pc,"mem40")
            stack[top] = slots.get_analysis_results(pc).get_slot(pc)

        elif is_mstore(instr,"64"):
            accesses.add_write_access(pc,"mem40")

        elif is_mstore(instr,"4"):
            accesses.add_write_access(pc,"mem4")

        elif is_mstore(instr,"32"):
            accesses.add_write_access(pc,"mem0")

        elif is_mstore(instr,"0"):
            accesses.add_write_access(pc,"mem0")

        elif op_code == "PUSH1" and instr.split()[1] == "0x60": 
            stack[self.stack_pos] = ["null"]
            accesses.add_allocation_init(pc,"null")                                

        elif op_code.startswith("LOG") or op_code == "RETURN" or op_code == "REVERT": 
            if top in stack: 
                self.add_read_access(top,pc,stack)

        elif op_code == "SHA3": 
            if top in stack: 
                self.add_read_access(top,pc,stack)
            else:  
                accesses.add_read_access(pc,"mem0") 

        elif op_code == "CALL" or op_code == "CALLCODE": 
            self.add_read_access(top-3,pc,stack)
            self.add_write_access(top-5,pc,stack)

        elif op_code == "STATICCALL" or op_code == "DELEGATECALL": 
            self.add_read_access(top-2,pc,stack)
            self.add_write_access(top-4,pc,stack)

        elif op_code in ["CALLDATACOPY","CODECOPY","RETURNDATACOPY"]:
            self.add_write_access(top,pc,stack)

        elif op_code == "EXTCODECOPY" or op_code.startswith("CREATE"):
            self.add_write_access(top-1,pc,stack)

        elif op_code == "MLOAD": 
            self.add_read_access(top,pc,stack)
            if top in stack: 
                reslist = []
                for memaddress in stack[top]: 
                    if memaddress in memory: 
                        reslist = reslist+memory[memaddress]
                if len(reslist) > 0: 
                    stack[top] = list(set(reslist))
                else:
                    stack.pop(top,None)
            else: 
                print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)
                accesses.add_read_access(pc,"unknown")                                   
            

        elif op_code == "MSTORE8":
            self.add_write_access(top,pc,stack)

        elif op_code == "MSTORE": 
            self.add_write_access(top,pc,stack)
            if top in stack:
                for memaddress in stack[top]:
                    if top-1 in stack: 
                        for memitem in stack[top-1]:
                            if memaddress in memory:
                                memory[memaddress] = list(set(memory[memaddress] + [memitem]))
                            else: 
                                memory[memaddress] = [memitem]
            else: 
                print("MEMORY ANALYSIS WARNING: Unknown access at this point " + pc)
                accesses.add_write_access(pc,"unknown")                                

        elif op_code in arithemtic_operations:

            if top in stack and (not top-1 in stack): 
                stack[top-1] = stack[top]
                if op_code == "SUB": 
                    print ("MEMORY ANALYSIS WARNING (" + pc + "): Subtracting a slot minus a number " + str(stack[top]) + ". Ignoring optimizations of this function")
                    g_found_outofslot = True

            elif top-1 in stack and (not top in stack): 
                pass
                #stack[top-1] = stack[top-1]
            elif top in stack and top-1 in stack: 
                # print ("MEMORY ANALYSIS WARNING (" + pc + "): Arithmentic operations with two slots: " + 
                #         op_code + " (" + 
                #         str(stack[top-1]) + "," + 
                #         str(stack[top]) + ")")
                if stack[top] == ["null"] and stack[top-1] != ["null"]: 
                    #stack[top-1] = stack[top-1]
                    pass
                elif stack[top] != ["null"] and stack[top-1] == ["null"]: 
                    stack[top-1] = stack[top]
                elif op_code == "SUB": 
                    stack.pop(top-1,None)
                elif stack[top] != ["null"] or stack[top-1] != ["null"]: 
                    stack[top-1] = filter(lambda x: x != "null", list(set(stack[top]+stack[top-1])))

        elif op_code == "POP":
            stack.pop(top,None)

        elif op_code.startswith("DUP",0):
            position = top-int(op_code[3:], 10)+1
            if position in stack:
                stack[self.stack_pos] = stack[position]

        elif op_code.startswith("SWAP",0):
            position = top-int(op_code[4:], 10)
            if position in stack and not(top in stack):
                stack[top] = stack[position] 
                stack.pop(position,None)
            elif top in stack and not(position in stack): 
                stack[position] = stack[top] 
                stack.pop(top,None)
            elif top in stack and position in stack:
                valpos = stack[position] 
                stack[position] = stack[top]
                stack[top] = valpos

        for i in range(stack_res,self.stack_pos): 
            stack.pop(i,None)

        return MemoryAbstractState(stack_res, stack, memory)

    def add_read_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                accesses.add_read_access(pc,memaddress)

    def add_write_access (self,pos, pc, stack):
        if pos in stack: 
            for memaddress in stack[pos]: 
                accesses.add_write_access(pc,memaddress)


    def __repr__(self):
        return (#"pos = " + str(self.stack_pos) + 
                " stack^" + str(self.stack_pos) + " = " + str(self.stack) + 
                " :: memory = " + str(self.memory))

class SlotsAbstractState:

    global slots_autoid
    slots_autoid = 0

    def __init__(self,opened,closing_pairs,pc_slot):
        #
        self.opened = opened
        self.closing_pairs = closing_pairs
        self.pc_slot = pc_slot
        
    def leq (self,state): 
        return state.opened <= self.opened

    def lub (self,state): 
        opened = self.opened.copy()
        stateopen = state.opened.copy()
        stateclose = state.closing_pairs.copy()
        pc_slot = self.pc_slot.copy()

        lubopen= opened.union(stateopen)

        for skey in state.closing_pairs:
            if skey in stateclose: 
                stateclose[skey] = stateclose[skey].union(state.closing_pairs[skey])
            else:
                stateclose[skey] = state.closing_pairs[skey]

        for skey in state.pc_slot:
            if skey in stateclose: 
                pc_slot[skey] = list(set(pc_slot[skey] + state.pc_slot[skey]))
            else:
                pc_slot[skey] = state.pc_slot[skey]

        return SlotsAbstractState(lubopen,stateclose,pc_slot)

    def process_instruction (self,instr, pc):

        global slots_autoid
        global accesses

        opened = self.opened.copy()
        closed = self.closing_pairs.copy()
        pc_slot = self.pc_slot.copy()
        
        op_code = instr.split()[0]
        opinfo = get_opcode(op_code)

        if is_mload(instr,"64"):
            slots = None
            
            # We take the slot pointed by any opened pc at this pp
            if (len(opened) > 0):
                slots = []
                for item in opened:
                    slots = slots + self.pc_slot[item]
                slots = list(set(slots))
            else:
                slots_autoid = slots_autoid + 1
                slots = ["slot" + str(slots_autoid)]

            for s in slots: 
                accesses.add_allocation_init(pc,s)
            pc_slot[pc] = slots
            opened.add(pc)

        # pc != "0:2": Hack to avoid warning the initial assignment of MEM40
        elif (is_mstore(instr,"64") or 
              op_code == "CALL" or 
            op_code == "STATICCALL" or 
            op_code == "DELEGATECALL" or 
            op_code == "RETURN" or 
            op_code == "REVERT"):
                    
            if len(self.opened) > 1 and op_code != "RETURN" and pc != "0:2": 
                print ("WARNING!!: More than one slot closed at: " + pc + " :: " + str(opened))

            for item in opened:
                for slot in self.pc_slot[item]:
                    accesses.add_allocation_close(pc,slot)

            closed[pc] = self.opened.copy()

            opened.clear()

        return SlotsAbstractState(opened, closed, pc_slot)

    def get_slot(self,pc):
        return self.pc_slot[pc]        

    def __repr__(self):

        return ("opened " + str(self.opened) +
                " :: closing_pairs " + str(self.closing_pairs) + 
                " :: pc_slot " + str(self.pc_slot))


class BlockAnalysisInfo: 

    ## Creates an initial abstract state with the received information
    def __init__ (self, block_info, input_state): 
        self.block_info = block_info
        self.input_state = input_state
        self.output_state = None
        self.state_per_instr = []

    def get_input_state (self): 
        return self.input_state

    def get_output_state (self): 
        return self.output_state  

    def get_state_at_instr (self,pos): 
        return self.state_per_instr[pos]

    ## Evaluates if a block need to be revisited or not
    def revisit_block (self,input_state, jump_target): 
        leq = input_state.leq(self.input_state)

        if leq: 
            return False
        self.input_state = self.input_state.lub(input_state)
        del self.state_per_instr[:]
        return True
        
    def process_block (self):
        instructions = self.block_info.get_instructions()

        # We start with the initial state of the block
        current_state = self.input_state
        idblock = self.block_info.get_start_address()

        if debug_info:
            print("\n\nProcessing " + str(idblock) + 
            " :: " + str(current_state) + 
            " -- " + str(self.block_info.get_stack_info()))
        
        i = 0
        for instr in self.block_info.get_instructions(): 
            # From the current state we generate a new state by processing the instruction
            current_state = current_state.process_instruction(instr, str(idblock) + ":" + str(i))
            if debug_info:
                print("      -- " + str(self.block_info.get_start_address()) + "[" + str(i) + "]" + 
                        instr + " -- " + str(current_state))
            self.state_per_instr.append(current_state)
            i = i + 1

        self.output_state = current_state
    
    def __repr__(self):

        i = 0
        for state in self.state_per_instr: 
            print (str(self.block_info.get_start_address()) + "." + str(i) + ": " + str(self.state_per_instr[i]))
            i = i + 1
        return "" # "Block id: " + str(self.block_info.get_start_address()) + " States: " + str(len(self.state_per_instr))


class Analysis: 

    def __init__(self,vertices, blockid, initialState): 
        self.vertices = vertices
        self.pending = [blockid]
        self.blocks_info = {}
        self.blocks_info[blockid] = BlockAnalysisInfo(vertices[blockid], initialState)

    def analyze (self):
        while (len(self.pending) > 0) :
            block_id = self.pending.pop()

            # Process the block
            block_info = self.blocks_info[block_id]

            block_info.process_block()

            output_state = block_info.get_output_state()
            self.process_jumps(block_id,block_info.get_output_state())

    def process_jumps (self,block_id, input_state): 
        basic_block = self.vertices[block_id]

        jump_target = basic_block.get_jump_target()        
        if jump_target != 0 and self.blocks_info.get(jump_target) == None:
            self.pending.append(jump_target)
            self.blocks_info[jump_target] = BlockAnalysisInfo(self.vertices[jump_target], input_state)

        elif jump_target != 0 and self.blocks_info.get(jump_target).revisit_block(input_state,jump_target): 
            #print("REVISITING BLOCK!!! " + str(jump_target))
            self.pending.append(jump_target)

        jump_target = basic_block.get_falls_to()
        if jump_target != None and self.blocks_info.get(jump_target) == None:
            self.pending.append(jump_target)
            self.blocks_info[jump_target] = BlockAnalysisInfo(self.vertices[jump_target], input_state)
        elif jump_target != None and self.blocks_info.get(jump_target).revisit_block(input_state,jump_target): 
            self.pending.append(jump_target)
                
    def get_analysis_results(self,pc):
        block = pc.split(":")[0]
        try:
            block = int(block)
            pass
        except ValueError: 
            pass
        id = pc.split(":")[1]
        return self.blocks_info[block].get_state_at_instr(int(id))

    def get_block_results(self,blockid): 
        return self.blocks_info[blockid]

    def __repr__(self): 
        for id in self.blocks_info:
            print(str(self.blocks_info[id]))    
        return ""

def perform_memory_analysis(vertices, cname, csource, smap, sinfo, compblocks, fblockmap, debug): 
    
    global g_contract_name 
    global g_contract_source 
    global g_source_map
    global g_source_info 
    global g_function_block_map
    global g_component_of_blocks
    global debug_info 

    debug_info = debug
    
    g_contract_source = csource
    g_contract_name = cname
    g_source_map = smap
    g_source_info = sinfo
    g_function_block_map = compblocks
    g_component_of_blocks = fblockmap
    g_found_outofslot = False

    global slots
    global memory
    global accesses

    print("Slots analysis started!")

    accesses = MemoryAccesses({},{},{},{},vertices)
    
    slots = Analysis(vertices,0,SlotsAbstractState(set({}),{},{}))
    slots.analyze()

    print("Slots analysis finished!")

    if debug:
        print(accesses)

    memory = Analysis(vertices,0, MemoryAbstractState(0,{},{}))
    memory.analyze()

    # if debug:
    #     print("Memory results:")
    #     print(str(memory))
    #     print("End Memory results:")

    #     print("Memory accesess analysis finished!\n\n")
    #     print(accesses)

    #     print("\n\n")

    accesses.process_free_mstores(smap)

    print('Free memory analyss finished\n\n')

    return slots, memory, accesses

### Auxiliary functions 
def is_mload(opcode,pos):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MLOAD" and value==pos

def is_mstore(opcode, pos):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MSTORE" and value == pos



def order_accesses(text): 
    return int(text.split()[0])

def get_block_id(pc):
    block = pc.split(":")[0]
    try:
        block = int(block)
        pass
    except ValueError: 
        pass
    return block


def get_function_from_blockid (pp): 
    blockid = get_block_id(pp)

    initblock = None

    pred = g_function_block_map[blockid]

    for block in pred:
        for key in g_component_of_blocks: 
            (initblock, _) = g_component_of_blocks[key]
            if (initblock == block): 
                return key

