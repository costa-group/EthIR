// File: @openzeppelin/contracts/math/SafeMath.sol



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



// File: @openzeppelin/contracts/GSN/Context.sol



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



// File: @openzeppelin/contracts/ownership/Ownable.sol



pragma solidity ^0.5.0;



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

    address private _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor () internal {

        address msgSender = _msgSender();

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

}



// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.5.5;



/**

 * @dev Collection of functions related to the address type

 */

library Address {

    /**

     * @dev Returns true if `account` is a contract.

     *

     * [IMPORTANT]

     * ====

     * It is unsafe to assume that an address for which this function returns

     * false is an externally-owned account (EOA) and not a contract.

     *

     * Among others, `isContract` will return false for the following 

     * types of addresses:

     *

     *  - an externally-owned account

     *  - a contract in construction

     *  - an address where a contract will be created

     *  - an address where a contract lived, but was destroyed

     * ====

     */

    function isContract(address account) internal view returns (bool) {

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts

        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned

        // for accounts without code, i.e. `keccak256('')`

        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // solhint-disable-next-line no-inline-assembly

        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);

    }



    /**

     * @dev Converts an `address` into `address payable`. Note that this is

     * simply a type cast: the actual underlying value is not changed.

     *

     * _Available since v2.4.0._

     */

    function toPayable(address account) internal pure returns (address payable) {

        return address(uint160(account));

    }



    /**

     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to

     * `recipient`, forwarding all available gas and reverting on errors.

     *

     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost

     * of certain opcodes, possibly making contracts go over the 2300 gas limit

     * imposed by `transfer`, making them unable to receive funds via

     * `transfer`. {sendValue} removes this limitation.

     *

     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].

     *

     * IMPORTANT: because control is transferred to `recipient`, care must be

     * taken to not create reentrancy vulnerabilities. Consider using

     * {ReentrancyGuard} or the

     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].

     *

     * _Available since v2.4.0._

     */

    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        // solhint-disable-next-line avoid-call-value

        (bool success, ) = recipient.call.value(amount)("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }

}



// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.5.0;



/**

 * @dev Contract module that helps prevent reentrant calls to a function.

 *

 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier

 * available, which can be applied to functions to make sure there are no nested

 * (reentrant) calls to them.

 *

 * Note that because there is a single `nonReentrant` guard, functions marked as

 * `nonReentrant` may not call one another. This can be worked around by making

 * those functions `private`, and then adding `external` `nonReentrant` entry

 * points to them.

 *

 * TIP: If you would like to learn more about reentrancy and alternative ways

 * to protect against it, check out our blog post

 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].

 *

 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas

 * metering changes introduced in the Istanbul hardfork.

 */

contract ReentrancyGuard {

    bool private _notEntered;



    constructor () internal {

        // Storing an initial non-zero value makes deployment a bit more

        // expensive, but in exchange the refund on every call to nonReentrant

        // will be lower in amount. Since refunds are capped to a percetange of

        // the total transaction's gas, it is best to keep them low in cases

        // like this one, to increase the likelihood of the full refund coming

        // into effect.

        _notEntered = true;

    }



    /**

     * @dev Prevents a contract from calling itself, directly or indirectly.

     * Calling a `nonReentrant` function from another `nonReentrant`

     * function is not supported. It is possible to prevent this from happening

     * by making the `nonReentrant` function external, and make it call a

     * `private` function that does the actual work.

     */

    modifier nonReentrant() {

        // On the first call to nonReentrant, _notEntered will be true

        require(_notEntered, "ReentrancyGuard: reentrant call");



        // Any calls to nonReentrant after this point will fail

        _notEntered = false;



        _;



        // By storing the original value once again, a refund is triggered (see

        // https://eips.ethereum.org/EIPS/eip-2200)

        _notEntered = true;

    }

}



// File: contracts/UniswapV2/UniswapV2Router.sol



pragma solidity ^0.5.12;


interface IUniswapV2Router02 {

    function factory() external pure returns (address);



    function WETH() external pure returns (address);



    function addLiquidity(

        address tokenA,

        address tokenB,

        uint256 amountADesired,

        uint256 amountBDesired,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline

    )

        external

        returns (

            uint256 amountA,

            uint256 amountB,

            uint256 liquidity

        );



    function addLiquidityETH(

        address token,

        uint256 amountTokenDesired,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    )

        external

        payable

        returns (

            uint256 amountToken,

            uint256 amountETH,

            uint256 liquidity

        );



    function removeLiquidity(

        address tokenA,

        address tokenB,

        uint256 liquidity,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountA, uint256 amountB);



    function removeLiquidityETH(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountToken, uint256 amountETH);



    function removeLiquidityWithPermit(

        address tokenA,

        address tokenB,

        uint256 liquidity,

        uint256 amountAMin,

        uint256 amountBMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountA, uint256 amountB);



    function removeLiquidityETHWithPermit(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountToken, uint256 amountETH);



    function swapExactTokensForTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapTokensForExactTokens(

        uint256 amountOut,

        uint256 amountInMax,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapExactETHForTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



    function swapTokensForExactETH(

        uint256 amountOut,

        uint256 amountInMax,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapExactTokensForETH(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapETHForExactTokens(

        uint256 amountOut,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



    function removeLiquidityETHSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountETH);



    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountETH);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;



    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable;



    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;



    function quote(

        uint256 amountA,

        uint256 reserveA,

        uint256 reserveB

    ) external pure returns (uint256 amountB);



    function getAmountOut(

        uint256 amountIn,

        uint256 reserveIn,

        uint256 reserveOut

    ) external pure returns (uint256 amountOut);



    function getAmountIn(

        uint256 amountOut,

        uint256 reserveIn,

        uint256 reserveOut

    ) external pure returns (uint256 amountIn);



    function getAmountsOut(uint256 amountIn, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);



    function getAmountsIn(uint256 amountOut, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);

}



// File: contracts/UniswapV2/UniswapV2Zapin.sol



pragma solidity ^0.5.12;












library TransferHelper {

    function safeApprove(

        address token,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('approve(address,uint256)')));

        (bool success, bytes memory data) = token.call(

            abi.encodeWithSelector(0x095ea7b3, to, value)

        );

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            "TransferHelper: APPROVE_FAILED"

        );

    }



    function safeTransfer(

        address token,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(

            abi.encodeWithSelector(0xa9059cbb, to, value)

        );

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            "TransferHelper: TRANSFER_FAILED"

        );

    }



    function safeTransferFrom(

        address token,

        address from,

        address to,

        uint256 value

    ) internal {

        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = token.call(

            abi.encodeWithSelector(0x23b872dd, from, to, value)

        );

        require(

            success && (data.length == 0 || abi.decode(data, (bool))),

            "TransferHelper: TRANSFER_FROM_FAILED"

        );

    }

}



// import "@uniswap/lib/contracts/libraries/Babylonian.sol";

library Babylonian {

    function sqrt(uint256 y) internal pure returns (uint256 z) {

        if (y > 3) {

            z = y;

            uint256 x = y / 2 + 1;

            while (x < z) {

                z = x;

                x = (y / x + x) / 2;

            }

        } else if (y != 0) {

            z = 1;

        }

        // else z = 0

    }

}



/**

 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include

 * the optional functions; to access them see {ERC20Detailed}.

 */

interface IERC20 {

    /**

     * @dev Returns the number of decimals.

     */

    function decimals() external view returns (uint256);



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

    function transfer(address recipient, uint256 amount)

        external

        returns (bool);



    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through {transferFrom}. This is

     * zero by default.

     *

     * This value changes when {approve} or {transferFrom} are called.

     */

    function allowance(address owner, address spender)

        external

        view

        returns (uint256);



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

    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) external returns (bool);



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

    event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );

}



interface IWETH {

    function deposit() external payable;



    function transfer(address to, uint256 value) external returns (bool);



    function withdraw(uint256) external;

}



interface IUniswapV1Factory {

    function getExchange(address token)

        external

        view

        returns (address exchange);

}



interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB)

        external

        view

        returns (address);

}



interface IUniswapExchange {

    // converting ERC20 to ERC20 and transfer

    function tokenToTokenTransferInput(

        uint256 tokens_sold,

        uint256 min_tokens_bought,

        uint256 min_eth_bought,

        uint256 deadline,

        address recipient,

        address token_addr

    ) external returns (uint256 tokens_bought);



    function tokenToTokenSwapInput(

        uint256 tokens_sold,

        uint256 min_tokens_bought,

        uint256 min_eth_bought,

        uint256 deadline,

        address token_addr

    ) external returns (uint256 tokens_bought);



    function getEthToTokenInputPrice(uint256 eth_sold)

        external

        view

        returns (uint256 tokens_bought);



    function getTokenToEthInputPrice(uint256 tokens_sold)

        external

        view

        returns (uint256 eth_bought);



    function tokenToEthTransferInput(

        uint256 tokens_sold,

        uint256 min_eth,

        uint256 deadline,

        address recipient

    ) external returns (uint256 eth_bought);



    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)

        external

        payable

        returns (uint256 tokens_bought);



    function ethToTokenTransferInput(

        uint256 min_tokens,

        uint256 deadline,

        address recipient

    ) external payable returns (uint256 tokens_bought);



    function balanceOf(address _owner) external view returns (uint256);



    function transfer(address _to, uint256 _value) external returns (bool);



    function transferFrom(

        address from,

        address to,

        uint256 tokens

    ) external returns (bool success);

}



interface IUniswapV2Pair {

    function token0() external pure returns (address);



    function token1() external pure returns (address);



    function getReserves()

        external

        view

        returns (

            uint112 _reserve0,

            uint112 _reserve1,

            uint32 _blockTimestampLast

        );

}



contract UniswapV2_ZapIn is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    using Address for address;

    bool private stopped = false;

    uint16 public goodwill;

    address public dzgoodwillAddress;

    uint256 public defaultSlippage;



    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(

        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    );



    IUniswapV1Factory public UniSwapV1FactoryAddress = IUniswapV1Factory(

        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95

    );



    IUniswapV2Factory public UniSwapV2FactoryAddress = IUniswapV2Factory(

        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

    );



    address wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;



    constructor(

        uint16 _goodwill,

        address _dzgoodwillAddress,

        uint256 _slippage

    ) public {

        goodwill = _goodwill;

        dzgoodwillAddress = _dzgoodwillAddress;

        defaultSlippage = _slippage;

    }



    // circuit breaker modifiers

    modifier stopInEmergency {

        if (stopped) {

            revert("Temporarily Paused");

        } else {

            _;

        }

    }



    /**

    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens

    @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if ether)

    @param _ToUnipoolToken0 The Uniswap V2 pair token0 address

    @param _ToUnipoolToken1 The Uniswap V2 pair token1 address

    @param _amount The amount of fromToken to invest

    @param slippage Slippage user wants

    @return Amount of LP bought

     */

    function ZapIn(

        address _FromTokenContractAddress,

        address _ToUnipoolToken0,

        address _ToUnipoolToken1,

        uint256 _amount,

        uint256 slippage

    ) public payable nonReentrant stopInEmergency returns (uint256) {

        uint256 toInvest;

        if (_FromTokenContractAddress == address(0)) {

            require(msg.value > 0, "Error: ETH not sent");

            toInvest = msg.value;

        } else {

            require(msg.value == 0, "Error: ETH sent");

            require(_amount > 0, "Error: Invalid ERC amount");

            TransferHelper.safeTransferFrom(

                _FromTokenContractAddress,

                msg.sender,

                address(this),

                _amount

            );

            toInvest = _amount;

        }



        uint256 withSlippage = slippage > 0 && slippage < 10000

            ? slippage

            : defaultSlippage;



        uint256 LPBought = _performZapIn(

            _FromTokenContractAddress,

            _ToUnipoolToken0,

            _ToUnipoolToken1,

            toInvest,

            withSlippage

        );



        //get pair address

        address _ToUniPoolAddress = UniSwapV2FactoryAddress.getPair(

            _ToUnipoolToken0,

            _ToUnipoolToken1

        );



        //transfer goodwill

        uint256 goodwillPortion = _transferGoodwill(

            _ToUniPoolAddress,

            LPBought

        );



        TransferHelper.safeTransfer(

            _ToUniPoolAddress,

            msg.sender,

            SafeMath.sub(LPBought, goodwillPortion)

        );

        return SafeMath.sub(LPBought, goodwillPortion);

    }



    function _performZapIn(

        address _FromTokenContractAddress,

        address _ToUnipoolToken0,

        address _ToUnipoolToken1,

        uint256 _amount,

        uint256 slippage

    ) internal returns (uint256) {

        uint256 token0Bought;

        uint256 token1Bought;



        if (canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)) {

            (token0Bought, token1Bought) = exchangeTokensV2(

                _FromTokenContractAddress,

                _ToUnipoolToken0,

                _ToUnipoolToken1,

                _amount,

                slippage

            );

        } else if (

            canSwapFromV1(_ToUnipoolToken0, _ToUnipoolToken1, _amount, _amount)

        ) {

            (token0Bought, token1Bought) = exchangeTokensV1(

                _FromTokenContractAddress,

                _ToUnipoolToken0,

                _ToUnipoolToken1,

                _amount,

                slippage

            );

        }



        require(token0Bought > 0 && token0Bought > 0, "Could not exchange");



        TransferHelper.safeApprove(

            _ToUnipoolToken0,

            address(uniswapV2Router),

            token0Bought

        );



        TransferHelper.safeApprove(

            _ToUnipoolToken1,

            address(uniswapV2Router),

            token1Bought

        );



        (uint256 amountA, uint256 amountB, uint256 LP) = uniswapV2Router

            .addLiquidity(

            _ToUnipoolToken0,

            _ToUnipoolToken1,

            token0Bought,

            token1Bought,

            1,

            1,

            address(this),

            now + 60

        );



        uint256 residue;

        if (SafeMath.sub(token0Bought, amountA) > 0) {

            if (canSwapFromV2(_ToUnipoolToken0, _FromTokenContractAddress)) {

                residue = swapFromV2(

                    _ToUnipoolToken0,

                    _FromTokenContractAddress,

                    SafeMath.sub(token0Bought, amountA),

                    10000

                );

            } else {

                TransferHelper.safeTransfer(

                    _ToUnipoolToken0,

                    msg.sender,

                    SafeMath.sub(token0Bought, amountA)

                );

            }

        }



        if (SafeMath.sub(token1Bought, amountB) > 0) {

            if (canSwapFromV2(_ToUnipoolToken1, _FromTokenContractAddress)) {

                residue += swapFromV2(

                    _ToUnipoolToken1,

                    _FromTokenContractAddress,

                    SafeMath.sub(token1Bought, amountB),

                    10000

                );

            } else {

                TransferHelper.safeTransfer(

                    _ToUnipoolToken1,

                    msg.sender,

                    SafeMath.sub(token1Bought, amountB)

                );

            }

        }



        if (residue > 0) {

            TransferHelper.safeTransfer(

                _FromTokenContractAddress,

                msg.sender,

                residue

            );

        }



        return LP;

    }



    function exchangeTokensV1(

        address _FromTokenContractAddress,

        address _ToUnipoolToken0,

        address _ToUnipoolToken1,

        uint256 _amount,

        uint256 slippage

    ) internal returns (uint256 token0Bought, uint256 token1Bought) {

        IUniswapV2Pair pair = IUniswapV2Pair(

            UniSwapV2FactoryAddress.getPair(_ToUnipoolToken0, _ToUnipoolToken1)

        );

        (uint256 res0, uint256 res1, ) = pair.getReserves();

        if (_FromTokenContractAddress == address(0)) {

            token0Bought = _eth2Token(_ToUnipoolToken0, _amount, slippage);

            uint256 amountToSwap = calculateSwapInAmount(res0, token0Bought);

            //if no reserve or a new pair is created

            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token0Bought, 2);

            token1Bought = _eth2Token(_ToUnipoolToken1, amountToSwap, slippage);

            token0Bought = SafeMath.sub(token0Bought, amountToSwap);

        } else {

            if (_ToUnipoolToken0 == _FromTokenContractAddress) {

                uint256 amountToSwap = calculateSwapInAmount(res0, _amount);

                //if no reserve or a new pair is created

                if (amountToSwap <= 0) amountToSwap = SafeMath.div(_amount, 2);

                token1Bought = _token2Token(

                    _FromTokenContractAddress,

                    address(this),

                    _ToUnipoolToken1,

                    amountToSwap,

                    slippage

                );



                token0Bought = SafeMath.sub(_amount, amountToSwap);

            } else if (_ToUnipoolToken1 == _FromTokenContractAddress) {

                uint256 amountToSwap = calculateSwapInAmount(res1, _amount);

                //if no reserve or a new pair is created

                if (amountToSwap <= 0) amountToSwap = SafeMath.div(_amount, 2);

                token0Bought = _token2Token(

                    _FromTokenContractAddress,

                    address(this),

                    _ToUnipoolToken0,

                    amountToSwap,

                    slippage

                );



                token1Bought = SafeMath.sub(_amount, amountToSwap);

            } else {

                token0Bought = _token2Token(

                    _FromTokenContractAddress,

                    address(this),

                    _ToUnipoolToken0,

                    _amount,

                    slippage

                );

                uint256 amountToSwap = calculateSwapInAmount(

                    res0,

                    token0Bought

                );

                //if no reserve or a new pair is created

                if (amountToSwap <= 0) amountToSwap = SafeMath.div(_amount, 2);



                token1Bought = _token2Token(

                    _FromTokenContractAddress,

                    address(this),

                    _ToUnipoolToken1,

                    amountToSwap,

                    slippage

                );

                token0Bought = SafeMath.sub(token0Bought, amountToSwap);

            }

        }

    }



    function exchangeTokensV2(

        address _FromTokenContractAddress,

        address _ToUnipoolToken0,

        address _ToUnipoolToken1,

        uint256 _amount,

        uint256 slippage

    ) internal returns (uint256 token0Bought, uint256 token1Bought) {

        IUniswapV2Pair pair = IUniswapV2Pair(

            UniSwapV2FactoryAddress.getPair(_ToUnipoolToken0, _ToUnipoolToken1)

        );

        (uint256 res0, uint256 res1, ) = pair.getReserves();

        if (

            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken0) &&

            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)

        ) {

            token0Bought = swapFromV2(

                _FromTokenContractAddress,

                _ToUnipoolToken0,

                _amount,

                slippage

            );

            uint256 amountToSwap = calculateSwapInAmount(res0, token0Bought);

            //if no reserve or a new pair is created

            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token0Bought, 2);

            token1Bought = swapFromV2(

                _ToUnipoolToken0,

                _ToUnipoolToken1,

                amountToSwap,

                slippage

            );

            token0Bought = SafeMath.sub(token0Bought, amountToSwap);

        } else if (

            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken1) &&

            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)

        ) {

            token1Bought = swapFromV2(

                _FromTokenContractAddress,

                _ToUnipoolToken1,

                _amount,

                slippage

            );

            uint256 amountToSwap = calculateSwapInAmount(res1, token1Bought);

            //if no reserve or a new pair is created

            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token1Bought, 2);

            token0Bought = swapFromV2(

                _ToUnipoolToken1,

                _ToUnipoolToken0,

                amountToSwap,

                slippage

            );

            token1Bought = SafeMath.sub(token1Bought, amountToSwap);

        }

    }



    //checks if tokens can be exchanged with UniV1

    function canSwapFromV1(

        address _fromToken,

        address _toToken,

        uint256 fromAmount,

        uint256 toAmount

    ) public view returns (bool) {

        require(

            _fromToken != address(0) || _toToken != address(0),

            "Invalid Exchange values"

        );



        if (_fromToken == address(0)) {

            IUniswapExchange toExchange = IUniswapExchange(

                UniSwapV1FactoryAddress.getExchange(_toToken)

            );

            uint256 tokenBalance = IERC20(_toToken).balanceOf(

                address(toExchange)

            );

            uint256 ethBalance = address(toExchange).balance;

            if (tokenBalance > toAmount && ethBalance > fromAmount) return true;

        } else if (_toToken == address(0)) {

            IUniswapExchange fromExchange = IUniswapExchange(

                UniSwapV1FactoryAddress.getExchange(_fromToken)

            );

            uint256 tokenBalance = IERC20(_fromToken).balanceOf(

                address(fromExchange)

            );

            uint256 ethBalance = address(fromExchange).balance;

            if (tokenBalance > fromAmount && ethBalance > toAmount) return true;

        } else {

            IUniswapExchange toExchange = IUniswapExchange(

                UniSwapV1FactoryAddress.getExchange(_toToken)

            );

            IUniswapExchange fromExchange = IUniswapExchange(

                UniSwapV1FactoryAddress.getExchange(_fromToken)

            );

            uint256 balance1 = IERC20(_fromToken).balanceOf(

                address(fromExchange)

            );

            uint256 balance2 = IERC20(_toToken).balanceOf(address(toExchange));

            if (balance1 > fromAmount && balance2 > toAmount) return true;

        }

        return false;

    }



    //checks if tokens can be exchanged with UniV2

    function canSwapFromV2(address _fromToken, address _toToken)

        public

        view

        returns (bool)

    {

        require(

            _fromToken != address(0) || _toToken != address(0),

            "Invalid Exchange values"

        );



        if (_fromToken == _toToken) return true;



        if (_fromToken == address(0) || _fromToken == wethTokenAddress) {

            if (_toToken == wethTokenAddress || _toToken == address(0))

                return true;

            IUniswapV2Pair pair = IUniswapV2Pair(

                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)

            );

            if (_haveReserve(pair)) return true;

        } else if (_toToken == address(0) || _toToken == wethTokenAddress) {

            if (_fromToken == wethTokenAddress || _fromToken == address(0))

                return true;

            IUniswapV2Pair pair = IUniswapV2Pair(

                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)

            );

            if (_haveReserve(pair)) return true;

        } else {

            IUniswapV2Pair pair1 = IUniswapV2Pair(

                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)

            );

            IUniswapV2Pair pair2 = IUniswapV2Pair(

                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)

            );

            IUniswapV2Pair pair3 = IUniswapV2Pair(

                UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)

            );

            if (_haveReserve(pair1) && _haveReserve(pair2)) return true;

            if (_haveReserve(pair3)) return true;

        }

        return false;

    }



    //checks if the UNI v2 contract have reserves to swap tokens

    function _haveReserve(IUniswapV2Pair pair) internal view returns (bool) {

        if (address(pair) != address(0)) {

            (uint256 res0, uint256 res1, ) = pair.getReserves();

            if (res0 > 0 && res1 > 0) {

                return true;

            }

        }

    }



    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)

        public

        pure

        returns (uint256)

    {

        return

            Babylonian

                .sqrt(

                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))

            )

                .sub(reserveIn.mul(1997)) / 1994;

    }



    //swaps _fromToken for _toToken

    //for eth, address(0) otherwise ERC token address

    function swapFromV2(

        address _fromToken,

        address _toToken,

        uint256 amount,

        uint256 slippage

    ) internal returns (uint256) {

        require(

            _fromToken != address(0) || _toToken != address(0),

            "Invalid Exchange values"

        );

        if (_fromToken == _toToken) return amount;



        require(canSwapFromV2(_fromToken, _toToken), "Cannot be exchanged");

        require(amount > 0, "Invalid amount");



        if (_fromToken == address(0)) {

            if (_toToken == wethTokenAddress) {

                IWETH(wethTokenAddress).deposit.value(amount)();

                return amount;

            }

            address[] memory path = new address[](2);

            path[0] = wethTokenAddress;

            path[1] = _toToken;

            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];

            minTokens = SafeMath.div(

                SafeMath.mul(minTokens, SafeMath.sub(10000, slippage)),

                10000

            );

            uint256[] memory amounts = uniswapV2Router

                .swapExactETHForTokens

                .value(amount)(minTokens, path, address(this), now + 180);

            return amounts[1];

        } else if (_toToken == address(0)) {

            if (_fromToken == wethTokenAddress) {

                IWETH(wethTokenAddress).withdraw(amount);

                return amount;

            }

            address[] memory path = new address[](2);

            TransferHelper.safeApprove(

                _fromToken,

                address(uniswapV2Router),

                amount

            );

            path[0] = _fromToken;

            path[1] = wethTokenAddress;

            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];

            minTokens = SafeMath.div(

                SafeMath.mul(minTokens, SafeMath.sub(10000, slippage)),

                10000

            );

            uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(

                amount,

                minTokens,

                path,

                address(this),

                now + 180

            );

            return amounts[1];

        } else {

            TransferHelper.safeApprove(

                _fromToken,

                address(uniswapV2Router),

                amount

            );

            uint256 returnedAmount = _swapTokenToTokenV2(

                _fromToken,

                _toToken,

                amount,

                slippage

            );

            require(returnedAmount > 0, "Error in swap");

            return returnedAmount;

        }

    }



    //swaps 2 ERC tokens (UniV2)

    function _swapTokenToTokenV2(

        address _fromToken,

        address _toToken,

        uint256 amount,

        uint256 slippage

    ) internal returns (uint256) {

        IUniswapV2Pair pair1 = IUniswapV2Pair(

            UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)

        );

        IUniswapV2Pair pair2 = IUniswapV2Pair(

            UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)

        );

        IUniswapV2Pair pair3 = IUniswapV2Pair(

            UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)

        );



        uint256[] memory amounts;



        if (_haveReserve(pair3)) {

            address[] memory path = new address[](2);

            path[0] = _fromToken;

            path[1] = _toToken;

            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[1];

            minTokens = SafeMath.div(

                SafeMath.mul(minTokens, SafeMath.sub(10000, slippage)),

                10000

            );

            amounts = uniswapV2Router.swapExactTokensForTokens(

                amount,

                minTokens,

                path,

                address(this),

                now + 180

            );

            return amounts[1];

        } else if (_haveReserve(pair1) && _haveReserve(pair2)) {

            address[] memory path = new address[](3);

            path[0] = _fromToken;

            path[1] = wethTokenAddress;

            path[2] = _toToken;

            uint256 minTokens = uniswapV2Router.getAmountsOut(amount, path)[2];

            minTokens = SafeMath.div(

                SafeMath.mul(minTokens, SafeMath.sub(10000, slippage)),

                10000

            );

            amounts = uniswapV2Router.swapExactTokensForTokens(

                amount,

                minTokens,

                path,

                address(this),

                now + 180

            );

            return amounts[2];

        }

        return 0;

    }



    /**

    @notice This function is used to buy tokens from eth

    @param _tokenContractAddress Token address which we want to buy

    @param _amount The amount of eth we want to exchange

    @return The quantity of token bought

     */

    function _eth2Token(

        address _tokenContractAddress,

        uint256 _amount,

        uint256 slippage

    ) internal returns (uint256 tokenBought) {

        IUniswapExchange FromUniSwapExchangeContractAddress = IUniswapExchange(

            UniSwapV1FactoryAddress.getExchange(_tokenContractAddress)

        );



        uint256 minTokenBought = FromUniSwapExchangeContractAddress

            .getEthToTokenInputPrice(_amount);

        minTokenBought = SafeMath.div(

            SafeMath.mul(minTokenBought, SafeMath.sub(10000, slippage)),

            10000

        );



        tokenBought = FromUniSwapExchangeContractAddress

            .ethToTokenSwapInput

            .value(_amount)(minTokenBought, SafeMath.add(now, 300));

    }



    /**

    @notice This function is used to swap token with ETH

    @param _FromTokenContractAddress The token address to swap from

    @param tokens2Trade The quantity of tokens to swap

    @return The amount of eth bought

     */

    function _token2Eth(

        address _FromTokenContractAddress,

        uint256 tokens2Trade,

        address _toWhomToIssue,

        uint256 slippage

    ) internal returns (uint256 ethBought) {

        IUniswapExchange FromUniSwapExchangeContractAddress = IUniswapExchange(

            UniSwapV1FactoryAddress.getExchange(_FromTokenContractAddress)

        );



        TransferHelper.safeApprove(

            _FromTokenContractAddress,

            address(FromUniSwapExchangeContractAddress),

            tokens2Trade

        );



        uint256 minEthBought = FromUniSwapExchangeContractAddress

            .getTokenToEthInputPrice(tokens2Trade);

        minEthBought = SafeMath.div(

            SafeMath.mul(minEthBought, SafeMath.sub(10000, slippage)),

            10000

        );



        ethBought = FromUniSwapExchangeContractAddress.tokenToEthTransferInput(

            tokens2Trade,

            minEthBought,

            SafeMath.add(now, 300),

            _toWhomToIssue

        );

        require(ethBought > 0, "Error in swapping Eth: 1");

    }



    /**

    @notice This function is used to swap tokens

    @param _FromTokenContractAddress The token address to swap from

    @param _ToWhomToIssue The address to transfer after swap

    @param _ToTokenContractAddress The token address to swap to

    @param tokens2Trade The quantity of tokens to swap

    @return The amount of tokens returned after swap

     */

    function _token2Token(

        address _FromTokenContractAddress,

        address _ToWhomToIssue,

        address _ToTokenContractAddress,

        uint256 tokens2Trade,

        uint256 slippage

    ) internal returns (uint256 tokenBought) {

        IUniswapExchange FromUniSwapExchangeContractAddress = IUniswapExchange(

            UniSwapV1FactoryAddress.getExchange(_FromTokenContractAddress)

        );



        TransferHelper.safeApprove(

            _FromTokenContractAddress,

            address(FromUniSwapExchangeContractAddress),

            tokens2Trade

        );



        uint256 minEthBought = FromUniSwapExchangeContractAddress

            .getTokenToEthInputPrice(tokens2Trade);

        minEthBought = SafeMath.div(

            SafeMath.mul(minEthBought, SafeMath.sub(10000, slippage)),

            10000

        );



        uint256 minTokenBought = FromUniSwapExchangeContractAddress

            .getEthToTokenInputPrice(minEthBought);

        minTokenBought = SafeMath.div(

            SafeMath.mul(minTokenBought, SafeMath.sub(10000, slippage)),

            10000

        );



        tokenBought = FromUniSwapExchangeContractAddress

            .tokenToTokenTransferInput(

            tokens2Trade,

            minTokenBought,

            minEthBought,

            SafeMath.add(now, 300),

            _ToWhomToIssue,

            _ToTokenContractAddress

        );

        require(tokenBought > 0, "Error in swapping ERC: 1");

    }



    /**

    @notice This function is used to calculate and transfer goodwill

    @param _tokenContractAddress Token in which goodwill is deducted

    @param tokens2Trade The total amount of tokens to be zapped in

    @return The quantity of goodwill deducted

     */

    function _transferGoodwill(

        address _tokenContractAddress,

        uint256 tokens2Trade

    ) internal returns (uint256 goodwillPortion) {

        goodwillPortion = SafeMath.div(

            SafeMath.mul(tokens2Trade, goodwill),

            10000

        );



        if (goodwillPortion == 0) {

            return 0;

        }



        TransferHelper.safeTransfer(

            _tokenContractAddress,

            dzgoodwillAddress,

            goodwillPortion

        );

    }



    function updateSlippage(uint256 _newSlippage) public onlyOwner {

        require(

            _newSlippage > 0 && _newSlippage < 10000,

            "Slippage Value not allowed"

        );

        defaultSlippage = _newSlippage;

    }



    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {

        require(

            _new_goodwill >= 0 && _new_goodwill < 10000,

            "GoodWill Value not allowed"

        );

        goodwill = _new_goodwill;

    }



    function set_new_dzgoodwillAddress(address _new_dzgoodwillAddress)

        public

        onlyOwner

    {

        dzgoodwillAddress = _new_dzgoodwillAddress;

    }



    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {

        uint256 qty = _TokenAddress.balanceOf(address(this));

        TransferHelper.safeTransfer(address(_TokenAddress), owner(), qty);

    }



    // - to Pause the contract

    function toggleContractActive() public onlyOwner {

        stopped = !stopped;

    }



    // - to withdraw any ETH balance sitting in the contract

    function withdraw() public onlyOwner {

        uint256 contractBalance = address(this).balance;

        address payable _to = owner().toPayable();

        _to.transfer(contractBalance);

    }



    // - to kill the contract

    function destruct() public onlyOwner {

        address payable _to = owner().toPayable();

        selfdestruct(_to);

    }



    function() external payable {}

}