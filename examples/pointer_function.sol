pragma solidity ^0.8.0;

contract Point{
  uint full;
  uint8 n;
  function () internal fwd1;
  function () internal fwd2;
  function () internal fwd3;
  function () internal fwd4;
  function () internal fwd5;

  function funct1() private {
  }
  function funct2() private {
  }
  function funct3() private {
  }
  function funct4() private {
  }


  function enter() public {
    full = 35;
    n = 5;
    fwd1 = funct1;
    fwd2 = funct2;
    fwd3 = funct3;
    fwd4 = funct4;

    fwd2();
  }

}