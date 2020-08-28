{{
  "language": "Solidity",
  "sources": {
    "/home/julian/betx/betx-contracts/contracts/impl/permissions/OutcomeReporterWhitelist.sol": {
      "keccak256": "0x0ed741c0b29adbb28b9047f6dabe0a68efe4e20fa303faafee059d8771ca601c",
      "content": "pragma solidity 0.5.16;\npragma experimental ABIEncoderV2;\n\nimport \"./Whitelist.sol\";\nimport \"../../interfaces/permissions/ISuperAdminRole.sol\";\n\n\n/// @title OutcomeReporterWhitelist\n/// @author Julian Wilson <julian@nextgenbt.com>\n/// @notice A whitelist that represents all members allowed to\n///         report on markets in the protocol.\ncontract OutcomeReporterWhitelist is Whitelist {\n    constructor(ISuperAdminRole _superAdminRole) public Whitelist(_superAdminRole) {}\n}"
    },
    "/home/julian/betx/betx-contracts/contracts/impl/permissions/Whitelist.sol": {
      "keccak256": "0xd869bdaf9c50af72815561efa7c7ad0b61a7b483b7f76fee1c08179537bd2a2d",
      "content": "pragma solidity 0.5.16;\npragma experimental ABIEncoderV2;\n\nimport \"../../interfaces/permissions/ISuperAdminRole.sol\";\nimport \"../../interfaces/permissions/IWhitelist.sol\";\n\n\n/// @title Whitelist\n/// @author Julian Wilson <julian@nextgenbt.com>\n/// @notice The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.\n///         This simplifies the implementation of \"user permissions\".\n///         This Whitelist is special in that only super admins can add others to this whitelist.\n///         This is copied verbatim, plus the SuperAdminRole authorization, from openzeppelin.\ncontract Whitelist is IWhitelist {\n    ISuperAdminRole internal superAdminRole;\n\n    mapping (address => bool) public whitelisted;\n\n    constructor(ISuperAdminRole _superAdminRole) public {\n        superAdminRole = _superAdminRole;\n    }\n\n    /// @notice Throws if the operator is not a super admin.\n    /// @param operator The operator.\n    modifier onlySuperAdmin(address operator) {\n        require(\n            superAdminRole.isSuperAdmin(operator),\n            \"NOT_A_SUPER_ADMIN\"\n        );\n        _;\n    }\n\n    /// @notice Adds an operator to the whitelist\n    ///         Only callable by the SuperAdmin role.\n    /// @param operator The operator to add.\n    function addAddressToWhitelist(address operator)\n        public\n        onlySuperAdmin(msg.sender)\n    {\n        whitelisted[operator] = true;\n    }\n\n    /// @notice Removes an address from the whitelist\n    ///         Only callable by the SuperAdmin role.\n    /// @param operator The operator to remove.\n    function removeAddressFromWhitelist(address operator)\n        public\n        onlySuperAdmin(msg.sender)\n    {\n        whitelisted[operator] = false;\n    }\n\n    /// @notice Checks if the operator is whitelisted.\n    /// @param operator The operator.\n    /// @return true if the operator is whitelisted, false otherwise\n    function getWhitelisted(address operator) public view returns (bool) {\n        return whitelisted[operator];\n    }\n}"
    },
    "/home/julian/betx/betx-contracts/contracts/interfaces/permissions/ISuperAdminRole.sol": {
      "keccak256": "0x6ad66846e01a39300df731455ab5aa8984edd52807700a5da232fecef83532e9",
      "content": "pragma solidity 0.5.16;\n\ncontract ISuperAdminRole {\n    function isSuperAdmin(address account) public view returns (bool);\n    function addSuperAdmin(address account) public;\n    function removeSuperAdmin(address account) public;\n    function getSuperAdminCount() public view returns (uint256);\n}\n"
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