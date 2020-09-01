pragma solidity ^0.4.26;

// ERC20 contract interface
contract Token {
  function balanceOf(address) public view returns (uint);
  function decimals() public view returns (uint);
}

contract ERC20Utilities {
  /* Fallback function, don't accept any ETH */
  function() public payable {
    revert("ERC20Utilities does not accept payments");
}

  function tokenDecimals(address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
  
    // is it a contract and does it implement balanceOf ?
    if (tokenCode > 0 && token.call(bytes4(0x70a08231), "0x0000000000000000000000000000000000000000")) {  
      return Token(token).decimals();
    } else {
      return 0;
    }
}

  function batchTokenDecimals(address[] tokens) external view returns (uint[]) {
    uint[] memory tokenDecimalsRes = new uint[](tokens.length);
    
    for (uint j = 0; j < tokens.length; j++) {
      uint addrIdx = j;
      if (tokens[j] != address(0x0)) { 
        tokenDecimalsRes[addrIdx] = tokenDecimals(tokens[j]);
      } else {
        tokenDecimalsRes[addrIdx] = 18; // ETH decimals are hardcoded
      }
    }  

    return tokenDecimalsRes;
  }

  function tokenBalance(address user, address token) public view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
  
    // is it a contract and does it implement balanceOf 
    if (tokenCode > 0 && token.call(bytes4(0x70a08231), user)) {  
      return Token(token).balanceOf(user);
    } else {
      return 0;
    }
  }
  
  function batchTokenBalances(address[] users, address[] tokens) external view returns (uint[]) {
    uint[] memory addrBalances = new uint[](tokens.length * users.length);
    
    for(uint i = 0; i < users.length; i++) {
      for (uint j = 0; j < tokens.length; j++) {
        uint addrIdx = j + tokens.length * i;
        if (tokens[j] != address(0x0)) { 
          addrBalances[addrIdx] = tokenBalance(users[i], tokens[j]);
        } else {
          addrBalances[addrIdx] = users[i].balance; // ETH balance    
        }
      }  
    }
  
    return addrBalances;
  }    

}