{{
  "language": "Solidity",
  "sources": {
    "@keep-network/sortition-pools/contracts/StackLib.sol": {
      "content": "pragma solidity 0.5.17;\n\nlibrary StackLib {\n    function stackPeek(uint256[] storage _array)\n        internal\n        view\n        returns (uint256)\n    {\n        require(_array.length > 0, \"No value to peek, array is empty\");\n        return (_array[_array.length - 1]);\n    }\n\n    function stackPush(uint256[] storage _array, uint256 _element) public {\n        _array.push(_element);\n    }\n\n    function stackPop(uint256[] storage _array) internal returns (uint256) {\n        require(_array.length > 0, \"No value to pop, array is empty\");\n        uint256 value = _array[_array.length - 1];\n        _array.length -= 1;\n        return value;\n    }\n\n    function getSize(uint256[] storage _array) internal view returns (uint256) {\n        return _array.length;\n    }\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": false,
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