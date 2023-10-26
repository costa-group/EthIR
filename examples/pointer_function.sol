pragma solidity ^0.8.0;

contract Point{
  function () internal fwd;
  function () internal fwd2;
  function () internal fwd3;
  function () internal fwd4;
  function () internal fwd5;

  function funct1() private {
  }


  function enter() public {
    fwd = funct1;
    fwd5();
  }

}