// File: contracts\interfaces\IWhitelist.sol

pragma solidity 0.5.15;


/**
 * Source: https://raw.githubusercontent.com/simple-restricted-token/reference-implementation/master/contracts/token/ERC1404/ERC1404.sol
 * With ERC-20 APIs removed (will be implemented as a separate contract).
 * And adding authorizeTransfer.
 */
interface IWhitelist
{
  /**
   * @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
   * @param from Sending address
   * @param to Receiving address
   * @param value Amount of tokens being transferred
   * @return Code by which to reference message for rejection reasoning
   * @dev Overwrite with your custom transfer restriction logic
   */
  function detectTransferRestriction(
    address from,
    address to,
    uint value
  ) external view
    returns (uint8);

  /**
   * @notice Returns a human-readable message for a given restriction code
   * @param restrictionCode Identifier for looking up a message
   * @return Text showing the restriction's reasoning
   * @dev Overwrite with your custom message and restrictionCode handling
   */
  function messageForTransferRestriction(
    uint8 restrictionCode
  ) external pure
    returns (string memory);

  /**
   * @notice Called by the DAT contract before a transfer occurs.
   * @dev This call will revert when the transfer is not authorized.
   * This is a mutable call to allow additional data to be recorded,
   * such as when the user aquired their tokens.
   */
  function authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  ) external;
}

// File: @openzeppelin\upgrades\contracts\Initializable.sol

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

// File: node_modules\@openzeppelin\contracts-ethereum-package\contracts\GSN\Context.sol

pragma solidity ^0.5.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts-ethereum-package\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: contracts\Whitelist.sol

pragma solidity 0.5.15;



/**
 * @title whitelist implementation which manages KYC approvals for the org.
 * @dev modeled after ERC-1404
 */
contract Whitelist is IWhitelist, Ownable
{
  /**
   * Emits when an operator KYC approves (or revokes) a trader.
   */
  event Approve(address indexed _trader, bool _isApproved);

  mapping(address => bool) public approved;
  address public dat;

  /**
   * @notice Called once to complete configuration for this contract.
   * @dev Done with `initialize` instead of a constructor in order to support
   * using this contract via an Upgradable Proxy.
   */
  function initialize(
    address _dat
  ) public
  {
    Ownable.initialize(msg.sender);
    dat = _dat;

    // Setting 0 to approved allows mint/burn actions
    approved[address(0)] = true;
  }

  function detectTransferRestriction(
    address _from,
    address _to,
    uint //_value (ignored)
  ) public view returns(uint8)
  {
    if(approved[_from] && approved[_to])
    {
      // Transfer approved
      return 0;
    }

    // Transfer denied
    return 1;
  }

  function messageForTransferRestriction(
    uint8 _restrictionCode
  ) external pure
    returns (string memory)
  {
    if(_restrictionCode == 0)
    {
      return "SUCCESS";
    }
    if(_restrictionCode == 1)
    {
      return "DENIED";
    }
    return "UNKNOWN_ERROR";
  }

  /**
   * @notice Allows the owner of this contract to approve (or deny)
   * a trader's account.
   */
  function approve(
    address _trader,
    bool _isApproved
  ) external onlyOwner
  {
    approved[_trader] = _isApproved;
    emit Approve(_trader, _isApproved);
  }

  /**
   * @notice Called by the DAT contract before a transfer occurs.
   * @dev This call will revert when the transfer is not authorized.
   * This is a mutable call to allow additional data to be recorded,
   * such as when the user aquired their tokens.
   */
  function authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  ) external
  {
    require(dat == msg.sender, "CALL_VIA_DAT_ONLY");
    require(detectTransferRestriction(_from, _to, _value) == 0, "TRANSFER_DENIED");
    // Future versions will add additional logic here
  }
}