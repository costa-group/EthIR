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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract Owned {
    constructor() public { owner = msg.sender; }
    address payable owner;

    // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

/*
	Allows the creator to specify different addresses with differently sized shares,
	which will get accordingly sized portions of all Tokens from handledToken, 
	sitting in this smart contract, by calling distributeTokens() from anyone.
*/
contract ERC20Distributor is Owned{
	using SafeMath for uint256;
	
    IERC20 public handledToken;
    
    struct Account {
        address addy;
        uint256 share;
    }
    
	Account[] accounts;
    uint256 totalShares = 0;
	uint256 totalAccounts = 0;
	uint256 fullViewPercentage = 10000;
	
    // Constructor. Pass it the token you want this contract to work with
	// This can't be changed!
    constructor(IERC20 _token) public {
        handledToken = _token;
    }
	
	// get general infos about the contracts state
	function getGlobals() public view returns(
		uint256 _tokenBalance, 
		uint256 _totalAccounts, 
		uint256 _totalShares, 
		uint256 _fullViewPercentage){
		return (
			handledToken.balanceOf(address(this)), 
			totalAccounts, 
			totalShares, 
			fullViewPercentage
		);
	}
	
	// get specific infos about a account which is defined in this contract
	function getAccountInfo(uint256 index) public view returns(
		uint256 _tokenBalance,
		uint256 _tokenEntitled,
		uint256 _shares, 
		uint256 _percentage,
		address _address){
		return (
			handledToken.balanceOf(accounts[index].addy),
			(accounts[index].share.mul(handledToken.balanceOf(address(this)))).div(totalShares),
			accounts[index].share, 
			(accounts[index].share.mul(fullViewPercentage)).div(totalShares), 
			accounts[index].addy
		);
	}
 
	// called by anyone, distributes all handledToken sitting in this contract
	// to the defined accounts, accordingly to their current share portion
    function distributeTokens() public { 
		uint256 sharesProcessed = 0;
		uint256 currentAmount = handledToken.balanceOf(address(this));
		
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].share > 0 && accounts[i].addy != address(0)){
				uint256 amount = (currentAmount.mul(accounts[i].share)).div(totalShares.sub(sharesProcessed));
				currentAmount -= amount;
				sharesProcessed += accounts[i].share;
				handledToken.transfer(accounts[i].addy, amount);
			}
		}
    }

	// add or update existing account, defined by it's address & shares
    function writeAccount(address _address, uint256 _share) public onlyOwner {
        require(_address != address(0), "address can't be 0 address");
        require(_address != address(this), "address can't be this contract address");
        require(_share > 0, "share must be more than 0");
		deleteAccount(_address);
        Account memory acc = Account(_address, _share);
        accounts.push(acc);
        totalShares += _share;
		totalAccounts++;
    }
    
	// removes existing account from account list
    function deleteAccount(address _address) public onlyOwner{
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].addy == _address){
				totalShares -= accounts[i].share;
				if(i < accounts.length - 1){
					accounts[i] = accounts[accounts.length - 1];
				}
				delete accounts[accounts.length - 1];
				accounts.length--;
				totalAccounts--;
			}
		}
    }
	
	// allows the creator to withdraw any other ERC20 Token,
	// which might land here
	function withdrawOtherERC20(IERC20 _token) public onlyOwner{
		require(_token.balanceOf(address(this)) > 0, "no balance");
		require(_token != handledToken, "not allowed to withdraw handledToken");
		_token.transfer(owner, _token.balanceOf(address(this)));
	}
}