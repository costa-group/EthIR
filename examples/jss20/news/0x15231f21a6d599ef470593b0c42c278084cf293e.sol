pragma solidity 0.4.25;

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

// File: contracts/saga/ModelCalculator.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Model Calculator.
 */
contract ModelCalculator is IModelCalculator {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    // Auto-generated via 'AutoGenerate/ModelCalculator/PrintConstants.py'
    uint256 public constant FIXED_ONE = 0x20000000000000000000000000000000;
    uint256 public constant A_B_SCALE = 10000000000000000000000000000000000;

    /**
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Return true if and only if a = 1 and b = 0
     */
    function isTrivialInterval(uint256 _alpha, uint256 _beta) external pure returns (bool) {
        return _alpha == A_B_SCALE && _beta == 0;
    }

    /**
     * Denote x = valR
     * Denote y = maxN
     * Denote z = maxR
     * Return x * y / z
     */
    function getValN(uint256 _valR, uint256 _maxN, uint256 _maxR) external pure returns (uint256) {
        return _valR.mul(_maxN) / _maxR;
    }

    /**
     * Denote x = valN
     * Denote y = maxR
     * Denote z = maxN
     * Return x * y / z
     */
    function getValR(uint256 _valN, uint256 _maxR, uint256 _maxN) external pure returns (uint256) {
        return _valN.mul(_maxR) / _maxN;
    }

    /**
     * Denote x = newR
     * Denote y = minR
     * Denote z = minN
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Return a * (x / y) ^ a / (a / z + b * ((x / y) ^ a - 1))
     */
    function getNewN(uint256 _newR, uint256 _minR, uint256 _minN, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        uint256 temp = pow(_newR.mul(FIXED_ONE), _minR, _alpha, A_B_SCALE);
        return _alpha.mul(temp) / (_alpha.mul(FIXED_ONE) / _minN).add(_beta.mul(temp.sub(FIXED_ONE)));
    }

    /**
     * Denote x = newN
     * Denote y = minN
     * Denote z = minR
     * Denote a = alpha / A_B_SCALE
     * Denote b = beta  / A_B_SCALE
     * Return ((a - b * y) * x / (a - b * x) * y) ^ (1 / a) * z
     */
    function getNewR(uint256 _newN, uint256 _minN, uint256 _minR, uint256 _alpha, uint256 _beta) external pure returns (uint256) {
        uint256 temp1 = _alpha.sub(_beta.mul(_minN));
        uint256 temp2 = _alpha.sub(_beta.mul(_newN));
        return pow((temp1.mul(FIXED_ONE) / temp2).mul(_newN), _minN, A_B_SCALE, _alpha).mul(_minR) / FIXED_ONE;
    }

    /**
     * Return (a / b / FIXED_ONE) ^ (c / d) * FIXED_ONE
     */
    function pow(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256) {
        return exp(log(_a / _b).mul(_c) / _d);
    }

    /**
     * Return log(x / FIXED_ONE) * FIXED_ONE
     * Auto-generated via 'PrintFunctionLog.py'
     * Detailed description (see 'FunctionLog.pdf'):
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     * The boundaries of the input are asserted in order to ensure that the process is arithmetically-safe
     */
    function log(uint256 _x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        assert(_x < 0x282bcb7edf620be5a97bf8a6e89874720); // ensure that the input is smaller than e^3
        if (_x >= 0x8f69ff327e2a0abedc8cb1a87d3bc87a) {res += 0x30000000000000000000000000000000; _x = _x * FIXED_ONE / 0x8f69ff327e2a0abedc8cb1a87d3bc87a;} // add 3 / 2^1
        if (_x >= 0x43be76d19f73def530d5bb8fb9dc43e4) {res += 0x18000000000000000000000000000000; _x = _x * FIXED_ONE / 0x43be76d19f73def530d5bb8fb9dc43e4;} // add 3 / 2^2
        if (_x >= 0x2e8f4a27b7ded4c468f16cb3612480b8) {res += 0x0c000000000000000000000000000000; _x = _x * FIXED_ONE / 0x2e8f4a27b7ded4c468f16cb3612480b8;} // add 3 / 2^3
        if (_x >= 0x2699702e16b06a5a9c189196f8cc9268) {res += 0x06000000000000000000000000000000; _x = _x * FIXED_ONE / 0x2699702e16b06a5a9c189196f8cc9268;} // add 3 / 2^4
        if (_x >= 0x232526e0e9c19ad127a319b7501d5785) {res += 0x03000000000000000000000000000000; _x = _x * FIXED_ONE / 0x232526e0e9c19ad127a319b7501d5785;} // add 3 / 2^5
        if (_x >= 0x2189246d053d1785259fcc7ac9652bd4) {res += 0x01800000000000000000000000000000; _x = _x * FIXED_ONE / 0x2189246d053d1785259fcc7ac9652bd4;} // add 3 / 2^6
        if (_x >= 0x20c24486c821ba29cacb3aebd2b6edc3) {res += 0x00c00000000000000000000000000000; _x = _x * FIXED_ONE / 0x20c24486c821ba29cacb3aebd2b6edc3;} // add 3 / 2^7
        if (_x >= 0x206090906c40ed411b2823439dced945) {res += 0x00600000000000000000000000000000; _x = _x * FIXED_ONE / 0x206090906c40ed411b2823439dced945;} // add 3 / 2^8
        if (_x >= 0x2030241206c206e81bcab23d632c0b35) {res += 0x00300000000000000000000000000000; _x = _x * FIXED_ONE / 0x2030241206c206e81bcab23d632c0b35;} // add 3 / 2^9

        assert(_x >= FIXED_ONE);
        z = y = _x - FIXED_ONE;
        w = y * y / FIXED_ONE;
        res += z * (0x40000000000000000000000000000000 - y) / 0x040000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^01 / 01 - y^02 / 02
        res += z * (0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x080000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^03 / 03 - y^04 / 04
        res += z * (0x26666666666666666666666666666666 - y) / 0x0c0000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^05 / 05 - y^06 / 06
        res += z * (0x24924924924924924924924924924924 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^07 / 07 - y^08 / 08
        res += z * (0x238e38e38e38e38e38e38e38e38e38e3 - y) / 0x140000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^09 / 09 - y^10 / 10
        res += z * (0x22e8ba2e8ba2e8ba2e8ba2e8ba2e8ba2 - y) / 0x180000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^11 / 11 - y^12 / 12
        res += z * (0x22762762762762762762762762762762 - y) / 0x1c0000000000000000000000000000000; z = z * w / FIXED_ONE; // add y^13 / 13 - y^14 / 14
        res += z * (0x22222222222222222222222222222222 - y) / 0x200000000000000000000000000000000;                        // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
     * Return e ^ (x / FIXED_ONE) * FIXED_ONE
     * Auto-generated via 'PrintFunctionExp.py'
     * Detailed description (see 'FunctionExp.pdf'):
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     * The boundaries of the input are asserted in order to ensure that the process is arithmetically-safe
     */
    function exp(uint256 _x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = _x % 0x4000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_ONE; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_ONE; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_ONE; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_ONE; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_ONE; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_ONE; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_ONE; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_ONE; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_ONE; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_ONE; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_ONE; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_ONE; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_ONE; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_ONE; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_ONE; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_ONE; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_ONE; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_ONE; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_ONE; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_ONE; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((_x & 0x004000000000000000000000000000000) != 0) res = res * 0x70f5a893b608861e1f58934f97aea5816 / 0x63afbe7ab2082ba1a0ae5e4eb1b479e04; // multiply by e^2^(-3)
        if ((_x & 0x008000000000000000000000000000000) != 0) res = res * 0x63afbe7ab2082ba1a0ae5e4eb1b479e11 / 0x4da2cbf1be5827f9eb3ad1aa9866ebb76; // multiply by e^2^(-2)
        if ((_x & 0x010000000000000000000000000000000) != 0) res = res * 0x4da2cbf1be5827f9eb3ad1aa9866ebb8b / 0x2f16ac6c59de6f8d5d6f63c1482a7c89d; // multiply by e^2^(-1)
        if ((_x & 0x020000000000000000000000000000000) != 0) res = res * 0x2f16ac6c59de6f8d5d6f63c1482a7c8a1 / 0x1152aaa3bf81cb9fdb76eae12d0295732; // multiply by e^2^(+0)
        if ((_x & 0x040000000000000000000000000000000) != 0) res = res * 0x1152aaa3bf81cb9fdb76eae12d029572c / 0x02582ab704279e8efd15e0265855c47ab; // multiply by e^2^(+1)
        if ((_x & 0x080000000000000000000000000000000) != 0) res = res * 0x02582ab704279e8efd15e0265855c4792 / 0x000afe10820813d65dfe6a33c07f738f5; // multiply by e^2^(+2)
        assert(_x < 0x100000000000000000000000000000000); // ensure that the input is smaller than 2^(+3)

        return res;
    }
}
