pragma solidity ^0.4.11;

contract Loop1{

  uint[] c;
  
  function mini(uint n) returns (uint){
    uint r = 0;
    c[0] = 1;
    while(n>0){
      r = r+1;
      n = n-1;
    }

    return r;
  }

  function enter(){
    uint x = 5;
    uint result = mini(x);
  }


}
