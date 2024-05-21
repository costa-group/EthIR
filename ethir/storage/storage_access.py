from memory.memory_utils import TOP
from optimizer.optimizer_connector import EQUALS, NONEQUALS, UNKOWN

global KECCAK
KECCAK="k"

global BOTTOM
BOTTOM="_"

global TOP_OPER
TOP_OPER=5



## Exp = N | k(Exp) | k(Exp) + N
## N = 1..K | T
class StorageAccess: 


    def __init__(self,stoAccess):
        self.access = stoAccess.access
        self.offset = stoAccess.offset
        self.noper = stoAccess.noper

    def __init__(self,access,offset,noper):
        self.access = access
        self.offset = offset
        self.noper = noper

    def leq (self,access): 
        if self == access: 
            return True

        elif self.access == TOP and access.access != TOP: 
            return False
        elif self.access != TOP and access.access == TOP: 
            return True
        elif self.access != access.access: 
            return False
        # self.access == access.access
        elif self.offset == TOP and access.offset != TOP: 
            return False
        elif self.offset != TOP and access.offset == TOP: 
            return True

        return False

    def isTop (self): 
        return self.access == TOP or self.offset == TOP

    def add(self,operand): 

        if self.access != BOTTOM and operand.access != BOTTOM: 
            print("STORAGE ANALYSIS WARNING: Adding two keccak's " + str(self.access) + " " + str(operand.access))
            return StorageAccess(TOP,TOP,0)
        
        noper = self.noper + operand.noper + 1

        if self.offset == TOP or operand.offset == TOP: 
            value = TOP
        elif noper >= TOP_OPER: 
            value = TOP
        elif not self.offset.isnumeric() or not operand.offset.isnumeric(): 
            if self.offset == "0": 
                value = str(operand.offset)
            elif operand.offset == "0": 
                value = str(self.offset)
            else: 
                value = str(self.offset) + "+" + str(operand.offset)
        else: 
            value = int(self.offset) + int(operand.offset)

        if self.access != BOTTOM: 
            return StorageAccess(self.access,str(value),noper)
        elif operand.access != BOTTOM: 
            return StorageAccess(operand.access,str(value),noper)
        else: 
            return StorageAccess(BOTTOM,str(value),noper)        

    def get_access_expr(self): 
        return KECCAK + "(" + str(self.access) + ")"

    def compare_acesses(a1, a2): 

        # 2 fully concrete accesses
        if "*" not in str(a1) and "*" not in str(a2) and a1 == a2: 
            return EQUALS

        # Accesses are concrete and equals, but offsets are different
        if "*" not in str(a1) and "*" not in str(a2) and a1.access == a2.access and a1.offset != a2.offset: 
            return NONEQUALS

        # Accesses are concrete and different
        if "*" not in str(a1.access) and "*" not in str(a2.access) and a1.access != a2.access: 
            return NONEQUALS

        return UNKOWN

    def __repr__(self):
        if self.access == BOTTOM: 
            return str(self.offset)
        if self.access == TOP and self.offset == TOP: 
            return TOP
        if self.access != TOP and self.offset == "0": 
            return KECCAK + "(" + str(self.access) + ")"
        
        return "<" + KECCAK + "(" + str(self.access) + ")" + "," + str(self.offset) + ">"

    def __eq__(self,ob):
        if not isinstance(ob, StorageAccess):
            return False

        return self.access == ob.access and self.offset == ob.offset

    def __hash__(self):
        return hash(self.access) + hash(self.offset)
