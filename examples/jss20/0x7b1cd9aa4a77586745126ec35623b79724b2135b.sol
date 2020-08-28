// File: contracts/OpenZepplinOwnable.sol

pragma solidity ^0.5.0;

contract Context {
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/OpenZepplinSafeMath.sol

pragma solidity ^0.5.0;

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

// File: contracts/OpenZepplinIERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/UniSwap_SNX_MKRZap.sol

pragma solidity ^0.5.0;




interface UniSwapAddLiquidityZap{
    function LetsInvest() external payable returns (bool);
}

contract UniSwap_SNX_DAI_ZAP is Ownable {
    using SafeMath for uint;

    UniSwapAddLiquidityZap UniSNXLiquidityContract = UniSwapAddLiquidityZap(0xD5320F3757C7db376f9f09BA7e05BA37C2BdD0Cb);
    UniSwapAddLiquidityZap UniMKRLiquidityContract = UniSwapAddLiquidityZap(0xC54dF9FBE4212289ccb4D08546BA928Cec7F9426);
    IERC20 public SNX_TOKEN_ADDRESS = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 public MKR_TOKEN_ADDRESS = IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    IERC20 public UniSwapMKRContract = IERC20(0x2C4Bd064b998838076fa341A83d007FC2FA50957);
    IERC20 public UniSwapSNXContract = IERC20(0x3958B4eC427F8fa24eB60F42821760e88d485f7F);


    uint public balance = address(this).balance;
    
    // - in relation to the emergency functioning of this contract
    bool private stopped = false;

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}

    // should we ever want to change the address of UniSNXLiquidityContract
    function set_UniSNXLiquidityContract(UniSwapAddLiquidityZap _new_UniSNXLiquidityContract) public onlyOwner {
        UniSNXLiquidityContract = _new_UniSNXLiquidityContract;
    }

    // should we ever want to change the address of UniMKRLiquidityContract
    function set_UniMKRLiquidityContract(UniSwapAddLiquidityZap _new_UniMKRLiquidityContract) public onlyOwner {
        UniMKRLiquidityContract = _new_UniMKRLiquidityContract;
    }

    // should we ever want to change the address of the SNX_TOKEN_ADDRESS
    function set_SNX_TOKEN_ADDRESS (IERC20 _new_SNX_TOKEN_ADDRESS) public onlyOwner {
        SNX_TOKEN_ADDRESS = _new_SNX_TOKEN_ADDRESS;
    }

    // should we ever want to change the address of the MKR_TOKEN_ADDRESS
    function set_MKR_TOKEN_ADDRESS (IERC20 _new_MKR_TOKEN_ADDRESS) public onlyOwner {
        MKR_TOKEN_ADDRESS = _new_MKR_TOKEN_ADDRESS;
    }


    // should we ever want to change the address of the UniSwapMKRContract
    function set_UniSwapMKRContract (IERC20 _new_UniSwapMKRContract) public onlyOwner {
        UniSwapMKRContract = _new_UniSwapMKRContract;
    }

    // should we ever want to change the address of the UniSwapSNXContract
    function set_UniSwapSNXContract (IERC20 _new_UniSwapSNXContract) public onlyOwner {
        UniSwapSNXContract = _new_UniSwapSNXContract;
    }

    function LetsInvest() payable stopInEmergency public returns (bool) {
        //some basic checks
        require (msg.value > 0.003 ether);
        
        uint MKRPortion = SafeMath.div(SafeMath.mul(msg.value, 50), 100);
        uint SNXPortion = SafeMath.sub(msg.value,MKRPortion);

        require(UniMKRLiquidityContract.LetsInvest.value(MKRPortion)(), "AddLiquidity MKR Failed");
        require(UniSNXLiquidityContract.LetsInvest.value(SNXPortion)(), "AddLiquidity SNX Failed");

        uint MKRLiquidityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(msg.sender, MKRLiquidityTokens);

        uint SNXLiquidityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(msg.sender, SNXLiquidityTokens);

        uint residualMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(msg.sender, residualMKRHoldings);

        uint residualSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(msg.sender, residualSNXHoldings);
        return true;
    }

    // incase of half-way error
    function withdrawMKR() public onlyOwner {
        uint StuckMKRHoldings = MKR_TOKEN_ADDRESS.balanceOf(address(this));
        MKR_TOKEN_ADDRESS.transfer(_owner, StuckMKRHoldings);
    }

    function withdrawSNX() public onlyOwner {
        uint StuckSNXHoldings = SNX_TOKEN_ADDRESS.balanceOf(address(this));
        SNX_TOKEN_ADDRESS.transfer(_owner, StuckSNXHoldings);
    }
    
    function withdrawMKRLiquityTokens() public onlyOwner {
        uint StuckMKRLiquityTokens = UniSwapMKRContract.balanceOf(address(this));
        UniSwapMKRContract.transfer(_owner, StuckMKRLiquityTokens);
    }

   function withdrawSNXLiquityTokens() public onlyOwner {
        uint StuckSNXLiquityTokens = UniSwapSNXContract.balanceOf(address(this));
        UniSwapSNXContract.transfer(_owner, StuckSNXLiquityTokens);
    }

    
    // fx in relation to ETH held by the contract sent by the owner
    
    // - this function lets you deposit ETH into this wallet
    function depositETH() payable public onlyOwner {
        balance += msg.value;
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender == _owner) {
            depositETH();
        } else {
            LetsInvest();
        }
    }
    
    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        _owner.transfer(address(this).balance);
    }
}