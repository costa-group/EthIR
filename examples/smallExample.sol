pragma solidity ^0.4.11;

contract SmallExample{

  uint sum = 0;
  uint number = 0;
  
  function multiply(uint a){
    
    for(uint i = 0; i<a; i++){
      sum = sum+number;
    }

  }

  function enter(){
    number = 5;
    multiply(7);    
  }

  //main
  function (){
    enter();
  }

}
