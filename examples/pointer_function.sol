pragma solidity ^0.8.0;

contract Point{
  function () internal fwd1;
  function () internal fwd2;
  function () internal fwd3;

  function funct1() private {
  }
  function funct2() private {
  }

  function enter() public {
    fwd1 = funct1;
    fwd2 = funct2;

    fwd1();
    fwd2();
  }

}
