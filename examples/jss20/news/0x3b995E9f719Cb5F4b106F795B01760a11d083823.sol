{{

  "language": "Solidity",

  "sources": {

    "solidity/contracts/price-feed/SatWeiPriceFeed.sol": {

      "content": "/*\n Authored by Satoshi Nakamoto 🤪\n */\n\npragma solidity 0.5.17;\n\nimport {SafeMath} from \"openzeppelin-solidity/contracts/math/SafeMath.sol\";\nimport \"openzeppelin-solidity/contracts/ownership/Ownable.sol\";\nimport \"../external/IMedianizer.sol\";\nimport \"../interfaces/ISatWeiPriceFeed.sol\";\n\n/// @notice satoshi/wei price feed.\n/// @dev Used ETH/USD medianizer values converted to sat/wei.\ncontract SatWeiPriceFeed is Ownable, ISatWeiPriceFeed {\n    using SafeMath for uint256;\n\n    bool private _initialized = false;\n    address internal tbtcSystemAddress;\n\n    IMedianizer[] private ethBtcFeeds;\n\n    constructor() public {\n    // solium-disable-previous-line no-empty-blocks\n    }\n\n    /// @notice Initialises the addresses of the ETHBTC price feeds.\n    /// @param _tbtcSystemAddress Address of the `TBTCSystem` contract. Used for access control.\n    /// @param _ETHBTCPriceFeed The ETHBTC price feed address.\n    function initialize(\n        address _tbtcSystemAddress,\n        IMedianizer _ETHBTCPriceFeed\n    )\n        external onlyOwner\n    {\n        require(!_initialized, \"Already initialized.\");\n        tbtcSystemAddress = _tbtcSystemAddress;\n        ethBtcFeeds.push(_ETHBTCPriceFeed);\n        _initialized = true;\n    }\n\n    /// @notice Get the current price of 1 satoshi in wei.\n    /// @dev This does not account for any 'Flippening' event.\n    /// @return The price of one satoshi in wei.\n    function getPrice()\n        external onlyTbtcSystem view returns (uint256)\n    {\n        bool ethBtcActive;\n        uint256 ethBtc;\n\n        for(uint i = 0; i < ethBtcFeeds.length; i++){\n            (ethBtc, ethBtcActive) = ethBtcFeeds[i].peek();\n            if(ethBtcActive) {\n                break;\n            }\n        }\n\n        require(ethBtcActive, \"Price feed offline\");\n\n        // convert eth/btc to sat/wei\n        // We typecast down to uint128, because the first 128 bits of\n        // the medianizer value is unrelated to the price.\n        return uint256(10**28).div(uint256(uint128(ethBtc)));\n    }\n\n    /// @notice Get the first active Medianizer contract from the ethBtcFeeds array.\n    /// @return The address of the first Active Medianizer. address(0) if none found\n    function getWorkingEthBtcFeed() external view returns (address){\n        bool ethBtcActive;\n\n        for(uint i = 0; i < ethBtcFeeds.length; i++){\n            (, ethBtcActive) = ethBtcFeeds[i].peek();\n            if(ethBtcActive) {\n                return address(ethBtcFeeds[i]);\n            }\n        }\n        return address(0);\n    }\n\n    /// @notice Add _ethBtcFeed to internal ethBtcFeeds array.\n    /// @dev IMedianizer must be active in order to add.\n    function addEthBtcFeed(IMedianizer _ethBtcFeed) external onlyTbtcSystem {\n        bool ethBtcActive;\n        (, ethBtcActive) = _ethBtcFeed.peek();\n        require(ethBtcActive, \"Cannot add inactive feed\");\n        ethBtcFeeds.push(_ethBtcFeed);\n    }\n\n    /// @notice Function modifier ensures modified function is only called by tbtcSystemAddress.\n    modifier onlyTbtcSystem(){\n        require(msg.sender == tbtcSystemAddress, \"Caller must be tbtcSystem contract\");\n        _;\n    }\n}\n"

    },

    "solidity/contracts/interfaces/ISatWeiPriceFeed.sol": {

pragma solidity ^0.5.17;
    },

    "solidity/contracts/external/IMedianizer.sol": {

      "content": "pragma solidity 0.5.17;\n\n/// @notice A medianizer price feed.\n/// @dev Based off the MakerDAO medianizer (https://github.com/makerdao/median)\ninterface IMedianizer {\n    /// @notice Get the current price.\n    /// @dev May revert if caller not whitelisted.\n    /// @return Designated price with 18 decimal places.\n    function read() external view returns (uint256);\n\n    /// @notice Get the current price and check if the price feed is active\n    /// @dev May revert if caller not whitelisted.\n    /// @return Designated price with 18 decimal places.\n    /// @return true if price is > 0, else returns false\n    function peek() external view returns (uint256, bool);\n}\n"

    },

    "openzeppelin-solidity/contracts/math/SafeMath.sol": {

      "content": "pragma solidity ^0.5.0;\n\n/**\n * @dev Wrappers over Solidity's arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it's recommended to use it always.\n */\nlibrary SafeMath {\n    /**\n     * @dev Returns the addition of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `+` operator.\n     *\n     * Requirements:\n     * - Addition cannot overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c >= a, \"SafeMath: addition overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b <= a, \"SafeMath: subtraction overflow\");\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the multiplication of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `*` operator.\n     *\n     * Requirements:\n     * - Multiplication cannot overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n        // benefit is lost if 'b' is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"SafeMath: multiplication overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Solidity only automatically asserts when dividing by 0\n        require(b > 0, \"SafeMath: division by zero\");\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b != 0, \"SafeMath: modulo by zero\");\n        return a % b;\n    }\n}\n"

    },

    "openzeppelin-solidity/contracts/ownership/Ownable.sol": {

      "content": "pragma solidity ^0.5.0;\n\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be aplied to your functions to restrict their use to\n * the owner.\n */\ncontract Ownable {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor () internal {\n        _owner = msg.sender;\n        emit OwnershipTransferred(address(0), _owner);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(isOwner(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Returns true if the caller is the current owner.\n     */\n    function isOwner() public view returns (bool) {\n        return msg.sender == _owner;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * > Note: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public onlyOwner {\n        _transferOwnership(newOwner);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     */\n    function _transferOwnership(address newOwner) internal {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"

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