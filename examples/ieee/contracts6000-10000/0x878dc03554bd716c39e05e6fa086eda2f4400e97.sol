pragma solidity 0.5.17;


interface DharmaGasReserveInterface {
    event Pulled(address indexed gasAccount, uint256 amount);

    function pullGas() external;

    function addGasAccount(address gasAccount) external;
    function removeGasAccount(address gasAccount) external;
    function setPullAmount(uint256 amount) external;
    function setRateLimit(uint256 interval) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);

    function getGasAccounts() external view returns (address[] memory);
    function getPullAmount() external view returns (uint256);
    function getRateLimit() external view returns (uint256);
    function getLastPullTime(address gasAccount) external view returns (uint256);
}


contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() internal {
    _owner = tx.origin;
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
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


contract DharmaGasReserve is DharmaGasReserveInterface, TwoStepOwnable {
    // Track all authorized gas accounts.
    address[] private _gasAccounts;

    // Indexes start at 1, as 0 signifies non-inclusion
    mapping (address => uint256) private _gasAccountIndexes;
    
    mapping (address => uint256) private _lastPullTime;
    
    uint256 private _pullAmount;
    uint256 private _rateLimit;

    constructor(address[] memory initialGasAccounts) public {
        _pullAmount = 3 ether;
        _rateLimit = 1 hours;
        for (uint256 i; i < initialGasAccounts.length; i++) {
            address gasAccount = initialGasAccounts[i];
            _addGasAccount(gasAccount);
        }
    }

    function pullGas() external {
        require(
            _gasAccountIndexes[msg.sender] != 0,
            "Only authorized gas accounts may pull from this contract."
        );

        require(
            now > _lastPullTime[msg.sender] + _rateLimit,
            "Gas account is currently rate-limited."
        );
        _lastPullTime[msg.sender] = now;

        uint256 pullAmount = _pullAmount;
        (bool ok, ) = msg.sender.call.value(pullAmount)("");
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }

        emit Pulled(msg.sender, pullAmount);
    }

    function addGasAccount(address gasAccount) external onlyOwner {
        _addGasAccount(gasAccount);
    }

    function removeGasAccount(address gasAccount) external onlyOwner {
        uint256 removedGasAccountIndex = _gasAccountIndexes[gasAccount];
        require(
            removedGasAccountIndex != 0,
            "No gas account found matching the provided account."
        );

        // swap account to remove with the last one then pop from the array.
        address lastGasAccount = _gasAccounts[_gasAccounts.length - 1];
        _gasAccounts[removedGasAccountIndex - 1] = lastGasAccount;
        _gasAccountIndexes[lastGasAccount] = removedGasAccountIndex;
        _gasAccounts.pop();
        delete _gasAccountIndexes[gasAccount];
    }

    function setPullAmount(uint256 amount) external onlyOwner {
        _pullAmount = amount;
    }

    function setRateLimit(uint256 interval) external onlyOwner {
        _rateLimit = interval;
    }

    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external onlyOwner returns (bool ok, bytes memory returnData) {
        // Call the specified target and supply the specified data.
        (ok, returnData) = target.call.value(amount)(data);
    }

    function getGasAccounts() external view returns (address[] memory) {
        return _gasAccounts;
    }

    function getPullAmount() external view returns (uint256) {
        return  _pullAmount;
    }

    function getRateLimit() external view returns (uint256) {
        return _rateLimit;
    }

    function getLastPullTime(address gasAccount) external view returns (uint256) {
        return _lastPullTime[gasAccount];
    }

    function _addGasAccount(address gasAccount) internal {
        require(
            _gasAccountIndexes[gasAccount] == 0,
            "Gas account matching the provided account already exists."
        );
        _gasAccounts.push(gasAccount);
        _gasAccountIndexes[gasAccount] = _gasAccounts.length;
    }
}