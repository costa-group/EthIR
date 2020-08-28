pragma solidity ^0.4.20;


interface IERC20 {
    function transferFrom(
        address from, 
        address to, 
        uint256 value
    ) 
        external 
        returns (bool);
}


contract MassTransfer {
    function massTransfer(
        address[] memory _addresses,
        address _tokenToSend,
        uint256 _amountToEach
    )
        public
    {
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(_tokenToSend).transferFrom(msg.sender, _addresses[i], _amountToEach);
        }
    }
}