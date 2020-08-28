pragma solidity 0.4.25;

// File: contracts/saga/interfaces/IMonetaryModel.sol

/**
 * @title Monetary Model Interface.
 */
interface IMonetaryModel {
    /**
     * @dev Buy SGA in exchange for SDR.
     * @param _sdrAmount The amount of SDR received from the buyer.
     * @return The amount of SGA that the buyer is entitled to receive.
     */
    function buy(uint256 _sdrAmount) external returns (uint256);

    /**
     * @dev Sell SGA in exchange for SDR.
     * @param _sgaAmount The amount of SGA received from the seller.
     * @return The amount of SDR that the seller is entitled to receive.
     */
    function sell(uint256 _sgaAmount) external returns (uint256);
}

// File: contracts/saga/interfaces/IMonetaryModelState.sol

/**
 * @title Monetary Model State Interface.
 */
interface IMonetaryModelState {
    /**
     * @dev Set the total amount of SDR in the model.
     * @param _amount The total amount of SDR in the model.
     */
    function setSdrTotal(uint256 _amount) external;

    /**
     * @dev Set the total amount of SGA in the model.
     * @param _amount The total amount of SGA in the model.
     */
    function setSgaTotal(uint256 _amount) external;

    /**
     * @dev Get the total amount of SDR in the model.
     * @return The total amount of SDR in the model.
     */
    function getSdrTotal() external view returns (uint256);

    /**
     * @dev Get the total amount of SGA in the model.
     * @return The total amount of SGA in the model.
     */
    function getSgaTotal() external view returns (uint256);
}

// File: contracts/saga/interfaces/IModelCalculator.sol

/**
 * @title Model Calculator Interface.
 */
interface IModelCalculator {
    /**
     * @dev Check whether or not an interval is trivial.
     * @param _alpha The alpha-value of the interval.
     * @param _beta The beta-value of the interval.
     * @return True if and only if the interval is trivial.
     */
    function isTrivialInterval(uint256 _alpha, uint256 _beta) external pure returns (bool);

    /**
     * @dev Calculate N(R) on a trivial interval.
     * @param _valR The given value of R on the interval.
     * @param _maxN The maximum value of N on the interval.
     * @param _maxR The maximum value of R on the interval.
     * @return N(R).
     */
    function getValN(uint256 _valR, uint256 _maxN, uint256 _maxR) external pure returns (uint256);

    /**
     * @dev Calculate R(N) on a trivial interval.
     * @param _valN The given value of N on the interval.
     * @param _maxR The maximum value of R on the interval.
     * @param _maxN The maximum value of N on the interval.
     * @return R(N).
     */
    function getValR(uint256 _valN, uint256 _maxR, uint256 _maxN) external pure returns (uint256);

    /**
     * @dev Calculate N(R) on a non-trivial interval.
     * @param _newR The given value of R on the interval.
     * @param _minR The minimum value of R on the interval.
     * @param _minN The minimum value of N on the interval.
     * @param _alpha The alpha-value of the interval.
     * @param _beta The beta-value of the interval.
     * @return N(R).
     */
    function getNewN(uint256 _newR, uint256 _minR, uint256 _minN, uint256 _alpha, uint256 _beta) external pure returns (uint256);

    /**
     * @dev Calculate R(N) on a non-trivial interval.
     * @param _newN The given value of N on the interval.
     * @param _minN The minimum value of N on the interval.
     * @param _minR The minimum value of R on the interval.
     * @param _alpha The alpha-value of the interval.
     * @param _beta The beta-value of the interval.
     * @return R(N).
     */
    function getNewR(uint256 _newN, uint256 _minN, uint256 _minR, uint256 _alpha, uint256 _beta) external pure returns (uint256);
}

// File: contracts/saga/interfaces/IPriceBandCalculator.sol

/**
 * @title Price Band Calculator Interface.
 */
interface IPriceBandCalculator {
    /**
     * @dev Deduct price-band from a given amount of SDR.
     * @param _sdrAmount The amount of SDR.
     * @param _sgaTotal The total amount of SGA.
     * @param _alpha The alpha-value of the current interval.
     * @param _beta The beta-value of the current interval.
     * @return The amount of SDR minus the price-band.
     */
    function buy(uint256 _sdrAmount, uint256 _sgaTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256);

    /**
     * @dev Deduct price-band from a given amount of SDR.
     * @param _sdrAmount The amount of SDR.
     * @param _sgaTotal The total amount of SGA.
     * @param _alpha The alpha-value of the current interval.
     * @param _beta The beta-value of the current interval.
     * @return The amount of SDR minus the price-band.
     */
    function sell(uint256 _sdrAmount, uint256 _sgaTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256);
}

// File: contracts/saga/interfaces/IIntervalIterator.sol

/**
 * @title Interval Iterator Interface.
 */
interface IIntervalIterator {
    /**
     * @dev Move to a higher interval and start a corresponding timer if necessary.
     */
    function grow() external;

    /**
     * @dev Reset the timer of the current interval if necessary and move to a lower interval.
     */
    function shrink() external;

    /**
     * @dev Return the current interval.
     */
    function getCurrentInterval() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Return the current interval coefficients.
     */
    function getCurrentIntervalCoefs() external view returns (uint256, uint256);
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

// File: contracts/saga/MonetaryModel.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Monetary Model.
 */
contract MonetaryModel is IMonetaryModel, ContractAddressLocatorHolder {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    event MonetaryModelBuyCompleted(uint256 _input, uint256 _output);
    event MonetaryModelSellCompleted(uint256 _input, uint256 _output);

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

    /**
     * @dev Return the contract which implements the IMonetaryModelState interface.
     */
    function getMonetaryModelState() public view returns (IMonetaryModelState) {
        return IMonetaryModelState(getContractAddress(_IMonetaryModelState_));
    }

    /**
     * @dev Return the contract which implements the IModelCalculator interface.
     */
    function getModelCalculator() public view returns (IModelCalculator) {
        return IModelCalculator(getContractAddress(_IModelCalculator_));
    }

    /**
     * @dev Return the contract which implements the IPriceBandCalculator interface.
     */
    function getPriceBandCalculator() public view returns (IPriceBandCalculator) {
        return IPriceBandCalculator(getContractAddress(_IPriceBandCalculator_));
    }

    /**
     * @dev Return the contract which implements the IIntervalIterator interface.
     */
    function getIntervalIterator() public view returns (IIntervalIterator) {
        return IIntervalIterator(getContractAddress(_IIntervalIterator_));
    }

    /**
     * @dev Buy SGA in exchange for SDR.
     * @param _sdrAmount The amount of SDR received from the buyer.
     * @return The amount of SGA that the buyer is entitled to receive.
     */
    function buy(uint256 _sdrAmount) external only(_ITransactionManager_) returns (uint256) {
        IMonetaryModelState monetaryModelState = getMonetaryModelState();
        IIntervalIterator intervalIterator = getIntervalIterator();

        uint256 sgaTotal = monetaryModelState.getSgaTotal();
        (uint256 alpha, uint256 beta) = intervalIterator.getCurrentIntervalCoefs();
        uint256 sdrAmountAfterFee = getPriceBandCalculator().buy(_sdrAmount, sgaTotal, alpha, beta);
        uint256 sgaAmount = buyFunc(sdrAmountAfterFee, monetaryModelState, intervalIterator);

        emit MonetaryModelBuyCompleted(_sdrAmount, sgaAmount);
        return sgaAmount;
    }

    /**
     * @dev Sell SGA in exchange for SDR.
     * @param _sgaAmount The amount of SGA received from the seller.
     * @return The amount of SDR that the seller is entitled to receive.
     */
    function sell(uint256 _sgaAmount) external only(_ITransactionManager_) returns (uint256) {
        IMonetaryModelState monetaryModelState = getMonetaryModelState();
        IIntervalIterator intervalIterator = getIntervalIterator();

        uint256 sgaTotal = monetaryModelState.getSgaTotal();
        (uint256 alpha, uint256 beta) = intervalIterator.getCurrentIntervalCoefs();
        uint256 sdrAmountBeforeFee = sellFunc(_sgaAmount, monetaryModelState, intervalIterator);
        uint256 sdrAmount = getPriceBandCalculator().sell(sdrAmountBeforeFee, sgaTotal, alpha, beta);

        emit MonetaryModelSellCompleted(_sgaAmount, sdrAmount);
        return sdrAmount;
    }

    /**
     * @dev Execute the SDR-to-SGA algorithm.
     * @param _sdrAmount The amount of SDR.
     * @return The equivalent amount of SGA.
     * @notice The two additional parameters can also be retrieved inside the function.
     * @notice They are passed from the outside, however, in order to improve performance and reduce the cost.
     * @notice Another parameter is retrieved inside the function due to a technical limitation, namely, insufficient stack size.
     */
    function buyFunc(uint256 _sdrAmount, IMonetaryModelState _monetaryModelState, IIntervalIterator _intervalIterator) private returns (uint256) {
        uint256 sgaCount = 0;
        uint256 sdrCount = _sdrAmount;

        uint256 sdrDelta;
        uint256 sgaDelta;

        uint256 sdrTotal = _monetaryModelState.getSdrTotal();
        uint256 sgaTotal = _monetaryModelState.getSgaTotal();

        //Gas consumption is capped, since according to the parameters of the Saga monetary model the execution of more than one iteration of this loop involves transaction of tens (or more) of millions of SDR worth of ETH and are thus unlikely.
        (uint256 minN, uint256 maxN, uint256 minR, uint256 maxR, uint256 alpha, uint256 beta) = _intervalIterator.getCurrentInterval();
        while (sdrCount >= maxR.sub(sdrTotal)) {
            sdrDelta = maxR.sub(sdrTotal);
            sgaDelta = maxN.sub(sgaTotal);
            _intervalIterator.grow();
            (minN, maxN, minR, maxR, alpha, beta) = _intervalIterator.getCurrentInterval();
            sdrTotal = minR;
            sgaTotal = minN;
            sdrCount = sdrCount.sub(sdrDelta);
            sgaCount = sgaCount.add(sgaDelta);
        }

        if (sdrCount > 0) {
            if (getModelCalculator().isTrivialInterval(alpha, beta))
                sgaDelta = getModelCalculator().getValN(sdrCount, maxN, maxR);
            else
                sgaDelta = getModelCalculator().getNewN(sdrTotal.add(sdrCount), minR, minN, alpha, beta).sub(sgaTotal);
            sdrTotal = sdrTotal.add(sdrCount);
            sgaTotal = sgaTotal.add(sgaDelta);
            sgaCount = sgaCount.add(sgaDelta);
        }

        _monetaryModelState.setSdrTotal(sdrTotal);
        _monetaryModelState.setSgaTotal(sgaTotal);

        return sgaCount;
    }

    /**
     * @dev Execute the SGA-to-SDR algorithm.
     * @param _sgaAmount The amount of SGA.
     * @return The equivalent amount of SDR.
     * @notice The two additional parameters can also be retrieved inside the function.
     * @notice They are passed from the outside, however, in order to improve performance and reduce the cost.
     * @notice Another parameter is retrieved inside the function due to a technical limitation, namely, insufficient stack size.
     */
    function sellFunc(uint256 _sgaAmount, IMonetaryModelState _monetaryModelState, IIntervalIterator _intervalIterator) private returns (uint256) {
        uint256 sdrCount = 0;
        uint256 sgaCount = _sgaAmount;

        uint256 sgaDelta;
        uint256 sdrDelta;

        uint256 sgaTotal = _monetaryModelState.getSgaTotal();
        uint256 sdrTotal = _monetaryModelState.getSdrTotal();

        //Gas consumption is capped, since according to the parameters of the Saga monetary model the execution of more than one iteration of this loop involves transaction of tens (or more) of millions of SDR worth of ETH and are thus unlikely.
        (uint256 minN, uint256 maxN, uint256 minR, uint256 maxR, uint256 alpha, uint256 beta) = _intervalIterator.getCurrentInterval();
        while (sgaCount > sgaTotal.sub(minN)) {
            sgaDelta = sgaTotal.sub(minN);
            sdrDelta = sdrTotal.sub(minR);
            _intervalIterator.shrink();
            (minN, maxN, minR, maxR, alpha, beta) = _intervalIterator.getCurrentInterval();
            sgaTotal = maxN;
            sdrTotal = maxR;
            sgaCount = sgaCount.sub(sgaDelta);
            sdrCount = sdrCount.add(sdrDelta);
        }

        if (sgaCount > 0) {
            if (getModelCalculator().isTrivialInterval(alpha, beta))
                sdrDelta = getModelCalculator().getValR(sgaCount, maxR, maxN);
            else
                sdrDelta = sdrTotal.sub(getModelCalculator().getNewR(sgaTotal.sub(sgaCount), minN, minR, alpha, beta));
            sgaTotal = sgaTotal.sub(sgaCount);
            sdrTotal = sdrTotal.sub(sdrDelta);
            sdrCount = sdrCount.add(sdrDelta);
        }

        _monetaryModelState.setSgaTotal(sgaTotal);
        _monetaryModelState.setSdrTotal(sdrTotal);

        return sdrCount;
    }
}
