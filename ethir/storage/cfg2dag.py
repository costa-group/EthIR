
class CFG2DAG: 


    def __init__(self,vertices, sccs):
        self.vertices = vertices
        self.sccs = sccs
        self.node2scc = {}
        self.terminals = {}
        self.cfgdag = {}
        self.paths2terminal = {}
        self.reverse_sccs()

        # print("SCC's: " + str(sccs))
        # print("Node2SCC: " + str(self.node2scc))

        self.generate_DAG_from_CFG()
        # print("DAG CFG: " + str(self.cfgdag))

    def is_scc (self, node):
        return (node in self.sccs['multiple'] or
                str(node) in self.sccs['multiple']) 

    def get_nodedag (self, node):
        if node in self.node2scc:
            return self.node2scc[node]

        if "_" not in node and int(node) in self.node2scc:
            return self.node2scc[int(node)]

        return node

    def reverse_sccs(self): 
        multiple = self.sccs['multiple']
        for scc in multiple:
            if self.__is_nested(scc,multiple): 
                continue

            for node in multiple[scc]: 
                self.node2scc[node] = scc

    def __is_nested(self,scc, multiple):
        for s in multiple:
            if s == scc: 
                continue
            
            if scc in multiple[s]: 
                return True
        return False

    def generate_DAG_from_CFG (self): 

        for blockid in self.vertices: 
            node = self.vertices[blockid]
             
            fromnode = blockid
            if blockid in self.node2scc: 
                fromnode = self.node2scc[blockid]
            
            jump_target = node.get_jump_target()
            if jump_target != 0 and jump_target in self.node2scc: 
                jump_target = self.node2scc[jump_target]
            self.__add2DAG(fromnode,jump_target)

            jump_target = node.get_falls_to()
            if jump_target != 0 and jump_target in self.node2scc: 
                jump_target = self.node2scc[jump_target]
            self.__add2DAG(fromnode,jump_target)

    def __add2DAG (self,fromid,toid):
        if toid is None or toid == 0 or fromid == toid: 
            return

        if fromid not in self.cfgdag: 
            self.cfgdag[fromid] = set([toid])
            return;

        dests = self.cfgdag[fromid]
        if toid not in dests: 
            dests.add(toid)

    def process_all_paths_from(self,fromnode): 
        visited = set()
        terminal = []
        self.__get_all_terminals(fromnode,fromnode,visited, terminal)

        self.terminals[fromnode] = terminal

        for tnode in terminal: 
            paths = list()
            path = list()
            self.__find_all_paths(fromnode,tnode,path,paths)
            self.paths2terminal[(fromnode,tnode)] = paths

    def __get_all_terminals(self,fromnode,node,visited, terminal): 
        
        visited.add(node)

        if node not in self.cfgdag: 
            instr = self.vertices[node].get_instructions()
            if "STOP" in instr or "RETURN" in instr:  
                terminal.append(node)   
            return

        for dest in self.cfgdag[node]: 
            if dest not in visited: 
                self.__get_all_terminals(fromnode,dest,visited, terminal)
        

    def __find_all_paths(self, start, end, path, paths):
        path.append(start)
        if start == end:
            paths.append(list(path))
            path.pop()
            return

        if start in self.cfgdag: 
            for node in self.cfgdag[start]:
                if node not in path:
                    self.__find_all_paths(node, end, path, paths)
        
        path.pop()

