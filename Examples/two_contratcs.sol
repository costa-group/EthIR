pragma solidity ^0.4.11;

contract Sum {

Mul mimul;

function suma (int a, int b) returns (int sol) {
  sol = a+b;
  return sol;
 }

 function mult (int a, int b) returns (int){
   return mimul.normal(a,b);
 }

}


contract Mul {

function normal(int a, int b) returns (int){
         return a*b;
}

function multiplica(int m1, int m2) returns (int) {
   Sum s;
   int mult = m1;
   for (int i = 0; i<m2; i++)
       mult = s.suma(mult,m1);

   return mult;
}

}
