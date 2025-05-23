pragma solidity ^0.5.14;


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

 * @title SafeMathUint

 * @dev Math operations with safety checks that revert on error

 */

library SafeMathUint {

  function toInt256Safe(uint256 a) internal pure returns (int256) {

    int256 b = int256(a);

    require(b >= 0);

    return b;

  }

}



/**

 * @title SafeMathInt

 * @dev Math operations with safety checks that revert on error

 * @dev SafeMath adapted for int256

 * Based on code of https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol

 */

library SafeMathInt {

  function mul(int256 a, int256 b) internal pure returns (int256) {

    // Prevent overflow when multiplying INT256_MIN with -1

    // https://github.com/RequestNetwork/requestNetwork/issues/43

    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));



    int256 c = a * b;

    require((b == 0) || (c / b == a));

    return c;

  }



  function div(int256 a, int256 b) internal pure returns (int256) {

    // Prevent overflow when dividing INT256_MIN by -1

    // https://github.com/RequestNetwork/requestNetwork/issues/43

    require(!(a == - 2**255 && b == -1) && (b > 0));



    return a / b;

  }



  function sub(int256 a, int256 b) internal pure returns (int256) {

    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));



    return a - b;

  }



  function add(int256 a, int256 b) internal pure returns (int256) {

    int256 c = a + b;

    require((b >= 0 && c >= a) || (b < 0 && c < a));

    return c;

  }



  function toUint256Safe(int256 a) internal pure returns (uint256) {

    require(a >= 0);

    return uint256(a);

  }

}



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



/**

 * @title Roles

 * @dev Library for managing addresses assigned to a Role.

 */

library Roles {

    struct Role {

        mapping (address => bool) bearer;

    }



    /**

     * @dev Give an account access to this role.

     */

    function add(Role storage role, address account) internal {

        require(!has(role, account), "Roles: account already has role");

        role.bearer[account] = true;

    }



    /**

     * @dev Remove an account's access to this role.

     */

    function remove(Role storage role, address account) internal {

        require(has(role, account), "Roles: account does not have role");

        role.bearer[account] = false;

    }



    /**

     * @dev Check if an account has this role.

     * @return bool

     */

    function has(Role storage role, address account) internal view returns (bool) {

        require(account != address(0), "Roles: account is the zero address");

        return role.bearer[account];

    }

}



contract lexDAORole is Context {

    using Roles for Roles.Role;



    event lexDAOAdded(address indexed account);

    event lexDAORemoved(address indexed account);



    Roles.Role private _lexDAOs;



    modifier onlylexDAO() {

        require(islexDAO(_msgSender()), "lexDAO: caller does not have the lexDAO role");

        _;

    }



    function islexDAO(address account) public view returns (bool) {

        return _lexDAOs.has(account);

    }



    function addlexDAO(address account) public onlylexDAO {

        _addlexDAO(account);

    }



    function renouncelexDAO() public {

        _removelexDAO(_msgSender());

    }



    function _addlexDAO(address account) internal {

        _lexDAOs.add(account);

        emit lexDAOAdded(account);

    }



    function _removelexDAO(address account) internal {

        _lexDAOs.remove(account);

        emit lexDAORemoved(account);

    }

}



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



/**

 * @dev Implementation of the {IERC20} interface.

 *

 * This implementation is agnostic to the way tokens are created. This means

 * that a supply mechanism has to be added in a derived contract using {_mint}.

 * For a generic mechanism see {ERC20Mintable}.

 *

 * TIP: For a detailed writeup see our guide

 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How

 * to implement supply mechanisms].

 *

 * We have followed general OpenZeppelin guidelines: functions revert instead

 * of returning `false` on failure. This behavior is nonetheless conventional

 * and does not conflict with the expectations of ERC20 applications.

 *

 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.

 * This allows applications to reconstruct the allowance for all accounts just

 * by listening to said events. Other implementations of the EIP may not emit

 * these events, as it isn't required by the specification.

 *

 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}

 * functions have been added to mitigate the well-known issues around setting

 * allowances. See {IERC20-approve}.

 */

contract ERC20 is Context, IERC20 {

    using SafeMath for uint256;



    mapping (address => uint256) private _balances;



    mapping (address => mapping (address => uint256)) private _allowances;



    uint256 private _totalSupply;



    /**

     * @dev See {IERC20-totalSupply}.

     */

    function totalSupply() public view returns (uint256) {

        return _totalSupply;

    }



    /**

     * @dev See {IERC20-balanceOf}.

     */

    function balanceOf(address account) public view returns (uint256) {

        return _balances[account];

    }



    /**

     * @dev See {IERC20-transfer}.

     *

     * Requirements:

     *

     * - `recipient` cannot be the zero address.

     * - the caller must have a balance of at least `amount`.

     */

    function transfer(address recipient, uint256 amount) public returns (bool) {

        _transfer(_msgSender(), recipient, amount);

        return true;

    }



    /**

     * @dev See {IERC20-allowance}.

     */

    function allowance(address owner, address spender) public view returns (uint256) {

        return _allowances[owner][spender];

    }



    /**

     * @dev See {IERC20-approve}.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     */

    function approve(address spender, uint256 amount) public returns (bool) {

        _approve(_msgSender(), spender, amount);

        return true;

    }



    /**

     * @dev See {IERC20-transferFrom}.

     *

     * Emits an {Approval} event indicating the updated allowance. This is not

     * required by the EIP. See the note at the beginning of {ERC20};

     *

     * Requirements:

     * - `sender` and `recipient` cannot be the zero address.

     * - `sender` must have a balance of at least `amount`.

     * - the caller must have allowance for `sender`'s tokens of at least

     * `amount`.

     */

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;

    }



    /**

     * @dev Atomically increases the allowance granted to `spender` by the caller.

     *

     * This is an alternative to {approve} that can be used as a mitigation for

     * problems described in {IERC20-approve}.

     *

     * Emits an {Approval} event indicating the updated allowance.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     */

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;

    }



    /**

     * @dev Atomically decreases the allowance granted to `spender` by the caller.

     *

     * This is an alternative to {approve} that can be used as a mitigation for

     * problems described in {IERC20-approve}.

     *

     * Emits an {Approval} event indicating the updated allowance.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     * - `spender` must have allowance for the caller of at least

     * `subtractedValue`.

     */

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));

        return true;

    }



    /**

     * @dev Moves tokens `amount` from `sender` to `recipient`.

     *

     * This is internal function is equivalent to {transfer}, and can be used to

     * e.g. implement automatic token fees, slashing mechanisms, etc.

     *

     * Emits a {Transfer} event.

     *

     * Requirements:

     *

     * - `sender` cannot be the zero address.

     * - `recipient` cannot be the zero address.

     * - `sender` must have a balance of at least `amount`.

     */

    function _transfer(address sender, address recipient, uint256 amount) internal {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");



        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

    }



    /** @dev Creates `amount` tokens and assigns them to `account`, increasing

     * the total supply.

     *

     * Emits a {Transfer} event with `from` set to the zero address.

     *

     * Requirements

     *

     * - `to` cannot be the zero address.

     */

    function _mint(address account, uint256 amount) internal {

        require(account != address(0), "ERC20: mint to the zero address");



        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);

    }



    /**

     * @dev Destroys `amount` tokens from `account`, reducing the

     * total supply.

     *

     * Emits a {Transfer} event with `to` set to the zero address.

     *

     * Requirements

     *

     * - `account` cannot be the zero address.

     * - `account` must have at least `amount` tokens.

     */

    function _burn(address account, uint256 amount) internal {

        require(account != address(0), "ERC20: burn from the zero address");



        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

    }



    /**

     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.

     *

     * This is internal function is equivalent to `approve`, and can be used to

     * e.g. set automatic allowances for certain subsystems, etc.

     *

     * Emits an {Approval} event.

     *

     * Requirements:

     *

     * - `owner` cannot be the zero address.

     * - `spender` cannot be the zero address.

     */

    function _approve(address owner, address spender, uint256 amount) internal {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");



        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }



    /**

     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted

     * from the caller's allowance.

     *

     * See {_burn} and {_approve}.

     */

    function _burnFrom(address account, uint256 amount) internal {

        _burn(account, amount);

        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));

    }

}



/**

 * @dev Optional functions from the ERC20 standard.

 */

contract ERC20Detailed is IERC20 {

    string private _name;

    string private _symbol;

    uint8 private _decimals;



    /**

     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of

     * these values are immutable: they can only be set once during

     * construction.

     */

    constructor (string memory name, string memory symbol, uint8 decimals) public {

        _name = name;

        _symbol = symbol;

        _decimals = decimals;

    }



    /**

     * @dev Returns the name of the token.

     */

    function name() public view returns (string memory) {

        return _name;

    }



    /**

     * @dev Returns the symbol of the token, usually a shorter version of the

     * name.

     */

    function symbol() public view returns (string memory) {

        return _symbol;

    }



    /**

     * @dev Returns the number of decimals used to get its user representation.

     * For example, if `decimals` equals `2`, a balance of `505` tokens should

     * be displayed to a user as `5,05` (`505 / 10 ** 2`).

     *

     * Tokens usually opt for a value of 18, imitating the relationship between

     * Ether and Wei.

     *

     * > Note that this information is only used for _display_ purposes: it in

     * no way affects any of the arithmetic of the contract, including

     * `IERC20.balanceOf` and `IERC20.transfer`.

     */

    function decimals() public view returns (uint8) {

        return _decimals;

    }

}



interface IFundsDistributionToken {

	/**

	 * @dev Returns the total amount of funds a given address is able to withdraw currently.

	 * @param owner Address of FundsDistributionToken holder

	 * @return A uint256 representing the available funds for a given account

	 */

	function withdrawableFundsOf(address owner) external view returns (uint256);



	/**

	 * @dev Withdraws all available funds for a FundsDistributionToken holder.

	 */

	function withdrawFunds() external;



	/**

	 * @dev This event emits when new funds are distributed

	 * @param by the address of the sender who distributed funds

	 * @param fundsDistributed the amount of funds received for distribution

	 */

	event FundsDistributed(address indexed by, uint256 fundsDistributed);



	/**

	 * @dev This event emits when distributed funds are withdrawn by a token holder.

	 * @param by the address of the receiver of funds

	 * @param fundsWithdrawn the amount of funds that were withdrawn

	 */

	event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn);

}



/** 

 * @title FundsDistributionToken

 * @author Johannes Escherich

 * @author Roger-Wu

 * @author Johannes Pfeffer

 * @author Tom Lam

 * @dev A mintable token that can represent claims on cash flow of arbitrary assets such as dividends, loan repayments, 

 * fee or revenue shares among large numbers of token holders. Anyone can deposit funds, token holders can withdraw.

 * their claims.

 * FundsDistributionToken (FDT) implements the accounting logic. FDT-Extension contracts implement methods for depositing and 

 * withdrawing funds in Ether or according to a token standard such as ERC20, ERC223, ERC777.

 */

contract FundsDistributionToken is ERC20, ERC20Detailed, IFundsDistributionToken {

	using SafeMath for uint256;

	using SafeMathUint for uint256;

	using SafeMathInt for int256;



	// optimize, see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728

	uint256 constant internal pointsMultiplier = 2**128;

	uint256 internal pointsPerShare;



	mapping(address => int256) internal pointsCorrection;

	mapping(address => uint256) internal withdrawnFunds;



	/** 

	 * prev. distributeDividends

	 * @notice Distributes funds to token holders.

	 * @dev It reverts if the total supply of tokens is 0.

	 * It emits the `FundsDistributed` event if the amount of received ether is greater than 0.

	 * About undistributed funds:

	 *   In each distribution, there is a small amount of funds which does not get distributed,

	 *     which is `(msg.value * pointsMultiplier) % totalSupply()`.

	 *   With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed

	 *     in a distribution can be less than 1 (base unit).

	 *   We can actually keep track of the undistributed ether in a distribution

	 *     and try to distribute it in the next distribution ....... todo implement  

	 */

	function _distributeFunds(uint256 value) internal {

		require(totalSupply() > 0, "FundsDistributionToken._distributeFunds: SUPPLY_IS_ZERO");



		if (value > 0) {

			pointsPerShare = pointsPerShare.add(

				value.mul(pointsMultiplier) / totalSupply()

			);

			emit FundsDistributed(msg.sender, value);

		}

	}



	/**

	 * prev. withdrawDividend

	 * @notice Prepares funds withdrawal

	 * @dev It emits a `FundsWithdrawn` event if the amount of withdrawn ether is greater than 0.

	 */

	function _prepareWithdraw() internal returns (uint256) {

		uint256 _withdrawableDividend = withdrawableFundsOf(msg.sender);



		withdrawnFunds[msg.sender] = withdrawnFunds[msg.sender].add(_withdrawableDividend);



		emit FundsWithdrawn(msg.sender, _withdrawableDividend);



		return _withdrawableDividend;

	}



	/** 

	 * prev. withdrawableDividendOf

	 * @notice View the amount of funds that an address can withdraw.

	 * @param _owner The address of a token holder.

	 * @return The amount funds that `_owner` can withdraw.

	 */

	function withdrawableFundsOf(address _owner) public view returns(uint256) {

		return accumulativeFundsOf(_owner).sub(withdrawnFunds[_owner]);

	}



	/**

	 * prev. withdrawnDividendOf

	 * @notice View the amount of funds that an address has withdrawn.

	 * @param _owner The address of a token holder.

	 * @return The amount of funds that `_owner` has withdrawn.

	 */

	function withdrawnFundsOf(address _owner) public view returns(uint256) {

		return withdrawnFunds[_owner];

	}



	/**

	 * prev. accumulativeDividendOf

	 * @notice View the amount of funds that an address has earned in total.

	 * @dev accumulativeFundsOf(_owner) = withdrawableFundsOf(_owner) + withdrawnFundsOf(_owner)

	 * = (pointsPerShare * balanceOf(_owner) + pointsCorrection[_owner]) / pointsMultiplier

	 * @param _owner The address of a token holder.

	 * @return The amount of funds that `_owner` has earned in total.

	 */

	function accumulativeFundsOf(address _owner) public view returns(uint256) {

		return pointsPerShare.mul(balanceOf(_owner)).toInt256Safe()

			.add(pointsCorrection[_owner]).toUint256Safe() / pointsMultiplier;

	}



	/**

	 * @dev Internal function that transfer tokens from one address to another.

	 * Update pointsCorrection to keep funds unchanged.

	 * @param from The address to transfer from.

	 * @param to The address to transfer to.

	 * @param value The amount to be transferred.

	 */

	function _transfer(address from, address to, uint256 value) internal {

		super._transfer(from, to, value);



		int256 _magCorrection = pointsPerShare.mul(value).toInt256Safe();

		pointsCorrection[from] = pointsCorrection[from].add(_magCorrection);

		pointsCorrection[to] = pointsCorrection[to].sub(_magCorrection);

	}



	/**

	 * @dev Internal function that mints tokens to an account.

	 * Update pointsCorrection to keep funds unchanged.

	 * @param account The account that will receive the created tokens.

	 * @param value The amount that will be created.

	 */

	function _mint(address account, uint256 value) internal {

		super._mint(account, value);



		pointsCorrection[account] = pointsCorrection[account]

			.sub( (pointsPerShare.mul(value)).toInt256Safe() );

	}



	/** 

	 * @dev Internal function that burns an amount of the token of a given account.

	 * Update pointsCorrection to keep funds unchanged.

	 * @param account The account whose tokens will be burnt.

	 * @param value The amount that will be burnt.

	 */

	function _burn(address account, uint256 value) internal {

		super._burn(account, value);



		pointsCorrection[account] = pointsCorrection[account]

			.add( (pointsPerShare.mul(value)).toInt256Safe() );

	}

}



contract ClaimToken is lexDAORole, FundsDistributionToken {

	using SafeMathUint for uint256;

	using SafeMathInt for int256;

	

	// fixed message to reference token deployment (e.g., IPFS hash)

	string public stamp;

	

	// token in which the funds can be sent to the FundsDistributionToken

	IERC20 public fundsToken;

	

	// default lexDAO to arbitrate token deployment and offered terms, if any

    address public lexDAO;



	// balance of fundsToken that the FundsDistributionToken currently holds

	uint256 public fundsTokenBalance;



	modifier onlyFundsToken () {

		require(msg.sender == address(fundsToken), "ClaimToken: UNAUTHORIZED_SENDER");

		_;

	}



	constructor(

		string memory name, 

		string memory symbol,

		string memory _stamp,

		uint8 decimals,

		IERC20 _fundsToken,

		address _lexDAO,

        address owner,

        uint256 supply

	) 

		public 

		ERC20Detailed(name, symbol, decimals)

	{

		require(address(_fundsToken) != address(0), "ClaimToken: INVALID_FUNDS_TOKEN_ADDRESS");



        _mint(owner, supply);

        stamp = _stamp;

		fundsToken = _fundsToken;

		lexDAO = _lexDAO;

	}



	/**

	 * @notice Withdraws all available funds for a token holder.

	 */

	function withdrawFunds() 

		external 

	{

		uint256 withdrawableFunds = _prepareWithdraw();



		require(fundsToken.transfer(msg.sender, withdrawableFunds), "ClaimToken: TRANSFER_FAILED");



		_updateFundsTokenBalance();

	}



	/**

	 * @dev Updates the current funds token balance 

	 * and returns the difference of new and previous funds token balances.

	 * @return A int256 representing the difference of the new and previous funds token balance.

	 */

	function _updateFundsTokenBalance() internal returns (int256) {

		uint256 prevFundsTokenBalance = fundsTokenBalance;



		fundsTokenBalance = fundsToken.balanceOf(address(this));



		return int256(fundsTokenBalance).sub(int256(prevFundsTokenBalance));

	}



	/**

	 * @notice Register a payment of funds in tokens. May be called directly after a deposit is made.

	 * @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the previous and the new 

	 * funds token balance and increments the total received funds (cumulative) by delta by calling _registerFunds().

	 */

	function updateFundsReceived() external {

		int256 newFunds = _updateFundsTokenBalance();



		if (newFunds > 0) {

			_distributeFunds(newFunds.toUint256Safe());

		}

	}

	

	/**

     * @dev See {ERC20-_mint}.

     *

     * Requirements:

     *

     * - the caller must have the {lexDAORole}.

     */

    function lexDAOmint(address account, uint256 amount) public onlylexDAO returns (bool) {

        _mint(account, amount);

        return true;

    }    

    

    /**

     * @dev See {ERC20-_burn}.

     * 

     * Requirements:

     *

     * - the caller must have the {lexDAORole}.

     */

    function lexDAOburn(address account, uint256 amount) public onlylexDAO returns (bool) {

        _burn(account, amount);

        return true;

    }

}



/**

 * @dev Factory pattern to clone new claim token contracts with lexDAO arbitration.

 */

contract ClaimTokenFactory {

    // presented by OpenEsquire || lexDAO ~ Use at own risk!

    uint8 public version = 1;

    

    // Factory settings

    string public stamp;

    bool public gated;

    address public deployer;

    

    address payable public _lexDAO; // lexDAO Agent

    

    ClaimToken private CT;

    

    address[] public tokens;

    

    event Deployed(address indexed CT, address indexed owner);

    

    event lexDAOupdated(address indexed newDAO);

    

    constructor (string memory _stamp, bool _gated, address _deployer, address payable lexDAO) public 

	{

        stamp = _stamp;

        gated = _gated;

        deployer = _deployer;

        _lexDAO = lexDAO;

	}

    

    function newClaimToken(

        string memory name, 

		string memory symbol,

		string memory _stamp,

		uint8 decimals,

		IERC20 _fundsToken,

		address owner,

		uint256 supply) public {

       

        if (gated == true) {

            require(msg.sender == deployer);

        }

        

        CT = new ClaimToken(

            name, 

            symbol,

            _stamp,

            decimals,

            _fundsToken,

            _lexDAO, 

            owner,

            supply);

        

        tokens.push(address(CT));

        

        emit Deployed(address(CT), owner);

    }

    

    function tipLexDAO() public payable { // forwards ether (Ξ) tip to lexDAO Agent

        _lexDAO.transfer(msg.value);

    }

    

    function getTokenCount() public view returns (uint256 tokenCount) {

        return tokens.length;

    }

    

    function updateDAO(address payable newDAO) public {

        require(msg.sender == _lexDAO);

        _lexDAO = newDAO;

        

        emit lexDAOupdated(newDAO);

    }

}



/**

 * @dev Factory pattern to clone new claim token factory contracts with lexDAO arbitration.

 */

contract ClaimTokenFactoryMaker {

    // presented by OpenEsquire || lexDAO ~ Use at own risk! 



    address payable public _lexDAO; // lexDAO Agent

    

    ClaimTokenFactory private factory;

    

    address[] public factories; // index of factories

    

    event Deployed(address indexed factory, bool indexed _gated, address indexed deployer);

    

    constructor (address payable lexDAO) public 

	{

        _lexDAO = lexDAO;

	}

    

    function newClaimTokenFactory(string memory _stamp, bool _gated, address _deployer) public {

        factory = new ClaimTokenFactory(_stamp, _gated, _deployer, _lexDAO);

        

        factories.push(address(factory));

        

        emit Deployed(address(factory), _gated, _deployer);

    }

    

    function tipLexDAO() public payable { // forwards ether (Ξ) tip to lexDAO Agent

        _lexDAO.transfer(msg.value);

    }

    

    function getFactoryCount() public view returns (uint256 factoryCount) {

        return factories.length;

    }

    

    function updateDAO(address payable newDAO) public {

        require(msg.sender == _lexDAO);

        _lexDAO = newDAO;

    }

}