

from typing import Dict, List

from basicblock import BasicBlock
from my_tree import MyTree


class Cfg_collapser:

    old_vertices: Dict[int, BasicBlock] = {}

    collapsed_vertices: Dict[int, BasicBlock] = {}

    visited: List[int] = []

    working_collapsed_node: BasicBlock

    tree: MyTree


    def __init__(self, vertices):
        self.old_vertices = vertices        

        self.working_collapsed_node = None

        self.tree = MyTree(False)



    def get_collapsed_vertices(self):
        return self.collapsed_vertices
    
    def get_tree(self):
        return self.tree

    
    def collapse(self, starting_address = 0) -> Dict[int, BasicBlock]:

        actual_node = self.old_vertices[starting_address]
        self.visited.append(actual_node.get_start_address())

        if actual_node.get_block_type() == "terminal":

            if self.working_collapsed_node is not None:
                self.join_blocks(actual_node)
                self.working_collapsed_node.set_block_type("terminal")

                self.tree.add_node_to_graph(self.working_collapsed_node)
                self.collapsed_vertices[self.working_collapsed_node.get_start_address()] = self.working_collapsed_node
                self.working_collapsed_node = None
            
            else:
                self.collapsed_vertices[starting_address] = actual_node.copy()
                self.tree.add_node_to_graph(actual_node.copy())
            
            return
        

        elif actual_node.get_block_type() == "conditional" or actual_node.get_block_type() == "falls_to":
            # The block is joined with the previous ones (if there are any) and it is closed (it will not be joined with the following blocks)

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
        for instruction in new_block.get_instructions():
            self.working_collapsed_node.add_instruction(instruction)

        self.working_collapsed_node.set_jump_target(new_block.get_jump_target())
        self.working_collapsed_node.set_falls_to(new_block.get_falls_to())