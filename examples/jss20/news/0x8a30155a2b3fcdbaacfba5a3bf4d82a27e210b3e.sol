// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: @trusttoken/registry/contracts/Registry.sol

pragma solidity ^0.5.13;


interface RegistryClone {
    function syncAttributeValue(address _who, bytes32 _attribute, uint256 _value) external;
}

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }
    
    // never remove any storage variables
    address public owner;
    address public pendingOwner;
    bool initialized;

    // Stores arbitrary attributes for users. An example use case is an IERC20
    // token that requires its users to go through a KYC/AML check - in this case
    // a validator can set an account's "hasPassedKYC/AML" attribute to 1 to indicate
    // that account can use the token. This mapping stores that value (1, in the
    // example) as well as which validator last set the value and at what time,
    // so that e.g. the check can be renewed at appropriate intervals.
    mapping(address => mapping(bytes32 => AttributeData)) attributes;
    // The logic governing who is allowed to set what attributes is abstracted as
    // this accessManager, so that it may be replaced by the owner as needed
    bytes32 constant WRITE_PERMISSION = keccak256("canWriteTo-");
    mapping(bytes32 => RegistryClone[]) subscribers;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);
    event StartSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);
    event StopSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);

    // Allows a write if either a) the writer is that Registry's owner, or
    // b) the writer is writing to attribute foo and that writer already has
    // the canWriteTo-foo attribute set (in that same Registry)
    function confirmWrite(bytes32 _attribute, address _admin) internal view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(abi.encodePacked(WRITE_PERMISSION ^ _attribute))));
    }

    // Writes are allowed only if the accessManager approves
    function setAttribute(address _who, bytes32 _attribute, uint256 _value, bytes32 _notes) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);

        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index --> 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    function subscribe(bytes32 _attribute, RegistryClone _syncer) external onlyOwner {
        subscribers[_attribute].push(_syncer);
        emit StartSubscription(_attribute, _syncer);
    }

    function unsubscribe(bytes32 _attribute, uint256 _index) external onlyOwner {
        uint256 length = subscribers[_attribute].length;
        require(_index < length);
        emit StopSubscription(_attribute, subscribers[_attribute][_index]);
        subscribers[_attribute][_index] = subscribers[_attribute][length - 1];
        subscribers[_attribute].length = length - 1;
    }

    function subscriberCount(bytes32 _attribute) public view returns (uint256) {
        return subscribers[_attribute].length;
    }

    function setAttributeValue(address _who, bytes32 _attribute, uint256 _value) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index --> 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    // Returns true if the uint256 value stored for this attribute is non-zero
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }


    // Returns the exact value of the attribute, as well as its metadata
    function getAttribute(address _who, bytes32 _attribute) public view returns (uint256, bytes32, address, uint256) {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function syncAttribute(bytes32 _attribute, uint256 _startIndex, address[] calldata _addresses) external {
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index --> _startIndex) {
            RegistryClone target = targets[index];
            for (uint256 i = _addresses.length; i --> 0; ) {
                address who = _addresses[i];
                target.syncAttributeValue(who, _attribute, attributes[who][_attribute].value);
            }
        }
    }

    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

   /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/TrueCurrencies/modularERC20/InstantiatableOwnable.sol

pragma solidity ^0.5.13;


/**
 * @title InstantiatableOwnable
 * @dev The InstantiatableOwnable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract InstantiatableOwnable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The InstantiatableOwnable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/TrueCurrencies/modularERC20/Claimable.sol

pragma solidity ^0.5.13;



/**
 * @title Claimable
 * @dev Extension for the InstantiatableOwnable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is InstantiatableOwnable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/TrueCurrencies/modularERC20/BalanceSheet.sol

pragma solidity ^0.5.13;



// A wrapper around the balanceOf mapping.
contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }
}

// File: contracts/TrueCurrencies/modularERC20/AllowanceSheet.sol

pragma solidity ^0.5.13;



// A wrapper around the allowanceOf mapping.
contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

// File: contracts/TrueReward/FinancialOpportunity.sol

pragma solidity ^0.5.13;

/**
 * @title FinancialOpportunity
 * @dev Interface for third parties to implement financial opportunities
 *
 * -- Overview --
 * The goal of this contract is to allow anyone to create an opportunity
 * to earn interest on TUSD. deposit() "mints" yTUSD whcih is redeemable
 * for some amount of TUSD. TrueUSD wraps this contractwith TrustToken
 * Assurance, which provides protection from bugs and system design flaws
 * TUSD is a compliant stablecoin, therefore we do not allow transfers of
 * yTUSD, thus there are no transfer functions
 *
 * -- tokenValue() --
 * This function returns the value in TUSD of 1 yTUSD
 * This value should never decrease
 *
 * -- TUSD vs yTUSD --
 * yTUSD represents a fixed value which is redeemable for some amount of TUSD
 * Think of yTUSD like cTUSD, where cTokens are minted and increase in value versus
 * the underlying asset as interest is accrued
 *
 * -- totalSupply() --
 * This function returns the total supply of yTUSD issued by this contract
 * It is important to track this value accuratley and add/deduct the correct
 * amount on deposit/redemptions
 *
 * -- Assumptions --
 * - tokenValue can never decrease
 * - total TUSD owed to depositors = tokenValue() * totalSupply()
 */
interface FinancialOpportunity {

    /**
     * @dev Returns total supply of yTUSD in this contract
     *
     * @return total supply of yTUSD in this contract
    **/
    function totalSupply() external view returns (uint);

    /**
     * @dev Exchange rate between TUSD and yTUSD
     *
     * tokenValue should never decrease
     *
     * @return TUSD / yTUSD price ratio
     */
    function tokenValue() external view returns(uint);

    /**
     * @dev deposits TrueUSD and returns yTUSD minted
     *
     * We can think of deposit as a minting function which
     * will increase totalSupply of yTUSD based on the deposit
     *
     * @param from account to transferFrom
     * @param amount amount in TUSD to deposit
     * @return yTUSD minted from this deposit
     */
    function deposit(address from, uint amount) external returns(uint);

    /**
     * @dev Redeem yTUSD for TUSD and withdraw to account
     *
     * This function should use tokenValue to calculate
     * how much TUSD is owed. This function should burn yTUSD
     * after redemption
     *
     * This function must return value in TUSD
     *
     * @param to account to transfer TUSD for
     * @param amount amount in TUSD to withdraw from finOp
     * @return TUSD amount returned from this transaction
     */
    function redeem(address to, uint amount) external returns(uint);
}

// File: contracts/TrueCurrencies/ProxyStorage.sol

pragma solidity ^0.5.13;





/*
Defines the storage layout of the token implementation contract. Any newly declared
state variables in future upgrades should be appended to the bottom. Never remove state variables
from this list
 */
contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool initialized;

    BalanceSheet balances_Deprecated;
    AllowanceSheet allowances_Deprecated;

    uint256 totalSupply_;

    bool private paused_Deprecated = false;
    address private globalPause_Deprecated;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    Registry public registry;

    string name_Deprecated;
    string symbol_Deprecated;

    uint[] gasRefundPool_Deprecated;
    uint256 private redemptionAddressCount_Deprecated;
    uint256 public minimumGasPriceForFutureRefunds;

    mapping (address => uint256) _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    mapping (bytes32 => mapping (address => uint256)) attributes;

    // reward token storage
    mapping(address => FinancialOpportunity) finOps;
    mapping(address => mapping(address => uint256)) finOpBalances;
    mapping(address => uint256) finOpSupply;

    // true reward allocation
    // proportion: 1000 = 100%
    struct RewardAllocation { uint proportion; address finOp; }
    mapping(address => RewardAllocation[]) _rewardDistribution;
    uint256 maxRewardProportion = 1000;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     ** 19         "trueXXX.proxy.owner"                                         Proxy Owner
     ** 27         "trueXXX.pending.proxy.owner"                                 Pending Proxy Owner
     ** 28         "trueXXX.proxy.implementation"                                Proxy Implementation
     ** 32         uint256(11)                                                   gasRefundPool_Deprecated
     ** 64         uint256(address),uint256(14)                                  balanceOf
     ** 64         uint256(address),keccak256(uint256(address),uint256(15))      allowance
     ** 64         uint256(address),keccak256(bytes32,uint256(16))               attributes
    **/
}

// File: contracts/TrueCurrencies/HasOwner.sol

pragma solidity ^0.5.13;


/**
 * @title HasOwner
 * @dev The HasOwner contract is a copy of Claimable Contract by Zeppelin.
 and provides basic authorization control functions. Inherits storage layout of
 ProxyStorage.
 */
contract HasOwner is ProxyStorage {

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev sets the original `owner` of the contract to the sender
    * at construction. Must then be reinitialized
    */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/TrueCurrencies/TrueCoinReceiver.sol

pragma solidity ^0.5.13;

contract TrueCoinReceiver {
    function tokenFallback( address from, uint256 value ) external;
}

// File: contracts/TrueCurrencies/ReclaimerToken.sol

pragma solidity ^0.5.13;


contract ReclaimerToken is HasOwner {
    /**
    *@dev send all eth balance in the contract to another address
    */
    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
    *@dev send all token balance of an arbitary erc20 token
    in the contract to another address
    */
    function reclaimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

    /**
    *@dev allows owner of the contract to gain ownership of any contract that the contract currently owns
    */
    function reclaimContract(InstantiatableOwnable _ownable) external onlyOwner {
        _ownable.transferOwnership(owner);
    }
}

// File: contracts/TrueCurrencies/modularERC20/InitializableOwnable.sol

pragma solidity ^0.5.13;


/**
 * @title InitializableOwnable
 * @dev The InitializableOwnable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract InitializableOwnable {
    address public owner;
    bool configured = false;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The InitializableOwnable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function _configure() internal {
        require(!configured);
        owner = msg.sender;
        configured = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/TrueCurrencies/modularERC20/InitializableClaimable.sol

pragma solidity ^0.5.13;



/**
 * @title InitializableOwnable
 * @dev Extension for the InstantiatableOwnable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract InitializableClaimable is InitializableOwnable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/TrueCurrencies/modularERC20/ModularBasicToken.sol

pragma solidity ^0.5.13;





// Fork of OpenZeppelin's BasicToken
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract ModularBasicToken is HasOwner {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _who) public view returns (uint256) {
        return _getBalance(_who);
    }

    function _getBalance(address _who) internal view returns (uint256) {
        return _balanceOf[_who];
    }

    function _addBalance(address _who, uint256 _value) internal returns (uint256 priorBalance) {
        priorBalance = _balanceOf[_who];
        _balanceOf[_who] = priorBalance.add(_value);
    }

    function _subBalance(address _who, uint256 _value) internal returns (uint256 result) {
        result = _balanceOf[_who].sub(_value);
        _balanceOf[_who] = result;
    }

    function _setBalance(address _who, uint256 _value) internal {
        _balanceOf[_who] = _value;
    }
}

// File: contracts/TrueCurrencies/modularERC20/ModularStandardToken.sol

pragma solidity ^0.5.13;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ModularStandardToken is ModularBasicToken {
    using SafeMath for uint256;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    uint256 constant INFINITE_ALLOWANCE = 0xfe00000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approveAllArgs(_spender, _value, msg.sender);
        return true;
    }

    function _approveAllArgs(
        address _spender,
        uint256 _value,
        address _tokenHolder
    ) internal {
        _setAllowance(_tokenHolder, _spender, _value);
        emit Approval(_tokenHolder, _spender, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        _increaseAllowanceAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    function _increaseAllowanceAllArgs(
        address _spender,
        uint256 _addedValue,
        address _tokenHolder
    ) internal {
        _addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(
            _tokenHolder,
            _spender,
            _getAllowance(_tokenHolder, _spender)
        );
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        _decreaseAllowanceAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function _decreaseAllowanceAllArgs(
        address _spender,
        uint256 _subtractedValue,
        address _tokenHolder
    ) internal {
        uint256 oldValue = _getAllowance(_tokenHolder, _spender);
        uint256 newValue;
        if (_subtractedValue > oldValue) {
            newValue = 0;
        } else {
            newValue = oldValue - _subtractedValue;
        }
        _setAllowance(_tokenHolder, _spender, newValue);
        emit Approval(_tokenHolder, _spender, newValue);
    }

    function allowance(address _who, address _spender)
        public
        view
        returns (uint256)
    {
        return _getAllowance(_who, _spender);
    }

    function _getAllowance(address _who, address _spender)
        internal
        view
        returns (uint256 value)
    {
        return _allowance[_who][_spender];
    }

    function _addAllowance(address _who, address _spender, uint256 _value)
        internal
    {
        _allowance[_who][_spender] = _allowance[_who][_spender].add(_value);
    }

    function _subAllowance(address _who, address _spender, uint256 _value)
        internal
        returns (uint256 newAllowance)
    {
        newAllowance = _allowance[_who][_spender].sub(_value);
        if (newAllowance < INFINITE_ALLOWANCE) {
            _allowance[_who][_spender] = newAllowance;
        }
    }

    function _setAllowance(address _who, address _spender, uint256 _value)
        internal
    {
        _allowance[_who][_spender] = _value;
    }
}

// File: contracts/TrueCurrencies/modularERC20/ModularBurnableToken.sol

pragma solidity ^0.5.13;


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ModularBurnableToken is ModularStandardToken {
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 value);
    uint256 constant CENT = 10 ** 16;

    function burn(uint256 _value) external {
        _burnAllArgs(msg.sender, _value - _value % CENT);
    }

    function _burnAllArgs(address _from, uint256 _value) internal {
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        _subBalance(_from, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
    }
}

// File: contracts/TrueCurrencies/BurnableTokenWithBounds.sol

pragma solidity ^0.5.13;


/**
 * @title Burnable Token WithBounds
 * @dev Burning functions as redeeming money from the system. The platform will keep track of who burns coins,
 * and will send them back the equivalent amount of money (rounded down to the nearest cent).
 */
contract BurnableTokenWithBounds is ModularBurnableToken {

    event SetBurnBounds(uint256 newMin, uint256 newMax);

    function _burnAllArgs(address _burner, uint256 _value) internal {
        require(_value >= burnMin, "below min burn bound");
        require(_value <= burnMax, "exceeds max burn bound");
        super._burnAllArgs(_burner, _value);
    }

    //Change the minimum and maximum amount that can be burned at once. Burning
    //may be disabled by setting both to 0 (this will not be done under normal
    //operation, but we can't add checks to disallow it without losing a lot of
    //flexibility since burning could also be as good as disabled
    //by setting the minimum extremely high, and we don't want to lock
    //in any particular cap for the minimum)
    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, "min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }
}

// File: contracts/TrueCurrencies/GasRefundToken.sol

pragma solidity ^0.5.13;


/**
@title Gas Refund Token
Allow any user to sponsor gas refunds for transfer and mints. Utilitzes the gas refund mechanism in EVM
Each time an non-empty storage slot is set to 0, evm refund 15,000 to the sender
of the transaction.
*/
contract GasRefundToken is ProxyStorage {

    /**
      A buffer of "Sheep" runs from 0xffff...fffe down
      They suicide when you call them, if you are their parent
    */

    function sponsorGas2() external {
        /**
        Deploy (9 bytes)
          PC Assembly       Opcodes                                       Stack
          00 PUSH1(27)      60 1b                                         1b
          02 DUP1           80                                            1b 1b
          03 PUSH1(9)       60 09                                         1b 1b 09
          05 RETURNDATASIZE 3d                                            1b 1b 09 00
          06 CODECOPY       39                                            1b
          07 RETURNDATASIZE 3d                                            1b 00
          08 RETURN         f3
        Sheep (27 bytes = 3 + 20 + 4)
          PC Assembly       Opcodes                                       Stack
          00 RETURNDATASIZE 3d                                            00
          01 CALLER         33                                            00 caller
          02 PUSH20(me)     73 memememememememememememememememememememe   00 caller me
          17 XOR            18                                            00 invalid
          18 PC             58                                            00 invalid 18
          19 JUMPI          57                                            00
          1a SELFDESTRUCT   ff
        */
        assembly {
            mstore(0, or(0x601b8060093d393df33d33730000000000000000000000000000000000000000, address))
            mstore(32,   0x185857ff00000000000000000000000000000000000000000000000000000000)
            let offset := sload(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            let location := sub(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe, offset)
            sstore(location, create(0, 0, 0x24))
            location := sub(location, 1)
            sstore(location, create(0, 0, 0x24))
            location := sub(location, 1)
            sstore(location, create(0, 0, 0x24))
            sstore(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, add(offset, 3))
        }
    }

    /**
    @dev refund 39,000 gas
    @dev costs slightly more than 16,100 gas
    */
    function gasRefund39() internal {
        assembly {
            let offset := sload(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            if gt(offset, 0) {
              let location := sub(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,offset)
              sstore(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, sub(offset, 1))
              let sheep := sload(location)
              pop(call(gas, sheep, 0, 0, 0, 0, 0))
              sstore(location, 0)
            }
        }
    }

    function sponsorGas() external {
        uint256 refundPrice = minimumGasPriceForFutureRefunds;
        require(refundPrice > 0);
        assembly {
            let offset := sload(0xfffff)
            let result := add(offset, 9)
            sstore(0xfffff, result)
            let position := add(offset, 0x100000)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
            position := add(position, 1)
            sstore(position, refundPrice)
        }
    }

    function minimumGasPriceForRefund() public view returns (uint256 result) {
        assembly {
            let offset := sload(0xfffff)
            let location := add(offset, 0xfffff)
            result := add(sload(location), 1)
        }
    }

    /**
    @dev refund 30,000 gas
    @dev costs slightly more than 15,400 gas
    */
    function gasRefund30() internal {
        assembly {
            let offset := sload(0xfffff)
            if gt(offset, 1) {
                let location := add(offset, 0xfffff)
                if gt(gasprice,sload(location)) {
                    sstore(location, 0)
                    location := sub(location, 1)
                    sstore(location, 0)
                    sstore(0xfffff, sub(offset, 2))
                }
            }
        }
    }

    /**
    @dev refund 15,000 gas
    @dev costs slightly more than 10,200 gas
    */
    function gasRefund15() internal {
        assembly {
            let offset := sload(0xfffff)
            if gt(offset, 1) {
                let location := add(offset, 0xfffff)
                if gt(gasprice,sload(location)) {
                    sstore(location, 0)
                    sstore(0xfffff, sub(offset, 1))
                }
            }
        }
    }

    /**
    *@dev Return the remaining sponsored gas slots
    */
    function remainingGasRefundPool() public view returns (uint length) {
        assembly {
            length := sload(0xfffff)
        }
    }

    function gasRefundPool(uint256 _index) public view returns (uint256 gasPrice) {
        assembly {
            gasPrice := sload(add(0x100000, _index))
        }
    }

    bytes32 constant CAN_SET_FUTURE_REFUND_MIN_GAS_PRICE = "canSetFutureRefundMinGasPrice";

    function setMinimumGasPriceForFutureRefunds(uint256 _minimumGasPriceForFutureRefunds) public {
        require(registry.hasAttribute(msg.sender, CAN_SET_FUTURE_REFUND_MIN_GAS_PRICE));
        minimumGasPriceForFutureRefunds = _minimumGasPriceForFutureRefunds;
    }
}

// File: contracts/TrueCurrencies/CompliantDepositTokenWithHook.sol

pragma solidity ^0.5.13;







contract CompliantDepositTokenWithHook is ReclaimerToken, RegistryClone, BurnableTokenWithBounds, GasRefundToken {

    bytes32 constant IS_REGISTERED_CONTRACT = "isRegisteredContract";
    bytes32 constant IS_DEPOSIT_ADDRESS = "isDepositAddress";
    uint256 constant REDEMPTION_ADDRESS_COUNT = 0x100000;
    bytes32 constant IS_BLACKLISTED = "isBlacklisted";

    function canBurn() internal pure returns (bytes32);

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transferAllArgs(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transferFromAllArgs(_from, _to, _value, msg.sender);
        return true;
    }

    function _burnFromAllowanceAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        _requireCanTransferFrom(_spender, _from, _to);
        _requireOnlyCanBurn(_to);
        require(_value >= burnMin, "below min burn bound");
        require(_value <= burnMax, "exceeds max burn bound");
        if (0 == _subBalance(_from, _value)) {
            if (0 != _subAllowance(_from, _spender, _value)) {
                gasRefund15();
            }
            // else no refund
        } else {
            if (0 == _subAllowance(_from, _spender, _value)) {
                gasRefund15();
            } else {
                gasRefund39();
            }
        }
        emit Transfer(_from, _to, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_to, _value);
        emit Transfer(_to, address(0), _value);
    }

    function _burnFromAllArgs(address _from, address _to, uint256 _value) internal {
        _requireCanTransfer(_from, _to);
        _requireOnlyCanBurn(_to);
        require(_value >= burnMin, "below min burn bound");
        require(_value <= burnMax, "exceeds max burn bound");
        if (0 == _subBalance(_from, _value)) {
            gasRefund15();
        } else {
            gasRefund30();
        }
        emit Transfer(_from, _to, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_to, _value);
        emit Transfer(_to, address(0), _value);
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        if (uint256(_to) < REDEMPTION_ADDRESS_COUNT) {
            _value -= _value % CENT;
            _burnFromAllowanceAllArgs(_from, _to, _value, _spender);
        } else {
            bool hasHook;
            address originalTo = _to;
            (_to, hasHook) = _requireCanTransferFrom(_spender, _from, _to);
            if (0 == _addBalance(_to, _value)) {
                if (0 == _subAllowance(_from, _spender, _value)) {
                    if (0 != _subBalance(_from, _value)) {
                        gasRefund30();
                    }
                    // else do not refund
                } else {
                    if (0 == _subBalance(_from, _value)) {
                        gasRefund30();
                    } else {
                        gasRefund39();
                    }
                }
            } else {
                if (0 == _subAllowance(_from, _spender, _value)) {
                    if (0 != _subBalance(_from, _value)) {
                        gasRefund15();
                    }
                    // else do not refund
                } else {
                    if (0 == _subBalance(_from, _value)) {
                        gasRefund15();
                    } else {
                        gasRefund39();
                    }
                }

            }
            emit Transfer(_from, originalTo, _value);
            if (originalTo != _to) {
                emit Transfer(originalTo, _to, _value);
                if (hasHook) {
                    TrueCoinReceiver(_to).tokenFallback(originalTo, _value);
                }
            } else {
                if (hasHook) {
                    TrueCoinReceiver(_to).tokenFallback(_from, _value);
                }
            }
        }
    }

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        if (uint256(_to) < REDEMPTION_ADDRESS_COUNT) {
            _value -= _value % CENT;
            _burnFromAllArgs(_from, _to, _value);
        } else {
            bool hasHook;
            address finalTo;
            (finalTo, hasHook) = _requireCanTransfer(_from, _to);
            if (0 == _subBalance(_from, _value)) {
                if (0 == _addBalance(finalTo, _value)) {
                    gasRefund30();
                }
                // else do not refund
            } else {
                if (0 == _addBalance(finalTo, _value)) {
                    gasRefund39();
                } else {
                    gasRefund30();
                }
            }
            emit Transfer(_from, _to, _value);
            if (finalTo != _to) {
                emit Transfer(_to, finalTo, _value);
                if (hasHook) {
                    TrueCoinReceiver(finalTo).tokenFallback(_to, _value);
                }
            } else {
                if (hasHook) {
                    TrueCoinReceiver(finalTo).tokenFallback(_from, _value);
                }
            }
        }
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0), "to address cannot be zero");
        bool hasHook;
        address originalTo = _to;
        (_to, hasHook) = _requireCanMint(_to);
        totalSupply_ = totalSupply_.add(_value);
        emit Mint(originalTo, _value);
        emit Transfer(address(0), originalTo, _value);
        if (_to != originalTo) {
            emit Transfer(originalTo, _to, _value);
        }
        _addBalance(_to, _value);
        if (hasHook) {
            if (_to != originalTo) {
                TrueCoinReceiver(_to).tokenFallback(originalTo, _value);
            } else {
                TrueCoinReceiver(_to).tokenFallback(address(0), _value);
            }
        }
    }

    event WipeBlacklistedAccount(address indexed account, uint256 balance);
    event SetRegistry(address indexed registry);

    /**
    * @dev Point to the registry that contains all compliance related data
    @param _registry The address of the registry instance
    */
    function setRegistry(Registry _registry) public onlyOwner {
        registry = _registry;
        emit SetRegistry(address(registry));
    }

    modifier onlyRegistry {
        require(msg.sender == address(registry));
        _;
    }

    function syncAttributeValue(address _who, bytes32 _attribute, uint256 _value) public onlyRegistry {
        attributes[_attribute][_who] = _value;
    }

    function _burnAllArgs(address _from, uint256 _value) internal {
        _requireCanBurn(_from);
        super._burnAllArgs(_from, _value);
    }

    // Destroy the tokens owned by a blacklisted account
    function wipeBlacklistedAccount(address _account) public onlyOwner {
        require(_isBlacklisted(_account), "_account is not blacklisted");
        uint256 oldValue = _getBalance(_account);
        _setBalance(_account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipeBlacklistedAccount(_account, oldValue);
        emit Transfer(_account, address(0), oldValue);
    }

    function _isBlacklisted(address _account) internal view returns (bool blacklisted) {
        return attributes[IS_BLACKLISTED][_account] != 0;
    }

    function _requireCanTransfer(address _from, address _to) internal view returns (address, bool) {
        uint256 depositAddressValue = attributes[IS_DEPOSIT_ADDRESS][address(uint256(_to) >> 20)];
        if (depositAddressValue != 0) {
            _to = address(depositAddressValue);
        }
        require (attributes[IS_BLACKLISTED][_to] == 0, "blacklisted");
        require (attributes[IS_BLACKLISTED][_from] == 0, "blacklisted");
        return (_to, attributes[IS_REGISTERED_CONTRACT][_to] != 0);
    }

    function _requireCanTransferFrom(address _spender, address _from, address _to) internal view returns (address, bool) {
        require (attributes[IS_BLACKLISTED][_spender] == 0, "blacklisted");
        uint256 depositAddressValue = attributes[IS_DEPOSIT_ADDRESS][address(uint256(_to) >> 20)];
        if (depositAddressValue != 0) {
            _to = address(depositAddressValue);
        }
        require (attributes[IS_BLACKLISTED][_to] == 0, "blacklisted");
        require (attributes[IS_BLACKLISTED][_from] == 0, "blacklisted");
        return (_to, attributes[IS_REGISTERED_CONTRACT][_to] != 0);
    }

    function _requireCanMint(address _to) internal view returns (address, bool) {
        uint256 depositAddressValue = attributes[IS_DEPOSIT_ADDRESS][address(uint256(_to) >> 20)];
        if (depositAddressValue != 0) {
            _to = address(depositAddressValue);
        }
        require (attributes[IS_BLACKLISTED][_to] == 0, "blacklisted");
        return (_to, attributes[IS_REGISTERED_CONTRACT][_to] != 0);
    }

    function _requireOnlyCanBurn(address _from) internal view {
        require (attributes[canBurn()][_from] != 0, "cannot burn from this address");
    }

    function _requireCanBurn(address _from) internal view {
        require (attributes[IS_BLACKLISTED][_from] == 0, "blacklisted");
        require (attributes[canBurn()][_from] != 0, "cannot burn from this address");
    }

    function paused() public pure returns (bool) {
        return false;
    }
}

// File: contracts/TrueCurrencies/Proxy/OwnedUpgradeabilityProxy.sol

pragma solidity ^0.5.13;

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Event to show ownership transfer is pending
    * @param currentOwner representing the address of the current owner
    * @param pendingOwner representing the address of the pending owner
    */
    event NewPendingOwner(address currentOwner, address pendingOwner);

    // Storage position of the owner and pendingOwner of the contract
    bytes32 private constant proxyOwnerPosition = 0x6279e8199720cf3557ecd8b58d667c8edc486bd1cf3ad59ea9ebdfcae0d0dfac;
    //keccak256("trueUSD.proxy.owner");

    bytes32 private constant pendingProxyOwnerPosition = 0x8ddbac328deee8d986ec3a7b933a196f96986cb4ee030d86cc56431c728b83f4;
    //keccak256("trueUSD.pending.proxy.owner");

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "only Proxy Owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the pending owner.
    */
    modifier onlyPendingProxyOwner() {
        require(msg.sender == pendingProxyOwner(), "only pending Proxy Owner");
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function pendingProxyOwner() public view returns (address pendingOwner) {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            pendingOwner := sload(position)
        }
    }

    /**
    * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    /**
    * @dev Sets the address of the owner
    */
    function _setPendingUpgradeabilityOwner(address newPendingProxyOwner) internal {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            sstore(position, newPendingProxyOwner)
        }
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    *changes the pending owner to newOwner. But doesn't actually transfer
    * @param newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0));
        _setPendingUpgradeabilityOwner(newOwner);
        emit NewPendingOwner(proxyOwner(), newOwner);
    }

    /**
    * @dev Allows the pendingOwner to claim ownership of the proxy
    */
    function claimProxyOwnership() external onlyPendingProxyOwner {
        emit ProxyOwnershipTransferred(proxyOwner(), pendingProxyOwner());
        _setUpgradeabilityOwner(pendingProxyOwner());
        _setPendingUpgradeabilityOwner(address(0));
    }

    /**
    * @dev Allows the proxy owner to upgrade the current version of the proxy.
    * @param implementation representing the address of the new implementation to be set.
    */
    function upgradeTo(address implementation) external onlyProxyOwner {
        address currentImplementation;
        bytes32 position = implementationPosition;
        assembly {
            currentImplementation := sload(position)
        }
        require(currentImplementation != implementation);
        assembly {
          sstore(position, implementation)
        }
        emit Upgraded(implementation);
    }

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param implementation representing the address of the upgraded implementation
    */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 0x6e41e0fbe643dfdb6043698bf865aada82dc46b953f754a3468eaa272a362dc7;
    //keccak256("trueUSD.proxy.implementation");

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function() external payable {
        bytes32 position = implementationPosition;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, sload(position), ptr, calldatasize, returndatasize, returndatasize)
            returndatacopy(ptr, 0, returndatasize)

            switch result
            case 0 { revert(ptr, returndatasize) }
            default { return(ptr, returndatasize) }
        }
    }
}

// File: contracts/TrueCurrencies/RewardToken.sol

pragma solidity ^0.5.13;



/**
 * @title RewardToken
 * @dev Non-transferrable token meant to represent
 * RewardTokens are TrueCurrencies owed by a financial opportunity
 *
 * -- Overview --
 * RewardTokens are redeemable for an underlying Token.
 * RewardTokens are non-transferrable for compliance reasons
 * The caller of depositor is responsible for exchanging their
 * tokens, rather just keep accounting of user rewardToken balances
 *
 * -- Financial Opportunity --
 * RewardTokens are backed by an underlying financial opportunity
 * Each financial opportunity can accept Token deposits for
 * See FinancialOpportunity.sol
 *
 * -- Mint/Redeem/Burn --
 * To create rewardTokens, we call mintRewardToken with some amount of TUSD
 * To redeem rewardTokens we call redeemRewardToken and recieve TUSD
 * Only the account that has rewardTokens can burn reward tokens. The only
 * time we would want to burn rewardTokens is if the underlying opportunity
 * is no longer redeemable, and we want to wipe the debt.
 *
 */
contract RewardToken is CompliantDepositTokenWithHook {

    /* variables in proxy storage
    mapping(address => FinancialOpportunity) finOps;
    mapping(address => mapping(address => uint256)) finOpBalances;
    mapping(address => uint256) finOpSupply;
    */

    event MintRewardToken(address account, uint256 amount, address finOp);
    event RedeemRewardToken(address account, uint256 amount, address finOp);
    event BurnRewardToken(address account, uint256 amount, address finOp);

    /**
     * @dev Only addresses registered in this contract's mapping are valid
     *
     * @param finOp reverts if this finOp is not registered
     */
    modifier validFinOp(address finOp) {
        require(finOp != address(0), "invalid opportunity");
        _;
    }

    /**
     * @dev get debt balance of account in rewardToken
     *
     * @param finOp financial opportunity
     */
    function rewardTokenSupply(
        address finOp
    ) public view validFinOp(finOp) returns (uint256) {
        return finOpSupply[finOp];
    }

    /**
     * @dev get debt balance of account in rewardToken
     *
     * @param account account to get rewardToken balance of
     * @param finOp financial opportunity
     */
    function rewardTokenBalance(
        address account,
        address finOp
    ) public view validFinOp(finOp) returns (uint256) {
        return finOpBalances[finOp][account];
    }

    /**
     * @dev mint rewardToken for financial opportunity
     *
     * For valid finOp, deposit Token into finOp
     * Update finOpSupply & finOpBalance for account
     * Emit mintRewardToken event on success
     *
     * @param account account to mint rewardToken for
     * @param amount amount of depositToken to mint
     * @param finOp financial opportunity address
     */
    function mintRewardToken(
        address account,
        uint256 amount,
        address finOp
    ) internal validFinOp(finOp) returns (uint256) {
        // require sufficient balance
        require(super.balanceOf(account) >= amount, "insufficient token balance");

        // approve finOp can spend Token
        _setAllowance(account, finOp, amount);

        // deposit into finOp
        uint256 rewardAmount = _getFinOp(finOp).deposit(account, amount);

        // increase finOp rewardToken supply
        finOpSupply[finOp] = finOpSupply[finOp].add(rewardAmount);

        // increase account rewardToken balance
        _addRewardBalance(account, rewardAmount, finOp);

        // emit mint event
        emit MintRewardToken(account, amount, finOp);

        return rewardAmount;
    }

    /**
     * @dev redeem rewardToken balance for depositToken
     *
     * For valid finOp, deposit Token into finOp
     * Update finOpSupply & finOpBalance for account
     * Emit mintRewardToken event on success
     *
     * @param account account to redeem rewardToken for
     * @param amount depositToken amount to redeem
     * @param finOp financial opportunitu address
     */
    function redeemRewardToken(
        address account,
        uint256 amount,
        address finOp
    ) internal validFinOp(finOp) returns (uint256) {
        // require sufficient balance
        require(rewardTokenBalance(account, finOp) >= amount, "insufficient reward balance");

        // withdraw from finOp, giving TUSD to account
        uint256 tokenAmount = _getFinOp(finOp).redeem(account, amount);

        // decrease finOp rewardToken supply
        finOpSupply[finOp] = finOpSupply[finOp].sub(amount);

        // decrease account rewardToken balance
        _subRewardBalance(account, amount, finOp);

        // emit mint event
        emit RedeemRewardToken(account, tokenAmount, finOp);

        return tokenAmount;
    }

    /**
     * @dev burn rewardToken without redeeming
     *
     * Burn rewardToken for finOp
     *
     * @param account account to burn rewardToken for
     * @param amount depositToken amount to burn
     * @param finOp financial opportunity address
     */
    function burnRewardToken(
        address account,
        uint256 amount,
        address finOp
    )
        internal
        validFinOp(finOp)
    {
        // burn call must come from sender
        require(msg.sender == account);

        // sender must have rewardToken amount to burn
        require(rewardTokenBalance(account, finOp) >= amount);

        // subtract reward balance from
        _subRewardBalance(account, amount, finOp);

        // reduce total supply
        finOpSupply[finOp].sub(amount);

        // burn event
        emit BurnRewardToken(account, amount, finOp);
    }

    /**
     * @dev add rewardToken balance to account
     *
     * @param account account to add to
     * @param amount rewardToken amount to add
     * @param finOp financial opportunity to add reward tokens to
     */
    function _addRewardBalance(address account, uint256 amount, address finOp) internal {
        finOpBalances[finOp][account] = finOpBalances[finOp][account].add(amount);
    }

    /**
     * @dev subtract rewardToken balance from account
     *
     * @param account account to subtract from
     * @param amount rewardToken ammount to subtract
     * @param finOp financial opportunity
     */
    function _subRewardBalance(address account, uint256 amount, address finOp) internal {
        finOpBalances[finOp][account] = finOpBalances[finOp][account].sub(amount);
    }

    /**
     * @dev Utility to convert depositToken value to rewardToken value
     *
     * @param amount depositToken amount to convert to rewardToken
     * @param finOp financial opportunity address
     */
    function _toRewardToken(uint256 amount, address finOp) internal view returns (uint256) {
        uint256 ratio = _getFinOp(finOp).tokenValue();
        return amount.mul(10 ** 18).div(ratio);
    }

    /**
     * @dev Utility to convert rewardToken value to depositToken value
     *
     * @param amount rewardToken amount to convert to depositToken
     * @param finOp financial opportunity address
     */
    function _toToken(uint amount, address finOp) internal view returns (uint256) {
        uint256 ratio = _getFinOp(finOp).tokenValue();
        return ratio.mul(amount).div(10 ** 18);
    }

    /**
     * @dev utility to get FinancialOpportunity for address
     *
     * @param finOp financial opportunity to get
     */
    function _getFinOp(address finOp) internal view returns (FinancialOpportunity) {
        return FinancialOpportunity(finOp);
    }
}

// File: contracts/TrueCurrencies/RewardTokenWithReserve.sol

pragma solidity ^0.5.13;


/**
 * @title RewardTokenWithReserve
 * @dev Provides a reserve to swap rewardTokens for gas savings
 *
 * -- Overview --
 * The Reserve holds Tokens and RewardTokens
 * Because gas costs can be high for depositing/redeeming in financial
 * opportunities, we use this contract to keep a reserve of tokens
 * to provide swap opportunities
 *
 */
contract RewardTokenWithReserve is RewardToken {

    // Reserve is an address which nobody has the private key to
    // Reserves of TUSD and TrueRewardBackedToken are held at this addess
    address public constant RESERVE = 0xf000000000000000000000000000000000000000;

    event SwapRewardForToken(address account, address receiver, uint256 amount, address finOp);
    event SwapTokenForReward(address account, address receiver, uint256 amount, address finOp);

    /**
     * @dev get reserve token balance
     *
     * @return token balance of reserve
     */
    function reserveBalance() public view returns (uint256) {
        return super.balanceOf(RESERVE);
    }

    /**
     * @dev Get rewardToken reserve balance
     *
     * @param finOp address of financial opportunity
     * @return rewardToken balance of reserve for finOp
     */
    function reserveRewardBalance(address finOp) public view returns (uint) {
        return rewardTokenBalance(RESERVE, finOp);
    }

    /**
     * @dev Withdraw Token from reserve through transferAll
     *
     * @param to address to withdraw to
     * @param value amount to withdraw
     */
    function reserveWithdraw(address to, uint256 value) external onlyOwner {
        _transferAllArgs(RESERVE, to, value);
    }

    /**
     * @dev Allow this contract to rebalance currency reserves
     * This is called when there is too much money in an opportunity and we want
     * to get more TrueCurrency.
     * This allows us to reduct the cost of transfers 5-10x in/out of opportunities
     *
     * @param amount amount of rewardTokens to redeem
     * @param finOp financial opportunity to redeem from
     */
    function reserveRedeem(uint256 amount, address finOp) internal {
        redeemRewardToken(RESERVE, amount, finOp);
    }

    /**
     * @dev Allow this contract to rebalance currency reserves
     * This is called when there is not enough rewardToken for an
     * opportunity and we want to add rewardTokens to the reserve
     *
     * @param amount amount of Token to redeem for rewardToken
     * @param finOp financial opportunity to redeem for
     */
    function reserveMint(uint256 amount, address finOp) internal {
        mintRewardToken(RESERVE, amount, finOp);
    }

    /**
     * @dev Use reserve to swap Token for rewardToken between accounts
     *
     * @param sender account to deduct token from
     * @param receiver account to add rewardToken to
     * @param amount Token amount to exchange for rewardToken
     * @param finOp financial opportunity to swap tokens for
     */
    function swapTokenForReward(
        address sender,
        address receiver,
        uint256 amount,
        address finOp
    ) internal validFinOp(finOp) {
        // require sender has sufficient balance
        require(balanceOf(sender) >= amount, "insufficient balance");

        // calculate rewardToken value for depositToken amount
        uint256 rewardAmount = _toRewardToken(amount, finOp);

        // require reserve
        require(rewardTokenBalance(RESERVE, finOp) >= rewardAmount, "not enough rewardToken in reserve");

        // sub from sender and add to reserve for depositToken
        _subBalance(sender, amount);
        _addBalance(RESERVE, amount);

        // sub from reserve and add to sender for rewardToken
        _subRewardBalance(RESERVE, rewardAmount, finOp);
        _addRewardBalance(receiver, rewardAmount, finOp);

        // emit event
        emit SwapTokenForReward(sender, receiver, amount, finOp);
    }

    /**
     * @dev Use reserve to swap rewardToken for Token between accounts
     *
     * @param sender account to swap rewardToken from
     * @param receiver account to add Token to
     * @param tokenAmount token amount to receive for Token
     * @param finOp financial opportunity
     */
    function swapRewardForToken(
        address sender,
        address receiver,
        uint256 tokenAmount,
        address finOp
    ) internal validFinOp(finOp) {
        // ensure reserve has enough balance
        require(balanceOf(RESERVE) >= tokenAmount, "not enough depositToken in reserve");

        uint256 rewardAmount = _toRewardToken(tokenAmount, finOp);

        // require sufficient balance
        require (rewardTokenBalance(sender, finOp) >= rewardAmount, "insufficient rewardToken balance");

        // sub account and add reserve for rewardToken
        _subRewardBalance(sender, rewardAmount, finOp);
        _addRewardBalance(RESERVE, rewardAmount, finOp);

        // sub account and add reserve for Token
        _subBalance(RESERVE, tokenAmount);
        _addBalance(receiver, tokenAmount);

        // emit event
        emit SwapRewardForToken(sender, receiver, rewardAmount, finOp);
    }
}

// File: contracts/TrueCurrencies/TrueRewardBackedToken.sol

pragma solidity ^0.5.13;




/**
 * @title TrueRewardBackedToken
 * @dev TrueRewardBackedToken is TrueCurrency backed by debt
 *
 * -- Overview --
 * Enabling TrueRewards deposits TrueCurrency into a financial opportunity
 * Financial opportunities provide awards over time
 * Awards are reflected in the wallet balance updated block-by-block
 *
 * -- rewardToken vs yToken --
 * rewardToken represents an amount of ASSURED TrueCurrency owed to the rewardToken holder
 * yToken represents an amount of NON-ASSURED TrueCurrency owed to a yToken holder
 * For this contract, we only handle rewardToken (Assured Opportunities)
 *
 * -- Calculating rewardToken --
 * TrueCurrency Value = rewardToken * financial opportunity tokenValue()
 *
 * -- rewardToken Assumptions --
 * We assume tokenValue never decreases for assured financial opportunities
 * rewardToken is not transferrable in that the token itself is never tranferred
 * Rather, we override our transfer functions to account for user balances
 *
 * -- Reserve --
 * This contract uses a reserve holding of TrueCurrency and rewardToken to save on gas costs
 * because calling the financial opportunity deposit() and redeem() everytime
 * can be expensive
 * See RewardTokenWithReserve.sol
 *
 * -- Future Upgrades to Financial Opportunity --
 * Currently, we only have a single financial opportunity
 * We plan on upgrading this contract to support a multiple financial opportunity,
 * so some of the code is built to support this
 *
 */
contract TrueRewardBackedToken is RewardTokenWithReserve {

    /* variables in Proxy Storage:
    mapping(address => FinancialOpportunity) finOps;
    mapping(address => mapping(address => uint256)) finOpBalances;
    mapping(address => uint256) finOpSupply;
    uint256 maxRewardProportion = 1000;
    */

    // registry attribute for whitelist
    // 0x6973547275655265776172647357686974656c69737465640000000000000000
    bytes32 constant IS_TRUEREWARDS_WHITELISTED = "isTrueRewardsWhitelisted";

    // financial opportunity address
    address public opportunity_;

    event TrueRewardEnabled(address _account);
    event TrueRewardDisabled(address _account);

    /** @dev return true if TrueReward is enabled for a given address */
    function trueRewardEnabled(address _address) public view returns (bool) {
        return _rewardDistribution[_address].length != 0;
    }

    /**
     * @dev Get total supply of all TrueCurrency
     * Equal to deposit backed TrueCurrency plus debt backed TrueCurrency
     * @return total supply in trueCurrency
     */
    function totalSupply() public view returns (uint256) {
        // if supply in opportunity finOp, return supply of deposits + debt
        // otherwise call super to return normal totalSupply
        if (opportunityRewardSupply() != 0) {
            return totalSupply_.add(opportunityTotalSupply());
        }
        return totalSupply_;
    }

    /**
     * @dev get total supply of TrueCurrency backed by fiat deposits
     * @return supply of fiat backed TrueCurrency
     */
    function depositBackedSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev get total supply of TrueCurrency backed by debt
     * @return supply of debt backed TrueCurrency
     */
    function debtBackedSupply() public view returns (uint256) {
        return totalSupply() - totalSupply_;
    }

    /**
     * @dev Get balance of TrueCurrency including rewards for an address
     *
     * @param _who address of account to get balanceOf for
     * @return balance total balance of address including rewards
     */
    function balanceOf(address _who) public view returns (uint256) {
        // if trueReward enabled, return token value of reward balance
        // otherwise call token balanceOf
        if (trueRewardEnabled(_who)) {
            return _toToken(rewardTokenBalance(_who, opportunity()), opportunity());
        }
        return super.balanceOf(_who);
    }

    /**
     * @dev Enable TrueReward and deposit user balance into opportunity.
     * Currently supports a single financial opportunity
     */
    function enableTrueReward() external {
        // require TrueReward is not enabled
        require(registry.hasAttribute(msg.sender, IS_TRUEREWARDS_WHITELISTED), "must be whitelisted to enable TrueRewards");
        require(!trueRewardEnabled(msg.sender), "TrueReward already enabled");

        // get sender balance
        uint balance = _getBalance(msg.sender);

        if (balance != 0) {
            // mint reward token
            mintRewardToken(msg.sender, balance, opportunity());
        }

        // set reward distribution
        // we set max distribution since we only have one opportunity
        _setDistribution(maxRewardProportion, opportunity());

        // emit enable event
        emit TrueRewardEnabled(msg.sender);
        //emit Transfer(address(0), msg.sender, balance);
    }

    /**
     * @dev Disable TrueReward and withdraw user balance from opportunity.
     */
    function disableTrueReward() external {
        // require TrueReward is enabled
        require(trueRewardEnabled(msg.sender), "TrueReward already disabled");
        // get balance
        uint rewardBalance = rewardTokenBalance(msg.sender, opportunity());

        // remove reward distribution
        _removeDistribution(opportunity());

        if (rewardBalance > 0) {
            // redeem for token
            redeemRewardToken(msg.sender, rewardBalance, opportunity());
        }

        // emit disable event
        emit TrueRewardDisabled(msg.sender);
        // emit Transfer(msg.sender, address(0), zTrueCurrency);
    }

    /**
     * @dev mint function for TrueRewardBackedToken
     * Mints TrueCurrency backed by debt
     * When we add multiple opportunities, this needs to work for mutliple interfaces
     */
    function mint(address _to, uint256 _value) public onlyOwner {
        // check if to address is enabled
        bool toEnabled = trueRewardEnabled(_to);

        // if to enabled, mint to this contract and deposit into finOp
        if (toEnabled) {
            // mint to this contract
            super.mint(address(this), _value);
            // transfer minted amount to target receiver
            _transferAllArgs(address(this), _to, _value);
        }
        // otherwise call normal mint process
        else {
            super.mint(_to, _value);
        }
    }

    /**
     * @dev redeem reserve rewardTokens for Token given a rewardToken amount
     * This is called by the TokenController to balance the reserve
     * @param _value amount of Token to deposit for rewardTokens
     */
    function opportunityReserveRedeem(uint256 _value) external onlyOwner {
        reserveRedeem(_value, opportunity());
    }

    /**
     * @dev mint reserve rewardTokens for opportunity given a Token deposit
     * This is called by the TokenController to balance the reserve
     * @param _value amount of Token to deposit for rewardTokens
     */
    function opportunityReserveMint(uint256 _value) external onlyOwner {
        reserveMint(_value, opportunity());
    }

    /**
     * @dev set a new opportunity financial opportunity address
     * @param _opportunity new opportunity to set
     */
    function setOpportunityAddress(address _opportunity) external onlyOwner {
        opportunity_ = _opportunity;
    }

    /**
     * @dev Get (assured) financial opportunity address
     * @return address financial opportunity address
     */
    function opportunity() public view returns (address) {
        return opportunity_;
    }

    /**
     * @dev Get total supply of opportunity rewardToken
     * @return total supply of opportunity rewardToken
     */
    function opportunityRewardSupply() internal view returns (uint256) {
        return rewardTokenSupply(opportunity());
    }

    /**
     * @dev Get total supply of TrueCurrency in opportunity
     * @return total supply of TrueCurrency in opportunity
     */
    function opportunityTotalSupply() internal view returns (uint256) {
        return _toToken(opportunityRewardSupply(), opportunity());
    }

    /**
     * @dev Transfer helper for accounts with rewardToken balances
     * Uses reserve float to save gas costs for transactions with value < reserve balance
     * Case #2 and #3 use reserve balances
     *
     * There are 6 transfer cases
     *  1. Both sender and receiver are disabled (see _transferAllArgs)
     *  2. Sender enabled, receiver disabled, value < reserve TrueCurrency balance
     *  3. Sender disabled, receiver enabled, value < reserve rewardToken balance (in TrueCurrency)
     *  4. Both sender and receiver are enabled
     *  5. Sender enabled, receiver disabled, value > reserve TrueCurrency balance
     *  6. Sender disabled, receiver enabled, value > reserve rewardToken balance (in TrueCurrency)
     *
     * @param _from account to transfer from
     * @param _to account to transfer to
     * @param _value value in Token to transfer
     * @return actual value transferred
     */
    function _transferWithRewards(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (uint256) {
        // get enable stat
        bool fromEnabled = trueRewardEnabled(_from);
        bool toEnabled = trueRewardEnabled(_to);

        // get opportunity address
        address finOp = opportunity();

        // calculate rewardToken balance
        uint rewardAmount = _toRewardToken(_value, finOp);

        // 2. Sender enabled, receiver disabled, value < reserve TrueCurrency balance
        // Swap rewardToken for Token through reserve
        if (fromEnabled && !toEnabled && _value <= reserveBalance()) {
            swapRewardForToken(_from, _to, _value, finOp);
        }
        // 3. Sender disabled, receiver enabled, value < reserve rewardToken balance
        // Swap Token for rewardToken through reserve
        else if (!fromEnabled && toEnabled && rewardAmount <= rewardTokenBalance(RESERVE, finOp)) {
            swapTokenForReward(_from, _to, _value, finOp);
        }
        // 4. Sender and receiver are enabled
        // Here we simply transfer rewardToken from the sender to the receiver
        else if (fromEnabled && toEnabled) {
            _subRewardBalance(_from, rewardAmount, finOp);
            _addRewardBalance(_to, rewardAmount, finOp);
        }
        // 5. Sender enabled, receiver disabled, value > reserve TrueCurrency balance
        // Recalculate value based on redeem value returned and give value to receiver
        else if (fromEnabled && !toEnabled) {
            _getFinOp(finOp).redeem(_to, rewardAmount);

            // decrease finOp rewardToken supply
            finOpSupply[finOp] = finOpSupply[finOp].sub(rewardAmount);

            // decrease account rewardToken balance
            _subRewardBalance(_from, rewardAmount, finOp);
        }
        // 6. Sender disabled, receiver enabled, value > reserve rewardToken balance
        // Transfer Token value between accounts and mint reward token for receiver
        else if (!fromEnabled && toEnabled) {
            // deposit into finOp
            _approveAllArgs(finOp, _value, _from);
            uint256 depositedAmount = _getFinOp(finOp).deposit(_from, _value);

            // increase finOp rewardToken supply
            finOpSupply[finOp] = finOpSupply[finOp].add(depositedAmount);

            // increase account rewardToken balance
            _addRewardBalance(_to, depositedAmount, finOp);
        }
        return _value;
    }

    /**
     * @dev Transfer helper function for TrueRewardBackedToken
     */
    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        // 1. Both sender and receiver are disabled
        // Exchange is in TrueCurrency -> call the normal transfer function
        if (!trueRewardEnabled(_from) && !trueRewardEnabled(_to)) {
            // sender not enabled receiver not enabled
            super._transferAllArgs(_from, _to, _value);
            return;
        }
        require(balanceOf(_from) >= _value, "not enough balance");

        // require account is not blacklisted and check if hook is registered
        (address finalTo, bool hasHook) = _requireCanTransfer(_from, _to);

        _value = _transferWithRewards(_from, finalTo, _value);

        // emit transfer event for from
        emit Transfer(_from, _to, _value);
        if (finalTo != _to) {
            emit Transfer(_to, finalTo, _value);
            if (hasHook) {
                TrueCoinReceiver(finalTo).tokenFallback(_to, _value);
            }
        } else {
            if (hasHook) {
                TrueCoinReceiver(finalTo).tokenFallback(_from, _value);
            }
        }
    }

    /**
     * @dev TransferFromAll helper function for TrueRewardBackedToken
     */
    function _transferFromAllArgs(
        address _from,
        address _to,
        uint256 _value,
        address _spender
    ) internal {
        // 1. Both sender and receiver are disabled -> normal transfer
        if (!trueRewardEnabled(_from) && !trueRewardEnabled(_to)) {
            super._transferFromAllArgs(_from, _to, _value, _spender);
            return;
        }

        // check balance
        require(balanceOf(_from) >= _value, "not enough balance");

        (address finalTo, bool hasHook) = _requireCanTransferFrom(_spender, _from, _to);

        // call transfer helper
        _value = _transferWithRewards(_from, finalTo, _value);

        // sub allowance of spender
        _subAllowance(_from, _spender, _value);

        // emit transfer event. For hook emit second transfer event
        // call fallback function for valid hook
        emit Transfer(_from, _to, _value);
        if (finalTo != _to) {
            emit Transfer(_to, finalTo, _value);
            if (hasHook) {
                TrueCoinReceiver(finalTo).tokenFallback(_to, _value);
            }
        } else {
            if (hasHook) {
                TrueCoinReceiver(finalTo).tokenFallback(_from, _value);
            }
        }
    }

    /**
     * @dev Set reward distribution for an opportunity
     *
     * @param proportion to set
     * @param finOp financial opportunity to set proportion for
     */
    function _setDistribution(uint256 proportion, address finOp) internal {
        require(proportion <= maxRewardProportion, "exceeds maximum proportion");
        require(_rewardDistribution[msg.sender].length == 0, "already enabled");
        _rewardDistribution[msg.sender].push(
            RewardAllocation(proportion, finOp));
    }

    /**
     * @dev Remove reward distribution for a financial opportunity
     * Remove
     */
    function _removeDistribution(address finOp) internal {
        delete _rewardDistribution[msg.sender][0];
        _rewardDistribution[msg.sender].length--;
    }
}

// File: contracts/TrueCurrencies/DelegateERC20.sol

pragma solidity ^0.5.13;


/** @title DelegateERC20
Accept forwarding delegation calls from the old TrueUSD (V1) contract. This way the all the ERC20
functions in the old contract still works (except Burn).
*/
contract DelegateERC20 is CompliantDepositTokenWithHook {

    address constant DELEGATE_FROM = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;

    modifier onlyDelegateFrom() {
        require(msg.sender == DELEGATE_FROM);
        _;
    }

    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function delegateBalanceOf(address who) public view returns (uint256) {
        return _getBalance(who);
    }

    function delegateTransfer(address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferAllArgs(origSender, to, value);
        return true;
    }

    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return _getAllowance(owner, spender);
    }

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferFromAllArgs(from, to, value, origSender);
        return true;
    }

    function delegateApprove(address spender, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _approveAllArgs(spender, value, origSender);
        return true;
    }

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _increaseAllowanceAllArgs(spender, addedValue, origSender);
        return true;
    }

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _decreaseAllowanceAllArgs(spender, subtractedValue, origSender);
        return true;
    }
}

// File: contracts/TrueCurrencies/TrueUSD.sol

pragma solidity ^0.5.13;





/** @title TrueUSD
 * @dev This is the top-level ERC20 contract, but most of the interesting functionality is
 * inherited - see the documentation on the corresponding contracts.
 */
contract TrueUSD is TrueRewardBackedToken, DelegateERC20 {
    uint8 constant DECIMALS = 18;
    uint8 constant ROUNDING = 2;

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function rounding() public pure returns (uint8) {
        return ROUNDING;
    }

    function name() public pure returns (string memory) {
        return "TrueUSD";
    }

    function symbol() public pure returns (string memory) {
        return "TUSD";
    }

    function canBurn() internal pure returns (bytes32) {
        return "canBurn";
    }

    // used by proxy to initialize
    // this sets the owner to msg.sender
    // may be a security risk for deployment
    function initialize() external {
        require(!initialized, "already initialized");
        initialized = true;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
}

// File: contracts/TrueCurrencies/Admin/TokenController.sol

pragma solidity ^0.5.13;








/** @title TokenController
@dev This contract allows us to split ownership of the TrueUSD contract
into two addresses. One, called the "owner" address, has unfettered control of the TrueUSD contract -
it can mint new tokens, transfer ownership of the contract, etc. However to make
extra sure that TrueUSD is never compromised, this owner key will not be used in
day-to-day operations, allowing it to be stored at a heightened level of security.
Instead, the owner appoints an various "admin" address.
There are 3 different types of admin addresses;  MintKey, MintRatifier, and MintPauser.
MintKey can request and revoke mints one at a time.
MintPausers can pause individual mints or pause all mints.
MintRatifiers can approve and finalize mints with enough approval.

There are three levels of mints: instant mint, ratified mint, and multiSig mint. Each have a different threshold
and deduct from a different pool.
Instant mint has the lowest threshold and finalizes instantly without any ratifiers. Deduct from instant mint pool,
which can be refilled by one ratifier.
Ratify mint has the second lowest threshold and finalizes with one ratifier approval. Deduct from ratify mint pool,
which can be refilled by three ratifiers.
MultiSig mint has the highest threshold and finalizes with three ratifier approvals. Deduct from multiSig mint pool,
which can only be refilled by the owner.
*/

contract TokenController {
    using SafeMath for uint256;

    struct MintOperation {
        address to;
        uint256 value;
        uint256 requestedBlock;
        uint256 numberOfApproval;
        bool paused;
        mapping(address => bool) approved;
    }

    address payable public owner;
    address payable public pendingOwner;

    bool public initialized;

    uint256 public instantMintThreshold;
    uint256 public ratifiedMintThreshold;
    uint256 public multiSigMintThreshold;


    uint256 public instantMintLimit;
    uint256 public ratifiedMintLimit;
    uint256 public multiSigMintLimit;

    uint256 public instantMintPool;
    uint256 public ratifiedMintPool;
    uint256 public multiSigMintPool;
    address[2] public ratifiedPoolRefillApprovals;

    uint8 constant public RATIFY_MINT_SIGS = 1; //number of approvals needed to finalize a Ratified Mint
    uint8 constant public MULTISIG_MINT_SIGS = 3; //number of approvals needed to finalize a MultiSig Mint

    bool public mintPaused;
    uint256 public mintReqInvalidBeforeThisBlock; //all mint request before this block are invalid
    address public mintKey;
    MintOperation[] public mintOperations; //list of a mint requests

    TrueRewardBackedToken public token;
    Registry public registry;
    address public fastPause;
    address public trueRewardManager;

    bytes32 constant public IS_MINT_PAUSER = "isTUSDMintPausers";
    bytes32 constant public IS_MINT_RATIFIER = "isTUSDMintRatifier";
    bytes32 constant public IS_REDEMPTION_ADMIN = "isTUSDRedemptionAdmin";

    address constant public PAUSED_IMPLEMENTATION = address(1); // ***To be changed the paused version of TrueUSD in Production

    modifier onlyFastPauseOrOwner() {
        require(msg.sender == fastPause || msg.sender == owner, "must be pauser or owner");
        _;
    }

    modifier onlyMintKeyOrOwner() {
        require(msg.sender == mintKey || msg.sender == owner, "must be mintKey or owner");
        _;
    }

    modifier onlyMintPauserOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_PAUSER) || msg.sender == owner, "must be pauser or owner");
        _;
    }

    modifier onlyMintRatifierOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_RATIFIER) || msg.sender == owner, "must be ratifier or owner");
        _;
    }

    modifier onlyOwnerOrRedemptionAdmin() {
        require(registry.hasAttribute(msg.sender, IS_REDEMPTION_ADMIN) || msg.sender == owner, "must be Redemption admin or owner");
        _;
    }

    modifier onlyTrueRewardManager() {
        require(msg.sender == trueRewardManager, "must be trueRewardManager");
        _;
    }


    //mint operations by the mintkey cannot be processed on when mints are paused
    modifier mintNotPaused() {
        if (msg.sender != owner) {
            require(!mintPaused, "minting is paused");
        }
        _;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnerPending(address indexed currentOwner, address indexed pendingOwner);
    event SetRegistry(address indexed registry);
    event TransferChild(address indexed child, address indexed newOwner);
    event RequestReclaimContract(address indexed other);
    event SetToken(TrueUSD newContract);

    event RequestMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    event FinalizeMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    event InstantMint(address indexed to, uint256 indexed value, address indexed mintKey);

    event TransferMintKey(address indexed previousMintKey, address indexed newMintKey);
    event MintRatified(uint256 indexed opIndex, address indexed ratifier);
    event RevokeMint(uint256 opIndex);
    event AllMintsPaused(bool status);
    event MintPaused(uint opIndex, bool status);
    event MintApproved(address approver, uint opIndex);
    event FastPauseSet(address _newFastPause);

    event MintThresholdChanged(uint instant, uint ratified, uint multiSig);
    event MintLimitsChanged(uint instant, uint ratified, uint multiSig);
    event InstantPoolRefilled();
    event RatifyPoolRefilled();
    event MultiSigPoolRefilled();

    /*
    ========================================
    Ownership functions
    ========================================
    */

    function initialize() external {
        require(!initialized, "already initialized");
        owner = msg.sender;
        initialized = true;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address payable newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit NewOwnerPending(address(owner), address(pendingOwner));
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(address(owner), address(pendingOwner));
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /*
    ========================================
    proxy functions
    ========================================
    */

    function transferTusdProxyOwnership(address _newOwner) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).transferProxyOwnership(_newOwner);
    }

    function claimTusdProxyOwnership() external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).claimProxyOwnership();
    }

    function upgradeTusdProxyImplTo(address _implementation) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(_implementation);
    }

    /*
    ========================================
    Minting functions
    ========================================
    */

    /**
     * @dev set the threshold for a mint to be considered an instant mint, ratify mint and multiSig mint
     Instant mint requires no approval, ratify mint requires 1 approval and multiSig mint requires 3 approvals
     */
    function setMintThresholds(uint256 _instant, uint256 _ratified, uint256 _multiSig) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintThreshold = _instant;
        ratifiedMintThreshold = _ratified;
        multiSigMintThreshold = _multiSig;
        emit MintThresholdChanged(_instant, _ratified, _multiSig);
    }


    /**
     * @dev set the limit of each mint pool. For example can only instant mint up to the instant mint pool limit
     before needing to refill
     */
    function setMintLimits(uint256 _instant, uint256 _ratified, uint256 _multiSig) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintLimit = _instant;
        if (instantMintPool > instantMintLimit) {
            instantMintPool = instantMintLimit;
        }
        ratifiedMintLimit = _ratified;
        if (ratifiedMintPool > ratifiedMintLimit) {
            ratifiedMintPool = ratifiedMintLimit;
        }
        multiSigMintLimit = _multiSig;
        if (multiSigMintPool > multiSigMintLimit) {
            multiSigMintPool = multiSigMintLimit;
        }
        emit MintLimitsChanged(_instant, _ratified, _multiSig);
    }

    /**
     * @dev Ratifier can refill instant mint pool
     */
    function refillInstantMintPool() external onlyMintRatifierOrOwner {
        ratifiedMintPool = ratifiedMintPool.sub(instantMintLimit.sub(instantMintPool));
        instantMintPool = instantMintLimit;
        emit InstantPoolRefilled();
    }

    /**
     * @dev Owner or 3 ratifiers can refill Ratified Mint Pool
     */
    function refillRatifiedMintPool() external onlyMintRatifierOrOwner {
        if (msg.sender != owner) {
            address[2] memory refillApprovals = ratifiedPoolRefillApprovals;
            require(msg.sender != refillApprovals[0] && msg.sender != refillApprovals[1]);
            if (refillApprovals[0] == address(0)) {
                ratifiedPoolRefillApprovals[0] = msg.sender;
                return;
            }
            if (refillApprovals[1] == address(0)) {
                ratifiedPoolRefillApprovals[1] = msg.sender;
                return;
            }
        }
        delete ratifiedPoolRefillApprovals; // clears the whole array
        multiSigMintPool = multiSigMintPool.sub(ratifiedMintLimit.sub(ratifiedMintPool));
        ratifiedMintPool = ratifiedMintLimit;
        emit RatifyPoolRefilled();
    }

    /**
     * @dev Owner can refill MultiSig Mint Pool
     */
    function refillMultiSigMintPool() external onlyOwner {
        multiSigMintPool = multiSigMintLimit;
        emit MultiSigPoolRefilled();
    }

    /**
     * @dev mintKey initiates a request to mint _value for account _to
     * @param _to the address to mint to
     * @param _value the amount requested
     */
    function requestMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        MintOperation memory op = MintOperation(_to, _value, block.number, 0, false);
        emit RequestMint(_to, _value, mintOperations.length, msg.sender);
        mintOperations.push(op);
    }


    /**
     * @dev Instant mint without ratification if the amount is less than instantMintThreshold and instantMintPool
     * @param _to the address to mint to
     * @param _value the amount minted
     */
    function instantMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        require(_value <= instantMintThreshold, "over the instant mint threshold");
        require(_value <= instantMintPool, "instant mint pool is dry");
        instantMintPool = instantMintPool.sub(_value);
        emit InstantMint(_to, _value, msg.sender);
        token.mint(_to, _value);
    }


    /**
     * @dev ratifier ratifies a request mint. If the number of ratifiers that signed off is greater than
     the number of approvals required, the request is finalized
     * @param _index the index of the requestMint to ratify
     * @param _to the address to mint to
     * @param _value the amount requested
     */
    function ratifyMint(uint256 _index, address _to, uint256 _value) external mintNotPaused onlyMintRatifierOrOwner {
        MintOperation memory op = mintOperations[_index];
        require(op.to == _to, "to address does not match");
        require(op.value == _value, "amount does not match");
        require(!mintOperations[_index].approved[msg.sender], "already approved");
        mintOperations[_index].approved[msg.sender] = true;
        mintOperations[_index].numberOfApproval = mintOperations[_index].numberOfApproval.add(1);
        emit MintRatified(_index, msg.sender);
        if (hasEnoughApproval(mintOperations[_index].numberOfApproval, _value)){
            finalizeMint(_index);
        }
    }

    /**
     * @dev finalize a mint request, mint the amount requested to the specified address
     @param _index of the request (visible in the RequestMint event accompanying the original request)
     */
    function finalizeMint(uint256 _index) public mintNotPaused {
        MintOperation memory op = mintOperations[_index];
        address to = op.to;
        uint256 value = op.value;
        if (msg.sender != owner) {
            require(canFinalize(_index));
            _subtractFromMintPool(value);
        }
        delete mintOperations[_index];
        token.mint(to, value);
        emit FinalizeMint(to, value, _index, msg.sender);
    }

    /**
     * assumption: only invoked when canFinalize
     */
    function _subtractFromMintPool(uint256 _value) internal {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            ratifiedMintPool = ratifiedMintPool.sub(_value);
        } else {
            multiSigMintPool = multiSigMintPool.sub(_value);
        }
    }

    /**
     * @dev compute if the number of approvals is enough for a given mint amount
     */
    function hasEnoughApproval(uint256 _numberOfApproval, uint256 _value) public view returns (bool) {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            if (_numberOfApproval >= RATIFY_MINT_SIGS){
                return true;
            }
        }
        if (_value <= multiSigMintPool && _value <= multiSigMintThreshold) {
            if (_numberOfApproval >= MULTISIG_MINT_SIGS){
                return true;
            }
        }
        if (msg.sender == owner) {
            return true;
        }
        return false;
    }

    /**
     * @dev compute if a mint request meets all the requirements to be finalized
     utility function for a front end
     */
    function canFinalize(uint256 _index) public view returns(bool) {
        MintOperation memory op = mintOperations[_index];
        require(op.requestedBlock > mintReqInvalidBeforeThisBlock, "this mint is invalid"); //also checks if request still exists
        require(!op.paused, "this mint is paused");
        require(hasEnoughApproval(op.numberOfApproval, op.value), "not enough approvals");
        return true;
    }

    /**
    *@dev revoke a mint request, Delete the mintOperation
    *@param index of the request (visible in the RequestMint event accompanying the original request)
    */
    function revokeMint(uint256 _index) external onlyMintKeyOrOwner {
        delete mintOperations[_index];
        emit RevokeMint(_index);
    }

    function mintOperationCount() public view returns (uint256) {
        return mintOperations.length;
    }

    /*
    ========================================
    Key management
    ========================================
    */

    /**
    *@dev Replace the current mintkey with new mintkey
    *@param _newMintKey address of the new mintKey
    */
    function transferMintKey(address _newMintKey) external onlyOwner {
        require(_newMintKey != address(0), "new mint key cannot be 0x0");
        emit TransferMintKey(mintKey, _newMintKey);
        mintKey = _newMintKey;
    }

    /*
    ========================================
    Mint Pausing
    ========================================
    */

    /**
    *@dev invalidates all mint request initiated before the current block
    */
    function invalidateAllPendingMints() external onlyOwner {
        mintReqInvalidBeforeThisBlock = block.number;
    }

    /**
    *@dev pause any further mint request and mint finalizations
    */
    function pauseMints() external onlyMintPauserOrOwner {
        mintPaused = true;
        emit AllMintsPaused(true);
    }

    /**
    *@dev unpause any further mint request and mint finalizations
    */
    function unpauseMints() external onlyOwner {
        mintPaused = false;
        emit AllMintsPaused(false);
    }

    /**
    *@dev pause a specific mint request
    *@param  _opIndex the index of the mint request the caller wants to pause
    */
    function pauseMint(uint _opIndex) external onlyMintPauserOrOwner {
        mintOperations[_opIndex].paused = true;
        emit MintPaused(_opIndex, true);
    }

    /**
    *@dev unpause a specific mint request
    *@param  _opIndex the index of the mint request the caller wants to unpause
    */
    function unpauseMint(uint _opIndex) external onlyOwner {
        mintOperations[_opIndex].paused = false;
        emit MintPaused(_opIndex, false);
    }

    /*
    ========================================
    set and claim contracts, administrative
    ========================================
    */


    /**
    *@dev Update this contract's token pointer to newContract (e.g. if the
    contract is upgraded)
    */
    function setToken(TrueUSD _newContract) external onlyOwner {
        token = _newContract;
        emit SetToken(_newContract);
    }

    /**
    *@dev Update this contract's registry pointer to _registry
    */
    function setRegistry(Registry _registry) external onlyOwner {
        registry = _registry;
        emit SetRegistry(address(registry));
    }

    /**
    *@dev Swap out token's permissions registry
    *@param _registry new registry for token
    */
    function setTokenRegistry(Registry _registry) external onlyOwner {
        token.setRegistry(_registry);
    }

    /**
    *@dev Claim ownership of an arbitrary HasOwner contract
    */
    function issueClaimOwnership(address _other) public onlyOwner {
        HasOwner other = HasOwner(_other);
        other.claimOwnership();
    }

    /**
    *@dev Transfer ownership of _child to _newOwner.
    Can be used e.g. to upgrade this TokenController contract.
    *@param _child contract that tokenController currently Owns
    *@param _newOwner new owner/pending owner of _child
    */
    function transferChild(HasOwner _child, address _newOwner) external onlyOwner {
        _child.transferOwnership(_newOwner);
        emit TransferChild(address(_child), _newOwner);
    }

    /**
    *@dev Transfer ownership of a contract from token to this TokenController.
    Can be used e.g. to reclaim balance sheet
    in order to transfer it to an upgraded TrueUSD contract.
    *@param _other address of the contract to claim ownership of
    */
    function requestReclaimContract(InstantiatableOwnable _other) public onlyOwner {
        token.reclaimContract(_other);
        emit RequestReclaimContract(address(_other));
    }

    /**
    *@dev send all ether in token address to the owner of tokenController
    */
    function requestReclaimEther() external onlyOwner {
        token.reclaimEther(owner);
    }

    /**
    *@dev transfer all tokens of a particular type in token address to the
    owner of tokenController
    *@param _token token address of the token to transfer
    */
    function requestReclaimToken(IERC20 _token) external onlyOwner {
        token.reclaimToken(_token, owner);
    }

    /**
    *@dev set new contract to which specified address can send eth to to quickly pause token
    *@param _newFastPause address of the new contract
    */
    function setFastPause(address _newFastPause) external onlyOwner {
        fastPause = _newFastPause;
        emit FastPauseSet(address(_newFastPause));
    }

    /**
    *@dev pause all pausable actions on TrueUSD, mints/burn/transfer/approve
    */
    function pauseToken() external onlyFastPauseOrOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(PAUSED_IMPLEMENTATION);
    }

    /**
    *@dev wipe balance of a blacklisted address
    *@param _blacklistedAddress address whose balance will be wiped
    */
    function wipeBlackListedTrueUSD(address _blacklistedAddress) external onlyOwner {
        token.wipeBlacklistedAccount(_blacklistedAddress);
    }

    /**
    *@dev Change the minimum and maximum amounts that TrueUSD users can
    burn to newMin and newMax
    *@param _min minimum amount user can burn at a time
    *@param _max maximum amount user can burn at a time
    */
    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        token.setBurnBounds(_min, _max);
    }

    /**
    *@dev Owner can send ether balance in contract address
    *@param _to address to which the funds will be send to
    */
    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
    *@dev Owner can send erc20 token balance in contract address
    *@param _token address of the token to send
    *@param _to address to which the funds will be send to
    */
    function reclaimToken(IERC20 _token, address _to) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_to, balance);
    }

    /*
    ========================================
    Truereward
    ========================================
    */

    /**
     * @dev Sets the contract which has permissions to manage truerewards reserve
     * Controls access to reserve functions to allow providing liquidity
     */
    function setTrueRewardManager(address _newTrueRewardManager) external onlyOwner {
        trueRewardManager = _newTrueRewardManager;
    }

    /**
     * @dev Sets the contract which has permissions to manage truerewards reserve
     * Controls access to reserve functions to allow providing liquidity
     */
    function setOpportunityAddress(address _opportunityAddress) external onlyOwner {
        token.setOpportunityAddress(_opportunityAddress);
    }

    /**
     * @dev Withdraw all TrueCurrencies from reserve
     * @param _to address to withdraw to
     * @param _value amount to withdraw
     */
    function reserveWithdraw(address _to, uint256 _value) external onlyTrueRewardManager {
        token.reserveWithdraw(_to, _value);
    }

    /**
     * @dev Allow this contract to rebalance currency reserves
     * This is called when there is not enough money in opportunity reserve and we want
     * to get more opportunity tokens
     *
     * @param _value amount to exchange for opportunity rewardTokens
     */
    function opportunityReserveMint(uint256 _value) external onlyTrueRewardManager {
        token.opportunityReserveMint(_value);
    }

    /**
     * @dev Allow this contract to rebalance currency reserves
     * This is called when there is too much money in opportunity and we want
     * to get more TrueCurrency.
     *
     * @param _value amount of opportunity rewardTokens to redeem for TrueCurrency
     */
    function opportunityReserveRedeem(uint256 _value) external onlyTrueRewardManager {
        token.opportunityReserveRedeem(_value);
    }
}