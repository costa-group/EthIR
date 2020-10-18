pragma solidity ^0.5.17;
contract COWS {
    function totalSupply() external view returns (uint256 _totalSupply){}
    function balanceOf(address _owner) external view returns (uint256 _balance){}
    function transfer(address _to, uint256 _value) external returns (bool _success){}
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success){}
    function approve(address _spender, uint256 _value) external returns (bool _success){}
    function allowance(address _owner, address _spender) external view returns (uint256 _remaining){}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract COWSAdminLock {
    
     uint256 constant sixmonth = 1613606400; //  Thursday, February 18, 2021 12:00:00 AM
    
     COWS token;
     
     address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner,"You are not Authorize to call this function");
        _;
    } 
    
     constructor() public {
        owner = msg.sender;
    
        token = COWS(0xE7fb8AA6593FF2b1dA6254D536B63284F16896B5);
    }
    
    function withdrawOwnerNioxToken(uint256 _tkns) public  onlyOwner returns (bool) {
             require(block.timestamp >= sixmonth);
             require(token.transfer(msg.sender, _tkns));
             return true;
    }
    
}