

from typing import Dict, List

from basicblock import BasicBlock
from my_tree import MyTree


class Cfg_collapser:

    old_vertices: Dict[int, BasicBlock]

    collapsed_vertices: Dict[int, BasicBlock]

    visited: List[int]

    working_collapsed_node: BasicBlock

    tree: MyTree


    def __init__(self, vertices, cname):
        self.old_vertices = vertices        

        self.working_collapsed_node = None

        self.tree = MyTree(False, cname)

        self.visited = []

        self.collapsed_vertices = {}



    def get_collapsed_vertices(self):
        return self.collapsed_vertices
    
    def get_tree(self):
        return self.tree

    
    def collapse(self, starting_address = 0) -> Dict[int, BasicBlock]:

        duplicaded_node = False

        if isinstance(starting_address, str) or self.old_vertices.get(f'{starting_address}_0') is not None:
            duplicaded_node = True
        
        if duplicaded_node and self.working_collapsed_node is not None:
            self.tree.add_node_to_graph(self.working_collapsed_node)
            self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
            self.working_collapsed_node = None


        actual_node = self.old_vertices[starting_address]
        self.visited.append(actual_node.get_start_address())

        if actual_node.get_block_type() == "terminal":
            # The block is joined with the previous ones (if any) and it is closed)

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)

                self.tree.add_node_to_graph(self.working_collapsed_node)
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None
            
            else:
                self.collapsed_vertices[starting_address] = actual_node.copy()
                self.tree.add_node_to_graph(actual_node.copy())
            
            return
        

        elif actual_node.get_block_type() == "conditional" or actual_node.get_block_type() == "falls_to":
            # The block is joined with the previous ones (if there are any) and it is closed (it will not be joined with the following blocks) before jumping to the next blocks

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)

                self.tree.add_node_to_graph(self.working_collapsed_node)
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None
            
            else:
                self.collapsed_vertices[starting_address] = actual_node.copy()
                self.tree.add_node_to_graph(actual_node.copy())

            self.jump_to_next_node(actual_node)
        

        elif actual_node.get_block_type() == "unconditional":
            # If several blocks arrive to this blocks, it closes the previous block
            
            if len(actual_node.get_comes_from()) > 1 and self.working_collapsed_node is not None:
                self.tree.add_node_to_graph(self.working_collapsed_node)
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None

            # If there is an open block it joins to it and it jumps to the following block

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)
            
            else:
                self.working_collapsed_node = actual_node.copy()
            
            if actual_node.get_jump_target() in self.visited:
                self.tree.add_node_to_graph(self.working_collapsed_node)
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None

    
            self.jump_to_next_node(actual_node)

        

    def jump_to_next_node(self, actual_node):
        jump_target = actual_node.get_jump_target()
        if jump_target not in self.visited:
            self.collapse(jump_target)

        falls_to = actual_node.get_falls_to()
        if falls_to is not None and falls_to not in self.visited:
            self.collapse(falls_to)




    def join_blocks(self, new_block: BasicBlock):
        self.working_collapsed_node.set_block_type(new_block.get_block_type())
        for instruction in new_block.get_instructions():
            self.working_collapsed_node.add_instruction(instruction)

        self.working_collapsed_node.jump_target = new_block.get_jump_target()
        self.working_collapsed_node.falls_to = new_block.get_falls_to()