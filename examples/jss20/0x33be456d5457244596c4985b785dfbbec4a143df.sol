pragma solidity ^0.5.8;

contract Timestamper {
    event Stamp(string s);
    function stamp(string calldata _s) external {
        emit Stamp(_s);
    }    
}