pragma solidity ^0.5.0;

/*
 *	utils.sol
 */
 
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
 *	HEX.sol
 */
 
interface HEX{
	
	// These are the needed calls from the original HEX contract
	
    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }
	
    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }
	
	function xfLobbyMembers(uint256 i, address _XfLobbyQueueStore) external view returns(uint40 headIndex, uint40 tailIndex);
	function xfLobbyEnter(address referrerAddr) external payable;
	function currentDay() external view returns (uint256);
	function xfLobbyExit(uint256 enterDay, uint256 count) external;
	
	
	// Following code is standard IERC20 interface:
	// Since I don't think you can inherit interfaces internaly yet
	
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
 *	ERC20Distributor.sol
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
    constructor(IERC20 _token) public {
        handledToken = _token;
    }
	
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
 
    function distributeTokens() public payable { 
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
	
	function withdrawERC20(IERC20 _token) public payable onlyOwner{
		require(_token.balanceOf(address(this)) > 0);
		_token.transfer(owner, _token.balanceOf(address(this)));
	}
}

/*
 *	HEXAutomator.sol
 */

contract HEXAutomator is Owned{
	HEX public HEXcontract = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
	ERC20Distributor public Distributor;
	
	bool public autoDistribution = true;
	uint256 public distributionWeekday = 5; 
	uint256 public distributionCycle = 1;
	uint256 public distributionCycleCounter = 0;
	
	constructor(ERC20Distributor _distAddr) public {
        Distributor = ERC20Distributor(_distAddr);
    }
	
	function () payable external{
		require(msg.value > 0);
		
		// Enter current open HEX Lobby with contracts address as referral
		HEXcontract.xfLobbyEnter.value(msg.value)(address(this));
		
		// Exits all past still open lobby entries
		selfLobbyExitAll();
		
		// Sends the received HEX to the Distributor
		withdrawHEXToDistributor();
		
		// check if distribution conditions are set & do it if so
		checkAutoDistribution();
	}
	
	// returns current day of hex contract
	function hexCurrentDay() public view 
		returns(uint256 currentDay){
		return HEXcontract.currentDay();
	}
	
	// iterates through all past days and returns an array of all days, 
	// which still have open lobbys including the current day if so
	function getOpenLobbyDays() public view returns(
		uint256[] memory openLobbyDays,
		uint256 openLobbyDaysCount
	){
		uint256 currentDay = hexCurrentDay();
		openLobbyDaysCount = 0;
		
		uint256[] memory openLobbyDaysIterator = new uint256[](currentDay + 1);
		
		for(uint256 i = 0; i <= currentDay; i++)
		{
			(uint40 HEX_headIndex, uint40 HEX_tailIndex) = 
			    HEXcontract.xfLobbyMembers(i, address(this));
			if(HEX_tailIndex > 0 && HEX_headIndex < HEX_tailIndex){
				openLobbyDaysIterator[i] = i + 1;
				openLobbyDaysCount++;
			}
		}
		
		uint256 counter = 0; 
		
		openLobbyDays = new uint256[](openLobbyDaysCount);
		
		for(uint i = 0; i <= currentDay; i++)
		{
			if(openLobbyDaysIterator[i] != 0){
				openLobbyDays[counter] = openLobbyDaysIterator[i] - 1;
				counter++;
			}
		}
		
		return (openLobbyDays, openLobbyDaysCount);
	}
	
	// Exits all still open lobby entries of this contract
	function selfLobbyExitAll() public {
		uint256[] memory openLobbyDays;
		
		(openLobbyDays,) = getOpenLobbyDays();
		
		for(uint i = 0; i < openLobbyDays.length; i++)
		{
			if(openLobbyDays[i] < hexCurrentDay()){
				selfLobbyExit(openLobbyDays[i], 0);
			}
		}
	}
	
	// Exits the smart contracts address of given enterDays HEX Lobby
	// _count can be 0 for default all, it's forwarded to HEX xfLobbyExit contract
	function selfLobbyExit(uint256 _enterDay, uint256 _count) public {
		
		require(_enterDay < hexCurrentDay());
		
		(uint40 HEX_headIndex, uint40 HEX_tailIndex) = 
			HEXcontract.xfLobbyMembers(_enterDay, address(this));
			
		if(HEX_tailIndex > 0 && HEX_headIndex < HEX_tailIndex){
			HEXcontract.xfLobbyExit(_enterDay, _count);
			distributionCycleCounter++;
		}
	}
	
	// transfers all on this contracts sitting HEX to the Distributor
	function withdrawHEXToDistributor() public {
		uint256 HEX_balance = HEXcontract.balanceOf(address(this));
		if(HEX_balance > 0){
			HEXcontract.transfer(address(Distributor), HEX_balance);
		}
	}
	
	// if autoDistribution is true, check conditions (weekday & cycles)
	// for autoDistribution and perform if valid
	function checkAutoDistribution() private {
		if(autoDistribution){
			if((distributionWeekday != 0 && (hexCurrentDay() + 7 - distributionWeekday) % 7 == 0) || 
				(distributionCycle != 0 && distributionCycleCounter >= distributionCycle)){
				if(HEXcontract.balanceOf(address(Distributor)) > 0){
					distributionCycleCounter = 0;
					Distributor.distributeTokens();
				}
			}
		}
	}
	
	// owner can change Distributor
	function changeDistributor(ERC20Distributor _distAddr) public onlyOwner{
        Distributor = ERC20Distributor(_distAddr);
	}
	
	// owner can switch auto distribution on/off
	function switchAutoDistribution() public onlyOwner{
		if(autoDistribution){
			autoDistribution = false;
		} else {
			autoDistribution = true;
		}
	}
	
	// @param _weekday: 0 = sunday, 1 = monday, ... , 6 = saturday | -1 to disable
	// Note: autoDistribution need to be true for auto distribution to work
	function changeDistributionWeekday(int256 _weekday) public onlyOwner{
		require(_weekday >= -1, "_weekday must be between -1 to 6");
		require(_weekday <= 6, "_weekday must be between -1 to 6");
		if(_weekday >= 0){
			distributionWeekday = 5 + uint256(_weekday);
			// 5 + ... syncs 0-6 notation to sunday - saturday,
			// due to hex contract starting with 0 on a tuesday
		} else {
			distributionWeekday = 0;
		}
	}
	
	// @param _cycle: number of lobbys, the contract shall participated & exited in
	// 				  before it auto distributes accumulated HEX | 0 to disable
	function changeDistributionCycle(uint256 _cycle) public onlyOwner{
		require(_cycle < 350, "Can't go higher than 350 cycles/days");
		distributionCycle = _cycle;
	}
		
	// allows the creator to withdraw any ERC20 Token,
	// which might land here
	function withdrawERC20(IERC20 _token) public onlyOwner {
		require(_token.balanceOf(address(this)) > 0, "no balance");
		_token.transfer(owner, _token.balanceOf(address(this)));
	}

	// destroys contract 
	// !! Attention !!
	// Be sure the contract hasn't any more open lobbys nor any funds on it
	function kill(bool _die) public onlyOwner {
		require(_die);
		selfdestruct(owner);
	}
}