pragma solidity ^0.4.26;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title ChargBridge
 * @dev Charg to Ethereum ERC20 Coin Bridge
 */
contract ChargBridge is Ownable {

	using SafeMath for uint;

    uint validatorsCount = 0;
    uint validationsRequired = 2;

    struct Transaction {
		address initiator;
		uint amount;
		uint validated;
		bool completed;
	}

    event FundsReceived(address indexed initiator, uint amount);

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);

    event Validated(bytes32 indexed txHash, address indexed validator, uint validatedCount, bool completed);

    mapping (address => bool) public isValidator;

    mapping (bytes32 => Transaction) public transactions;
	mapping (bytes32 => mapping (address => bool)) public validatedBy; // is validated by 


	function() external payable {
        if ( validatorsCount >= validationsRequired ) {
    		emit FundsReceived(msg.sender, msg.value);
        } else {
            revert();
        }
	}

	function setValidationsRequired( uint _value ) onlyOwner public {
        require (_value > 0);
        validationsRequired = _value;
	}

	function addValidator( address _validator ) onlyOwner public {
        require (!isValidator[_validator]);
        isValidator[_validator] = true;
        validatorsCount = validatorsCount.add(1);
        emit ValidatorAdded(_validator);
	}

	function removeValidator( address _validator ) onlyOwner public {
        require (isValidator[_validator]);
        isValidator[_validator] = false;
        validatorsCount = validatorsCount.sub(1);
        emit ValidatorRemoved(_validator);
	}

	function validate(bytes32 _txHash, address _initiator, uint _amount) public {
        
        require (isValidator[msg.sender]);
        require ( !transactions[_txHash].completed );
        require ( !validatedBy[_txHash][msg.sender] );

        if ( transactions[_txHash].initiator == address(0) ) {
            require ( _amount > 0 && address(this).balance > _amount );
            transactions[_txHash].initiator = _initiator;
            transactions[_txHash].amount = _amount;
            transactions[_txHash].validated = 1;

        } else {
            require ( transactions[_txHash].amount > 0 );
            require ( address(this).balance > transactions[_txHash].amount );
            require ( _initiator == transactions[_txHash].initiator );
            require ( transactions[_txHash].validated < validationsRequired );
            transactions[_txHash].validated = transactions[_txHash].validated.add(1);
        }
        validatedBy[_txHash][msg.sender] = true;
        if (transactions[_txHash].validated >= validationsRequired) {
    		_initiator.transfer(_amount);
            transactions[_txHash].completed = true;
        }
        emit Validated(_txHash, msg.sender, transactions[_txHash].validated, transactions[_txHash].completed);
	}
}