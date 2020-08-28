{{
  "language": "Solidity",
  "sources": {
    "/home/julian/betx/betx-contracts/contracts/impl/SystemParameters.sol": {
      "keccak256": "0xf3f93f3a6ed8bdbfc5819c12f2ffbd6a318fa2ce3b7e2a874e25c4831719c3f5",
      "content": "pragma solidity 0.5.16;\npragma experimental ABIEncoderV2;\n\nimport \"../interfaces/permissions/IWhitelist.sol\";\nimport \"../interfaces/ISystemParameters.sol\";\n\n\n/// @title SystemParameters\n/// @author Julian Wilson <julian@nextgenbt.com>\n/// @notice Stores system parameters.\ncontract SystemParameters is ISystemParameters {\n    address private oracleFeeRecipient;\n\n    IWhitelist private systemParamsWhitelist;\n\n    constructor(IWhitelist _systemParamsWhitelist) public {\n        systemParamsWhitelist = _systemParamsWhitelist;\n    }\n\n    /// @notice Throws if the caller is not a system params admin.\n    modifier onlySystemParamsAdmin() {\n        require(\n            systemParamsWhitelist.getWhitelisted(msg.sender),\n            \"NOT_SYSTEM_PARAM_ADMIN\"\n        );\n        _;\n    }\n\n    /// @notice Sets the oracle fee recipient. Only callable by SystemParams admins.\n    /// @param newOracleFeeRecipient The new oracle fee recipient address\n    function setNewOracleFeeRecipient(address newOracleFeeRecipient)\n        public\n        onlySystemParamsAdmin\n    {\n        oracleFeeRecipient = newOracleFeeRecipient;\n    }\n\n    function getOracleFeeRecipient() public view returns (address) {\n        return oracleFeeRecipient;\n    }\n}"
    },
    "/home/julian/betx/betx-contracts/contracts/interfaces/ISystemParameters.sol": {
      "keccak256": "0xbc89207a086ff51f62593b3c362e6faab4505e91c0d97e4d2b31654286294f40",
      "content": "pragma solidity 0.5.16;\n\ncontract ISystemParameters {\n    function getOracleFeeRecipient() public view returns (address);\n    function setNewOracleFeeRecipient(address) public;\n}\n"
    },
    "/home/julian/betx/betx-contracts/contracts/interfaces/permissions/IWhitelist.sol": {
      "keccak256": "0x43b8d9573b5d37864e6084472019925ff7947299dd39b9081dcef6df940fb76a",
      "content": "pragma solidity 0.5.16;\n\ncontract IWhitelist {\n    function addAddressToWhitelist(address) public;\n    function removeAddressFromWhitelist(address) public;\n    function getWhitelisted(address) public view returns (bool);\n}\n"
    }
  },
  "settings": {
    "evmVersion": "istanbul",
    "libraries": {},
    "optimizer": {
      "details": {
        "constantOptimizer": true,
        "cse": true,
        "deduplicate": true,
        "jumpdestRemover": true,
        "orderLiterals": true,
        "peephole": true,
        "yul": true,
        "yulDetails": {
          "stackAllocation": true
        }
      },
      "runs": 200
    },
    "remappings": [],
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