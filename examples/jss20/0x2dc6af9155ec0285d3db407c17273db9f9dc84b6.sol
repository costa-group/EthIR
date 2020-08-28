pragma solidity 0.5.8;

interface ERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function transferFrom(address from, address to, uint256 value) external returns (bool);
	function approve(address spender, uint256 value) external returns (bool);
}

contract ERC20HTLCLite {
	struct Swap {
		uint256 outAmount; //The ERC20 Pra amount to swap out
		uint256 expireHeight; //The height of blocks to wait before the asset can be returned to sender
		bytes32 randomNumberHash;
		uint64 timestamp;
		address senderAddr; //The swap creator address
		uint256 senderChainType;
		uint256 receiverChainType;
		address recipientAddr; //The ethereum address to lock swapped assets, counter-party of senderAddr
		string receiverAddr; //The PRA address (DID) to swap out
	}

	enum States {INVALID, OPEN, COMPLETED, EXPIRED}

	enum ChainTypes {ETH, PRA}

	// Events
	event HTLC(
		address indexed _msgSender,
		address indexed _recipientAddr,
		bytes32 indexed _swapID,
		bytes32 _randomNumberHash,
		uint64 _timestamp,
		uint256 _expireHeight,
		uint256 _outAmount,
		uint256 _praAmount,
		string _receiverAddr
	);
	event Claimed(
		address indexed _msgSender,
		address indexed _recipientAddr,
		bytes32 indexed _swapID,
		bytes32 _randomNumber,
		string _receiverAddr
	);
	event Refunded(
		address indexed _msgSender,
		address indexed _recipientAddr,
		bytes32 indexed _swapID,
		bytes32 _randomNumberHash,
		string _receiverAddr
	);

	// Storage, key: swapID
	mapping(bytes32 => Swap) private swaps;
	mapping(bytes32 => States) private swapStates;

	address public praContractAddr;
	address public praRecipientAddr;
	address public owner;
	address public admin;

	// whether the contract is paused
    bool public paused = false;

	/// @param _praContract The PRA contract address
	constructor(address _praContract) public {
		praContractAddr = _praContract;
		owner = msg.sender;
	}

	/// @notice Throws if the msg.sender is not admin or owner.
	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner);
		_;
	}

	/// @notice Modifier to allow actions only when the contract IS NOT paused
	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	/// @notice Modifier to allow actions only when the contract IS paused
	modifier whenPaused {
		require(paused);
		_;
	}

	/// @notice to pause the contract.
	function pause() public onlyAdmin whenNotPaused returns (bool) {
		paused = true;
		return paused;
	}

	/// @notice to unpause the contract.
	function unpause() public onlyAdmin whenPaused returns (bool) {
		paused = false;
		return paused;
	}

	/// @notice setAdmin set new admin address.
	///
	/// @param _new_admin The new admin address.
	function setAdmin(address _new_admin) public onlyAdmin {
		require(_new_admin != address(0));
		admin = _new_admin;
	}

	/// @notice setPraAddress set new PRA-ERC20 contract address.
	///
	/// @param _praContract The new PRA-ERC20 contract address.
	function setPraAddress(address _praContract) public onlyAdmin {
		praContractAddr = _praContract;
	}

	/// @notice setRecipientAddr set new PRA-ERC20 recipient address.
	///
	/// @param _recipientAddr The new PRA-ERC20 recipient address.
	function setRecipientAddr(address _recipientAddr) public onlyAdmin {
		praRecipientAddr = _recipientAddr;
	}

	// swap may only be built through the htlc function
	function() external payable { revert();	}

	//TODO: init set recipientAddr

	/// @notice htlt locks asset to contract address and create an atomic swap.
	///
	/// @param _randomNumberHash The hash of the random number and timestamp
	/// @param _timestamp Counted by second
	/// @param _heightSpan The number of blocks to wait before the asset can be returned to sender
	/// @param _outAmount PRA ERC20 asset to swap out, precision is 18
	/// @param _praAmount PRA asset to swap in, precision is 18
	/// @param _receiverAddr PRA DID to swap in.
	function htlc(
		bytes32 _randomNumberHash,
		uint64 _timestamp,
		uint256 _heightSpan,
		uint256 _outAmount,
		uint256 _praAmount,
		string memory _receiverAddr
	) public whenNotPaused returns (bool) {
		bytes32 swapID = calSwapID(_randomNumberHash, _receiverAddr);
		require(swapStates[swapID] == States.INVALID, "swap is opened previously");
		// Assume average eth block time interval is 15 second
		// The heightSpan period should be more than 15 minutes
		require(_heightSpan >= 60 && _heightSpan <= 60480, "_heightSpan should be in [60, 60480]");
		require(_outAmount >= 100000000000000000, "_outAmount must be more than 0.1");
		require(
			_timestamp > now - 1800 && _timestamp < now + 1800,
			"Timestamp must be 30 minutes between current time"
		);
		require(_outAmount == _praAmount, "_outAmount must be equal _praAmount");

		// Store the details of the swap.
		Swap memory swap = Swap({
			outAmount: _outAmount,
			expireHeight: _heightSpan + block.number,
			randomNumberHash: _randomNumberHash,
			timestamp: _timestamp,
			senderAddr: msg.sender,
			senderChainType: uint256(ChainTypes.ETH),
			receiverAddr: _receiverAddr,
			receiverChainType: uint256(ChainTypes.PRA),
			recipientAddr: praRecipientAddr
		});

		//step 1: Init
		swaps[swapID] = swap;
		swapStates[swapID] = States.OPEN;

		// Transfer pra token to the swap contract
		require(
			ERC20(praContractAddr).transferFrom(msg.sender, address(this), _outAmount),
			"failed to transfer client asset to swap contract"
		);

		// Emit initialization event
		emit HTLC(
			msg.sender,
			praRecipientAddr,
			swapID,
			_randomNumberHash,
			_timestamp,
			swap.expireHeight,
			_outAmount,
			_praAmount,
			_receiverAddr
		);

		//step 2: Claim
		// Complete the swap.
		swapStates[swapID] = States.COMPLETED;

		// Pay erc20 token to recipient
		require(
			ERC20(praContractAddr).transfer(praRecipientAddr, _outAmount),
			"Failed to transfer locked asset to recipient"
		);

		// delete closed swap
		delete swaps[swapID];

		// Emit completion event
		emit Claimed(msg.sender, praRecipientAddr, swapID, _randomNumberHash, _receiverAddr);

		return true;
	}

	/// @notice query an atomic swap by randomNumberHash
	///
	/// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
	function queryOpenSwap(bytes32 _swapID)
		external
		view
		returns (
			bytes32 _randomNumberHash,
			uint64 _timestamp,
			uint256 _expireHeight,
			uint256 _outAmount,
			address _sender,
			address _recipient
		)
	{
		Swap memory swap = swaps[_swapID];
		return (
			swap.randomNumberHash,
			swap.timestamp,
			swap.expireHeight,
			swap.outAmount,
			swap.senderAddr,
			swap.recipientAddr
		);
	}

	/// @notice Checks whether a swap with specified swapID exist
	///
	/// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
	function isSwapExist(bytes32 _swapID) external view returns (bool) {
		return (swapStates[_swapID] != States.INVALID);
	}

	/// @notice Calculate the swapID from randomNumberHash and swapCreator
	///
	/// @param _randomNumberHash The hash of random number and timestamp.
	/// @param receiverAddr The PRA address (DID) to swap out
	function calSwapID(bytes32 _randomNumberHash, string memory receiverAddr) public pure returns (bytes32) {
		return sha256(abi.encodePacked(_randomNumberHash, receiverAddr));
	}
}