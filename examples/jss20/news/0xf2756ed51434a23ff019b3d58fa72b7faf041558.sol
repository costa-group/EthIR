// File: contracts/sol6/IERC20.sol



pragma solidity ^0.6.6;




interface IERC20 {

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    function approve(address _spender, uint256 _value) external returns (bool success);



    function transfer(address _to, uint256 _value) external returns (bool success);



    function transferFrom(

        address _from,

        address _to,

        uint256 _value

    ) external returns (bool success);



    function allowance(address _owner, address _spender) external view returns (uint256 remaining);



    function balanceOf(address _owner) external view returns (uint256 balance);



    function decimals() external view returns (uint8 digits);



    function totalSupply() external view returns (uint256 supply);

}





// to support backward compatible contract name -- so function signature remains same

abstract contract ERC20 is IERC20 {



}



// File: contracts/sol6/IKyberReserve.sol



pragma solidity ^0.6.6;






interface IKyberReserve {

    function trade(

        IERC20 srcToken,

        uint256 srcAmount,

        IERC20 destToken,

        address payable destAddress,

        uint256 conversionRate,

        bool validate

    ) external payable returns (bool);



    function getConversionRate(

        IERC20 src,

        IERC20 dest,

        uint256 srcQty,

        uint256 blockNumber

    ) external view returns (uint256);

}



// File: contracts/sol6/IKyberNetwork.sol



pragma solidity ^0.6.6;






interface IKyberNetwork {

    event KyberTrade(

        IERC20 indexed src,

        IERC20 indexed dest,

        uint256 ethWeiValue,

        uint256 networkFeeWei,

        uint256 customPlatformFeeWei,

        bytes32[] t2eIds,

        bytes32[] e2tIds,

        uint256[] t2eSrcAmounts,

        uint256[] e2tSrcAmounts,

        uint256[] t2eRates,

        uint256[] e2tRates

    );



    function tradeWithHintAndFee(

        address payable trader,

        IERC20 src,

        uint256 srcAmount,

        IERC20 dest,

        address payable destAddress,

        uint256 maxDestAmount,

        uint256 minConversionRate,

        address payable platformWallet,

        uint256 platformFeeBps,

        bytes calldata hint

    ) external payable returns (uint256 destAmount);



    function listTokenForReserve(

        address reserve,

        IERC20 token,

        bool add

    ) external;



    function enabled() external view returns (bool);



    function getExpectedRateWithHintAndFee(

        IERC20 src,

        IERC20 dest,

        uint256 srcQty,

        uint256 platformFeeBps,

        bytes calldata hint

    )

        external

        view

        returns (

            uint256 expectedRateAfterNetworkFee,

            uint256 expectedRateAfterAllFees

        );



    function getNetworkData()

        external

        view

        returns (

            uint256 negligibleDiffBps,

            uint256 networkFeeBps,

            uint256 expiryTimestamp

        );



    function maxGasPrice() external view returns (uint256);

}



// File: contracts/sol6/IKyberNetworkProxy.sol



pragma solidity ^0.6.6;






interface IKyberNetworkProxy {



    event ExecuteTrade(

        address indexed trader,

        IERC20 src,

        IERC20 dest,

        address destAddress,

        uint256 actualSrcAmount,

        uint256 actualDestAmount,

        address platformWallet,

        uint256 platformFeeBps

    );



    /// @notice backward compatible

    function tradeWithHint(

        ERC20 src,

        uint256 srcAmount,

        ERC20 dest,

        address payable destAddress,

        uint256 maxDestAmount,

        uint256 minConversionRate,

        address payable walletId,

        bytes calldata hint

    ) external payable returns (uint256);



    function tradeWithHintAndFee(

        IERC20 src,

        uint256 srcAmount,

        IERC20 dest,

        address payable destAddress,

        uint256 maxDestAmount,

        uint256 minConversionRate,

        address payable platformWallet,

        uint256 platformFeeBps,

        bytes calldata hint

    ) external payable returns (uint256 destAmount);



    function trade(

        IERC20 src,

        uint256 srcAmount,

        IERC20 dest,

        address payable destAddress,

        uint256 maxDestAmount,

        uint256 minConversionRate,

        address payable platformWallet

    ) external payable returns (uint256);



    /// @notice backward compatible

    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18

    function getExpectedRate(

        ERC20 src,

        ERC20 dest,

        uint256 srcQty

    ) external view returns (uint256 expectedRate, uint256 worstRate);



    function getExpectedRateAfterFee(

        IERC20 src,

        IERC20 dest,

        uint256 srcQty,

        uint256 platformFeeBps,

        bytes calldata hint

    ) external view returns (uint256 expectedRate);

}



// File: contracts/sol6/IKyberStorage.sol



pragma solidity ^0.6.6;








interface IKyberStorage {

    enum ReserveType {NONE, FPR, APR, BRIDGE, UTILITY, CUSTOM, ORDERBOOK, LAST}



    function addKyberProxy(address kyberProxy, uint256 maxApprovedProxies)

        external;



    function removeKyberProxy(address kyberProxy) external;



    function setContracts(address _kyberFeeHandler, address _kyberMatchingEngine) external;



    function setKyberDaoContract(address _kyberDao) external;



    function getReserveId(address reserve) external view returns (bytes32 reserveId);



    function getReserveIdsFromAddresses(address[] calldata reserveAddresses)

        external

        view

        returns (bytes32[] memory reserveIds);



    function getReserveAddressesFromIds(bytes32[] calldata reserveIds)

        external

        view

        returns (address[] memory reserveAddresses);



    function getReserveIdsPerTokenSrc(IERC20 token)

        external

        view

        returns (bytes32[] memory reserveIds);



    function getReserveAddressesPerTokenSrc(IERC20 token, uint256 startIndex, uint256 endIndex)

        external

        view

        returns (address[] memory reserveAddresses);



    function getReserveIdsPerTokenDest(IERC20 token)

        external

        view

        returns (bytes32[] memory reserveIds);



    function getReserveAddressesByReserveId(bytes32 reserveId)

        external

        view

        returns (address[] memory reserveAddresses);



    function getRebateWalletsFromIds(bytes32[] calldata reserveIds)

        external

        view

        returns (address[] memory rebateWallets);



    function getKyberProxies() external view returns (IKyberNetworkProxy[] memory);



    function getReserveDetailsByAddress(address reserve)

        external

        view

        returns (

            bytes32 reserveId,

            address rebateWallet,

            ReserveType resType,

            bool isFeeAccountedFlag,

            bool isEntitledRebateFlag

        );



    function getReserveDetailsById(bytes32 reserveId)

        external

        view

        returns (

            address reserveAddress,

            address rebateWallet,

            ReserveType resType,

            bool isFeeAccountedFlag,

            bool isEntitledRebateFlag

        );



    function getFeeAccountedData(bytes32[] calldata reserveIds)

        external

        view

        returns (bool[] memory feeAccountedArr);



    function getEntitledRebateData(bytes32[] calldata reserveIds)

        external

        view

        returns (bool[] memory entitledRebateArr);



    function getReservesData(bytes32[] calldata reserveIds, IERC20 src, IERC20 dest)

        external

        view

        returns (

            bool areAllReservesListed,

            bool[] memory feeAccountedArr,

            bool[] memory entitledRebateArr,

            IKyberReserve[] memory reserveAddresses);



    function isKyberProxyAdded() external view returns (bool);

}



// File: contracts/sol6/IKyberMatchingEngine.sol



pragma solidity ^0.6.6;










interface IKyberMatchingEngine {

    enum ProcessWithRate {NotRequired, Required}



    function setNegligibleRateDiffBps(uint256 _negligibleRateDiffBps) external;



    function setKyberStorage(IKyberStorage _kyberStorage) external;



    function getNegligibleRateDiffBps() external view returns (uint256);



    function getTradingReserves(

        IERC20 src,

        IERC20 dest,

        bool isTokenToToken,

        bytes calldata hint

    )

        external

        view

        returns (

            bytes32[] memory reserveIds,

            uint256[] memory splitValuesBps,

            ProcessWithRate processWithRate

        );



    function doMatch(

        IERC20 src,

        IERC20 dest,

        uint256[] calldata srcAmounts,

        uint256[] calldata feesAccountedDestBps,

        uint256[] calldata rates

    ) external view returns (uint256[] memory reserveIndexes);

}



// File: contracts/sol6/wrappers/IKyberRateHelper.sol



pragma solidity ^0.6.6;






interface IKyberRateHelper {

    function getRatesForToken(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount

    )

        external

        view

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        );



    function getPricesForToken(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount

    )

        external

        view

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        );



    function getRatesForTokenWithCustomFee(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount,

        uint256 networkFeeBps

    )

        external

        view

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        );



    function getReservesRates(IERC20 token, uint256 optionalAmountWei)

        external

        view

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        );

}



// File: contracts/sol6/Dao/IEpochUtils.sol



pragma solidity ^0.6.6;


interface IEpochUtils {

    function epochPeriodInSeconds() external view returns (uint256);



    function firstEpochStartTimestamp() external view returns (uint256);



    function getCurrentEpochNumber() external view returns (uint256);



    function getEpochNumber(uint256 timestamp) external view returns (uint256);

}



// File: contracts/sol6/IKyberDao.sol



pragma solidity ^0.6.6;






interface IKyberDao is IEpochUtils {

    event Voted(address indexed staker, uint indexed epoch, uint indexed campaignID, uint option);



    function getLatestNetworkFeeDataWithCache()

        external

        returns (uint256 feeInBps, uint256 expiryTimestamp);



    function getLatestBRRDataWithCache()

        external

        returns (

            uint256 burnInBps,

            uint256 rewardInBps,

            uint256 rebateInBps,

            uint256 epoch,

            uint256 expiryTimestamp

        );



    function handleWithdrawal(address staker, uint256 penaltyAmount) external;



    function vote(uint256 campaignID, uint256 option) external;



    function getLatestNetworkFeeData()

        external

        view

        returns (uint256 feeInBps, uint256 expiryTimestamp);



    function shouldBurnRewardForEpoch(uint256 epoch) external view returns (bool);



    /**

     * @dev  return staker's reward percentage in precision for a past epoch only

     *       fee handler should call this function when a staker wants to claim reward

     *       return 0 if staker has no votes or stakes

     */

    function getPastEpochRewardPercentageInPrecision(address staker, uint256 epoch)

        external

        view

        returns (uint256);



    /**

     * @dev  return staker's reward percentage in precision for the current epoch

     *       reward percentage is not finalized until the current epoch is ended

     */

    function getCurrentEpochRewardPercentageInPrecision(address staker)

        external

        view

        returns (uint256);

}



// File: contracts/sol6/utils/Utils5.sol



pragma solidity ^0.6.6;






/**

 * @title Kyber utility file

 * mostly shared constants and rate calculation helpers

 * inherited by most of kyber contracts.

 * previous utils implementations are for previous solidity versions.

 */

contract Utils5 {

    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(

        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

    );

    uint256 internal constant PRECISION = (10**18);

    uint256 internal constant MAX_QTY = (10**28); // 10B tokens

    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth

    uint256 internal constant MAX_DECIMALS = 18;

    uint256 internal constant ETH_DECIMALS = 18;

    uint256 constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%

    uint256 internal constant MAX_ALLOWANCE = uint256(-1); // token.approve inifinite



    mapping(IERC20 => uint256) internal decimals;



    function getUpdateDecimals(IERC20 token) internal returns (uint256) {

        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access

        uint256 tokenDecimals = decimals[token];

        // moreover, very possible that old tokens have decimals 0

        // these tokens will just have higher gas fees.

        if (tokenDecimals == 0) {

            tokenDecimals = token.decimals();

            decimals[token] = tokenDecimals;

        }



        return tokenDecimals;

    }



    function setDecimals(IERC20 token) internal {

        if (decimals[token] != 0) return; //already set



        if (token == ETH_TOKEN_ADDRESS) {

            decimals[token] = ETH_DECIMALS;

        } else {

            decimals[token] = token.decimals();

        }

    }



    /// @dev get the balance of a user.

    /// @param token The token type

    /// @return The balance

    function getBalance(IERC20 token, address user) internal view returns (uint256) {

        if (token == ETH_TOKEN_ADDRESS) {

            return user.balance;

        } else {

            return token.balanceOf(user);

        }

    }



    function getDecimals(IERC20 token) internal view returns (uint256) {

        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access

        uint256 tokenDecimals = decimals[token];

        // moreover, very possible that old tokens have decimals 0

        // these tokens will just have higher gas fees.

        if (tokenDecimals == 0) return token.decimals();



        return tokenDecimals;

    }



    function calcDestAmount(

        IERC20 src,

        IERC20 dest,

        uint256 srcAmount,

        uint256 rate

    ) internal view returns (uint256) {

        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);

    }



    function calcSrcAmount(

        IERC20 src,

        IERC20 dest,

        uint256 destAmount,

        uint256 rate

    ) internal view returns (uint256) {

        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);

    }



    function calcDstQty(

        uint256 srcQty,

        uint256 srcDecimals,

        uint256 dstDecimals,

        uint256 rate

    ) internal pure returns (uint256) {

        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");

        require(rate <= MAX_RATE, "rate > MAX_RATE");



        if (dstDecimals >= srcDecimals) {

            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");

            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;

        } else {

            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");

            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));

        }

    }



    function calcSrcQty(

        uint256 dstQty,

        uint256 srcDecimals,

        uint256 dstDecimals,

        uint256 rate

    ) internal pure returns (uint256) {

        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");

        require(rate <= MAX_RATE, "rate > MAX_RATE");



        //source quantity is rounded up. to avoid dest quantity being too low.

        uint256 numerator;

        uint256 denominator;

        if (srcDecimals >= dstDecimals) {

            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");

            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));

            denominator = rate;

        } else {

            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");

            numerator = (PRECISION * dstQty);

            denominator = (rate * (10**(dstDecimals - srcDecimals)));

        }

        return (numerator + denominator - 1) / denominator; //avoid rounding down errors

    }



    function calcRateFromQty(

        uint256 srcAmount,

        uint256 destAmount,

        uint256 srcDecimals,

        uint256 dstDecimals

    ) internal pure returns (uint256) {

        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");

        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");



        if (dstDecimals >= srcDecimals) {

            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");

            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));

        } else {

            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");

            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);

        }

    }



    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {

        return x > y ? y : x;

    }

}



// File: contracts/sol6/utils/PermissionGroupsNoModifiers.sol



pragma solidity ^0.6.6;




contract PermissionGroupsNoModifiers {

    address public admin;

    address public pendingAdmin;

    mapping(address => bool) internal operators;

    mapping(address => bool) internal alerters;

    address[] internal operatorsGroup;

    address[] internal alertersGroup;

    uint256 internal constant MAX_GROUP_SIZE = 50;



    event AdminClaimed(address newAdmin, address previousAdmin);

    event AlerterAdded(address newAlerter, bool isAdd);

    event OperatorAdded(address newOperator, bool isAdd);

    event TransferAdminPending(address pendingAdmin);



    constructor(address _admin) public {

        require(_admin != address(0), "admin 0");

        admin = _admin;

    }



    function getOperators() external view returns (address[] memory) {

        return operatorsGroup;

    }



    function getAlerters() external view returns (address[] memory) {

        return alertersGroup;

    }



    function addAlerter(address newAlerter) public {

        onlyAdmin();

        require(!alerters[newAlerter], "alerter exists"); // prevent duplicates.

        require(alertersGroup.length < MAX_GROUP_SIZE, "max alerters");



        emit AlerterAdded(newAlerter, true);

        alerters[newAlerter] = true;

        alertersGroup.push(newAlerter);

    }



    function addOperator(address newOperator) public {

        onlyAdmin();

        require(!operators[newOperator], "operator exists"); // prevent duplicates.

        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");



        emit OperatorAdded(newOperator, true);

        operators[newOperator] = true;

        operatorsGroup.push(newOperator);

    }



    /// @dev Allows the pendingAdmin address to finalize the change admin process.

    function claimAdmin() public {

        require(pendingAdmin == msg.sender, "not pending");

        emit AdminClaimed(pendingAdmin, admin);

        admin = pendingAdmin;

        pendingAdmin = address(0);

    }



    function removeAlerter(address alerter) public {

        onlyAdmin();

        require(alerters[alerter], "not alerter");

        delete alerters[alerter];



        for (uint256 i = 0; i < alertersGroup.length; ++i) {

            if (alertersGroup[i] == alerter) {

                alertersGroup[i] = alertersGroup[alertersGroup.length - 1];

                alertersGroup.pop();

                emit AlerterAdded(alerter, false);

                break;

            }

        }

    }



    function removeOperator(address operator) public {

        onlyAdmin();

        require(operators[operator], "not operator");

        delete operators[operator];



        for (uint256 i = 0; i < operatorsGroup.length; ++i) {

            if (operatorsGroup[i] == operator) {

                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];

                operatorsGroup.pop();

                emit OperatorAdded(operator, false);

                break;

            }

        }

    }



    /// @dev Allows the current admin to set the pendingAdmin address

    /// @param newAdmin The address to transfer ownership to

    function transferAdmin(address newAdmin) public {

        onlyAdmin();

        require(newAdmin != address(0), "new admin 0");

        emit TransferAdminPending(newAdmin);

        pendingAdmin = newAdmin;

    }



    /// @dev Allows the current admin to set the admin in one tx. Useful initial deployment.

    /// @param newAdmin The address to transfer ownership to.

    function transferAdminQuickly(address newAdmin) public {

        onlyAdmin();

        require(newAdmin != address(0), "admin 0");

        emit TransferAdminPending(newAdmin);

        emit AdminClaimed(newAdmin, admin);

        admin = newAdmin;

    }



    function onlyAdmin() internal view {

        require(msg.sender == admin, "only admin");

    }



    function onlyAlerter() internal view {

        require(alerters[msg.sender], "only alerter");

    }



    function onlyOperator() internal view {

        require(operators[msg.sender], "only operator");

    }

}



// File: contracts/sol6/utils/WithdrawableNoModifiers.sol



pragma solidity ^0.6.6;








contract WithdrawableNoModifiers is PermissionGroupsNoModifiers {

    constructor(address _admin) public PermissionGroupsNoModifiers(_admin) {}



    event EtherWithdraw(uint256 amount, address sendTo);

    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);



    /// @dev Withdraw Ethers

    function withdrawEther(uint256 amount, address payable sendTo) external {

        onlyAdmin();

        (bool success, ) = sendTo.call{value: amount}("");

        require(success);

        emit EtherWithdraw(amount, sendTo);

    }



    /// @dev Withdraw all IERC20 compatible tokens

    /// @param token IERC20 The address of the token contract

    function withdrawToken(

        IERC20 token,

        uint256 amount,

        address sendTo

    ) external {

        onlyAdmin();

        token.transfer(sendTo, amount);

        emit TokenWithdraw(token, amount, sendTo);

    }

}



// File: contracts/sol6/wrappers/KyberRateHelper.sol



pragma solidity ^0.6.6;














contract KyberRateHelper is IKyberRateHelper, WithdrawableNoModifiers, Utils5 {

    struct Amounts {

        uint256 srcAmount;

        uint256 ethSrcAmount;

        uint256 destAmount;

    }



    IKyberMatchingEngine public matchingEngine;

    IKyberDao public kyberDao;

    IKyberStorage public kyberStorage;



    constructor(address _admin) public WithdrawableNoModifiers(_admin) {

        /* empty body */

    }



    event KyberDaoContractSet(IKyberDao kyberDao);

    event KyberStorageSet(IKyberStorage kyberStorage);

    event MatchingEngineContractSet(IKyberMatchingEngine matchingEngine);



    function setContracts(

        IKyberMatchingEngine _matchingEngine,

        IKyberDao _kyberDao,

        IKyberStorage _kyberStorage

    ) public {

        onlyAdmin();

        require(_matchingEngine != IKyberMatchingEngine(0), "matching engine 0");

        require(_kyberDao != IKyberDao(0), "kyberDao 0");

        require(_kyberStorage != IKyberStorage(0), "kyberStorage 0");



        if (matchingEngine != _matchingEngine) {

            matchingEngine = _matchingEngine;

            emit MatchingEngineContractSet(_matchingEngine);

        }



        if (kyberDao != _kyberDao) {

            kyberDao = _kyberDao;

            emit KyberDaoContractSet(_kyberDao);

        }



        if (kyberStorage != _kyberStorage) {

            kyberStorage = _kyberStorage;

            emit KyberStorageSet(_kyberStorage);

        }

    }



    function getPricesForToken(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount

    )

        public

        view

        override

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        )

    {

        return getRatesForTokenWithCustomFee(token, optionalBuyAmount, optionalSellAmount, 0);

    }



    /// @dev function to cover backward compatible with old network interface

    /// @dev get rate from token to eth, use the best eth amount to get rate from eth to token

    /// @param token Token to get rate

    /// @param optionalAmountWei Amount to get rate (default: 0)

    function getReservesRates(IERC20 token, uint256 optionalAmountWei)

        public

        override

        view

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        )

    {

        (uint256 networkFeeBps, ) = kyberDao.getLatestNetworkFeeData();

        uint256 buyAmount = optionalAmountWei > 0 ? optionalAmountWei : 1 ether;



        (buyReserves, buyRates) = getBuyInfo(token, buyAmount, networkFeeBps);



        uint256 bestRate = 0;

        for (uint256 i = 0; i < buyRates.length; i++) {

            if (buyRates[i] > bestRate) {

                bestRate = buyRates[i];

            }

        }



        if (bestRate == 0) {

            return (buyReserves, buyRates, sellReserves, sellRates);

        }

        uint256 sellAmount = calcDstQty(

            buyAmount,

            ETH_DECIMALS,

            getDecimals(token),

            bestRate

        );

        (sellReserves, sellRates) = getSellInfo(token, sellAmount, networkFeeBps);

    }



    function getRatesForToken(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount

    )

        public

        view

        override

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        )

    {

        (uint256 feeBps, ) = kyberDao.getLatestNetworkFeeData();

        return getRatesForTokenWithCustomFee(token, optionalBuyAmount, optionalSellAmount, feeBps);

    }



    function getRatesForTokenWithCustomFee(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 optionalSellAmount,

        uint256 networkFeeBps

    )

        public

        view

        override

        returns (

            bytes32[] memory buyReserves,

            uint256[] memory buyRates,

            bytes32[] memory sellReserves,

            uint256[] memory sellRates

        )

    {

        (buyReserves, buyRates) = getBuyInfo(

            token,

            optionalBuyAmount,

            networkFeeBps

        );

        (sellReserves, sellRates) = getSellInfo(

            token,

            optionalSellAmount,

            networkFeeBps

        );

    }



    function getBuyInfo(

        IERC20 token,

        uint256 optionalBuyAmount,

        uint256 networkFeeBps

    ) internal view returns (bytes32[] memory buyReserves, uint256[] memory buyRates) {

        Amounts memory A;

        bool[] memory isFeeAccountedFlags;

        address reserve;



        A.srcAmount = optionalBuyAmount > 0 ? optionalBuyAmount : 1000;

        (buyReserves, , ) = matchingEngine.getTradingReserves(ETH_TOKEN_ADDRESS, token, false, "");

        isFeeAccountedFlags = kyberStorage.getFeeAccountedData(buyReserves);

        buyRates = new uint256[](buyReserves.length);



        for (uint256 i = 0; i < buyReserves.length; i++) {

            (reserve, , , ,) = kyberStorage.getReserveDetailsById(buyReserves[i]);

            if (networkFeeBps == 0 || !isFeeAccountedFlags[i]) {

                buyRates[i] = IKyberReserve(reserve).getConversionRate(

                    ETH_TOKEN_ADDRESS,

                    token,

                    A.srcAmount,

                    block.number

                );

                continue;

            }



            A.ethSrcAmount = A.srcAmount - ((A.srcAmount * networkFeeBps) / BPS);

            buyRates[i] = IKyberReserve(reserve).getConversionRate(

                ETH_TOKEN_ADDRESS,

                token,

                A.ethSrcAmount,

                block.number

            );

            A.destAmount = calcDstQty(

                A.ethSrcAmount,

                ETH_DECIMALS,

                getDecimals(token),

                buyRates[i]

            );

            //use amount instead of ethSrcAmount to account for network fee

            buyRates[i] = calcRateFromQty(

                A.srcAmount,

                A.destAmount,

                ETH_DECIMALS,

                getDecimals(token)

            );

        }

    }



    function getSellInfo(

        IERC20 token,

        uint256 optionalSellAmount,

        uint256 networkFeeBps

    ) internal view returns (bytes32[] memory sellReserves, uint256[] memory sellRates) {

        Amounts memory A;

        bool[] memory isFeeAccountedFlags;

        address reserve;



        A.srcAmount = optionalSellAmount > 0 ? optionalSellAmount : 1000;

        (sellReserves, , ) = matchingEngine.getTradingReserves(

            token,

            ETH_TOKEN_ADDRESS,

            false,

            ""

        );

        isFeeAccountedFlags = kyberStorage.getFeeAccountedData(sellReserves);

        sellRates = new uint256[](sellReserves.length);



        for (uint256 i = 0; i < sellReserves.length; i++) {

            (reserve, , , ,) = kyberStorage.getReserveDetailsById(sellReserves[i]);

            sellRates[i] = IKyberReserve(reserve).getConversionRate(

                token,

                ETH_TOKEN_ADDRESS,

                A.srcAmount,

                block.number

            );

            if (networkFeeBps == 0 || !isFeeAccountedFlags[i]) {

                continue;

            }

            A.destAmount = calcDstQty(A.srcAmount, getDecimals(token), ETH_DECIMALS, sellRates[i]);

            A.destAmount -= (networkFeeBps * A.destAmount) / BPS;

            sellRates[i] = calcRateFromQty(

                A.srcAmount,

                A.destAmount,

                getDecimals(token),

                ETH_DECIMALS

            );

        }

    }

}