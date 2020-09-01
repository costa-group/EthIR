pragma solidity 0.5.16;
// deployed at 0xBea62796855548154464F6C8E7BC92672C9F87b8

// @title ShareToken
// @notice Shares all ETH received by the contract with token holders.
// Example: If Alice was holding 5% of all ShareToken during a time when the contract received 100 ETH, then
// Alice gets 5 ETH.
// @dev This contract is a modification of OpenZeppelin's ERC20Detailed v2.3.0.
// SECURITY: We have removed the _mint and _burn functions and made the _totalSupply constant to prevent multiple
// security vulnerabilities related to improper accounting of dividends.
// SECURITY: We have added new functionality to track dividends that modifies the _transfer function.
contract ShareToken {
    using SafeMath for uint256;

    // ======
    // EVENTS
    // ======

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event DividendWithdrawal(address indexed account, uint256 amount);

    event Announce(string message);

    // ==========
    // CONSTANTS
    // ==========

    string  constant private _name = "Shares";

    string  constant private _symbol = "SHARE";

    uint8   constant private _decimals = 18;

    uint256 constant private _totalSupply = 1e8 * (10 ** uint256(_decimals));

    address constant private _speaker = 0x13f194f9141325c3C8c25b36772Ee5CF35c2ef3a;

    // =========
    // VARIABLES
    // =========

    struct Dividend {
        uint256 checkpoint; // total contract income when the Dividend was last updated
        uint256 dividendBalance; // dividend balance when the Dividend was last updated
    }

    uint256 private _totalEthWithdrawals; // total amount of ETH that has exited this contract

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => Dividend) private _dividends;

    // ========================
    // FALLBACK AND CONSTRUCTOR
    // ========================

    function() external payable {}

    constructor () public {
        // assign initial supply to original _designers
        _balances[0x6Da435A99877EB20b00DF4fD8Ea80A67Ecf39ADb] = _totalSupply.div(4);
        emit Transfer(address(0), 0x6Da435A99877EB20b00DF4fD8Ea80A67Ecf39ADb, _totalSupply.div(4));

        _balances[0xfcC65D8B75a902D0e25e968B003fcbAd4EeA9616] = _totalSupply.div(4);
        emit Transfer(address(0), 0xfcC65D8B75a902D0e25e968B003fcbAd4EeA9616, _totalSupply.div(4));

        _balances[0x036aF49114C79f3c87DaFe847dD2fF2e566cf7A9] = _totalSupply.div(4);
        emit Transfer(address(0), 0x036aF49114C79f3c87DaFe847dD2fF2e566cf7A9, _totalSupply.div(4));

        _balances[0x3504f5ea9E4AF3a31054Fb2Fe680Af65AAb92d74] = _totalSupply.div(4);
        emit Transfer(address(0), 0x3504f5ea9E4AF3a31054Fb2Fe680Af65AAb92d74, _totalSupply.div(4));
    }

    // ============================
    // PRIVATE / INTERNAL FUNCTIONS
    // ============================

    function _earnedSinceCheckpoint(address account) internal view returns (uint256) {
        uint256 incomeSinceLastUpdate = totalIncome().sub(_dividends[account].checkpoint);
        return incomeSinceLastUpdate.mul(_balances[account]).div(_totalSupply);
    }

    function _updateDividend(address account) internal {
        _dividends[account].dividendBalance = _dividends[account].dividendBalance.add(_earnedSinceCheckpoint(account));
        _dividends[account].checkpoint = totalIncome();
    }
   function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _updateDividend(sender);
        _updateDividend(recipient);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // SECURITY: This should be the only way to get ETH out of this contract.
    function _withdrawDividends(address payable account, uint256 amount) internal {
        _updateDividend(account);
        _dividends[account].dividendBalance = _dividends[account].dividendBalance.sub(amount);
        _totalEthWithdrawals = _totalEthWithdrawals.add(amount);

        emit DividendWithdrawal(account, amount);
        address(account).transfer(amount);
    }

    // =============================================
    // EXTERNAL FUNCTIONS THAT MODIFY CONTRACT STATE
    // =============================================

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function withdrawDividends(uint256 amount) external returns (bool) {
        _withdrawDividends(msg.sender, amount);
        return true;
    }

    function announce(bytes memory b) public {
        require(msg.sender == _speaker);
        emit Announce(bytesToString(b));
    }

    function pay() external payable {}

    // =======================
    // VIEW / PURE FUNCTIONS
    // =======================
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function totalEthWithdrawals() public view returns (uint256) {
        return _totalEthWithdrawals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function dividendBalanceOf(address account) public view returns (uint256) {
        return _dividends[account].dividendBalance.add(_earnedSinceCheckpoint(account));
    }

    // @return The total amount of ETH this contract has ever received.
    // @dev This is a non-decreasing function over time.
    function totalIncome() public view returns (uint256) {
        return address(this).balance.add(_totalEthWithdrawals);
    }

    function stringToBytes(string memory m) public pure returns (bytes memory) {
        bytes memory b = abi.encode(m);
        return b;
    }

    function bytesToString(bytes memory b) public pure returns (string memory) {
        string memory s = abi.decode(b, (string));
        return s;
    }
}



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}