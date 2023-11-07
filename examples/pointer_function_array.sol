pragma solidity ^0.8.0;

contract Point{
  function () internal [2] function_array;

  function funct1() private {
  }
  function funct2() private {
  }
  function funct3() private {
  }
  function funct4() private {
  }


  function enter() public {
    function_array[0] = funct1;
    function_array[1] = funct2;
    function_array[0]();
  }

}