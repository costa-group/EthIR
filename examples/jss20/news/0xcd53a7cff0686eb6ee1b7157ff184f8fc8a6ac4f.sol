pragma solidity 0.4.25;

// File: contracts/saga/interfaces/IReserveManager.sol

/**
 * @title Reserve Manager Interface.
 */
interface IReserveManager {
    /**
     * @dev Get a deposit-recommendation.
     * @param _balance The balance of the token-contract.
     * @return The address of the wallet permitted to deposit ETH into the token-contract.
     * @return The amount that should be deposited in order for the balance to reach `mid` ETH.
     */
    function getDepositParams(uint256 _balance) external view returns (address, uint256);

    /**
     * @dev Get a withdraw-recommendation.
     * @param _balance The balance of the token-contract.
     * @return The address of the wallet permitted to withdraw ETH into the token-contract.
     * @return The amount that should be withdrawn in order for the balance to reach `mid` ETH.
     */
    function getWithdrawParams(uint256 _balance) external view returns (address, uint256);
}

// File: contracts/saga/interfaces/IPaymentManager.sol

/**
 * @title Payment Manager Interface.
 */
interface IPaymentManager {
    /**
     * @dev Retrieve the current number of outstanding payments.
     * @return The current number of outstanding payments.
     */
    function getNumOfPayments() external view returns (uint256);

    /**
     * @dev Retrieve the sum of all outstanding payments.
     * @return The sum of all outstanding payments.
     */
    function getPaymentsSum() external view returns (uint256);

    /**
     * @dev Compute differ payment.
     * @param _ethAmount The amount of ETH entitled by the client.
     * @param _ethBalance The amount of ETH retained by the payment handler.
     * @return The amount of differed ETH payment.
     */
    function computeDifferPayment(uint256 _ethAmount, uint256 _ethBalance) external view returns (uint256);

    /**
     * @dev Register a differed payment.
     * @param _wallet The payment wallet address.
     * @param _ethAmount The payment amount in ETH.
     */
    function registerDifferPayment(address _wallet, uint256 _ethAmount) external;
}

// File: contracts/saga/interfaces/IETHConverter.sol

/**
 * @title ETH Converter Interface.
 */
interface IETHConverter {
    /**
     * @dev Get the current SDR worth of a given ETH amount.
     * @param _ethAmount The amount of ETH to convert.
     * @return The equivalent amount of SDR.
     */
    function toSdrAmount(uint256 _ethAmount) external view returns (uint256);

    /**
     * @dev Get the current ETH worth of a given SDR amount.
     * @param _sdrAmount The amount of SDR to convert.
     * @return The equivalent amount of ETH.
     */
    function toEthAmount(uint256 _sdrAmount) external view returns (uint256);

    /**
     * @dev Get the original SDR worth of a converted ETH amount.
     * @param _ethAmount The amount of ETH converted.
     * @return The original amount of SDR.
     */
    function fromEthAmount(uint256 _ethAmount) external view returns (uint256);
}

// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol

/**
 * @title Contract Address Locator Interface.
 */
interface IContractAddressLocator {
    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address);

    /**
     * @dev Determine whether or not a contract address relates to one of the identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

// File: contracts/contract_address_locator/ContractAddressLocatorHolder.sol

/**
 * @title Contract Address Locator Holder.
 * @dev Hold a contract address locator, which maps a unique identifier to every contract address in the system.
 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.
 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.
 * @dev In addition to that, any function in any contract can be restricted to a specific caller.
 */
contract ContractAddressLocatorHolder {
    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";
    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;
    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;
    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;
    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;
    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;
    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;
    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;
    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;
    bytes32 internal constant _IMintListener_            = "IMintListener"           ;
    bytes32 internal constant _IMintManager_             = "IMintManager"            ;
    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;
    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;
    bytes32 internal constant _IRedButton_               = "IRedButton"              ;
    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;
    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;
    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;
    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;
    bytes32 internal constant _ISGAAuthorizationManager_ = "ISGAAuthorizationManager";
    bytes32 internal constant _ISGAToken_                = "ISGAToken"               ;
    bytes32 internal constant _ISGATokenManager_         = "ISGATokenManager"        ;
    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";
    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;
    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;
    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;
    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;
    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;
    bytes32 internal constant _IWalletsTradingDataSource_       = "IWalletsTradingDataSource"      ;
    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;
    bytes32 internal constant _WalletsTradingLimiter_SGATokenManager_          = "WalletsTLSGATokenManager"         ;
    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;
    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;
    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;
    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;

    IContractAddressLocator private contractAddressLocator;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) internal {
        require(_contractAddressLocator != address(0), "locator is illegal");
        contractAddressLocator = _contractAddressLocator;
    }

    /**
     * @dev Get the contract address locator.
     * @return The contract address locator.
     */
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) internal view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }



    /**
     * @dev Determine whether or not the sender relates to one of the identifiers.
     * @param _identifiers The identifiers.
     * @return A boolean indicating if the sender relates to one of the identifiers.
     */
    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {
        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);
    }

    /**
     * @dev Verify that the caller is mapped to a given identifier.
     * @param _identifier The identifier.
     */
    modifier only(bytes32 _identifier) {
        require(msg.sender == getContractAddress(_identifier), "caller is illegal");
        _;
    }

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

// File: contracts/saga/ReserveManager.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Reserve Manager.
 */
contract ReserveManager is IReserveManager, ContractAddressLocatorHolder, Claimable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    struct Wallets {
        address deposit;
        address withdraw;
    }

    struct Thresholds {
        uint256 min;
        uint256 max;
        uint256 mid;
    }

    Wallets public wallets;

    Thresholds public thresholds;

    uint256 public walletsSequenceNum = 0;
    uint256 public thresholdsSequenceNum = 0;

    event ReserveWalletsSaved(address _deposit, address _withdraw);
    event ReserveWalletsNotSaved(address _deposit, address _withdraw);
    event ReserveThresholdsSaved(uint256 _min, uint256 _max, uint256 _mid);
    event ReserveThresholdsNotSaved(uint256 _min, uint256 _max, uint256 _mid);

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the IETHConverter interface.
     */
    function getETHConverter() public view returns (IETHConverter) {
        return IETHConverter(getContractAddress(_IETHConverter_));
    }

    /**
     * @dev Return the contract which implements the IPaymentManager interface.
     */
    function getPaymentManager() public view returns (IPaymentManager) {
        return IPaymentManager(getContractAddress(_IPaymentManager_));
    }

    /**
     * @dev Set the reserve wallets.
     * @param _walletsSequenceNum The sequence-number of the operation.
     * @param _deposit The address of the wallet permitted to deposit ETH into the token-contract.
     * @param _withdraw The address of the wallet permitted to withdraw ETH from the token-contract.
     */
    function setWallets(uint256 _walletsSequenceNum, address _deposit, address _withdraw) external onlyOwner {
        require(_deposit != address(0), "deposit-wallet is illegal");
        require(_withdraw != address(0), "withdraw-wallet is illegal");

        if (walletsSequenceNum < _walletsSequenceNum) {
            walletsSequenceNum = _walletsSequenceNum;
            wallets.deposit = _deposit;
            wallets.withdraw = _withdraw;

            emit ReserveWalletsSaved(_deposit, _withdraw);
        }
        else {
            emit ReserveWalletsNotSaved(_deposit, _withdraw);
        }
    }

    /**
     * @dev Set the reserve thresholds.
     * @param _thresholdsSequenceNum The sequence-number of the operation.
     * @param _min The maximum balance which allows depositing ETH from the token-contract.
     * @param _max The minimum balance which allows withdrawing ETH into the token-contract.
     * @param _mid The balance that the deposit/withdraw recommendation functions will yield.
     */
    function setThresholds(uint256 _thresholdsSequenceNum, uint256 _min, uint256 _max, uint256 _mid) external onlyOwner {
        require(_min <= _mid, "min-threshold is greater than mid-threshold");
        require(_max >= _mid, "max-threshold is smaller than mid-threshold");

        if (thresholdsSequenceNum < _thresholdsSequenceNum) {
            thresholdsSequenceNum = _thresholdsSequenceNum;
            thresholds.min = _min;
            thresholds.max = _max;
            thresholds.mid = _mid;

            emit ReserveThresholdsSaved(_min, _max, _mid);
        }
        else {
            emit ReserveThresholdsNotSaved(_min, _max, _mid);
        }
    }

    /**
     * @dev Get a deposit-recommendation.
     * @param _balance The balance of the token-contract.
     * @return The address of the wallet permitted to deposit ETH into the token-contract.
     * @return The amount that should be deposited in order for the balance to reach `mid` ETH.
     */
    function getDepositParams(uint256 _balance) external view returns (address, uint256) {
        uint256 depositRecommendation = 0;
        uint256 sdrPaymentsSum = getPaymentManager().getPaymentsSum();
        uint256 ethPaymentsSum = getETHConverter().toEthAmount(sdrPaymentsSum);
        if (ethPaymentsSum >= _balance || (_balance - ethPaymentsSum) <= thresholds.min){// first part of the condition
            // prevents underflow in the second part
            depositRecommendation = (thresholds.mid).add(ethPaymentsSum) - _balance;// will never underflow
        }
        return (wallets.deposit, depositRecommendation);
    }

    /**
     * @dev Get a withdraw-recommendation.
     * @param _balance The balance of the token-contract.
     * @return The address of the wallet permitted to withdraw ETH into the token-contract.
     * @return The amount that should be withdrawn in order for the balance to reach `mid` ETH.
     */
    function getWithdrawParams(uint256 _balance) external view returns (address, uint256) {
        uint256 withdrawRecommendationAmount = 0;
        if (_balance >= thresholds.max && getPaymentManager().getNumOfPayments() == 0){// _balance >= thresholds.max >= thresholds.mid
            withdrawRecommendationAmount = _balance - thresholds.mid; // will never underflow
        }

        return (wallets.withdraw, withdrawRecommendationAmount);
    }
}
