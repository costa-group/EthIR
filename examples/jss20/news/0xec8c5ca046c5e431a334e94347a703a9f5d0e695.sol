{{
  "language": "Solidity",
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  },
  "sources": {
    "seth-swapper.sol": {
      "content": "pragma solidity 0.5.13;\n\ncontract IErc20 {\n\tfunction transfer(address to, uint256 value) public returns (bool);\n\tfunction balanceOf(address account) public view returns (uint256);\n}\n\ncontract SethSwapper {\n\taddress payable public receiver = 0x25dde46EC77A801ac887e7D1764B0c8913328348;\n\tIErc20 public sethProxy = IErc20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);\n\n\tfunction () external payable {\n\t\tsethProxy.transfer(msg.sender, msg.value);\n\t}\n\n\tfunction withdraw() external returns (bytes memory) {\n\t\t(bool success,) = receiver.call.value(address(this).balance)(\"\");\n\t\trequire(success, \"receiver.call failed\");\n\t}\n\n\tfunction withdrawUnknownToken(IErc20 token) external {\n\t\trequire(token != sethProxy, \"token == sethProxy\");\n\t\ttoken.transfer(receiver, token.balanceOf(address(this)));\n\t}\n}\n"
    }
  }
}}