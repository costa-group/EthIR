pragma solidity ^0.4.25;


// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingLimiter.sol



/**

 * @title Wallets Trading Limiter Interface.

 */

interface IWalletsTradingLimiter {

    /**

     * @dev Increment the limiter value of a wallet.

     * @param _wallet The address of the wallet.

     * @param _value The amount to be updated.

     */

    function updateWallet(address _wallet, uint256 _value) external;

}



// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingDataSource.sol



/**

 * @title Wallets Trading Data Source Interface.

 */

interface IWalletsTradingDataSource {

    /**

     * @dev Increment the value of a given wallet.

     * @param _wallet The address of the wallet.

     * @param _value The value to increment by.

     * @param _limit The limit of the wallet.

     */

    function updateWallet(address _wallet, uint256 _value, uint256 _limit) external;

}



// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingLimiterValueConverter.sol



/**

 * @title Wallets Trading Limiter Value Converter Interface.

 */

interface IWalletsTradingLimiterValueConverter {

    /**

     * @dev Get the current limiter currency worth of a given SGA amount.

     * @param _sgaAmount The amount of SGA to convert.

     * @return The equivalent amount of the limiter currency.

     */

    function toLimiterValue(uint256 _sgaAmount) external view returns (uint256);

}



// File: contracts/wallet_trading_limiter/interfaces/ITradingClasses.sol



/**

 * @title Trading Classes Interface.

 */

interface ITradingClasses {

    /**

     * @dev Get the limit of a class.

     * @param _id The id of the class.

     * @return The limit of the class.

     */

    function getLimit(uint256 _id) external view returns (uint256);

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



// File: contracts/authorization/interfaces/IAuthorizationDataSource.sol



/**

 * @title Authorization Data Source Interface.

 */

interface IAuthorizationDataSource {

    /**

     * @dev Get the authorized action-role of a wallet.

     * @param _wallet The address of the wallet.

     * @return The authorized action-role of the wallet.

     */

    function getAuthorizedActionRole(address _wallet) external view returns (bool, uint256);



    /**

     * @dev Get the trade-limit and trade-class of a wallet.

     * @param _wallet The address of the wallet.

     * @return The trade-limit and trade-class of the wallet.

     */

    function getTradeLimitAndClass(address _wallet) external view returns (uint256, uint256);

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



// File: contracts/wallet_trading_limiter/WalletsTradingLimiterBase.sol



/**

 * @title Wallets Trading Limiter Base.

 */

contract WalletsTradingLimiterBase is IWalletsTradingLimiter, ContractAddressLocatorHolder, Claimable {

    string public constant VERSION = "1.0.0";



    /**

     * @dev Create the contract.

     * @param _contractAddressLocator The contract address locator.

     */

    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}



    /**

     * @dev Return the contract which implements the IAuthorizationDataSource interface.

     */

    function getAuthorizationDataSource() public view returns (IAuthorizationDataSource) {

        return IAuthorizationDataSource(getContractAddress(_IAuthorizationDataSource_));

    }



    /**

     * @dev Return the contract which implements the IWalletsTradingDataSource interface.

     */

    function getWalletsTradingDataSource() public view returns (IWalletsTradingDataSource) {

        return IWalletsTradingDataSource(getContractAddress(_IWalletsTradingDataSource_));

    }



    /**

     * @dev Return the contract which implements the IWalletsTradingLimiterValueConverter interface.

     */

    function getWalletsTradingLimiterValueConverter() public view returns (IWalletsTradingLimiterValueConverter) {

        return IWalletsTradingLimiterValueConverter(getContractAddress(_IWalletsTradingLimiterValueConverter_));

    }



    /**

     * @dev Return the contract which implements the ITradingClasses interface.

     */

    function getTradingClasses() public view returns (ITradingClasses) {

        return ITradingClasses(getContractAddress(_ITradingClasses_));

    }



    /**

     * @dev Get the limiter value.

     * @param _value The amount to be converted to the limiter value.

     * @return The limiter value worth of the given amount.

     */

    function getLimiterValue(uint256 _value) public view returns (uint256);



    /**

     * @dev Get the contract locator identifier that is permitted to perform update wallet.

     * @return The contract locator identifier.

     */

    function getUpdateWalletPermittedContractLocatorIdentifier() public pure returns (bytes32);



    /**

     * @dev Increment the limiter value of a wallet.

     * @param _wallet The address of the wallet.

     * @param _value The amount to be updated.

     */

    function updateWallet(address _wallet, uint256 _value) external only(getUpdateWalletPermittedContractLocatorIdentifier()) {

        uint256 limiterValue =  getLimiterValue(_value);

        (uint256 tradeLimit, uint256 tradeClass) = getAuthorizationDataSource().getTradeLimitAndClass(_wallet);

        uint256 actualLimit = tradeLimit > 0 ? tradeLimit : getTradingClasses().getLimit(tradeClass);

        getWalletsTradingDataSource().updateWallet(_wallet, limiterValue, actualLimit);

    }

}



// File: contracts/saga/SGAWalletsTradingLimiter.sol



/**

 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1

 */



/**

 * @title SGA Wallets Trading Limiter.

 */

contract SGAWalletsTradingLimiter is WalletsTradingLimiterBase {

    string public constant VERSION = "1.0.0";



    /**

     * @dev Create the contract.

     * @param _contractAddressLocator The contract address locator.

     */

    constructor(IContractAddressLocator _contractAddressLocator) WalletsTradingLimiterBase(_contractAddressLocator) public {}





    /**

     * @dev Get the contract locator identifier that is permitted to perform update wallet.

     * @return The contract locator identifier.

     */

    function getUpdateWalletPermittedContractLocatorIdentifier() public pure returns (bytes32){

        return _ISGATokenManager_;

    }



    /**

     * @dev Get the limiter value.

     * @param _value The SGA amount to convert to limiter value.

     * @return The limiter value worth of the given SGA amount.

     */

    function getLimiterValue(uint256 _value) public view returns (uint256){

        return getWalletsTradingLimiterValueConverter().toLimiterValue(_value);

    }

}
