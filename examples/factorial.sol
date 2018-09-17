pragma solidity ^0.4.19;

contract Factorial {
  function fact(uint x) returns (uint y) {
    if (x == 0) {
      return 1;
    }
    else {
      return x*fact(x-1);
    }
  }
}
