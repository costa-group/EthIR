pragma solidity ^0.5.16;




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



interface IRewardsDistributionRecipient {

    function notifyRewardAmount(uint256 reward) external;

    function getRewardToken() external view returns (IERC20);

}



contract InitializableModuleKeys {



    // Governance                             // Phases

    bytes32 internal KEY_GOVERNANCE;          // 2.x

    bytes32 internal KEY_STAKING;             // 1.2

    bytes32 internal KEY_PROXY_ADMIN;         // 1.0



    // mStable

    bytes32 internal KEY_ORACLE_HUB;          // 1.2

    bytes32 internal KEY_MANAGER;             // 1.2

    bytes32 internal KEY_RECOLLATERALISER;    // 2.x

    bytes32 internal KEY_META_TOKEN;          // 1.1

    bytes32 internal KEY_SAVINGS_MANAGER;     // 1.0



    /**

     * @dev Initialize function for upgradable proxy contracts. This function should be called

     *      via Proxy to initialize constants in the Proxy contract.

     */

    function _initialize() internal {

        // keccak256() values are evaluated only once at the time of this function call.

        // Hence, no need to assign hard-coded values to these variables.

        KEY_GOVERNANCE = keccak256("Governance");

        KEY_STAKING = keccak256("Staking");

        KEY_PROXY_ADMIN = keccak256("ProxyAdmin");



        KEY_ORACLE_HUB = keccak256("OracleHub");

        KEY_MANAGER = keccak256("Manager");

        KEY_RECOLLATERALISER = keccak256("Recollateraliser");

        KEY_META_TOKEN = keccak256("MetaToken");

        KEY_SAVINGS_MANAGER = keccak256("SavingsManager");

    }

}



interface INexus {

    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);



    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;



    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;

}



contract InitializableModule is InitializableModuleKeys {



    INexus public nexus;



    /**

     * @dev Modifier to allow function calls only from the Governor.

     */

    modifier onlyGovernor() {

        require(msg.sender == _governor(), "Only governor can execute");

        _;

    }



    /**

     * @dev Modifier to allow function calls only from the Governance.

     *      Governance is either Governor address or Governance address.

     */

    modifier onlyGovernance() {

        require(

            msg.sender == _governor() || msg.sender == _governance(),

            "Only governance can execute"

        );

        _;

    }



    /**

     * @dev Modifier to allow function calls only from the ProxyAdmin.

     */

    modifier onlyProxyAdmin() {

        require(

            msg.sender == _proxyAdmin(), "Only ProxyAdmin can execute"

        );

        _;

    }



    /**

     * @dev Modifier to allow function calls only from the Manager.

     */

    modifier onlyManager() {

        require(msg.sender == _manager(), "Only manager can execute");

        _;

    }



    /**

     * @dev Initialization function for upgradable proxy contracts

     * @param _nexus Nexus contract address

     */

    function _initialize(address _nexus) internal {

        require(_nexus != address(0), "Nexus address is zero");

        nexus = INexus(_nexus);

        InitializableModuleKeys._initialize();

    }



    /**

     * @dev Returns Governor address from the Nexus

     * @return Address of Governor Contract

     */

    function _governor() internal view returns (address) {

        return nexus.governor();

    }



    /**

     * @dev Returns Governance Module address from the Nexus

     * @return Address of the Governance (Phase 2)

     */

    function _governance() internal view returns (address) {

        return nexus.getModule(KEY_GOVERNANCE);

    }



    /**

     * @dev Return Staking Module address from the Nexus

     * @return Address of the Staking Module contract

     */

    function _staking() internal view returns (address) {

        return nexus.getModule(KEY_STAKING);

    }



    /**

     * @dev Return ProxyAdmin Module address from the Nexus

     * @return Address of the ProxyAdmin Module contract

     */

    function _proxyAdmin() internal view returns (address) {

        return nexus.getModule(KEY_PROXY_ADMIN);

    }



    /**

     * @dev Return MetaToken Module address from the Nexus

     * @return Address of the MetaToken Module contract

     */

    function _metaToken() internal view returns (address) {

        return nexus.getModule(KEY_META_TOKEN);

    }



    /**

     * @dev Return OracleHub Module address from the Nexus

     * @return Address of the OracleHub Module contract

     */

    function _oracleHub() internal view returns (address) {

        return nexus.getModule(KEY_ORACLE_HUB);

    }



    /**

     * @dev Return Manager Module address from the Nexus

     * @return Address of the Manager Module contract

     */

    function _manager() internal view returns (address) {

        return nexus.getModule(KEY_MANAGER);

    }



    /**

     * @dev Return SavingsManager Module address from the Nexus

     * @return Address of the SavingsManager Module contract

     */

    function _savingsManager() internal view returns (address) {

        return nexus.getModule(KEY_SAVINGS_MANAGER);

    }



    /**

     * @dev Return Recollateraliser Module address from the Nexus

     * @return  Address of the Recollateraliser Module contract (Phase 2)

     */

    function _recollateraliser() internal view returns (address) {

        return nexus.getModule(KEY_RECOLLATERALISER);

    }

}



contract InitializableGovernableWhitelist is InitializableModule {



    event Whitelisted(address indexed _address);



    mapping(address => bool) public whitelist;



    /**

     * @dev Modifier to allow function calls only from the whitelisted address.

     */

    modifier onlyWhitelisted() {

        require(whitelist[msg.sender], "Not a whitelisted address");

        _;

    }



    /**

     * @dev Initialization function for upgradable proxy contracts

     * @param _nexus Nexus contract address

     * @param _whitelisted Array of whitelisted addresses.

     */

    function _initialize(

        address _nexus,

        address[] memory _whitelisted

    )

        internal

    {

        InitializableModule._initialize(_nexus);



        require(_whitelisted.length > 0, "Empty whitelist array");



        for(uint256 i = 0; i < _whitelisted.length; i++) {

            _addWhitelist(_whitelisted[i]);

        }

    }



    /**

     * @dev Adds a new whitelist address

     * @param _address Address to add in whitelist

     */

    function _addWhitelist(address _address) internal {

        require(_address != address(0), "Address is zero");

        require(! whitelist[_address], "Already whitelisted");



        whitelist[_address] = true;



        emit Whitelisted(_address);

    }



}



/**

 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include

 * the optional functions; to access them see {ERC20Detailed}.

 */



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



library SafeERC20 {

    using SafeMath for uint256;

    using Address for address;



    function safeTransfer(IERC20 token, address to, uint256 value) internal {

        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));

    }



    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {

        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));

    }



    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        // safeApprove should only be called when setting an initial allowance,

        // or when resetting it to zero. To increase and decrease it, use

        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'

        // solhint-disable-next-line max-line-length

        require((value == 0) || (token.allowance(address(this), spender) == 0),

            "SafeERC20: approve from non-zero to non-zero allowance"

        );

        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));

    }



    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).add(value);

        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");

        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    /**

     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement

     * on the return value: the return value is optional (but if data is returned, it must not be false).

     * @param token The token targeted by the call.

     * @param data The call data (encoded using abi.encode or one of its variants).

     */

    function callOptionalReturn(IERC20 token, bytes memory data) private {

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



/**

 * @title  RewardsDistributor

 * @author Stability Labs Pty. Ltd.

 * @notice RewardsDistributor allows Fund Managers to send rewards (usually in MTA)

 * to specified Reward Recipients.

 */

contract RewardsDistributor is InitializableGovernableWhitelist {



    using SafeERC20 for IERC20;



    event RemovedFundManager(address indexed _address);

    event DistributedReward(address funder, address recipient, address rewardToken, uint256 amount);



    /** @dev Recipient is a module, governed by mStable governance */

    constructor(

        address _nexus,

        address[] memory _fundManagers

    )

        public

    {

        InitializableGovernableWhitelist._initialize(_nexus, _fundManagers);

    }



    /**

     * @dev Allows the mStable governance to add a new FundManager

     * @param _address  FundManager to add

     */

    function addFundManager(address _address)

        external

        onlyGovernor

    {

        _addWhitelist(_address);

    }



    /**

     * @dev Allows the mStable governance to remove inactive FundManagers

     * @param _address  FundManager to remove

     */

    function removeFundManager(address _address)

        external

        onlyGovernor

    {

        require(_address != address(0), "Address is zero");

        require(whitelist[_address], "Address is not whitelisted");



        whitelist[_address] = false;



        emit RemovedFundManager(_address);

    }



    /**

     * @dev Distributes reward tokens to list of recipients and notifies them

     * of the transfer. Only callable by FundManagers

     * @param _recipients  Array of Reward recipients to credit

     * @param _amounts     Amounts of reward tokens to distribute

     */

    function distributeRewards(

        IRewardsDistributionRecipient[] calldata _recipients,

        uint256[] calldata _amounts

    )

        external

        onlyWhitelisted

    {

        uint256 len = _recipients.length;

        require(len > 0, "Must choose recipients");

        require(len == _amounts.length, "Mismatching inputs");



        for(uint i = 0; i < len; i++){

            uint256 amount = _amounts[i];

            IRewardsDistributionRecipient recipient = _recipients[i];

            // Send the RewardToken to recipient

            IERC20 rewardToken = recipient.getRewardToken();

            rewardToken.safeTransferFrom(msg.sender, address(recipient), amount);

            // Only after successfull tx - notify the contract of the new funds

            recipient.notifyRewardAmount(amount);



            emit DistributedReward(msg.sender, address(recipient), address(rewardToken), amount);

        }

    }

}