pragma solidity 0.5.14;

interface IToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenDrop {
 
    function dropToken(address tokenAddress, address[] memory recipients, uint256[] memory amounts) public {
        IToken token = IToken(tokenAddress);
        for (uint256 i = 0; i < recipients.length; i++) {
		  token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }
}