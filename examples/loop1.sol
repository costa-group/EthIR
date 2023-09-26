pragma solidity ^0.8.0;

contract Loop1{

  uint sum = 0;
  uint number = 0;
  
  function multiply(uint a) public{
    
    for(uint i = 0; i<a; i++){
      sum = sum+number;
    }

  }

  function enter()public{
    number = 5;
    multiply(7);    
  }

  //main
  constructor(){
    enter();
  }

}
