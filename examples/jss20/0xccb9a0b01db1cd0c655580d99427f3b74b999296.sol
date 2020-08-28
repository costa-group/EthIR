{{
  "language": "Solidity",
  "sources": {
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ampleforth/AmpleforthAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\nimport { ERC20 } from \"../../ERC20.sol\";\r\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\r\n\r\n\r\n/**\r\n * @title Asset adapter for Ampleforth.\r\n * @dev Implementation of ProtocolAdapter interface.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ncontract AmpleforthAdapter is ProtocolAdapter {\r\n\r\n    string public constant override adapterType = \"Asset\";\r\n\r\n    string public constant override tokenType = \"ERC20\";\r\n\r\n    /**\r\n     * @return AMPL balance by the given account.\r\n     * @dev Implementation of ProtocolAdapter interface function.\r\n     */\r\n    function getBalance(address token, address account) external view override returns (uint256) {\r\n        return ERC20(token).balanceOf(account);\r\n    }\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\ninterface ERC20 {\r\n    function approve(address, uint256) external returns (bool);\r\n    function transfer(address, uint256) external returns (bool);\r\n    function transferFrom(address, address, uint256) external returns (bool);\r\n    function name() external view returns (string memory);\r\n    function symbol() external view returns (string memory);\r\n    function decimals() external view returns (uint8);\r\n    function totalSupply() external view returns (uint256);\r\n    function balanceOf(address) external view returns (uint256);\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\n/**\r\n * @title Protocol adapter interface.\r\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ninterface ProtocolAdapter {\r\n\r\n    /**\r\n     * @dev MUST return \"Asset\" or \"Debt\".\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function adapterType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return token type (default is \"ERC20\").\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function tokenType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\r\n     */\r\n    function getBalance(address token, address account) external view returns (uint256);\r\n}\r\n"
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
}}{{
  "language": "Solidity",
  "sources": {
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ampleforth/AmpleforthAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\nimport { ERC20 } from \"../../ERC20.sol\";\r\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\r\n\r\n\r\n/**\r\n * @title Asset adapter for Ampleforth.\r\n * @dev Implementation of ProtocolAdapter interface.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ncontract AmpleforthAdapter is ProtocolAdapter {\r\n\r\n    string public constant override adapterType = \"Asset\";\r\n\r\n    string public constant override tokenType = \"ERC20\";\r\n\r\n    /**\r\n     * @return AMPL balance by the given account.\r\n     * @dev Implementation of ProtocolAdapter interface function.\r\n     */\r\n    function getBalance(address token, address account) external view override returns (uint256) {\r\n        return ERC20(token).balanceOf(account);\r\n    }\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/ERC20.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\ninterface ERC20 {\r\n    function approve(address, uint256) external returns (bool);\r\n    function transfer(address, uint256) external returns (bool);\r\n    function transferFrom(address, address, uint256) external returns (bool);\r\n    function name() external view returns (string memory);\r\n    function symbol() external view returns (string memory);\r\n    function decimals() external view returns (uint8);\r\n    function totalSupply() external view returns (uint256);\r\n    function balanceOf(address) external view returns (uint256);\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\n/**\r\n * @title Protocol adapter interface.\r\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ninterface ProtocolAdapter {\r\n\r\n    /**\r\n     * @dev MUST return \"Asset\" or \"Debt\".\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function adapterType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return token type (default is \"ERC20\").\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function tokenType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\r\n     */\r\n    function getBalance(address token, address account) external view returns (uint256);\r\n}\r\n"
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