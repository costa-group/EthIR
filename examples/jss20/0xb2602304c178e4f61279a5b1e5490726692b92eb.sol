pragma solidity 0.5.12;

contract TestERC223 {
    event Log(address from, uint value, bytes data);
    
    function tokenFallback(address from, uint value, bytes memory data) public {
        emit Log(from, value, data);
    }
}