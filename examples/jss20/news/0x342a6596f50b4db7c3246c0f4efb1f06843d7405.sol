// File: @sablier/shared-contracts/interfaces/ICERC20.sol

pragma solidity 0.5.11;

/**
 * @title CERC20 interface
 * @author Sablier
 * @dev See https://compound.finance/developers
 */
interface ICERC20 {
    function balanceOf(address who) external view returns (uint256);

    function isCToken() external view returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @sablier/shared-contracts/lifecycle/OwnableWithoutRenounce.sol

pragma solidity 0.5.11;



/**
 * @title OwnableWithoutRenounce
 * @author Sablier
 * @dev Fork of OpenZeppelin's Ownable contract, which provides basic authorization control, but with
 *  the `renounceOwnership` function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/ownership/Ownable.sol
 * See https://forum.openzeppelin.com/t/contract-request-ownable-without-renounceownership/1400
 * See https://docs.openzeppelin.com/contracts/2.x/gsn#_msg_sender_and_msg_data
 */
contract OwnableWithoutRenounce is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: contracts/interfaces/ICTokenManager.sol

pragma solidity 0.5.11;

/**
 * @title CTokenManager Interface
 * @author Sablier
 */
interface ICTokenManager {
    /**
     * @notice Emits when the owner discards a cToken.
     */
    event DiscardCToken(address indexed tokenAddress);

    /**
     * @notice Emits when the owner whitelists a cToken.
     */
    event WhitelistCToken(address indexed tokenAddress);

    function whitelistCToken(address tokenAddress) external;

    function discardCToken(address tokenAddress) external;

    function isCToken(address tokenAddress) external view returns (bool);
}

// File: contracts/CTokenManager.sol

pragma solidity 0.5.11;




/**
 * @title CTokenManager
 * @author Sablier
 */
contract CTokenManager is ICTokenManager, OwnableWithoutRenounce {
    /*** Storage Properties ***/

    /**
     * @notice Mapping of cTokens which can be used
     */
    mapping(address => bool) private cTokens;

    /*** Contract Logic Starts Here */

    constructor() public {
        OwnableWithoutRenounce.initialize(msg.sender);
    }

    /*** Owner Functions ***/

    /**
     * @notice Whitelists a cToken for compounding streams.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws is the token is whitelisted.
     *  Throws if the given address is not a `cToken`.
     * @param tokenAddress The address of the cToken to whitelist.
     */
    function whitelistCToken(address tokenAddress) external onlyOwner {
        require(!isCToken(tokenAddress), "cToken is whitelisted");
        require(ICERC20(tokenAddress).isCToken(), "token is not cToken");
        cTokens[tokenAddress] = true;
        emit WhitelistCToken(tokenAddress);
    }

    /**
     * @notice Discards a previously whitelisted cToken.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws if token is not whitelisted.
     * @param tokenAddress The address of the cToken to discard.
     */
    function discardCToken(address tokenAddress) external onlyOwner {
        require(isCToken(tokenAddress), "cToken is not whitelisted");
        cTokens[tokenAddress] = false;
        emit DiscardCToken(tokenAddress);
    }

    /*** View Functions ***/
    /**
     * @notice Checks if the given token address is one of the whitelisted cTokens.
     * @param tokenAddress The address of the token to check.
     * @return bool true=it is cToken, otherwise false.
     */
    function isCToken(address tokenAddress) public view returns (bool) {
        return cTokens[tokenAddress];
    }
}