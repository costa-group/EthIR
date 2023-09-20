pragma solidity ^0.8.0;

contract Point{
  function deleg() private {
    /* foo */
  }

  struct Pointer { function () internal fwd; }

  Pointer p;

  function enter() public {
    Pointer storage _p = p;
    _p.fwd = deleg;
    _p.fwd();
  }

}