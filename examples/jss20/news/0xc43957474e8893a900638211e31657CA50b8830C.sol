{{

  "language": "Solidity",

  "sources": {

    "solidity/contracts/system/KeepFactorySelection.sol": {

pragma solidity ^0.5.17;
    },

    "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeepFactory.sol": {

pragma solidity ^0.5.17;
    },

    "@keep-network/keep-ecdsa/contracts/api/IBondedECDSAKeep.sol": {

pragma solidity ^0.5.17;
    }

  },

  "settings": {

    "metadata": {

      "useLiteralContent": true

    },

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