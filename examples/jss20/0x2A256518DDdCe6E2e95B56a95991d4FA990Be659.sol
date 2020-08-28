{{
  "language": "Solidity",
  "settings": {
    "remappings": [
      "ROOT=/home/achapman/augur/packages/augur-core/src/contracts//"
    ],
    "optimizer": {
      "enabled": true,
      "runs": 200,
      "details": {
        "yul": true,
        "deduplicate": true,
        "cse": true,
        "constantOptimizer": true
      }
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
    "reporting/AffiliateValidator.sol": {
      "content": "pragma solidity 0.5.15;\n\ncontract IOwnable {\n    function getOwner() public view returns (address);\n    function transferOwnership(address _newOwner) public returns (bool);\n}\n\ncontract Ownable is IOwnable {\n    address internal owner;\n\n    /**\n     * @dev The Ownable constructor sets the original `owner` of the contract to the sender\n     * account.\n     */\n    constructor() public {\n        owner = msg.sender;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(msg.sender == owner);\n        _;\n    }\n\n    function getOwner() public view returns (address) {\n        return owner;\n    }\n\n    /**\n     * @dev Allows the current owner to transfer control of the contract to a newOwner.\n     * @param _newOwner The address to transfer ownership to.\n     */\n    function transferOwnership(address _newOwner) public onlyOwner returns (bool) {\n        require(_newOwner != address(0));\n        onTransferOwnership(owner, _newOwner);\n        owner = _newOwner;\n        return true;\n    }\n\n    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract\n    function onTransferOwnership(address, address) internal;\n}\n\ncontract IAffiliateValidator {\n    function validateReference(address _account, address _referrer) external view returns (bool);\n}\n\ncontract AffiliateValidator is Ownable, IAffiliateValidator {\n    // Mapping of affiliate address to their key\n    mapping (address => bytes32) public keys;\n\n    mapping (address => bool) public operators;\n\n    mapping (uint256 => bool) public usedSalts;\n\n    /**\n     * @notice Add an operator who can sign keys to admit accounts into this affiliate validator\n     * @param _operator The address of the new operator\n     */\n    function addOperator(address _operator) external onlyOwner {\n        operators[_operator] = true;\n    }\n\n    /**\n     * @notice Remove an existing operator\n     * @param _operator The operator to remove from the authorized operators\n     */\n    function removeOperator(address _operator) external onlyOwner {\n        operators[_operator] = false;\n    }\n\n    /**\n     * @notice Apply a key provided by an operator in order to be added to this validator\n     * @param _key The key to store. This is used to check if an account is attempting to self trade\n     * @param _salt A salt to secure the key hash\n     * @param _r r portion of the signature\n     * @param _s s portion of the signature\n     * @param _v v portion of the signature\n     * @return bytes32\n     */\n    function addKey(bytes32 _key, uint256 _salt, bytes32 _r, bytes32 _s, uint8 _v) external {\n        require(!usedSalts[_salt], \"Salt already used\");\n        bytes32 _hash = getKeyHash(_key, msg.sender, _salt);\n        require(isValidSignature(_hash, _r, _s, _v), \"Signature invalid\");\n        usedSalts[_salt] = true;\n        keys[msg.sender] = _key;\n    }\n\n    /**\n     * @notice Get the key hash for a given key\n     * @param _key The key to get a hash for\n     * @param _account The account to get a hash for\n     * @param _salt A salt to secure the key hash\n     * @return bytes32\n     */\n    function getKeyHash(bytes32 _key, address _account, uint256 _salt) public view returns (bytes32) {\n        return keccak256(abi.encodePacked(_key, _account, address(this), _salt));\n    }\n\n    function isValidSignature(bytes32 _hash, bytes32 _r, bytes32 _s, uint8 _v) public view returns (bool) {\n        address recovered = ecrecover(\n            keccak256(abi.encodePacked(\n                \"\\x19Ethereum Signed Message:\\n32\",\n                _hash\n            )),\n            _v,\n            _r,\n            _s\n        );\n        return operators[recovered];\n    }\n\n    function validateReference(address _account, address _referrer) external view returns (bool) {\n        bytes32 _accountKey = keys[_account];\n        bytes32 _referralKey = keys[_referrer];\n        if (_accountKey == bytes32(0) || _referralKey == bytes32(0)) {\n            return false;\n        }\n        return _accountKey != _referralKey;\n    }\n\n    function onTransferOwnership(address, address) internal {}\n}\n\n"
    }
  }
}}