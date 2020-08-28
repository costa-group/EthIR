pragma solidity 0.5.13;

interface tokenInterface {

    function balanceOf(address _address) external view returns (uint balance);
    
}

contract balanceViewer {
    
    address sai = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address mkr = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    
    function readAllBalances(address _address) public view returns(uint256 mkrBalance, uint256 saiBalance) {
        saiBalance = tokenInterface(sai).balanceOf(_address);
        mkrBalance = tokenInterface(mkr).balanceOf(_address);
    }
    
}