

from typing import Dict, List

from basicblock import BasicBlock
from my_tree import CollapsedTree


class Cfg_collapser:

    old_vertices: Dict[int, BasicBlock]

    collapsed_vertices: Dict[int, BasicBlock]

    visited: List[int]

    working_collapsed_node: BasicBlock

    tree: CollapsedTree

    duplicated_series: Dict[int, List]


    def __init__(self, vertices, cname):
        self.old_vertices = vertices        

        self.working_collapsed_node = None

        self.tree = CollapsedTree(False, cname)

        self.visited = []

        self.collapsed_vertices = {}

        self.duplicated_series = {}

        self.block_sizes_collapsed = {}
        
        self.block_sizes = {}


    def get_collapsed_vertices(self):
        return self.collapsed_vertices
    
    def get_tree(self):
        return self.tree

    def collapse(self):
        self.collapse_aux(0)
        self.collapse_duplicated()

        self.visited = []
        self.draw_tree(0)


    def collapse_aux(self, starting_address) -> Dict[int, BasicBlock]:

        actual_node = self.old_vertices[starting_address]
        self.visited.append(actual_node.get_start_address())

        if isinstance(starting_address, int):
            self.block_sizes[starting_address] = len(actual_node.get_instructions())

        # Duplicated node cases
        if self.working_collapsed_node is not None and self.is_duplicated_node(starting_address):
            working_starting_address =  self.simplify_address(self.working_collapsed_node.get_start_address())
            duplicated_nodes = self.get_duplicated_nodes(starting_address)

            # The address isn't a list for the previous node, one is created
            if self.duplicated_series.get(working_starting_address) is None:
                self.duplicated_series[working_starting_address] = [working_starting_address]

            # The previous node must have at least the same amount of nodes as the actual node
            if len(self.get_duplicated_nodes(self.working_collapsed_node.get_start_address())) >= len(duplicated_nodes):

                sequence_correct = True
                for node in duplicated_nodes:
                    comes_from = self.old_vertices[node].get_comes_from()
                    if len(comes_from) != 1 or self.simplify_address(comes_from[0]) != working_starting_address:
                        sequence_correct = False
                        break
                
                if sequence_correct:
                    series = self.duplicated_series.pop(working_starting_address)
                    series.append(self.simplify_address(starting_address))
                    self.duplicated_series[self.simplify_address(starting_address)] = series
               

            self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
            self.working_collapsed_node = None


        if actual_node.get_block_type() == "terminal":
            # The block is joined with the previous ones (if any) and it is closed
            
            if len(actual_node.get_comes_from()) > 1 and self.working_collapsed_node is not None:
                self.close_previous_node()

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)

                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None
            
            else:
                self.collapsed_vertices[starting_address] = actual_node.copy()
                self.add_size(starting_address)
            
            return
        

        elif actual_node.get_block_type() == "conditional" or actual_node.get_block_type() == "falls_to":

            if len(actual_node.get_comes_from()) > 1 and self.working_collapsed_node is not None:
                self.close_previous_node()
            # The block is joined with the previous ones (if there are any) and it is closed (it will not be joined with the following blocks) before jumping to the next blocks

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)

                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None
            
            else:
                self.collapsed_vertices[starting_address] = actual_node.copy()
                self.add_size(starting_address)

            self.jump_to_next_node(actual_node)
        

        elif actual_node.get_block_type() == "unconditional":
            # If several blocks arrive to this blocks, it closes the previous block
            
            if len(actual_node.get_comes_from()) > 1 and self.working_collapsed_node is not None:
                self.close_previous_node()

            # If there is an open block it joins to it and it jumps to the following block

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)
            
            else:
                self.working_collapsed_node = actual_node.copy()
                self.add_size(starting_address)
            
            if actual_node.get_jump_target() in self.visited:
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None

    
            self.jump_to_next_node(actual_node)


    def collapse_duplicated(self):
        for node_list in self.duplicated_series.values():
            if len(node_list) == 1:
                continue

            for node in self.get_duplicated_nodes(node_list[0]):
                self.working_collapsed_node = self.collapsed_vertices.get(node)

                for i in range(1, len(node_list)):
                    if self.simplify_address(self.working_collapsed_node.get_jump_target()) == node_list[i]:
                        self.join_blocks(self.collapsed_vertices.get(self.working_collapsed_node.get_jump_target()))
                    else:
                        break
    
    def draw_tree(self, start_address):
        node = self.collapsed_vertices.get(start_address)

        self.tree.add_node_to_graph(node)
        self.visited.append(start_address)

        jump_target = node.get_jump_target()
        if jump_target not in self.visited:
            self.draw_tree(jump_target)

        falls_to = node.get_falls_to()
        if falls_to is not None and falls_to not in self.visited:
            self.draw_tree(falls_to)
        

    def close_previous_node(self):
        self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
        self.working_collapsed_node = None


    def jump_to_next_node(self, actual_node):
        jump_target = actual_node.get_jump_target()
        if jump_target not in self.visited:
            self.collapse_aux(jump_target)

        falls_to = actual_node.get_falls_to()
        if falls_to is not None and falls_to not in self.visited:
            self.collapse_aux(falls_to)


    def join_blocks(self, new_block: BasicBlock):
        self.working_collapsed_node.set_block_type(new_block.get_block_type())
        for instruction in new_block.get_instructions():
            self.working_collapsed_node.add_instruction(instruction)
        
        if isinstance(self.working_collapsed_node.get_start_address(), int):
            self.block_sizes_collapsed[self.working_collapsed_node.get_start_address()] += len(new_block.get_instructions())

        self.working_collapsed_node.jump_target = new_block.get_jump_target()
        self.working_collapsed_node.falls_to = new_block.get_falls_to()


    '''
    Returns all the duplicated nodes of an address including tat address
    '''
    def get_duplicated_nodes(self, start_address) -> List[int]:
        address = self.simplify_address(start_address)
        addresses = [address]
        i = 0
        while self.old_vertices.get(f"{address}_{i}") is not None:
            addresses.append(f"{address}_{i}")
            i+=1
        return addresses


    def simplify_address(self, address) -> int:
        if isinstance(address, str):
            return int(address[:address.find("_")])
        else:
            return address
    

    def is_duplicated_node(self, starting_address):
        return isinstance(starting_address, str) or self.old_vertices.get(f'{starting_address}_0') is not None
    

    def add_size(self, starting_address):
        if isinstance(starting_address, int):
            self.block_sizes_collapsed[starting_address] = len(self.old_vertices[starting_address].get_instructions())