/*
|| THE LEXDAO REGISTRY (TLDR) || version 0.3

DEAR MSG.SENDER(S):

/ TLDR is a project in beta.
// Please audit and use at your own risk.
/// Entry into TLDR shall not create an attorney/client relationship.
//// Likewise, TLDR should not be construed as legal advice or replacement for professional counsel.

///// STEAL THIS C0D3SL4W 

|| lexDAO || 
~presented by Open, ESQ LLC_DAO~
< https://mainnet.aragon.org/#/openesquire/ >
*/

pragma solidity 0.5.9;

/***************
OPENZEPPELIN REFERENCE CONTRACTS - SafeMath, ScribeRole, ERC-20 transactional scripts
***************/
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

contract ScribeRole is Context {
    using Roles for Roles.Role;

    event ScribeAdded(address indexed account);
    event ScribeRemoved(address indexed account);

    Roles.Role private _Scribes;

    constructor () internal {
        _addScribe(_msgSender());
    }

    modifier onlyScribe() {
        require(isScribe(_msgSender()), "ScribeRole: caller does not have the Scribe role");
        _;
    }

    function isScribe(address account) public view returns (bool) {
        return _Scribes.has(account);
    }

    function renounceScribe() public {
        _removeScribe(_msgSender());
    }

    function _addScribe(address account) internal {
        _Scribes.add(account);
        emit ScribeAdded(account);
    }

    function _removeScribe(address account) internal {
        _Scribes.remove(account);
        emit ScribeRemoved(account);
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

/***************
TLDR CONTRACT
***************/
contract TLDR is ScribeRole, ERC20 { // TLDR: Curated covenant & escrow scriptbase with incentivized arbitration 
    using SafeMath for uint256;
    
    // lexDAO reference for lexScribe reputation governance fees (Ξ)
    address payable public lexDAO;
	
    // TLDR (LEX) ERC-20 token references 
    address public tldrAddress = address(this);
    ERC20 tldrToken = ERC20(tldrAddress); 
    
    string public name = "TLDR";
    string public symbol = "LEX";
    uint8 public decimals = 18;
	
    // counters for lexScribe lexScriptWrapper and registered DR (rdr) / DC (rdc)
    uint256 public LSW; // number of lexScriptWrapper enscribed 
    uint256 public RDC; // number of rdc
    uint256 public RDR; // number of rdr
	
    // mapping for lexScribe reputation governance program
    mapping(address => uint256) public reputation; // mapping lexScribe reputation points 
    mapping(address => uint256) public lastActionTimestamp; // mapping Unix timestamp of lexScribe governance actions (cooldown)
    mapping(address => uint256) public lastSuperActionTimestamp; // mapping Unix timestamp of material lexScribe governance actions requiring longer cooldown (icedown)
    
    // mapping for stored lexScript wrappers and registered digital retainers (DR / rdr)
    mapping (uint256 => lexScriptWrapper) public lexScript; // mapping registered lexScript 'wet code' templates
    mapping (uint256 => DC) public rdc; // mapping rdc call numbers for inspection and signature revocation
    mapping (uint256 => DR) public rdr; // mapping rdr call numbers for inspection and scripted payments
	
    struct lexScriptWrapper { // LSW: rdr lexScript templates maintained by lexScribes
        address lexScribe; // lexScribe (0x) address that enscribed lexScript template into TLDR / can make subsequent edits (lexVersion)
        address lexAddress; // (0x) address to receive lexScript wrapper lexFee / adjustable by associated lexScribe
        string templateTerms; // lexScript template terms to wrap rdr with legal security
        uint256 lexID; // number to reference in rdr to import lexScript terms
        uint256 lexVersion; // version number to mark lexScribe edits
        uint256 lexRate; // fixed divisible rate for lexFee in drToken per rdr payment made thereunder / e.g., 100 = 1% lexFee on rdr payDR transaction
    }
        
    struct DC { // Digital Covenant lexScript templates maintained by lexScribes
        address signatory; // DC signatory (0x) address
        string templateTerms; // DC templateTerms imported from referenced lexScriptWrapper
        string signatureDetails; // DC may include signatory name or other supplementary info
        uint256 lexID; // lexID number reference to include lexScriptWrapper for legal security 
        uint256 dcNumber; // DC number generated on signed covenant registration / identifies DC for signatory revocation 
        uint256 timeStamp; // block.timestamp ("now") of DC registration 
        bool revoked; // tracks signatory revocation status on DC
    }
    	
    struct DR { // Digital Retainer created on lexScript terms maintained by lexScribes / data registered for escrow script 
        address client; // rdr client (0x) address
        address provider; // provider (0x) address that receives ERC-20 payments in exchange for goods or services (deliverable)
        address drToken; // ERC-20 digital token (0x) address used to transfer value on Ethereum under rdr 
        string deliverable; // description of deliverable retained for benefit of Ethereum payments
        uint256 lexID; // lexID number reference to include lexScriptWrapper for legal security / default '1' for generalized rdr lexScript template
        uint256 drNumber; // rdr number generated on DR registration / identifies rdr for payDR function calls
        uint256 timeStamp; // block.timestamp ("now") of registration used to calculate retainerTermination UnixTime
        uint256 retainerTermination; // termination date of rdr in UnixTime / locks payments to provider / after, remainder can be withrawn by client
        uint256 deliverableRate; // rate for rdr deliverables in wei amount / 1 = 1000000000000000000
        uint256 paid; // tracking amount of designated ERC-20 digital value paid under rdr in wei amount for payCap logic
        uint256 payCap; // value cap limit on rdr payments in wei amount 
        bool confirmed; // tracks client countersignature status
        bool disputed; // tracks dispute status from client or provider / if called, locks remainder of escrow rdr payments for reputable lexScribe resolution
    }
    	
    constructor(string memory tldrTerms, uint256 tldrLexRate, address tldrLexAddress, address payable _lexDAO) public { // deploys TLDR contract & stores base lexScript
	    reputation[msg.sender] = 1; // sets TLDR summoner lexScribe reputation to '1' initial value
	    lexDAO = _lexDAO; // sets initial lexDAO (0x) address 
	
	    LSW = LSW.add(1); // counts initial 'tldr' entry to LSW
	    
	    lexScript[1] = lexScriptWrapper( // populates default '1' lexScript data for reference in LSW and rdr
                msg.sender,
                tldrLexAddress,
                tldrTerms,
                1,
                0,
                tldrLexRate);
    }
        
    // TLDR Contract Events
    event Enscribed(uint256 indexed lexID, uint256 indexed lexVersion, address indexed lexScribe); // triggered on successful LSW creation / edits to LSW
    event Signed(uint256 indexed lexID, uint256 indexed dcNumber, address indexed signatory); // triggered on successful DC creation / edits to DC 
    event Registered(uint256 indexed drNumber, uint256 indexed lexID, address indexed provider); // triggered on successful rdr 
    event Confirmed(uint256 indexed drNumber, uint256 indexed lexID, address indexed client); // triggered on successful rdr confirmation
    event Paid(uint256 indexed drNumber, uint256 indexed lexID); // triggered on successful rdr payments
    event Disputed(uint256 indexed drNumber); // triggered on rdr dispute
    event Resolved(uint256 indexed drNumber); // triggered on successful rdr dispute resolution
    
    /***************
    TLDR GOVERNANCE FUNCTIONS
    ***************/   
    // restricts lexScribe TLDR reputation governance function calls to once per day (cooldown)
    modifier cooldown() {
        require(now.sub(lastActionTimestamp[msg.sender]) > 1 days); // enforces cooldown period
        _;
        
	    lastActionTimestamp[msg.sender] = now; // block.timestamp, "now"
    }
        
    // restricts material lexScribe TLDR reputation staking and lexDAO governance function calls to once per 90 days (icedown)
    modifier icedown() {
        require(now.sub(lastSuperActionTimestamp[msg.sender]) > 90 days); // enforces icedown period
        _;
        
	    lastSuperActionTimestamp[msg.sender] = now; // block.timestamp, "now"
    }
    
    // lexDAO can add new lexScribe to maintain TLDR
    function addScribe(address account) public {
        require(msg.sender == lexDAO);
        _addScribe(account);
	    reputation[account] = 1;
    }
    
    // lexDAO can remove lexScribe from TLDR / slash reputation
    function removeScribe(address account) public {
        require(msg.sender == lexDAO);
        _removeScribe(account);
	    reputation[account] = 0;
    }
    
    // lexDAO can update (0x) address receiving reputation governance stakes (Ξ) / maintaining lexScribe registry
    function updateLexDAO(address payable newLexDAO) public {
    	require(msg.sender == lexDAO);
        require(newLexDAO != address(0)); // program safety check / newLexDAO cannot be "0" burn address
        
	    lexDAO = newLexDAO; // updates lexDAO (0x) address
    }
        
    // lexScribes can submit ether (Ξ) value for TLDR reputation and special TLDR function access (TLDR write privileges, rdr dispute resolution role) 
    function submitETHreputation() payable public onlyScribe icedown {
        require(msg.value == 0.1 ether); // tenth of ether (Ξ) fee for refreshing reputation in lexDAO
        
	    reputation[msg.sender] = 3; // sets / refreshes lexScribe reputation to '3' max value, 'three strikes, you're out' buffer
        
	    address(lexDAO).transfer(msg.value); // transfers ether value (Ξ) to designated lexDAO (0x) address
    }
    
    // lexScribes can burn minted LEX value for TLDR reputation 
    function submitLEXreputation() public onlyScribe icedown { 
	    _burn(_msgSender(), 10000000000000000000); // 10 LEX burned 
        
	    reputation[msg.sender] = 3; // sets / refreshes lexScribe reputation to '3' max value, 'three strikes, you're out' buffer
    }
         
    // public check on lexScribe reputation status
    function isReputable(address x) public view returns (bool) { // returns true if lexScribe is reputable
        return reputation[x] > 0;
    }
        
    // reputable lexScribes can reduce reputation within cooldown period 
    function reduceScribeRep(address reducedLexScribe) cooldown public {
        require(isReputable(msg.sender)); // program governance check / lexScribe must be reputable
        require(msg.sender != reducedLexScribe); // program governance check / cannot reduce own reputation
        
	    reputation[reducedLexScribe] = reputation[reducedLexScribe].sub(1); // reduces reputation by "1"
    }
        
    // reputable lexScribes can repair reputation within cooldown period
    function repairScribeRep(address repairedLexScribe) cooldown public {
        require(isReputable(msg.sender)); // program governance check / lexScribe must be reputable
        require(msg.sender != repairedLexScribe); // program governance check / cannot repair own reputation
        require(reputation[repairedLexScribe] < 3); // program governance check / cannot repair fully reputable lexScribe
        require(reputation[repairedLexScribe] > 0); // program governance check / cannot repair disreputable lexScribe 
        
	    reputation[repairedLexScribe] = reputation[repairedLexScribe].add(1); // repairs reputation by "1"
    }
       
    /***************
    TLDR LEXSCRIBE FUNCTIONS
    ***************/
    // reputable lexScribes can register lexScript legal wrappers on TLDR and program ERC-20 lexFees associated with lexID / LEX mint, "1"
    function writeLexScript(string memory templateTerms, uint256 lexRate, address lexAddress) public {
        require(isReputable(msg.sender)); // program governance check / lexScribe must be reputable 
	
	    uint256 lexID = LSW.add(1); // reflects new lexScript value for tracking lexScript wrappers
	    LSW = LSW.add(1); // counts new entry to LSW 
	    
	    lexScript[lexID] = lexScriptWrapper( // populate lexScript data for rdr / rdc usage
                msg.sender,
                lexAddress,
                templateTerms,
                lexID,
                0,
                lexRate);
                
        _mint(msg.sender, 1000000000000000000); // mints lexScribe "1" LEX for contribution to TLDR
	
        emit Enscribed(lexID, 0, msg.sender); 
    }
	    
    // lexScribes can update TLDR lexScript wrappers with new templateTerms and (0x) newLexAddress / version up LSW
    function editLexScript(uint256 lexID, string memory templateTerms, address lexAddress) public {
	    lexScriptWrapper storage lS = lexScript[lexID]; // retrieve LSW data
	
	    require(msg.sender == lS.lexScribe); // program safety check / authorization 
	
	    uint256 lexVersion = lS.lexVersion.add(1); // updates lexVersion 
	    
	    lexScript[lexID] = lexScriptWrapper( // populates updated lexScript data for rdr / rdc usage
                msg.sender,
                lexAddress,
                templateTerms,
                lexID,
                lexVersion,
                lS.lexRate);
                	
        emit Enscribed(lexID, lexVersion, msg.sender);
    }

    /***************
    TLDR MARKET FUNCTIONS
    ***************/
    // public can sign and associate (0x) identity with lexScript digital covenant wrapper 
    function signDC(uint256 lexID, string memory signatureDetails) public { // sign Digital Covenant with (0x) address
	    require(lexID > (0)); // program safety check
	    require(lexID <= LSW); // program safety check
	    lexScriptWrapper storage lS = lexScript[lexID]; // retrieve LSW data
	
	    uint256 dcNumber = RDC.add(1); // reflects new rdc value for public inspection and signature revocation
	    RDC = RDC.add(1); // counts new entry to RDC
	        
	    rdc[dcNumber] = DC( // populates rdc data
                msg.sender,
                lS.templateTerms,
                signatureDetails,
                lexID,
                dcNumber,
                now, 
                false);
                	
        emit Signed(lexID, dcNumber, msg.sender);
    }
    	
    // registered DC signatories can revoke (0x) signature  
    function revokeDC(uint256 dcNumber) public { // revoke Digital Covenant signature with (0x) address
	    DC storage dc = rdc[dcNumber]; // retrieve rdc data
	
	    require(msg.sender == dc.signatory); // program safety check / authorization
	    
	    rdc[dcNumber] = DC(// updates rdc data
                msg.sender,
                "Signature Revoked", // replaces Digital Covenant terms with revocation message
                dc.signatureDetails,
                dc.lexID,
                dc.dcNumber,
                now, // updates to revocation block.timestamp
                true); // reflects revocation status
                	
        emit Signed(dc.lexID, dcNumber, msg.sender);
    }
    
    // goods and/or service providers can register DR with TLDR lexScript (lexID) 
    function registerDR( // rdr 
    	address client,
    	address drToken,
    	string memory deliverable,
        uint256 retainerDuration,
    	uint256 deliverableRate,
    	uint256 payCap,
    	uint256 lexID) public {
    	require(lexID > (0)); // program safety check 
    	require(lexID <= LSW); // program safety check 
        require(deliverableRate <= payCap); // program safety check / economics
        
	    uint256 drNumber = RDR.add(1); // reflects new rdr value for inspection and escrow management
        uint256 retainerTermination = now.add(retainerDuration); // rdr termination date in UnixTime, "now" block.timestamp + retainerDuration

	    RDR = RDR.add(1); // counts new entry to RDR
                
            rdr[drNumber] = DR( // populate rdr data 
                client,
                msg.sender,
                drToken,
                deliverable,
                lexID,
                drNumber,
                now, // block.timestamp, "now"
                retainerTermination,
                deliverableRate,
                0,
                payCap,
                false,
                false);
        	 
        emit Registered(drNumber, lexID, msg.sender); 
    }

    // rdr client can confirm rdr offer script and countersign drNumber / trigger escrow deposit in approved payCap amount
    function confirmDR(uint256 drNumber) public {
        DR storage dr = rdr[drNumber]; // retrieve rdr data

        require(dr.confirmed == false); // program safety check / status
        require(now <= dr.retainerTermination); // program safety check / time
        require(msg.sender == dr.client); // program safety check / authorization
        
        dr.confirmed = true; // reflect rdr client countersignature
        ERC20 drTokenERC20 = ERC20(dr.drToken);
        drTokenERC20.transferFrom(msg.sender, address(this), dr.payCap); // escrows payCap amount in approved drToken into TLDR 
    
        emit Confirmed(drNumber, dr.lexID, msg.sender);
    }
         
    // rdr client can call to delegate role
    function delegateDRclient(uint256 drNumber, address clientDelegate) public {
        DR storage dr = rdr[drNumber]; // retrieve rdr data
        
        require(dr.disputed == false); // program safety check / status
        require(now <= dr.retainerTermination); // program safety check / time
        require(msg.sender == dr.client); // program safety check / authorization
        require(dr.paid < dr.payCap); // program safety check / economics
        
        dr.client = clientDelegate; // updates rdr client address to delegate
    }
    
    // rdr parties can initiate dispute and lock escrowed remainder of rdr payCap in TLDR until resolution by reputable lexScribe
    function disputeDR(uint256 drNumber) public {
        DR storage dr = rdr[drNumber]; // retrieve rdr data
        
        require(dr.confirmed == true); // program safety check / status
	    require(dr.disputed == false); // program safety check / status
        require(now <= dr.retainerTermination); // program safety check / time
        require(msg.sender == dr.client || msg.sender == dr.provider); // program safety check / authorization
	    require(dr.paid < dr.payCap); // program safety check / economics
        
	    dr.disputed = true; // updates rdr value to reflect dispute status, "true"
	    
	    emit Disputed(drNumber);
    }
    
    // reputable lexScribe can resolve rdr dispute with division of remaining payCap amount in wei accounting for 5% fee / LEX mint, "1"
    function resolveDR(uint256 drNumber, uint256 clientAward, uint256 providerAward) public {
        DR storage dr = rdr[drNumber]; // retrieve rdr data
	
	    uint256 remainder = dr.payCap.sub(dr.paid); // alias remainder rdr wei amount for rdr resolution reference
	    uint256 resolutionFee = remainder.div(20); // calculates 5% lexScribe dispute resolution fee
	
	    require(dr.disputed == true); // program safety check / status
	    require(clientAward.add(providerAward) == remainder.sub(resolutionFee)); // program safety check / economics
        require(msg.sender != dr.client); // program safety check / authorization / client cannot resolve own dispute as lexScribe
        require(msg.sender != dr.provider); // program safety check / authorization / provider cannot resolve own dispute as lexScribe
        require(isReputable(msg.sender)); // program governance check / resolving lexScribe must be reputable
	    require(balanceOf(msg.sender) >= 5000000000000000000); // program governance check / resolving lexScribe must have at least "5" LEX balance
	
        ERC20 drTokenERC20 = ERC20(dr.drToken);
        drTokenERC20.transfer(dr.client, clientAward); // executes ERC-20 award transfer to rdr client
        drTokenERC20.transfer(dr.provider, providerAward); // executes ERC-20 award transfer to rdr provider
    	drTokenERC20.transfer(msg.sender, resolutionFee); // executes ERC-20 fee transfer to resolving lexScribe
    	
    	_mint(msg.sender, 1000000000000000000); // mints resolving lexScribe "1" LEX for contribution to TLDR
	
	    dr.paid = dr.paid.add(remainder); // tallies remainder to paid wei amount to reflect rdr closure
	    
	    emit Resolved(drNumber);
    }
    
    // client can call to pay rdr on TLDR
    function payDR(uint256 drNumber) public { // releases escrowed drToken deliverableRate amount to provider (0x) address / lexFee for attached lexID lexAddress
    	DR storage dr = rdr[drNumber]; // retrieve rdr data
    	lexScriptWrapper storage lS = lexScript[dr.lexID]; // retrieve LSW data
	
	    require(dr.confirmed == true); // program safety check / status
	    require(dr.disputed == false); // program safety check / status
    	require(now <= dr.retainerTermination); // program safety check / time
    	require(msg.sender == dr.client); // program safety check / authorization
    	require(dr.paid.add(dr.deliverableRate) <= dr.payCap); // program safety check / economics
	
    	uint256 lexFee = dr.deliverableRate.div(lS.lexRate); // derives lexFee from rdr deliverableRate
	
        ERC20 drTokenERC20 = ERC20(dr.drToken);
    	drTokenERC20.transfer(dr.provider, dr.deliverableRate.sub(lexFee)); // executes ERC-20 transfer to rdr provider in deliverableRate amount
    	drTokenERC20.transfer(lS.lexAddress, lexFee); // executes ERC-20 transfer of lexFee to (0x) lexAddress identified in lexID
    	dr.paid = dr.paid.add(dr.deliverableRate); // tracks total ERC-20 wei amount paid under rdr / used to calculate rdr remainder
        
	    emit Paid(drNumber, dr.lexID); 
    }
    
    // client can call to withdraw rdr remainder on TLDR after termination
    function withdrawRemainder(uint256 drNumber) public {  
    	DR storage dr = rdr[drNumber]; // retrieve rdr data
	
        require(dr.confirmed == true); // program safety check / status
        require(dr.disputed == false); // program safety check / status
    	require(now >= dr.retainerTermination); // program safety check / time
    	require(msg.sender == dr.client); // program safety check / authorization
    	
    	uint256 remainder = dr.payCap.sub(dr.paid); // derive rdr remainder
    	ERC20 drTokenERC20 = ERC20(dr.drToken);

    	require(remainder > 0); // program safety check / economics
	
    	drTokenERC20.transfer(dr.client, remainder); // executes ERC-20 transfer to rdr client in escrow remainder amount
    	
    	dr.paid = dr.paid.add(remainder); // tallies remainder to paid wei amount to reflect rdr closure
    }
}