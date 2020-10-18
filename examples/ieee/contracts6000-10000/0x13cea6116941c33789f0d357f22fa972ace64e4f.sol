pragma solidity ^0.5.7;

contract GCTransfer  {
    uint public balance = 0;
    address public owner;
    constructor () public {
        owner = msg.sender;
    }
    function() payable external {
        balance += msg.value;
    }
    function transferETH(address payable _to, uint256 _value) public onlyOwner {
        _to.transfer(_value);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}