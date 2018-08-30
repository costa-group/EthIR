#This module check if a smart contract contains a loop.
#To improve the performance, it uses a map reduce technique

from mrjob.job import MRJob

class MRHasLoop(MRJob):

    def mapper(self, key, line):
        l1 = line.strip()
        l = l1.strip("\t")
        llist= l.split()
        if llist != []:
            ll = llist[0].split("(")
        else:
            ll = []
        
        if ll!=[] and (ll[0]== "for" or ll[0]== "while"):
            yield "loop" , 1
        else :
            yield "loop" , 0

    def reducer(self, _, values):
        yield _, sum(values)
            
if __name__ == '__main__':
    MRHasLoop.run()
