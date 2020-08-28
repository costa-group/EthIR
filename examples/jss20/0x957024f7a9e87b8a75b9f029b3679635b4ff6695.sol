pragma solidity 0.4.25;

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

// File: contracts/saga/PriceBandCalculator.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Price Band Calculator.
 */
contract PriceBandCalculator is IPriceBandCalculator {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    // Auto-generated via 'AutoGenerate/PriceBandCalculator/PrintConstants.py'
    uint256 public constant ONE     = 1000000000;
    uint256 public constant MIN_RR  = 1000000000000000000000000000000000;
    uint256 public constant MAX_RR  = 10000000000000000000000000000000000;
    uint256 public constant GAMMA   = 179437500000000000000000000000000000000000;
    uint256 public constant DELTA   = 29437500;
    uint256 public constant BUY_N   = 2000;
    uint256 public constant BUY_D   = 2003;
    uint256 public constant SELL_N  = 1997;
    uint256 public constant SELL_D  = 2000;
    uint256 public constant MAX_SDR = 500786938745138896681892746900;

    /**
     * Denote r = sdrAmount
     * Denote n = sgaTotal
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Denote c = GAMMA / ONE / A_B_SCALE
     * Denote d = DELTA / ONE
     * Denote w = c / (a - b * n) - d
     * Return r / (1 + w)
     */
    function buy(uint256 _sdrAmount, uint256 _sgaTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        assert(_sdrAmount <= MAX_SDR);
        uint256 reserveRatio = _alpha.sub(_beta.mul(_sgaTotal));
        assert(MIN_RR <= reserveRatio && reserveRatio <= MAX_RR);
        uint256 variableFix = _sdrAmount * (reserveRatio * ONE) / (reserveRatio * (ONE - DELTA) + GAMMA);
        uint256 constantFix = _sdrAmount * BUY_N / BUY_D;
        return constantFix <= variableFix ? constantFix : variableFix;
    }

    /**
     * Denote r = sdrAmount
     * Denote n = sgaTotal
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Denote c = GAMMA / ONE / A_B_SCALE
     * Denote d = DELTA / ONE
     * Denote w = c / (a - b * n) - d
     * Return r * (1 - w)
     */
    function sell(uint256 _sdrAmount, uint256 _sgaTotal, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        assert(_sdrAmount <= MAX_SDR);
        uint256 reserveRatio = _alpha.sub(_beta.mul(_sgaTotal));
        assert(MIN_RR <= reserveRatio && reserveRatio <= MAX_RR);
        uint256 variableFix = _sdrAmount * (reserveRatio * (ONE + DELTA) - GAMMA) / (reserveRatio * ONE);
        uint256 constantFix = _sdrAmount * SELL_N / SELL_D;
        return constantFix <= variableFix ? constantFix : variableFix;
    }
}
