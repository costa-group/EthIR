/*

██╗     ███████╗██╗  ██╗                         

██║     ██╔════╝╚██╗██╔╝                         

██║     █████╗   ╚███╔╝                          

██║     ██╔══╝   ██╔██╗                          

███████╗███████╗██╔╝ ██╗                         

╚══════╝╚══════╝╚═╝  ╚═╝                         

██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗ 

██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗

██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝

██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗

███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║

╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

DEAR MSG.SENDER(S):



/ LXL is a project in beta.

// Please audit and use at your own risk.

/// Entry into LXL shall not create an attorney/client relationship.

//// Likewise, LXL should not be construed as legal advice or replacement for professional counsel.

///// STEAL THIS C0D3SL4W 



~presented by Open, ESQ || LexDAO LLC

*/



pragma solidity ^0.5.17;


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

    function _msgSender() internal view returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal view returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

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

     */

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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

     */

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}



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

     */

    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        (bool success, ) = recipient.call.value(amount)("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }

}



/**

 * @dev Interface of the ERC20 standard as defined in the EIP.

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



/**

 * @title SafeERC20

 * @dev Wrappers around ERC20 operations that throw on failure (when the token

 * contract returns false). Tokens that return no value (and instead revert or

 * throw on failure) are also supported, non-reverting calls are assumed to be

 * successful.

 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,

 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.

 */

library SafeERC20 {

    using SafeMath for uint256;

    using Address for address;



    function safeTransfer(IERC20 token, address to, uint256 value) internal {

        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));

    }



    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {

        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));

    }



    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        // safeApprove should only be called when setting an initial allowance,

        // or when resetting it to zero. To increase and decrease it, use

        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'

        // solhint-disable-next-line max-line-length

        require((value == 0) || (token.allowance(address(this), spender) == 0),

            "SafeERC20: approve from non-zero to non-zero allowance"

        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));

    }



    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).add(value);

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    /**

     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement

     * on the return value: the return value is optional (but if data is returned, it must not be false).

     * @param token The token targeted by the call.

     * @param data The call data (encoded using abi.encode or one of its variants).

     */

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since

        // we're implementing it ourselves.



        // A Solidity high level call has three parts:

        //  1. The target address is checked to verify it contains contract code

        //  2. The call itself is made, and success asserted

        //  3. The return value is decoded, which in turn checks the size of the returned data.

        // solhint-disable-next-line max-line-length

        require(address(token).isContract(), "SafeERC20: call to non-contract");



        // solhint-disable-next-line avoid-low-level-calls

        (bool success, bytes memory returndata) = address(token).call(data);

        require(success, "SafeERC20: low-level call failed");



        if (returndata.length > 0) { // Return data is optional

            // solhint-disable-next-line max-line-length

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");

        }

    }

}



contract LexLocker is Context { // deal deposits w/ embedded arbitration via lexDAO

    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    

    /** ADR Wrapper **/

    address public judge;

    address public judgment;

    address payable public lexDAO;

    uint256 public judgeBalance;

    uint256 public judgmentReward;



    /** <$> LXL <$> **/

    address private locker = address(this);

    uint8 public version = 1;

    uint256 public depositFee;

    uint256 public lxl; // index for registered lexlocker

    string public emoji = "⚖️🔐⚔️";

    mapping (uint256 => Deposit) public deposit; 



    struct Deposit {  

        address client; 

        address provider;

        address token;

        uint256 amount;

        uint256 index;

        uint256 termination;

        string details; 

        bool locked; 

        bool released;

    }

    	

    // LXL Deposit Events:

    event LexDAOpaid(address indexed sender, uint256 indexed payment, string indexed details);

    event Locked(address indexed sender, uint256 indexed index, string indexed details);

    event Registered(address indexed client, address indexed provider, uint256 indexed index);  

    event Released(uint256 indexed index); 

    event Resolved(address indexed resolver, uint256 indexed index, string indexed details); 

    

    constructor (

        address _judge, 

        address _judgment, 

        address payable _lexDAO, 

        uint256 _depositFee, 

        uint256 _judgeBalance, 

        uint256 _judgmentReward) public { 

        judge = _judge;

        judgment = _judgment;

        lexDAO = _lexDAO;

        depositFee = _depositFee;

        judgeBalance = _judgeBalance;

        judgmentReward = _judgmentReward;

    } 

    

    /***************

    LOCKER FUNCTIONS

    ***************/

    function depositToken( // register lexlocker and deposit token 

        address provider,

        address token,

        uint256 amount, 

        uint256 termination,

        string memory details) payable public {

        require(termination >= now, "termination set before deploy");

        require(msg.value == depositFee, "deposit fee not attached");



        uint256 index = lxl.add(1); // add to registered index

	    lxl = lxl.add(1);

                

            deposit[index] = Deposit( 

                _msgSender(), 

                provider,

                token,

                amount,

                index,

                termination,

                details, 

                false, 

                false);

        

        lexDAO.transfer(msg.value); // transfer lexlocker ether (Ξ) fee to lexDAO

        IERC20(token).safeTransferFrom(_msgSender(), locker, amount); // deposit token

        

        emit Registered(_msgSender(), provider, index); 

    }



    function release(uint256 index) public { // client can transfer deposit to provider

    	Deposit storage depos = deposit[index];

	    

	    require(depos.locked == false, "deposit already locked"); 

	    require(depos.released == false, "deposit already released"); 

    	require(_msgSender() == depos.client, "caller not deposit client"); 



        IERC20(depos.token).safeTransfer(depos.provider, depos.amount);

        

        depos.released = true; 

        

	    emit Released(index); 

    }

    

    function withdraw(uint256 index) public { // withdraw deposit to client if termination time passes

    	Deposit storage depos = deposit[index];

        

        require(depos.locked == false, "deposit already locked"); 

        require(depos.released == false, "deposit already released"); 

    	require(now >= depos.termination, "deposit time not terminated");

        

        IERC20(depos.token).safeTransfer(depos.client, depos.amount);

        

        depos.released = true; 

        

	    emit Released(index); 

    }

    

    /************

    ADR FUNCTIONS

    ************/

    function lock(uint256 index, string memory details) public { // index client or provider can lock deposit for resolution during locker period

        Deposit storage depos = deposit[index]; 

        

        require(depos.released == false, "deposit already released"); 

        require(now <= depos.termination, "deposit time already terminated"); 

        require(_msgSender() == depos.client || _msgSender() == depos.provider, "caller not deposit party"); 



	    depos.locked = true; 

	    

	    emit Locked(_msgSender(), index, details);

    }

    

    function resolve(uint256 index, uint256 clientAward, uint256 providerAward, string memory details) public { // judge resolves locked deposit for judgment reward 

        Deposit storage depos = deposit[index];

	    

	    require(depos.locked == true, "deposit not locked"); 

	    require(depos.released == false, "deposit already released");

	    require(_msgSender() != depos.client, "resolver cannot be deposit party");

	    require(_msgSender() != depos.provider, "resolver cannot be deposit party");

	    require(clientAward.add(providerAward) == depos.amount, "resolution awards must equal deposit amount");

	    require(IERC20(judge).balanceOf(_msgSender()) >= judgeBalance, "judge token balance insufficient to resolve");

        

        IERC20(depos.token).safeTransfer(depos.client, clientAward);

        IERC20(depos.token).safeTransfer(depos.provider, providerAward);



	    depos.released = true; 

	    

	    IERC20(judgment).safeTransfer(_msgSender(), judgmentReward);

	    

	    emit Resolved(_msgSender(), index, details);

    }

    

    /*************

    MGMT FUNCTIONS

    *************/

    modifier onlyLexDAO () {

        require(_msgSender() == lexDAO, "caller not lexDAO");

        _;

    }

    

    function payLexDAO(string memory details) payable public { // public attaches ether (Ξ) with details to lexDAO

        lexDAO.transfer(msg.value);

        emit LexDAOpaid(_msgSender(), msg.value, details);

    }

    

    function updateDepositFee(uint256 _depositFee) public onlyLexDAO {

        depositFee = _depositFee;

    }

    

    function updateJudge(address _judge) public onlyLexDAO { // token address

        judge = _judge;

    }

    

    function updateJudgeBalance(uint256 _judgeBalance) public onlyLexDAO {

        judgeBalance = _judgeBalance;

    }

    

    function updateJudgment(address _judgment) public onlyLexDAO { // token address

        judgment = _judgment;

    }

    

    function updateJudgmentReward(uint256 _judgmentReward) public onlyLexDAO {

        judgmentReward = _judgmentReward;

    }



    function updateLexDAO(address payable _lexDAO) public onlyLexDAO {

        lexDAO = _lexDAO;

    }

}