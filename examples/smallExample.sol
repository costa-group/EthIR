pragma solidity ^0.4.11;

contract SmallExample{

  int sum = 0;
  int number = 0;
  
  function multiply(int a){
    
    for(int i = 0; i<a; i++){
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
