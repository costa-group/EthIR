pragma solidity ^0.5.0;

/* Open, ESQ LLC 

This Ethereum smart contract mints 1 CYPHR token for 0.001 ether -- up to 1000 tokens (1 ether Ξ).

No warranties are made with regard to these scarce digital artifacts (other than intrinsic radness).

CYPHR generated hereby reference the IPFS hash of "A Cypherpunk's Manifesto,"
included below:

/*
                   A Cypherpunk's Manifesto

                        by Eric Hughes

Privacy is necessary for an open society in the electronic age.
Privacy is not secrecy.  A private matter is something one doesn't
want the whole world to know, but a secret matter is something one
doesn't want anybody to know. Privacy is the power to selectively
reveal oneself to the world.  

If two parties have some sort of dealings, then each has a memory of
their interaction.  Each party can speak about their own memory of
this; how could anyone prevent it?  One could pass laws against it,
but the freedom of speech, even more than privacy, is fundamental to
an open society; we seek not to restrict any speech at all.  If many
parties speak together in the same forum, each can speak to all the
others and aggregate together knowledge about individuals and other
parties.  The power of electronic communications has enabled such
group speech, and it will not go away merely because we might want it
to.

Since we desire privacy, we must ensure that each party to a
transaction have knowledge only of that which is directly necessary
for that transaction.  Since any information can be spoken of, we
must ensure that we reveal as little as possible.  In most cases
personal identity is not salient. When I purchase a magazine at a
store and hand cash to the clerk, there is no need to know who I am. 
When I ask my electronic mail provider to send and receive messages,
my provider need not know to whom I am speaking or what I am saying
or what others are saying to me;  my provider only need know how to
get the message there and how much I owe them in fees.  When my
identity is revealed by the underlying mechanism of the transaction,
I have no privacy.  I cannot here selectively reveal myself; I must
_always_ reveal myself.

Therefore, privacy in an open society requires anonymous transaction
systems.  Until now, cash has been the primary such system.  An
anonymous transaction system is not a secret transaction system.  An
anonymous system empowers individuals to reveal their identity when
desired and only when desired; this is the essence of privacy.

Privacy in an open society also requires cryptography.  If I say
something, I want it heard only by those for whom I intend it.  If 
the content of my speech is available to the world, I have no
privacy.  To encrypt is to indicate the desire for privacy, and to
encrypt with weak cryptography is to indicate not too much desire for
privacy.  Furthermore, to reveal one's identity with assurance when
the default is anonymity requires the cryptographic signature.

We cannot expect governments, corporations, or other large, faceless
organizations to grant us privacy out of their beneficence.  It is to
their advantage to speak of us, and  we should expect that they will
speak.  To try to prevent their speech is to fight against the
realities of information. Information does not just want to be free,
it longs to be free.  Information expands to fill the available
storage space.  Information is Rumor's younger, stronger cousin;
Information is fleeter of foot, has more eyes, knows more, and
understands less than Rumor.

We must defend our own privacy if we expect to have any.  We must
come together and create systems which allow anonymous transactions
to take place.  People have been defending their own privacy for
centuries with whispers, darkness, envelopes, closed doors, secret
handshakes, and couriers.  The technologies of the past did not allow
for strong privacy, but electronic technologies do.

We the Cypherpunks are dedicated to building anonymous systems.  We
are defending our privacy with cryptography, with anonymous mail
forwarding systems, with digital signatures, and with electronic
money.

Cypherpunks write code.  We know that someone has to write software
to defend privacy, and since we can't get privacy unless we all do,
we're going to write it. We publish our code so that our fellow
Cypherpunks may practice and play with it. Our code is free for all
to use, worldwide.  We don't much care if you don't approve of the
software we write.  We know that software can't be destroyed and that
a widely dispersed system can't be shut down. 

Cypherpunks deplore regulations on cryptography, for encryption is
fundamentally a private act.  The act of encryption, in fact, removes
information from the public realm.  Even laws against cryptography
reach only so far as a nation's border and the arm of its violence.
Cryptography will ineluctably spread over the whole globe, and with
it the anonymous transactions systems that it makes possible. 

For privacy to be widespread it must be part of a social contract.
People must come and together deploy these systems for the common
good.  Privacy only extends so far as the cooperation of one's
fellows in society.  We the Cypherpunks seek your questions and your
concerns and hope we may engage you so that we do not deceive
ourselves.  We will not, however, be moved out of our course because
some may disagree with our goals.

The Cypherpunks are actively engaged in making the networks safer for
privacy.  Let us proceed together apace.

Onward.

Eric Hughes
<hughes@soda.berkeley.edu>

9 March 1993
*/

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
 	* NOTE: This is a feature of the next version of OpenZeppelin Contracts.
 	* @dev Get it via `npm install @openzeppelin/contracts@next`.
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
 	* NOTE: This is a feature of the next version of OpenZeppelin Contracts.
 	* @dev Get it via `npm install @openzeppelin/contracts@next`.
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
 	* NOTE: This is a feature of the next version of OpenZeppelin Contracts.
 	* @dev Get it via `npm install @openzeppelin/contracts@next`.
 	*/
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    	require(b != 0, errorMessage);
    	return a % b;
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
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
	/**
 	* @dev Destroys `amount` tokens from the caller.
 	*
 	* See {ERC20-_burn}.
 	*/
	function burn(uint256 amount) public {
    	_burn(_msgSender(), amount);
	}

	/**
 	* @dev See {ERC20-_burnFrom}.
 	*/
	function burnFrom(address account, uint256 amount) public {
    	_burnFrom(account, amount);
	}
}

/*
 * ERC20 Token representing signatures to Cypherpunk Manifesto
 */
contract CYPHRtoken is ERC20Burnable {
	string public name = "QmRKvmFWDGE4tAf9Xa4HVLZ5FVpxNmtaUcP5dwg2h6XqPM"; // IPFS Hash for Manifesto Copy
	string public symbol = "CYPHR";
	uint8 public decimals = 0;
	uint256 public cap = 1000; // "1000" CYPHR Cap Limit
	uint256 public fee = 1000000000000000; // "0.001" ether (Ξ) rate for 1 CYPHR
	address payable public beneficiary = 0xBBE222Ef97076b786f661246232E41BE0DFf6cc4; // address to receive contributed ether (Ξ)

	/**
	* @dev See `ERC20._mint`.
 	* 
 	* Public function to contribute ether (Ξ) and receive CYPHR
 	*/
	function mint() public payable returns (bool) {
    	require(msg.value == fee);
    	beneficiary.transfer(msg.value);
    	_mint(msg.sender, 1);
    	return true;
	}
    
	/**
 	* @dev See `ERC20Mintable.mint`.
 	*
 	* Requirements:
 	*
 	* - `value` must not cause the total supply to go over the cap.
 	*/
	function _mint(address account, uint256 value) internal {
    	require(totalSupply().add(value) <= cap, "ERC20Capped: cap exceeded");
    	super._mint(account, value);
	}
}