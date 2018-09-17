pragma solidity ^0.4.19;

contract Fibonacci {
  function fact(uint x) returns (uint y) {
    if (x == 0) {
      return 1;
    }
    else if (x == 1) {
      return 1;
    }
    else {
      return 10+fact(x-2);
    }
  }
}
