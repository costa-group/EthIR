pragma solidity ^0.6.2;





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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


/**
 * @title Primitive's Contract Interfaces
 * @author Primitive
 */



interface IPrime {
    function balanceOf(address user) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function swap(address receiver) external returns (
        uint256 inTokenS,
        uint256 inTokenP,
        uint256 outTokenU
    );
    function mint(address receiver) external returns (
        uint256 inTokenU,
        uint256 outTokenR
    );
    function redeem(address receiver) external returns (
        uint256 inTokenR
    );
    function close(address receiver) external returns (
        uint256 inTokenR,
        uint256 inTokenP,
        uint256 outTokenU
    );

    function tokenR() external view returns (address);
    function tokenS() external view returns (address);
    function tokenU() external view returns (address);
    function base() external view returns (uint256);
    function price() external view returns (uint256);
    function expiry() external view returns (uint256);
    function cacheU() external view returns (uint256);
    function cacheS() external view returns (uint256);
    function factory() external view returns (address);
    function marketId() external view returns (uint256);
    function maxDraw() external view returns (uint256 draw);
    function getCaches() external view returns (uint256 _cacheU, uint256 _cacheS);
    function getTokens() external view returns (address _tokenU, address _tokenS, address _tokenR);
    function prime() external view returns (
            address _tokenS,
            address _tokenU,
            address _tokenR,
            uint256 _base,
            uint256 _price,
            uint256 _expiry
    );
}

interface IPrimeTrader {
    function safeRedeem(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenR
    );
    function safeSwap(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenS,
        uint256 inTokenP,
        uint256 outTokenU
    );
    function safeMint(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenU,
        uint256 outTokenR
    );
    function safeClose(address tokenP, uint256 amount, address receiver) external returns (
        uint256 inTokenR,
        uint256 inTokenP,
        uint256 outTokenU
    );
}

interface IPrimeRedeem {
    function balanceOf(address user) external view returns (uint);
    function mint(address user, uint256 amount) external payable returns (bool);
    function burn(address user, uint256 amount) external payable returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


/**
 * @title   Primitive's Pool for Writing Short Ether Puts 
 * @author  Primitive
 */



interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface PriceOracleProxy {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

contract PrimePool is Ownable, Pausable, ReentrancyGuard, ERC20 {
    using SafeMath for uint256;

    address public COMPOUND_DAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant ONE_ETHER = 1 ether;

    uint256 public volatility;

    address public oracle;
    address payable public weth;
    
    mapping(uint256 => address) public primes;

    event Market(address tokenP);
    event Deposit(address indexed user, uint256 inTokenU, uint256 outTokenPULP);
    event Withdraw(address indexed user, uint256 outTokenU, uint256 inTokenR);
    event Buy(address indexed user, uint256 inTokenS, uint256 outTokenU, uint256 premium);

    constructor (
        address payable _weth,
        address _oracle,
        string memory name,
        string memory symbol
    ) 
        public
        ERC20(name, symbol)
    {
        weth = _weth;
        oracle = _oracle;
        volatility = 100;
    }

    function addMarket(address tokenP) public onlyOwner returns (address) {
        primes[IPrime(tokenP).marketId()] = tokenP;
        emit Market(tokenP);
        return tokenP;
    }

    function kill() public onlyOwner returns (bool) {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
        return true;
    }

    modifier valid(address tokenP) {
        require(primes[IPrime(tokenP).marketId()] == tokenP, "ERR_PRIME");
        _;
    }


    receive() external payable {
        assert(msg.sender == weth);
    }


    /* =========== MAKER FUNCTIONS =========== */

    /**
     * @dev Adds liquidity by depositing tokenU. Receives tokenPULP.
     * @param amount The quantity of tokenU to deposit.
     * @return bool True if the transaction suceeds.
     */
    function deposit(
        uint256 amount,
        address tokenP
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        // Store locally for gas savings.
        address tokenU = IPrime(tokenP).tokenU();
        if(tokenU == weth) {
            require(msg.value == amount && amount > 0, "ERR_BAL_ETH");
        } else {
            require(IERC20(tokenU).balanceOf(msg.sender) >= amount && amount > 0, "ERR_BAL_UNDERLYING");
        }

        // Mint LP tokens proportional to the Total LP Supply and Total Pool Balance.
        uint256 outTokenPULP;
        uint256 balanceU = IERC20(tokenU).balanceOf(address(this));
        uint256 totalSupply = totalSupply();
         
        // If liquidity is not intiialized, mint LP tokens equal to deposit.
        if(balanceU.mul(totalSupply) == 0) {
            outTokenPULP = amount;
        } else if(amount.mul(totalSupply) < balanceU) {
            require(amount.mul(totalSupply) >= balanceU, "ERR_ZERO");
        } else {
            outTokenPULP = amount.mul(totalSupply).div(balanceU);
        }

        _mint(msg.sender, outTokenPULP);
        emit Deposit(msg.sender, amount, outTokenPULP);

        // Assume we hold the tokenU asset until it is utilized in minting a Prime.
        if(tokenU == weth) {
            IWETH(weth).deposit.value(msg.value)();
            return true;
        } else {
            return IERC20(tokenU).transferFrom(msg.sender, address(this), amount);
        }
    }

    /**
     * @dev liquidity Provider burns their tokenPULP for proportional amount of tokenU + tokenS.
     * @notice  outTokenU = inTokenPULP * balanceU / Total Supply tokenPULP, 
     *          outTokenS = inTokenPULP * balanceR / Total Supply tokenPULP,
     *          If the pool is fully utilized and there are no strike assets to redeem,
     *          the LPs will have to wait for options to be exercised or become expired.
     * @param amount The quantity of liquidity tokens to burn.
     * @param tokenP The address of the Prime option token.
     * @return bool True if liquidity tokens were burned, and both tokenU + tokenS were sent to user.
     */
    function withdraw(
        uint256 amount,
        address tokenP
    ) 
        external
        nonReentrant
        valid(tokenP)
        returns (bool)
    {
        // Check tokenPULP balance.
        require(balanceOf(msg.sender) >= amount && amount > 0, "ERR_BAL_PULP");
        
        // Store Total Supply before we burn
        uint256 totalSupply = totalSupply();

        // Burn tokenPULP.
        _burn(msg.sender, amount);

        // Store locally for gas savings.
        address tokenU = IPrime(tokenP).tokenU();
        address tokenR = IPrime(tokenP).tokenR();

        // outTokenU = inTokenPULP * Balance of tokenU / Total Supply of tokenPULP.
        uint256 outTokenU = amount.mul(IERC20(tokenU).balanceOf(address(this))).div(totalSupply);

        // TokenR:TokenS = 1:1.
        // outTokenR = inTokenPULP * Balance of tokenR / Total Supply of tokenPULP.
        uint256 outTokenR = amount.mul(IERC20(tokenR).balanceOf(address(this))).div(totalSupply);

        // Balance of tokenS in tokenP must be >= outTokenR.
        (uint256 maxDraw) = IPrime(tokenP).maxDraw();
        require(maxDraw >= outTokenR, "ERR_BAL_STRIKE");

        // Send tokenR to tokenP so we can call redeem() later to tokenP.
        (bool success) = IERC20(tokenR).transfer(tokenP, outTokenR);
    
        // Call redeem function to send tokenS to msg.sender.
        (uint256 inTokenR) = IPrime(tokenP).redeem(msg.sender);
        assert(inTokenR == outTokenR && success);

        // Send outTokenU to msg.sender.
        emit Withdraw(msg.sender, outTokenU, outTokenR);
        if(tokenU == weth) {
            IWETH(weth).withdraw(outTokenU);
            return sendEther(msg.sender, outTokenU);
        } else {
            return IERC20(tokenU).transfer(msg.sender, outTokenU);
        }
    }


    /* =========== TAKER FUNCTIONS =========== */


    /**
     * @dev Purchase ETH Put.
     * @notice An eth put is 200 DAI / 1 ETH. The right to swap 1 ETH (tokenS) for 200 Dai (tokenU).
     * As a user, you want to cover ETH, so you pay in ETH. Every 1 Quantity of ETH covers 200 DAI.
     * A user specifies the amount of ETH they want covered, i.e. the amount of ETH they can swap.
     * @param amount The quantity of tokenS (ETH) to 'cover' with an option. Denominated in tokenS (WETH).
     * @return bool True if the msg.sender receives tokenP.
     */
    function buy(
        uint256 amount,
        address tokenP
    )
        external 
        payable
        nonReentrant
        valid(tokenP)
        returns (bool)
    {
        // Store locally for gas savings.
        (
            address _tokenU, // Assume DAI
            address _tokenS, // Assume ETH
            address _tokenR, // Assume Redeemable for DAI 1:1.
            uint256 _base,
            uint256 _price,
            uint256 _expiry
        ) = IPrime(tokenP).prime();

        // Calculates the Intrinsic + Extrinsic value of tokenP.
        volatility = calculateVolatilityProxy(_tokenU, _tokenR, _base, _price);
        (uint256 premium, ) = calculatePremium(_base, _price, _expiry);
        premium = amount.mul(premium).div(ONE_ETHER);

        // Premium is paid in tokenS. If tokenS is WETH, its paid with ETH, which is then swapped to WETH.
        if(_tokenS == weth) {
            require(msg.value >= premium && premium > 0, "ERR_BAL_ETH");
            IWETH(weth).deposit.value(premium)();
            // Refunds remainder.
            sendEther(msg.sender, msg.value.sub(premium));
        } else {
            require(IERC20(_tokenS).balanceOf(msg.sender) >= amount && amount > 0, "ERR_BAL_STRIKE");
        }

        // tokenU = Amount * Quantity of tokenU (base) / Quantity of tokenS (price).
        uint256 outTokenU = amount.mul(_base).div(_price); 

        // Transfer tokenU (assume DAI) to option contract using Pool funds.
        (bool transferU) = IERC20(_tokenU).transfer(tokenP, outTokenU);

        // Mint Prime and Prime Redeem to this contract.
        (uint256 inTokenU,) = IPrime(tokenP).mint(address(this));

        // Send Prime to msg.sender.
        emit Buy(msg.sender, amount, outTokenU, premium);
        return transferU && IPrime(tokenP).transfer(msg.sender, inTokenU);
    }

    /**
     * @dev Calculates the intrinsic + extrinsic value of the option.
     * @notice Strike / Market * (Volatility * 1000) * sqrt(T in seconds remaining) / Seconds in a Day.
     */
    function calculatePremium(uint256 base, uint256 price, uint256 expiry)
        public
        view
        returns (uint256 premium, uint256 timeRemainder)
    {
        // Assume the oracle gets the Price of ETH using compound's oracle for DAI per ETH.
        // Price = ETH per DAI.
        uint256 market = PriceOracleProxy(oracle).getUnderlyingPrice(COMPOUND_DAI);
        // Strike price of DAI per ETH. ETH / DAI = price of dai per eth, then scaled to 10^18 units.
        uint256 strike = price.mul(ONE_ETHER).div(base);
        // Difference = Base * market price / strike price.
        uint256 difference = base.mul(market).div(strike);
        // Intrinsic value in DAI.
        uint256 intrinsic = difference >= base ? difference.sub(base) : 0;
        // Time left in seconds.
        timeRemainder = (expiry.sub(block.timestamp));
        // Strike / market scaled to 1e18.
        uint256 moneyness = strike.mul(ONE_ETHER).div(market);
        // Extrinsic value in DAI.
        uint256 extrinsic = moneyness
                            .mul(ONE_ETHER)
                            .mul(volatility)
                            .mul(sqrt(timeRemainder))
                                .div(ONE_ETHER)
                                .div(SECONDS_IN_DAY);
        // Total Premium in ETH.
        premium = (extrinsic.add(intrinsic)).mul(market).div(ONE_ETHER);
    }

    /**
     * @dev Calculates the Pool's Utilization to use as a proxy for volatility.
     * @notice If Pool is not utilized at all, the default volatility is 100.
     */
    function calculateVolatilityProxy(address tokenU, address tokenR, uint256 base, uint256 price)
        public
        view
        returns (uint256 _volatility)
    {
        (uint256 utilized) = poolUtilized(tokenR, base, price);
        uint256 balanceU = IERC20(tokenU).balanceOf(address(this));
        _volatility = utilized > 0 ?
                        utilized
                        .mul(1000)
                        .div(balanceU.add(utilized)) :
                        100;

    }

    /**
     * @dev Calculates the utilization of the Pool based on the proportion of tokenR owned.
     */
    function poolUtilized(address tokenR, uint256 base, uint256 price) public view returns (uint256 utilized) {
        utilized = IERC20(tokenR).balanceOf(address(this))
                    .mul(price)
                    .mul(ONE_ETHER)
                    .div(base)
                    .div(ONE_ETHER);
    }

    /**
     * @dev Utility function to send ethers safely.
     */
    function sendEther(address to, uint256 amount) private returns (bool) {
        (bool success, ) = to.call.value(amount)("");
        require(success, "ERR_SEND_ETHER");
        return success;
    }

    /**
     * @dev Utility function to calculate the square root of an integer. Used in calculating premium.
     */
    function sqrt(uint256 y) public pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}