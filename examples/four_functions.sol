
pragma solidity ^0.4.11;

contract Sum {

function suma () returns (uint sol) {
   sol = 0;
   for(uint i = 0; i < 5; i++)
           sol = sol+11;
   hola();
   adios(10);
 }

function hola() {
   uint i = 0;
   i = i+15;
   }

function adios(uint m) {
   uint c = 14;
   c = c+m;
   comer(c);   
}

function comer(uint x) {
   x = x*x;
   hola();
}

}
