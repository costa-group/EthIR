pragma solidity ^0.6.0;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}


contract InstaBalanceResolver {
    function getBalances(address owner, address[] memory tknAddress) public view returns (uint[] memory) {
        uint[] memory tokensBal = new uint[](tknAddress.length);
        for (uint i = 0; i < tknAddress.length; i++) {
            if (tknAddress[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                tokensBal[i] = owner.balance;
            } else {
                TokenInterface token = TokenInterface(tknAddress[i]);
                tokensBal[i] = token.balanceOf(owner);
            }
        }
        return tokensBal;
    }
}