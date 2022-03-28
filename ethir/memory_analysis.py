from basicblock import BasicBlock
from opcodes import get_opcode

global special_memory_addresses
special_memory_addresses = ["0x60"]
#special_memory_addresses = ["0x40", "0x80", "0x60"]

global arithemtic_operations
arithemtic_operations = ["ADD","SUB","MUL","DIV","AND","OR","EXP","SHR","SHL"]


global slots 
slots = None

global memory 
memory = None

global accesses
accesses = None

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

    def get_cfg_info (self,block_in): 
        result = []
        self.process_set(block_in,self.initset, "INIT", result)
        self.process_set(block_in,self.closeset, "CLOSE", result)
        self.process_set(block_in,self.readset, "READ", result)
        self.process_set(block_in,self.writeset, "WRITE", result)
        return result

    def process_set (self,block_in, set_in, text, result): 
        for pc in set_in: 
            block = pc.split(":")[0]
            offset = pc.split(":")[1]
            if block == block_in: 
                result.append(text + "[" + offset + "] -> " + str(list(set_in[pc]))) 

    def __repr__(self):
        return ("INIT ALLOC: " + str(self.initset) +
                "\nCLOSE ALLOC:" + str(self.closeset) + 
                "\nREAD: " + str(self.readset) + 
                "\nWRITE: " + str(self.writeset))


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
        for skey in state.get_stack(): 
            if (skey not in self.stack or 
                not (set(state.get_stack()[skey]) <= set(self.stack[skey]))):
                return False

        for mkey in state.get_memory(): 
            if (mkey not in self.memory or 
                not (set(state.get_memory()[mkey]) <= set(self.memory[mkey]))):
                return False
        
        return True

    def lub (self,state): 
        if self.stack_pos != state.get_stack_pos(): 
            print("WARNING: Different stacks in lub !!! ")
            print("WARNING: " + str(self))
            print("WARNING: " + str(state))

        print("********************************* Haciendo lub + ")
        print(str(self))
        print(str(state))

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

        print(str(res_stack))
        print(str(res_memory))

        return MemoryAbstractState(self.stack_pos, res_stack, res_memory)


    def process_instruction (self,instr,pc):
        global accesses
        global slots
        op_code = instr.split()[0]

        stack = self.stack.copy()
        memory = self.memory.copy()

        opinfo = get_opcode(op_code)
        stack_in = opinfo[1]
        stack_out = opinfo[2]
        stack_res = self.stack_pos - stack_in + stack_out
        top = self.stack_pos-1

        # TODO: this code should be moved to another function (passing reference parameters problem)

        # We save in the stack special memory addresses        
        if is_mload40(instr):
            stack[top] = [slots.get_analysis_results(pc).get_slot(pc)]

        #TODO Review the compiler version. Is 0x60 always null? 
        elif op_code == "PUSH1" and instr.split()[1] == "0x60": 
            stack[self.stack_pos] = ["null"]

        elif op_code.startswith("LOG"): 
            self.add_read_access(top,pc,stack)

        ## TODO: Add accesses in CALL / STATIC CALL
        elif op_code == "CALL" or op_code == "CALLCODE": 
            self.add_read_access(top-3,pc,stack)
            self.add_write_access(top-5,pc,stack)

        elif op_code == "STATICCALL" or op_code == "DELEGATECALL": 
            self.add_read_access(top-2,pc,stack)
            self.add_write_access(top-4,pc,stack)

        elif op_code == "CALLDATACOPY" or op_code == "CODECOPY" or op_code == "RETURNDATACOPY":
            self.add_write_access(top,pc,stack)

        elif op_code == "EXTCODECOPY" or op_code.startswith("CREATE"):
            self.add_write_access(top-1,pc,stack)

        elif op_code == "MLOAD": 
            self.add_read_access(top,pc,stack)
            if top in stack: 
                reslist = []
                for memaddress in stack[top]: 
                    if memaddress in memory: 
                        reslist.append(memory[memaddress])
                if len(reslist) > 0: 
                    stack[top] = list(set(reslist))
            else: 
                print("WARNING: Unknown access at this point " + pc)
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
                print("WARNING: Unknown access at this point " + pc)
                accesses.add_write_access(pc,"unknown")                                

        elif op_code in arithemtic_operations:
            if top in stack and (not top-1 in stack): 
                stack[top-1] = stack[top]
            elif top-1 in stack and (not top in stack): 
                stack[top-1] = stack[top-1]
            # TODO: Think if needed
            elif top in stack and top-1 in stack: 
                print ("WARNING: Arithmentic operations with two slots: " + 
                        op_code + " (" + 
                        str(stack[top-1]) + "," + 
                        str(stack[top]) + ")")
                #stack[top-1] = list(set(stack[top]+stack[top-1]))
            
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
        closing_pairs = self.closing_pairs.copy()
        stateopen = state.opened.copy()
        stateclose = state.closing_pairs.copy()
        pc_slot = self.copy()
        return SlotsAbstractState(opened.union(stateopen),closing_pairs.union(stateclose),pc_slot)

    def process_instruction (self,instr, pc):

        global slots_autoid
        global accesses

        opened = self.opened.copy()
        closed = self.closing_pairs.copy()
        pc_slot = self.pc_slot.copy()
        
        op_code = instr.split()[0]
        opinfo = get_opcode(op_code)

        if is_mload40(instr):
            slot = None
            
            accesses.add_read_access(pc,"mem40")

            # We take the slot pointed by any opened pc at this pp
            if (len(opened) > 0):
                for item in opened:
                    slot = self.pc_slot[item]
                    break
            else:
                slots_autoid = slots_autoid + 1
                slot = "slot" + str(slots_autoid)

            accesses.add_allocation_init(pc,slot)
            pc_slot[pc] = slot
            opened.add(pc)

        # pc != "0:2": Hack to avoid warning the initial assignment of MEM40
        elif (is_mstore40(instr) or op_code == "CALL" or op_code == "STATICCALL" or op_code == "RETURN"):
            
            if is_mstore40(instr):
                accesses.add_write_access(pc,"mem40")
                
            if len(self.opened) > 1 and op_code != "RETURN" and pc != "0:2": 
                print ("WARNING!!: More than one slot closed at: " + pc + " :: " + str(opened))

            for item in opened:
                accesses.add_allocation_close(pc,self.pc_slot[item])

            closed[pc] = self.opened.copy()

            opened.clear()

        return SlotsAbstractState(opened, closed, pc_slot)

    def get_slot(self,pc):
        return self.pc_slot[pc]        

    def __repr__(self):
        return ("opened " + str(self.opened) +
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
    def revisit_block (self,input_state): 
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
        print("\n\nProcessing " + str(idblock) + 
            " :: " + str(current_state) + 
            " -- " + str(self.block_info.get_stack_info()))
        
        i = 0
        for instr in self.block_info.get_instructions(): 
            # From the current state we generate a new state by processing the instruction
            current_state = current_state.process_instruction(instr, str(idblock) + ":" + str(i))
            print("      -- (" + str(i) + ") " + instr + " -- " + str(current_state))
            self.state_per_instr.append(current_state)
            i = i + 1

        self.output_state = current_state
    
    def __repr__(self):
        return "Block id: " + str(self.block_info.get_start_address()) + " States: " + str(len(self.state_per_instr))


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

        elif jump_target != 0 and self.blocks_info.get(jump_target).revisit_block(input_state): 
            self.pending.append(jump_target)

        jump_target = basic_block.get_falls_to()
        if jump_target != None and self.blocks_info.get(jump_target) == None:
            self.pending.append(jump_target)
            self.blocks_info[jump_target] = BlockAnalysisInfo(self.vertices[jump_target], input_state)
        elif jump_target != None and self.blocks_info.get(jump_target).revisit_block(input_state): 
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

def perform_memory_analysis(vertices): 
    global slots
    global memory
    global accesses
    print('Lest go!')
    
    print("Slots analysis started!")

    accesses = MemoryAccesses({},{},{},{},vertices)
    
    slots = Analysis(vertices,0,SlotsAbstractState(set({}),{},{}))
    slots.analyze()

    print("Slots analysis finished!")

    print(accesses)

    print("Memory analysis started!")
    memory = Analysis(vertices,0, MemoryAbstractState(0,{},{}))
    memory.analyze()
    print("Memory analysis finished!")
    print(accesses)

    print("\n\n")
    print("938: " + str(accesses.get_cfg_info("938")))
    print("938_0: " + str(accesses.get_cfg_info("938_0")))
    print("1064: " + str(accesses.get_cfg_info("1064")))
    print("155: " + str(accesses.get_cfg_info("155")))
    print("793: " + str(accesses.get_cfg_info("793")))

    print('We are done!!\n\n')

### Auxiliary functions 
def is_mload40(opcode):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MLOAD" and value=="64"

def is_mstore40(opcode):
    opcode = opcode.split(" ")
    opcode_name = opcode[0]

    if len(opcode) == 1:
        return False

    value = opcode[1]
    return opcode_name == "MSTORE" and value == "64"
