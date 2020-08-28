{{
  "language": "Solidity",
  "sources": {
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ddexMargin/DdexMarginAssetAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\r\n\r\n\r\n/**\r\n * @dev Hydro contract interface.\r\n * Only the functions required for DdexMarginAssetAdapter contract are added.\r\n * The Hydro contract is available here\r\n * github.com/HydroProtocol/protocol/blob/master/contracts/Hydro.sol.\r\n */\r\ninterface Hydro {\r\n    function getAllMarketsCount() external view returns (uint256);\r\n    function marketBalanceOf(uint16, address, address) external view returns (uint256);\r\n}\r\n\r\n\r\n/**\r\n * @title Asset adapter for DDEX protocol (margin account).\r\n * @dev Implementation of ProtocolAdapter interface.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ncontract DdexMarginAssetAdapter is ProtocolAdapter {\r\n\r\n    string public constant override adapterType = \"Asset\";\r\n\r\n    string public constant override tokenType = \"ERC20\";\r\n\r\n    address internal constant HYDRO = 0x241e82C79452F51fbfc89Fac6d912e021dB1a3B7;\r\n    address internal constant HYDRO_ETH = 0x000000000000000000000000000000000000000E;\r\n    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;\r\n\r\n    /**\r\n     * @return Amount of tokens held by the given account.\r\n     * @dev Implementation of ProtocolAdapter interface function.\r\n     */\r\n    function getBalance(address token, address account) external view override returns (uint256) {\r\n        uint256 allMarketsCount = Hydro(HYDRO).getAllMarketsCount();\r\n        uint256 totalBalance = 0;\r\n\r\n        for (uint16 i = 0; i < uint16(allMarketsCount); i++) {\r\n            try Hydro(HYDRO).marketBalanceOf(\r\n                i,\r\n                token == ETH ? HYDRO_ETH : token,\r\n                account\r\n            ) returns (uint256 marketBalance) {\r\n                totalBalance += marketBalance;\r\n            } catch {} // solhint-disable-line no-empty-blocks\r\n        }\r\n\r\n        return totalBalance;\r\n    }\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\n/**\r\n * @title Protocol adapter interface.\r\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ninterface ProtocolAdapter {\r\n\r\n    /**\r\n     * @dev MUST return \"Asset\" or \"Debt\".\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function adapterType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return token type (default is \"ERC20\").\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function tokenType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\r\n     */\r\n    function getBalance(address token, address account) external view returns (uint256);\r\n}\r\n"
    }
  },
  "settings": {
    "remappings": [],
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
  }
}}{{
  "language": "Solidity",
  "sources": {
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ddexMargin/DdexMarginAssetAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\nimport { ProtocolAdapter } from \"../ProtocolAdapter.sol\";\r\n\r\n\r\n/**\r\n * @dev Hydro contract interface.\r\n * Only the functions required for DdexMarginAssetAdapter contract are added.\r\n * The Hydro contract is available here\r\n * github.com/HydroProtocol/protocol/blob/master/contracts/Hydro.sol.\r\n */\r\ninterface Hydro {\r\n    function getAllMarketsCount() external view returns (uint256);\r\n    function marketBalanceOf(uint16, address, address) external view returns (uint256);\r\n}\r\n\r\n\r\n/**\r\n * @title Asset adapter for DDEX protocol (margin account).\r\n * @dev Implementation of ProtocolAdapter interface.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ncontract DdexMarginAssetAdapter is ProtocolAdapter {\r\n\r\n    string public constant override adapterType = \"Asset\";\r\n\r\n    string public constant override tokenType = \"ERC20\";\r\n\r\n    address internal constant HYDRO = 0x241e82C79452F51fbfc89Fac6d912e021dB1a3B7;\r\n    address internal constant HYDRO_ETH = 0x000000000000000000000000000000000000000E;\r\n    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;\r\n\r\n    /**\r\n     * @return Amount of tokens held by the given account.\r\n     * @dev Implementation of ProtocolAdapter interface function.\r\n     */\r\n    function getBalance(address token, address account) external view override returns (uint256) {\r\n        uint256 allMarketsCount = Hydro(HYDRO).getAllMarketsCount();\r\n        uint256 totalBalance = 0;\r\n\r\n        for (uint16 i = 0; i < uint16(allMarketsCount); i++) {\r\n            try Hydro(HYDRO).marketBalanceOf(\r\n                i,\r\n                token == ETH ? HYDRO_ETH : token,\r\n                account\r\n            ) returns (uint256 marketBalance) {\r\n                totalBalance += marketBalance;\r\n            } catch {} // solhint-disable-line no-empty-blocks\r\n        }\r\n\r\n        return totalBalance;\r\n    }\r\n}\r\n"
    },
    "/mnt/c/Users/Igor/Desktop/job/dev/zeriontech/defi-sdk/contracts/adapters/ProtocolAdapter.sol": {
      "content": "// Copyright (C) 2020 Zerion Inc. <https://zerion.io>\r\n//\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\r\n// GNU General Public License for more details.\r\n//\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program. If not, see <https://www.gnu.org/licenses/>.\r\n\r\npragma solidity 0.6.5;\r\npragma experimental ABIEncoderV2;\r\n\r\n\r\n/**\r\n * @title Protocol adapter interface.\r\n * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.\r\n * @author Igor Sobolev <sobolev@zerion.io>\r\n */\r\ninterface ProtocolAdapter {\r\n\r\n    /**\r\n     * @dev MUST return \"Asset\" or \"Debt\".\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function adapterType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return token type (default is \"ERC20\").\r\n     * SHOULD be implemented by the public constant state variable.\r\n     */\r\n    function tokenType() external pure returns (string memory);\r\n\r\n    /**\r\n     * @dev MUST return amount of the given token locked on the protocol by the given account.\r\n     */\r\n    function getBalance(address token, address account) external view returns (uint256);\r\n}\r\n"
    }
  },
  "settings": {
    "remappings": [],
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
  }
}}