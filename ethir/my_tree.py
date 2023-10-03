
import os
from basicblock import BasicBlock
import global_params_ethir


class MyTree:
    
    
    def __init__(self, more_info:bool, file_name = "Tree") -> None:
        self.tree_structure = ""
        self.more_info = more_info
        self.file_name = file_name

    def add_node_to_graph(self, node: BasicBlock):
        '''
        Recieves a block and stores the necessary information
        '''

        if self.more_info:
            label = f"{node.get_start_address()} \n {node.get_instructions()}"
        else:
            label = node.get_start_address()

        if node.get_block_type() == "terminal" :
            self.tree_structure += f'n_{node.get_start_address()} [style=diagonals,color=green,label="{label}"];\n'
        else :
            if node.get_block_type() == "conditional":
                self.tree_structure += f'n_{node.get_start_address()} [style=solid,color=blue,label="{label}"];\n'
            elif node.get_block_type() == "unconditional":
                self.tree_structure += f'n_{node.get_start_address()} [style=solid,color=orange,label="{label}"];\n'
            else:
                self.tree_structure += f'n_{node.get_start_address()} [style=solid,color=red,label="{label}"];\n'
                
        jump = node.get_jump_target()
        if type(jump) == str or jump > 0:
            if node.get_block_type() == "conditional":
                self.tree_structure += f"n_{node.get_start_address()} -> n_{jump} [label=\"t\"];\n"
            else:
                self.tree_structure += f"n_{node.get_start_address()} -> n_{jump} [label=\"\"];\n"
            
        falls_to = node.get_falls_to()
        if falls_to is not None:
            if node.get_block_type() == "conditional":
                self.tree_structure += f"n_{node.get_start_address()} -> n_{falls_to} [label=\"f\"];\n"
            else:
                self.tree_structure += f"n_{node.get_start_address()} -> n_{falls_to} [label=\"\"];\n"
    
    def generate_dot(self):
        '''
        Outputs the stored information to a .dot file
        '''

        if "costabs" not in os.listdir(global_params_ethir.tmp_path):
            os.mkdir(global_params_ethir.costabs_path)
        
        with open(f"/tmp/costabs/My{self.file_name}.dot", 'w') as f:
            f.write("digraph id3{ \n")
            f.write(self.tree_structure)
            f.write("}")
    
        
        