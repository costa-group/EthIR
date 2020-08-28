pragma solidity 0.5.16;

interface IPriceOracle {
    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound
    ) external view returns(
        uint256 returnAmount,
        uint[4] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
    );
}



interface ISoftETHToken {
    function burn(uint256 _amount) external;
    function mint(address _account, uint256 _amount) external returns(bool);
    function totalSupply() external view returns(uint256);
}



interface IExitToken {
    function mint(address _account, uint256 _amount) external returns(bool);
    function totalSupply() external view returns(uint256);
}







/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




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



contract Reward is Initializable {
    using SafeMath for uint256;

    // =============================================== Storage ========================================================

    // WARNING: since this contract is upgradeable, do not remove
    // existing storage variables and do not change their types!

    /// @dev The serial number of the latest finished staking epoch.
    uint256 public lastStakingEpochFinished;

    /// @dev The address of staker. Used by `finishStakingEpoch` function
    /// to emulate staking. EXIT tokens are minted to this address.
    address public staker;

    /// @dev The address that has the rights to change STAKE/USD rate.
    address public currencyRateChanger;

    /// @dev The address of EXIT token contract.
    IExitToken public exitToken;

    /// @dev The address of softETH token contract.
    ISoftETHToken public softETHToken;

    /// @dev The latest known ETH/USD rate (in USD cents) set by `rebalance` function.
    /// Has 2 decimals (e.g., 160.35 USD presented as 16035).
    uint256 public ethUsd;

    /// @dev The STAKE/USD rate (in USD cents) set by `setSTAKEUSD` function.
    /// Has 2 decimals (e.g., 20.45 USD presented as 2045).
    uint256 public stakeUsd;

    // ============================================== Constants =======================================================

    /// @dev How many EXIT tokens must be minted in relation to
    /// the USD worth of STAKE tokens staked into all pools.
    uint256 public constant EXIT_MINT_RATE = 10; // percents

    /// @dev How many times the USD worth of softETH tokens must
    /// exceed the total supply of EXIT tokens.
    uint256 public constant COLLATERAL_MULTIPLIER = 2;

    // ================================================ Events ========================================================

    /// @dev Emitted by the `rebalance` function.
    /// @param newTotalSupply The new `totalSupply` of softETH tokens.
    /// @param caller The address called the function.
    event Rebalanced(uint256 newTotalSupply, address indexed caller);

    /// @dev Emitted by the `finishStakingEpoch` function.
    /// @param stakingEpoch The number of finished staking epoch.
    /// @param totalStakeAmount The total amount of STAKE tokens staked before the epoch finished.
    /// @param exitMintAmount How many EXIT tokens were minted.
    /// @param caller The address called the function.
    event StakingEpochFinished(
        uint256 indexed stakingEpoch,
        uint256 totalStakeAmount,
        uint256 exitMintAmount,
        address indexed caller
    );

    // ============================================== Modifiers =======================================================

    /// @dev Modifier to check whether the `msg.sender` is the `currencyRateChanger`.
    modifier ifCurrencyRateChanger() {
        require(msg.sender == currencyRateChanger);
        _;
    }

    // =============================================== Setters ========================================================

    /// @dev Emulates finishing of staking epoch, mints EXIT tokens for the `staker` address.
    /// Can by called by anyone. The amount of EXIT tokens to be minted is calculated
    /// based on the `_totalStakeAmount` parameter, EXIT_MINT_RATE, and the current
    /// STAKE/USD rate defined in `stakeUsd`.
    /// @param _totalStakeAmount The total amount of STAKE tokens staked at the moment of
    /// the end of staking epoch. The amount must have 18 decimals.
    function finishStakingEpoch(uint256 _totalStakeAmount) public {
        require(exitToken != IExitToken(0));
        require(staker != address(0));
        require(stakeUsd != 0);

        uint256 usdAmount = _totalStakeAmount.mul(stakeUsd).div(100);
        uint256 mintAmount = usdAmount.mul(EXIT_MINT_RATE).div(100);
        exitToken.mint(staker, mintAmount);
        rebalance();

        lastStakingEpochFinished++;

        emit StakingEpochFinished(lastStakingEpochFinished, _totalStakeAmount, mintAmount, msg.sender);
    }

    /// @dev Initializes the contract. Used instead of constructor since this contract is upgradeable.
    /// @param _staker The address of staker. EXIT tokens will be minted to this address.
    /// @param _currencyRateChanger The address that has the rights to change STAKE/USD rate.
    /// @param _exitToken The address of EXIT token contract.
    /// @param _softETHToken The address of softETH token contract.
    function initialize(
        address _staker,
        address _currencyRateChanger,
        IExitToken _exitToken,
        ISoftETHToken _softETHToken
    ) public initializer {
        require(_admin() != address(0)); // make sure it is called by the proxy contract with `delegatecall`
        require(_staker != address(0));
        require(_currencyRateChanger != address(0));
        require(_exitToken != IExitToken(0));
        require(_softETHToken != ISoftETHToken(0));
        staker = _staker;
        currencyRateChanger = _currencyRateChanger;
        exitToken = _exitToken;
        softETHToken = _softETHToken;
    }

    /// @dev Rebalances the totalSupply of softETH so that it would exceed
    /// EXIT token supply COLLATERAL_MULTIPLIER times in USD worth.
    /// Can be called by anyone.
    function rebalance() public {
        require(exitToken != IExitToken(0));
        require(softETHToken != ISoftETHToken(0));

        uint256 ethInUSD = usdEthCurrent(); // how many ETHs in 1 USD at the moment
        require(ethInUSD != 0);
        
        // Calculate the current and new softETH amounts
        uint256 currentSupply = softETHCurrentSupply();
        uint256 expectedSupply = _softETHExpectedSupply(ethInUSD);

        if (expectedSupply > currentSupply) {
            // We need to have more softETH tokens, so mint the lack tokens
            softETHToken.mint(address(this), expectedSupply - currentSupply);
        } else if (expectedSupply < currentSupply) {
            // We need to have less softETH tokens, so burn the excess tokens
            softETHToken.burn(currentSupply - expectedSupply);
        }

        ethUsd = 100 ether / ethInUSD;

        emit Rebalanced(expectedSupply, msg.sender);
    }

    /// @dev Sets the current STAKE/USD rate in USD cents.
    /// Can only be called by the `currencyRateChanger`.
    /// @param _cents The rate in USD cents. Must have 2 decimals,
    /// e.g., 20.45 USD presented as 2045.
    function setSTAKEUSD(uint256 _cents) public ifCurrencyRateChanger {
        require(_cents != 0);
        stakeUsd = _cents;
    }

    // =============================================== Getters ========================================================

    /// @dev Returns the current amount of USDTs in 1 ETH, i.e. ETH/USDT rate (in USD cents).
    /// The returned amount has 2 decimals (e.g., 160.35 USD presented as 16035).
    function ethUsdCurrent() public view returns(uint256) {
        uint256 ethers = usdEthCurrent();
        if (ethers == 0) return 0;
        return 100 ether / ethers;
    }

    /// @dev Returns the current total supply of EXIT tokens.
    function exitCurrentSupply() public view returns(uint256) {
        return exitToken.totalSupply();
    }

    /// @dev Returns the current amount of ETHs in 1 USDT, i.e. USDT/ETH rate.
    /// The returned amount has 18 decimals.
    function usdEthCurrent() public view returns(uint256) {
        (uint256 returnAmount,) = IPriceOracle(PRICE_ORACLE).getExpectedReturn(
            0xdAC17F958D2ee523a2206206994597C13D831ec7, // fromToken (USDT)
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // toToken (ETH)
            1000000, // amount (1.00 USDT)
            1, // parts
            0  // disableFlags
        );
        return returnAmount;
    }

    /// @dev Returns the current total supply of softETH tokens.
    function softETHCurrentSupply() public view returns(uint256) {
        return softETHToken.totalSupply();
    }

    /// @dev Returns the current expected supply of softETH tokens
    /// based on the supply of EXIT tokens, COLLATERAL_MULTIPLIER,
    /// and the current USD/ETH rate.
    function softETHExpectedSupply() public view returns(uint256) {
        return _softETHExpectedSupply(usdEthCurrent());
    }

    /// @dev Returns the general data in a single request.
    function getCurrentDataBatch() public view returns(
        uint256 _ethUsd,
        uint256 _ethUsdCurrent,
        uint256 _exitCurrentSupply,
        uint256 _lastStakingEpochFinished,
        uint256 _softETHCurrentSupply,
        uint256 _softETHExpectedSupply,
        uint256 _stakeUsd
    ) {
        _ethUsd = ethUsd;
        _ethUsdCurrent = ethUsdCurrent();
        _exitCurrentSupply = exitCurrentSupply();
        _lastStakingEpochFinished = lastStakingEpochFinished;
        _softETHCurrentSupply = softETHCurrentSupply();
        _softETHExpectedSupply = softETHExpectedSupply();
        _stakeUsd = stakeUsd;
    }

    // ============================================== Internal ========================================================

    /// @dev The address of the contract in Ethereum Mainnet which provides the current USD/ETH rate.
    address internal constant PRICE_ORACLE = 0xAd13fE330B0aE312bC51d2E5B9Ca2ae3973957C7;

    /// @dev Returns the admin slot.
    function _admin() internal view returns(address adm) {
        /// Storage slot with the admin of the contract.
        /// This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        assembly {
            adm := sload(slot)
        }
    }

    /// @dev Returns the current expected supply of softETH tokens
    /// based on the supply of EXIT tokens, COLLATERAL_MULTIPLIER,
    /// and the passed USD/ETH rate.
    /// @param _ethInUSD The current USD/ETH rate (must have 18 decimals).
    function _softETHExpectedSupply(uint256 _ethInUSD) internal view returns(uint256) {
        return exitToken.totalSupply().mul(COLLATERAL_MULTIPLIER).mul(_ethInUSD).div(1 ether);
    }

}