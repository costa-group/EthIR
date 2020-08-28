// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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

// File: contracts/interfaces/ILoanContractDispatcher.sol

pragma solidity 0.5.12;

interface ILoanContractDispatcher {
    event LoanContractCreated(
        address loanDispatcher,
        address contractAddress,
        address indexed originator,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 minInterestRate,
        uint256 maxInterestRate,
        uint256 termEndTimestamp,
        address indexed administrator,
        uint256 operatorFee,
        uint256 auctionLength,
        address indexed tokenAddress
    );

    event MinAmountUpdated(uint256 minAmount, address loanDispatcher);
    event MaxAmountUpdated(uint256 maxAmount, address loanDispatcher);
    event MinInterestRateUpdated(uint256 minInterestRate, address loanDispatcher);
    event MaxInterestRateUpdated(uint256 maxInterestRate, address loanDispatcher);
    event MinTermLengthUpdated(uint256 minTermLength, address loanDispatcher);
    event MinAuctionLengthUpdated(uint256 minAuctionLength, address loanDispatcher);
    event OperatorFeeUpdated(uint256 operatorFee, address loanDispatcher, address administrator);

    event AuthAddressUpdated(address newAuthAddress, address administrator, address loanDispatcher);
    event DaiProxyAddressUpdated(
        address newDaiProxyAddress,
        address administrator,
        address loanDispatcher
    );
    event SwapFactoryAddressUpdated(
        address newSwapFactory,
        address administrator,
        address loanDispatcher
    );

    event AdministratorUpdated(address newAdminAddress, address loanDispatcher);
    event AddTokenToAcceptedList(address tokenAddress, address loanDispatcher);
    event RemoveTokenFromAcceptedList(address tokenAddress, address loanDispatcher);

    event LoanDispatcherCreated(
        address loanDispatcher,
        address auth,
        address DAIProxyAddress,
        address swapFactory,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxInterestRate,
        uint256 minInterestRate,
        uint256 operatorFee,
        uint256 minAuctionLength,
        uint256 minTermLength
    );

    function checkLoanContract(address loanAddress) external view returns (bool);

    function isTokenAccepted(address tokenAddress) external view returns (bool);

    function addTokenToAcceptedList(address tokenAddress) external;

    function removeTokenFromAcceptedList(address tokenAddress) external;
    
    function setAuthAddress(address authAddress) external;

    function setDaiProxyAddress(address daiProxyAddress) external;

    function setAdministrator(address admin) external;

    function setOperatorFee(uint256 newFee) external;

    function setMinAmount(uint256 requestedMinAmount) external;

    function setMaxAmount(uint256 requestedMaxAmount) external;

    function setMinInterestRate(uint256 requestedMinInterestRate) external;

    function setMaxInterestRate(uint256 requestedMaxInterestRate) external;

    function setMinTermLength(uint256 requestedMinTermLength) external;

    function setMinAuctionLength(uint256 requestedMinAuctionLength) external;

    function deploy(
        uint256 loanMinAmount,
        uint256 loanMaxAmount,
        uint256 loanMinInterestRate,
        uint256 loanMaxInterestRate,
        uint256 termLength,
        uint256 auctionLength,
        address tokenAddress
    ) external returns (address);
}

// File: contracts/interfaces/IAuthorization.sol

pragma solidity 0.5.12;

interface IAuthorization {
    function getKycAddress() external view returns (address);

    function getDepositAddress() external view returns (address);

    function hasDeposited(address user) external view returns (bool);

    function isKYCConfirmed(address user) external view returns (bool);

    function setKYCRegistry(address _kycAddress) external returns (bool);

    function setDepositRegistry(address _depositAddress) external returns (bool);
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


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
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

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

// File: contracts/interfaces/IDAIProxy.sol

pragma solidity 0.5.12;

interface IDAIProxy {
    function fund(address loanAddress, uint256 fundingAmount) external;
    function repay(address loanAddress, uint256 repaymentAmount) external;
}

// File: contracts/interfaces/ILoanContract.sol

pragma solidity 0.5.12;

interface ILoanContract {
    function onFundingReceived(address lender, uint256 amount) external returns (bool);
    function withdrawRepayment() external;
    function withdrawRepaymentAndDeposit() external;
    function withdrawLoan() external;
    function onRepaymentReceived(address from, uint256 amount) external returns (bool);
    function getInterestRate() external view returns (uint256);
    function calculateValueWithInterest(uint256 value) external view returns (uint256);
    function getMaxAmount() external view returns (uint256);
    function getAuctionBalance() external view returns (uint256);
    function getTokenAddress() external view returns (address);
}

// File: contracts/interfaces/ISwapAndDeposit.sol

pragma solidity 0.5.12;

interface ISwapAndDeposit {
    event SwapDeposit(address loan, address guy);

    function init(address _depositAddress, address _factoryAddress) external returns (bool);

    function isDestroyed() external view returns (bool);
    function swapAndDeposit(address depositor, address inputTokenAddress, uint256 inputTokenAmount)
        external;
}

// File: contracts/interfaces/ISwapAndDepositFactory.sol

pragma solidity 0.5.12;

interface ISwapAndDepositFactory {
    event SwapContract(address newSwap);

    function setAuthAddress(address _authAddress) external;

    function setUniswapAddress(address _uniswapAddress) external;

    function setLibraryAddress(address _libraryAddress) external;

    function deploy() external returns (address proxyAddress);
}

// File: contracts/libs/ERC20Wrapper.sol

pragma solidity 0.5.12;

interface IERC20Wrapper {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _quantity) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _quantity) external returns (bool);
    function approve(address _spender, uint256 _quantity) external returns (bool);
    function symbol() external view returns (string memory);
}

library ERC20Wrapper {
    function balanceOf(address _token, address _owner) external view returns (uint256) {
        return IERC20Wrapper(_token).balanceOf(_owner);
    }

    function allowance(address _token, address owner, address spender)
        external
        view
        returns (uint256)
    {
        return IERC20Wrapper(_token).allowance(owner, spender);
    }

    function transfer(address _token, address _to, uint256 _quantity) external returns (bool) {
        if (isIssuedToken(_token)) {
            IERC20Wrapper(_token).transfer(_to, _quantity);

            require(checkSuccess(), "ERC20Wrapper.transfer: Bad return value");
            return true;
        } else {
            return IERC20Wrapper(_token).transfer(_to, _quantity);
        }
    }

    function transferFrom(address _token, address _from, address _to, uint256 _quantity)
        external
        returns (bool)
    {
        if (isIssuedToken(_token)) {
            IERC20Wrapper(_token).transferFrom(_from, _to, _quantity);
            // Check that transferFrom returns true or null
            require(checkSuccess(), "ERC20Wrapper.transferFrom: Bad return value");
            return true;
        } else {
            return IERC20Wrapper(_token).transferFrom(_from, _to, _quantity);
        }
    }

    function approve(address _token, address _spender, uint256 _quantity) external returns (bool) {
        if (isIssuedToken(_token)) {
            IERC20Wrapper(_token).approve(_spender, _quantity);
            // Check that approve returns true or null
            require(checkSuccess(), "ERC20Wrapper.approve: Bad return value");
            return true;
        } else {
            return IERC20Wrapper(_token).approve(_spender, _quantity);
        }
    }

    function isIssuedToken(address _token) private returns (bool) {
        return (keccak256(abi.encodePacked((IERC20Wrapper(_token).symbol()))) ==
            keccak256(abi.encodePacked(("USDT"))));
    }

    // ============ Private Functions ============

    /**
     * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
     * function returned 0 bytes or 1.
     */
    function checkSuccess() private pure returns (bool) {
        // default to failure
        uint256 returnValue = 0;

        assembly {
            // check number of bytes returned from last function call
            switch returndatasize
                // no bytes returned: assume success
                case 0x0 {
                    returnValue := 1
                }
                // 32 bytes returned
                case 0x20 {
                    // copy 32 bytes into scratch space
                    returndatacopy(0x0, 0x0, 0x20)

                    // load those bytes into returnValue
                    returnValue := mload(0x0)
                }
                // not sure what was returned: dont mark as success
                default {

                }
        }

        // check if returned value is one or nothing
        return returnValue == 1;
    }
}

// File: contracts/LoanContract.sol

pragma solidity 0.5.12;










contract LoanContract is ILoanContract {
    using SafeMath for uint256;
    address public swapFactory;
    address public proxyContractAddress;
    address public tokenAddress;
    address public originator;
    address public administrator;

    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public auctionEndTimestamp;
    uint256 public auctionStartTimestamp;
    uint256 public auctionLength;
    uint256 public lastFundedTimestamp;
    uint256 public termEndTimestamp;
    uint256 public termLength;
    uint256 public auctionBalance;
    uint256 public loanWithdrawnAmount;
    uint256 public borrowerDebt;
    uint256 public minInterestRate;
    uint256 public maxInterestRate;
    uint256 public operatorFee;
    uint256 public operatorBalance;
    uint256 constant MONTH_SECONDS = 2592000;
    uint256 constant ONE_HUNDRED = 100000000000000000000;

    struct Position {
        uint256 bidAmount;
        bool withdrawn;
    }

    mapping(address => Position) public lenderPosition;

    enum LoanState {
        CREATED, // accepts bids until timelimit initial state
        FAILED_TO_FUND, // not fully funded in timelimit
        ACTIVE, // fully funded, inside timelimit
        DEFAULTED, // not repaid in time loanRepaymentLength
        REPAID, // the borrower repaid in full, lenders have yet to reclaim funds
        CLOSED, // from failed_to_fund => last lender to withdraw triggers change / from repaid => fully witdrawn by lenders
        FROZEN // when admin unlocks withdrawals
    }

    LoanState public currentState;

    IDAIProxy public proxy;

    bool public loanWithdrawn;
    bool public minimumReached;

    event LoanCreated(
        address indexed contractAddr,
        address indexed originator,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 minInterestRate,
        uint256 maxInterestRate,
        uint256 auctionStartTimestamp,
        uint256 auctionEndTimestamp,
        address indexed administrator,
        uint256 operatorFee,
        address tokenAddress
    );

    event MinimumFundingReached(address loanAddress, uint256 currentBalance, uint256 interest);
    event FullyFunded(
        address loanAddress,
        uint256 balanceToRepay,
        uint256 auctionBalance,
        uint256 interest,
        uint256 fundedTimestamp
    );
    event Funded(
        address loanAddress,
        address indexed lender,
        uint256 amount,
        uint256 interest,
        uint256 fundedTimestamp
    );
    event LoanRepaid(address loanAddress, uint256 indexed timestampRepaid);
    event RepaymentWithdrawn(address loanAddress, address indexed to, uint256 amount);
    event RefundWithdrawn(address loanAddress, address indexed lender, uint256 amount);
    event FullyRefunded(address loanAddress);
    event FailedToFund(address loanAddress, address indexed lender, uint256 amount);
    event LoanFundsWithdrawn(address loanAddress, address indexed borrower, uint256 amount);
    event LoanDefaulted(address loanAddress);
    event AuctionSuccessful(
        address loanAddress,
        uint256 balanceToRepay,
        uint256 auctionBalance,
        uint256 operatorBalance,
        uint256 interest,
        uint256 fundedTimestamp
    );
    event FundsUnlockedWithdrawn(address loanAddress, address indexed lender, uint256 amount);
    event FullyFundsUnlockedWithdrawn(address loanAddress);
    event LoanFundsUnlocked(uint256 auctionBalance);
    event OperatorWithdrawn(uint256 amount, address administrator);

    modifier onlyFrozen() {
        require(currentState == LoanState.FROZEN, "Loan status is not FROZEN");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == administrator, "Caller is not an administrator");
        _;
    }

    modifier onlyCreated() {
        require(currentState == LoanState.CREATED, "Loan status is not CREATED");
        _;
    }

    modifier onlyActive() {
        updateStateMachine();
        require(currentState == LoanState.ACTIVE, "Loan status is not ACTIVE");
        _;
    }

    modifier onlyRepaid() {
        updateStateMachine();
        require(currentState == LoanState.REPAID, "Loan status is not REPAID");
        _;
    }

    modifier onlyFailedToFund() {
        updateStateMachine();
        require(currentState == LoanState.FAILED_TO_FUND, "Loan status is not FAILED_TO_FUND");
        _;
    }

    modifier onlyProxy() {
        require(msg.sender == address(proxy), "Caller is not the proxy");
        _;
    }

    modifier onlyOriginator() {
        require(msg.sender == originator, "Caller is not the originator");
        _;
    }

    constructor(
        uint256 _termLength,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _minInterestRate,
        uint256 _maxInterestRate,
        address _originator,
        address _tokenAddress,
        address _proxyAddress,
        address _administrator,
        uint256 _operatorFee,
        uint256 _auctionLength,
        address _swapFactory
    ) public {
        tokenAddress = _tokenAddress;
        proxyContractAddress = _proxyAddress;
        proxy = IDAIProxy(_proxyAddress);
        originator = _originator;
        administrator = _administrator;
        swapFactory = _swapFactory;

        minInterestRate = _minInterestRate;
        maxInterestRate = _maxInterestRate;
        minAmount = _minAmount;
        maxAmount = _maxAmount;

        auctionLength = _auctionLength;
        auctionStartTimestamp = block.timestamp;
        auctionEndTimestamp = auctionStartTimestamp + auctionLength;

        termLength = _termLength;

        loanWithdrawnAmount = 0;

        operatorFee = _operatorFee;

        setState(LoanState.CREATED);
        emit LoanCreated(
            address(this),
            originator,
            minAmount,
            maxAmount,
            minInterestRate,
            maxInterestRate,
            auctionStartTimestamp,
            auctionEndTimestamp,
            administrator,
            operatorFee,
            tokenAddress
        );
    }

    function getMaxAmount() external view returns (uint256) {
        return maxAmount;
    }

    function getAuctionBalance() external view returns (uint256) {
        return auctionBalance;
    }

    function getLenderBidAmount(address lender) external view returns (uint256) {
        return lenderPosition[lender].bidAmount;
    }

    function getLenderWithdrawn(address lender) external view returns (bool) {
        return lenderPosition[lender].withdrawn;
    }

    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }

    // Notes:
    // - This function does not track if real IERC20 balance has changed. Needs to blindly "trust" DaiProxy.
    function onFundingReceived(address lender, uint256 amount)
        external
        onlyCreated
        onlyProxy
        returns (bool)
    {
        if (isAuctionExpired()) {
            if (auctionBalance < minAmount) {
                setState(LoanState.FAILED_TO_FUND);
                emit FailedToFund(address(this), lender, amount);
                return false;
            } else {
                require(setSuccessfulAuction(), "error while transitioning to successful auction");
                emit FailedToFund(address(this), lender, amount);
                return false;
            }
        }
        uint256 interest = getInterestRate();
        lenderPosition[lender].bidAmount = lenderPosition[lender].bidAmount.add(amount);
        auctionBalance = auctionBalance.add(amount);

        lastFundedTimestamp = block.timestamp;

        if (auctionBalance >= minAmount && !minimumReached) {
            minimumReached = true;
            emit Funded(address(this), lender, amount, interest, lastFundedTimestamp);
            emit MinimumFundingReached(address(this), auctionBalance, interest);
        } else {
            emit Funded(address(this), lender, amount, interest, lastFundedTimestamp);
        }

        if (auctionBalance == maxAmount) {
            require(setSuccessfulAuction(), "error while transitioning to successful auction");
            emit FullyFunded(
                address(this),
                borrowerDebt,
                auctionBalance,
                interest,
                lastFundedTimestamp
            );
        }
        return true;
    }

    function unlockFundsWithdrawal() external onlyAdmin {
        setState(LoanState.FROZEN);
        emit LoanFundsUnlocked(auctionBalance);
    }

    function withdrawFees() external onlyAdmin returns (bool) {
        require(loanWithdrawn == true, "borrower didnt withdraw");
        require(operatorBalance > 0, "no funds to withdraw");
        uint256 allFees = operatorBalance;
        operatorBalance = 0;
        require(ERC20Wrapper.transfer(tokenAddress, msg.sender, allFees), "transfer failed");
        emit OperatorWithdrawn(allFees, msg.sender);
        return true;
    }

    function withdrawFundsUnlocked() external onlyFrozen {
        require(!loanWithdrawn, "Loan already withdrawn");
        require(!lenderPosition[msg.sender].withdrawn, "Lender already withdrawn");
        require(lenderPosition[msg.sender].bidAmount > 0, "Account did not deposit");

        lenderPosition[msg.sender].withdrawn = true;

        loanWithdrawnAmount = loanWithdrawnAmount.add(lenderPosition[msg.sender].bidAmount);

        require(
            ERC20Wrapper.transfer(tokenAddress, msg.sender, lenderPosition[msg.sender].bidAmount),
            "error while transfer"
        );

        emit FundsUnlockedWithdrawn(
            address(this),
            msg.sender,
            lenderPosition[msg.sender].bidAmount
        );

        if (loanWithdrawnAmount == auctionBalance.add(operatorBalance)) {
            setState(LoanState.CLOSED);
            emit FullyFundsUnlockedWithdrawn(address(this));
        }
    }

    function withdrawRefund() external onlyFailedToFund {
        require(!lenderPosition[msg.sender].withdrawn, "Lender already withdrawn");
        require(lenderPosition[msg.sender].bidAmount > 0, "Account did not deposited.");

        lenderPosition[msg.sender].withdrawn = true;

        loanWithdrawnAmount = loanWithdrawnAmount.add(lenderPosition[msg.sender].bidAmount);

        emit RefundWithdrawn(address(this), msg.sender, lenderPosition[msg.sender].bidAmount);

        require(
            ERC20Wrapper.transfer(tokenAddress, msg.sender, lenderPosition[msg.sender].bidAmount),
            "error while transfer"
        );

        if (loanWithdrawnAmount == auctionBalance) {
            setState(LoanState.CLOSED);
            emit FullyRefunded(address(this));
        }
    }

    function withdrawRepayment() external onlyRepaid {
        require(!lenderPosition[msg.sender].withdrawn, "Lender already withdrawn");
        require(lenderPosition[msg.sender].bidAmount != 0, "Account did not deposited");
        uint256 amount = calculateValueWithInterest(lenderPosition[msg.sender].bidAmount);
        lenderPosition[msg.sender].withdrawn = true;

        loanWithdrawnAmount = loanWithdrawnAmount.add(amount);
        require(ERC20Wrapper.transfer(tokenAddress, msg.sender, amount), "error while transfer");

        emit RepaymentWithdrawn(address(this), msg.sender, amount);
        if (loanWithdrawnAmount == borrowerDebt) {
            setState(LoanState.CLOSED);
            emit FullyRefunded(address(this));
        }
    }

    function withdrawRepaymentAndDeposit() external onlyRepaid {
        require(swapFactory != address(0), "swap factory is 0");
        require(!lenderPosition[msg.sender].withdrawn, "Lender already withdrawn");
        require(lenderPosition[msg.sender].bidAmount != 0, "Account did not deposited");
        uint256 amount = calculateValueWithInterest(lenderPosition[msg.sender].bidAmount);
        lenderPosition[msg.sender].withdrawn = true;
        loanWithdrawnAmount = loanWithdrawnAmount.add(amount);
        address swapAddress = ISwapAndDepositFactory(swapFactory).deploy();
        require(swapAddress != address(0), "error swap deploy");
        ERC20Wrapper.approve(tokenAddress, swapAddress, amount);
        ISwapAndDeposit(swapAddress).swapAndDeposit(msg.sender, tokenAddress, amount);
        require(
            ISwapAndDeposit(swapAddress).isDestroyed(),
            "Swap contract error, should self-destruct"
        );
        emit RepaymentWithdrawn(address(this), msg.sender, amount);
        if (loanWithdrawnAmount == borrowerDebt) {
            setState(LoanState.CLOSED);
            emit FullyRefunded(address(this));
        }
    }

    function withdrawLoan() external onlyActive onlyOriginator {
        require(!loanWithdrawn, "Already withdrawn");
        loanWithdrawn = true;
        emit LoanFundsWithdrawn(address(this), msg.sender, auctionBalance);
        require(
            ERC20Wrapper.transfer(tokenAddress, msg.sender, auctionBalance),
            "error while transfer"
        );
    }

    function onRepaymentReceived(address from, uint256 amount)
        external
        onlyActive
        onlyProxy
        returns (bool)
    {
        require(from == originator, "from address is not the originator");
        require(borrowerDebt == amount, "Repayment amount is not the same");

        setState(LoanState.REPAID);
        emit LoanRepaid(address(this), block.timestamp);
        return true;
    }

    function isAuctionExpired() public view returns (bool) {
        return block.timestamp > auctionEndTimestamp;
    }

    function isDefaulted() public view returns (bool) {
        if (block.timestamp <= auctionEndTimestamp || block.timestamp <= termEndTimestamp) {
            return false;
        }

        return true;
    }

    function updateStateMachine() public returns (LoanState) {
        if (isAuctionExpired() && currentState == LoanState.CREATED) {
            if (!minimumReached) {
                setState(LoanState.FAILED_TO_FUND);
            } else {
                require(setSuccessfulAuction(), "error while transitioning to successful auction");
            }
        }
        if (isDefaulted() && currentState == LoanState.ACTIVE) {
            setState(LoanState.DEFAULTED);
            emit LoanDefaulted(address(this));
        }

        return currentState;
    }

    function calculateValueWithInterest(uint256 value) public view returns (uint256) {
        return
            value.add(
                value.mul(getInterestRate().mul(termLength).div(MONTH_SECONDS)).div(ONE_HUNDRED)
            );
    }

    function getInterestRate() public view returns (uint256) {
        if (currentState == LoanState.CREATED) {
            return
                (maxInterestRate.sub(minInterestRate))
                    .mul(block.timestamp.sub(auctionStartTimestamp))
                    .div(auctionEndTimestamp.sub(auctionStartTimestamp))
                    .add(minInterestRate);
        } else if (currentState == LoanState.ACTIVE || currentState == LoanState.REPAID) {
            return
                (maxInterestRate.sub(minInterestRate))
                    .mul(lastFundedTimestamp.sub(auctionStartTimestamp))
                    .div(auctionEndTimestamp.sub(auctionStartTimestamp))
                    .add(minInterestRate);
        } else {
            return 0;
        }
    }

    function setState(LoanState state) internal {
        currentState = state;
    }

    function setSuccessfulAuction() internal onlyCreated returns (bool) {
        setState(LoanState.ACTIVE);
        borrowerDebt = calculateValueWithInterest(auctionBalance);
        operatorBalance = auctionBalance.mul(operatorFee).div(ONE_HUNDRED);
        auctionBalance = auctionBalance - operatorBalance;

        if (block.timestamp < auctionEndTimestamp) {
            termEndTimestamp = block.timestamp.add(termLength);
        } else {
            termEndTimestamp = auctionEndTimestamp.add(termLength);
        }

        emit AuctionSuccessful(
            address(this),
            borrowerDebt,
            auctionBalance,
            operatorBalance,
            getInterestRate(),
            lastFundedTimestamp
        );
        return true;
    }
}

// File: contracts/LoanContractDispatcher.sol

pragma solidity 0.5.12;






contract LoanContractDispatcher is ILoanContractDispatcher, Ownable {
    address public auth;
    address public DAIProxyAddress;
    address public swapFactory;

    address public administrator;

    uint256 public operatorFee;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public minTermLength;
    uint256 public minAuctionLength;

    uint256 public minInterestRate;
    uint256 public maxInterestRate;

    mapping(address => bool) public acceptedTokens;

    mapping(address => bool) public isLoanContract;

    modifier onlyKYC {
        require(IAuthorization(auth).isKYCConfirmed(msg.sender), "user does not have KYC");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == administrator, "Caller is not an administrator");
        _;
    }

    event LoanContractCreated(
        address loanDispatcher,
        address contractAddress,
        address indexed originator,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 minInterestRate,
        uint256 maxInterestRate,
        uint256 termEndTimestamp,
        address indexed administrator,
        uint256 operatorFee,
        uint256 auctionLength,
        address indexed tokenAddress
    );

    event MinAmountUpdated(uint256 minAmount, address loanDispatcher);
    event MaxAmountUpdated(uint256 maxAmount, address loanDispatcher);
    event MinInterestRateUpdated(uint256 minInterestRate, address loanDispatcher);
    event MaxInterestRateUpdated(uint256 maxInterestRate, address loanDispatcher);
    event MinTermLengthUpdated(uint256 minTermLength, address loanDispatcher);
    event MinAuctionLengthUpdated(uint256 minAuctionLength, address loanDispatcher);
    event OperatorFeeUpdated(uint256 operatorFee, address loanDispatcher, address administrator);

    event AuthAddressUpdated(address newAuthAddress, address administrator, address loanDispatcher);
    event DaiProxyAddressUpdated(
        address newDaiProxyAddress,
        address administrator,
        address loanDispatcher
    );
    event SwapFactoryAddressUpdated(
        address newSwapFactory,
        address administrator,
        address loanDispatcher
    );

    event AdministratorUpdated(address newAdminAddress, address loanDispatcher);
    event AddTokenToAcceptedList(address tokenAddress, address loanDispatcher);
    event RemoveTokenFromAcceptedList(address tokenAddress, address loanDispatcher);

    event LoanDispatcherCreated(
        address loanDispatcher,
        address auth,
        address DAIProxyAddress,
        address swapFactory,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxInterestRate,
        uint256 minInterestRate,
        uint256 operatorFee,
        uint256 minAuctionLength,
        uint256 minTermLength
    );

    constructor(address authAddress, address _DAIProxyAddress, address _swapFactory) public {
        auth = authAddress;
        DAIProxyAddress = _DAIProxyAddress;
        swapFactory = _swapFactory;
        minAmount = 1e18;
        maxAmount = 2500000e18;

        maxInterestRate = 20e18;
        minInterestRate = 0e18;
        operatorFee = 2e18;

        minAuctionLength = 604800;
        minTermLength = 2592000;

        emit LoanDispatcherCreated(
            address(this),
            auth,
            DAIProxyAddress,
            swapFactory,
            minAmount,
            maxAmount,
            maxInterestRate,
            minInterestRate,
            operatorFee,
            minAuctionLength,
            minTermLength
        );
    }

    function isTokenAccepted(address tokenAddress) external view returns (bool) {
        return acceptedTokens[tokenAddress];
    }

    function addTokenToAcceptedList(address tokenAddress) external onlyAdmin {
        acceptedTokens[tokenAddress] = true;
        emit AddTokenToAcceptedList(tokenAddress, address(this));
    }

    function removeTokenFromAcceptedList(address tokenAddress) external onlyAdmin {
        acceptedTokens[tokenAddress] = false;
        emit RemoveTokenFromAcceptedList(tokenAddress, address(this));
    }

    function setAuthAddress(address authAddress) external onlyAdmin {
        auth = authAddress;
        emit AuthAddressUpdated(authAddress, administrator, address(this));
    }

    function setDaiProxyAddress(address daiProxyAddress) external onlyAdmin {
        DAIProxyAddress = daiProxyAddress;
        emit DaiProxyAddressUpdated(DAIProxyAddress, administrator, address(this));
    }

    function setSwapFactory(address _swapFactory) external onlyAdmin {
        swapFactory = _swapFactory;
        emit SwapFactoryAddressUpdated(swapFactory, administrator, address(this));
    }

    function setAdministrator(address admin) external onlyOwner {
        administrator = admin;
        emit AdministratorUpdated(administrator, address(this));
    }

    function setOperatorFee(uint256 newFee) external onlyAdmin {
        operatorFee = newFee;
        emit OperatorFeeUpdated(operatorFee, address(this), msg.sender);
    }

    function setMinAmount(uint256 requestedMinAmount) external onlyAdmin {
        require(
            requestedMinAmount <= maxAmount,
            "Minimum amount needs to be lesser or equal than maximum amount"
        );
        minAmount = requestedMinAmount;
        emit MinAmountUpdated(minAmount, address(this));
    }

    function setMaxAmount(uint256 requestedMaxAmount) external onlyAdmin {
        require(
            requestedMaxAmount >= minAmount,
            "Maximum amount needs to be greater or equal than minimum amount"
        );
        maxAmount = requestedMaxAmount;
        emit MaxAmountUpdated(maxAmount, address(this));
    }

    function setMinInterestRate(uint256 requestedMinInterestRate) external onlyAdmin {
        require(
            requestedMinInterestRate <= maxInterestRate,
            "Minimum interest needs to be lesser or equal than maximum interest"
        );
        minInterestRate = requestedMinInterestRate;
        emit MinInterestRateUpdated(minInterestRate, address(this));
    }

    function setMaxInterestRate(uint256 requestedMaxInterestRate) external onlyAdmin {
        require(
            requestedMaxInterestRate >= minInterestRate,
            "Maximum interest needs to be greater or equal than minimum interest"
        );
        maxInterestRate = requestedMaxInterestRate;
        emit MaxInterestRateUpdated(maxInterestRate, address(this));
    }

    function setMinTermLength(uint256 requestedMinTermLength) external onlyAdmin {
        minTermLength = requestedMinTermLength;
        emit MinTermLengthUpdated(minTermLength, address(this));
    }

    function setMinAuctionLength(uint256 requestedMinAuctionLength) external onlyAdmin {
        minAuctionLength = requestedMinAuctionLength;
        emit MinAuctionLengthUpdated(minAuctionLength, address(this));
    }

    function deploy(
        uint256 loanMinAmount,
        uint256 loanMaxAmount,
        uint256 loanMinInterestRate,
        uint256 loanMaxInterestRate,
        uint256 termLength,
        uint256 auctionLength,
        address tokenAddress
    ) external onlyKYC returns (address) {
        require(administrator != address(0), "There is no administrator set");
        require(
            loanMinAmount >= minAmount &&
                loanMinAmount <= maxAmount &&
                loanMinAmount <= loanMaxAmount,
            "minimum amount not correct"
        );
        require(
            loanMaxAmount >= minAmount &&
                loanMaxAmount <= maxAmount &&
                loanMaxAmount >= loanMinAmount,
            "maximum amount not correct"
        );
        require(
            loanMaxInterestRate >= minInterestRate && loanMaxInterestRate <= maxInterestRate,
            "maximum interest rate not correct"
        );
        require(
            loanMinInterestRate >= minInterestRate && loanMinInterestRate <= maxInterestRate,
            "minimum interest rate not correct"
        );
        require(
            loanMaxInterestRate >= loanMinInterestRate,
            "minimum interest should not be greater than maximum interest"
        );
        require(termLength >= minTermLength, "Term length is to small");
        require(auctionLength >= minAuctionLength, "Auction length is to small");
        require(acceptedTokens[tokenAddress] == true, "TokenAddress not accepted");

        LoanContract loanContract = new LoanContract(
            termLength,
            loanMinAmount,
            loanMaxAmount,
            loanMinInterestRate,
            loanMaxInterestRate,
            msg.sender,
            tokenAddress,
            DAIProxyAddress,
            administrator,
            operatorFee,
            auctionLength,
            swapFactory
        );
        isLoanContract[address(loanContract)] = true;

        emit LoanContractCreated(
            address(this),
            address(loanContract),
            msg.sender,
            loanMinAmount,
            loanMaxAmount,
            loanMinInterestRate,
            loanMaxInterestRate,
            termLength,
            administrator,
            operatorFee,
            auctionLength,
            tokenAddress
        );

        return address(loanContract);
    }

    function checkLoanContract(address loanAddress) external view returns (bool) {
        return isLoanContract[loanAddress];
    }
}