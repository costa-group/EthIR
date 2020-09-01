pragma solidity 0.4.25;

// File: contracts/saga/interfaces/IReconciliationAdjuster.sol

/**
 * @title Reconciliation Adjuster Interface.
 */
interface IReconciliationAdjuster {
    /**
     * @dev Get the buy-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustBuy(uint256 _sdrAmount) external view returns (uint256);

    /**
     * @dev Get the sell-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustSell(uint256 _sdrAmount) external view returns (uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/saga/ReconciliationAdjuster.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Reconciliation Adjuster.
 */
contract ReconciliationAdjuster is IReconciliationAdjuster, Claimable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    /**
     * @dev SDR adjustment factor maximum resolution.
     * @notice Allow for sufficiently-high resolution.
     * @notice Prevents multiplication-overflow.
     */
    uint256 public constant MAX_RESOLUTION = 0x10000000000000000;

    uint256 public sequenceNum = 0;
    uint256 public factorN = 0;
    uint256 public factorD = 0;

    event FactorSaved(uint256 _factorN, uint256 _factorD);
    event FactorNotSaved(uint256 _factorN, uint256 _factorD);

    /**
    * @dev throw if called before factor set.
    */
    modifier onlyIfFactorSet() {
        assert(factorN > 0 && factorD > 0);
        _;
    }

    /**
     * @dev Set the SDR adjustment factor.
     * @param _sequenceNum The sequence-number of the operation.
     * @param _factorN The numerator of the SDR adjustment factor.
     * @param _factorD The denominator of the SDR adjustment factor.
     */
    function setFactor(uint256 _sequenceNum, uint256 _factorN, uint256 _factorD) external onlyOwner {
        require(1 <= _factorN && _factorN <= MAX_RESOLUTION, "adjustment factor numerator is out of range");
        require(1 <= _factorD && _factorD <= MAX_RESOLUTION, "adjustment factor denominator is out of range");

        if (sequenceNum < _sequenceNum) {
            sequenceNum = _sequenceNum;
            factorN = _factorN;
            factorD = _factorD;
            emit FactorSaved(_factorN, _factorD);
        }
        else {
            emit FactorNotSaved(_factorN, _factorD);
        }
    }

    /**
     * @dev Get the buy-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustBuy(uint256 _sdrAmount) external view onlyIfFactorSet returns (uint256) {
        return _sdrAmount.mul(factorD) / factorN;
    }

    /**
     * @dev Get the sell-adjusted value of a given SDR amount.
     * @param _sdrAmount The amount of SDR to adjust.
     * @return The adjusted amount of SDR.
     */
    function adjustSell(uint256 _sdrAmount) external view onlyIfFactorSet returns (uint256) {
        return _sdrAmount.mul(factorN) / factorD;
    }
}
