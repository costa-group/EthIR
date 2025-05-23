{{
  "language": "Solidity",
  "sources": {
    "/Users/igor/job/dev/protocol-wrappers/contracts/adapters/uniswap/UniswapV2Adapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\nimport { ERC20 } from \"../../ERC20.sol\";\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\n\n\n/**\n * @title Adapter for Uniswap V2 protocol.\n * @dev Implementation of ProtocolAdapter interface.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ncontract UniswapV2Adapter is ProtocolAdapter {\n\n    string public constant override adapterType = \"Asset\";\n\n    string public constant override tokenType = \"Uniswap V2 pool token\";\n\n    /**\n     * @return Amount of Uniswap pool tokens held by the given account.\n     * @param token Address of the Uniswap pool.\n     * @dev Implementation of ProtocolAdapter interface function.\n     */\n    function getBalance(address token, address account) external view override returns (uint256) {\n        return ERC20(token).balanceOf(account);\n    }\n}\n"
    },
    "/Users/igor/job/dev/protocol-wrappers/contracts/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\ninterface ERC20 {\n    function approve(address, uint256) external returns (bool);\n    function transfer(address, uint256) external returns (bool);\n    function transferFrom(address, address, uint256) external returns (bool);\n    function name() external view returns (string memory);\n    function symbol() external view returns (string memory);\n    function decimals() external view returns (uint8);\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address) external view returns (uint256);\n}\n"
    },
    "/Users/igor/job/dev/protocol-wrappers/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\n//\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU General Public License as published by\n// the Free Software Foundation, either version 3 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\n// GNU General Public License for more details.\n//\n// You should have received a copy of the GNU General Public License\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\n\npragma solidity 0.6.5;\npragma experimental ABIEncoderV2;\n\n\n/**\n * @title Protocol adapter interface.\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\n * @author Igor Sobolev <sobolev@zerion.io>\n */\ninterface ProtocolAdapter {\n\n    /**\n     * @dev MUST return \"Asset\" or \"Debt\".\n     * SHOULD be implemented by the public constant state variable.\n     */\n    function adapterType() external pure returns (string memory);\n\n    /**\n     * @dev MUST return token type (default is \"ERC20\").\n     * SHOULD be implemented by the public constant state variable.\n     */\n    function tokenType() external pure returns (string memory);\n\n    /**\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\n     */\n    function getBalance(address token, address account) external view returns (uint256);\n}\n"
    }
  },
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
    },
    "remappings": []
  }
}}