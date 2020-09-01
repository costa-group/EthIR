pragma solidity >0.4.99 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address payable newOwner) public {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address payable) {
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
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TicketsStorage is Ownable {
    using SafeMath for uint;

    struct Ticket {
        address payable wallet;
        uint investment;
        uint stakeAmount;
        uint stake;
        uint happyNumber;
        uint8[] percentArray;
        address payable ownerWallet;
    }

    mapping(address => mapping(uint => Ticket)) private tickets;
    // adrress of contract -> round -> Ticket

    mapping(address => mapping(bytes32 => uint)) numberTicket;
    // adrress of contract -> hash -> Ticket

    mapping(address => bool) private parentContract;
    //address of contract -> bool
    mapping(address => bool) private whitelist;
    //address of contract -> bool

    event FindedNumber(address indexed requestor, uint reqValue, uint findValue);


    modifier onlyParentContract {
        require(parentContract[msg.sender] || isOwner(), "onlyParentContract methods called by non - parent of contract.");
        _;
    }

    modifier onlyWhitelist {
        require(whitelist[msg.sender] || isOwner(), "only whitelist contract methods called by non - parent of contract.");
        _;
    }

    constructor() public
    Ownable(msg.sender)
    { }

    function save(address _contract, uint _round, address payable _wallet, uint _investment, uint _stake) public onlyWhitelist {
        Ticket storage ticket = tickets[_contract][_round];
        ticket.wallet = _wallet;
        ticket.investment = _investment;
        ticket.stake = _stake;
    }

    function saveHash(address _contract, bytes32 _hash, uint _round) public onlyWhitelist {
        numberTicket[_contract][_hash] = _round;
    }

    function update(address _contract, uint _round, uint _stakeAmount, uint _happyNumber) public onlyWhitelist {
        Ticket storage ticket = tickets[_contract][_round];
        ticket.stakeAmount = _stakeAmount;
        ticket.happyNumber = _happyNumber;
    }

    function ticketInfo(address _contract, uint round) public view returns (
        address payable _wallet,
        uint _investment,
        uint _stakeAmount,
        uint _stake,
        uint _happyNumber
    ) {
        Ticket memory ticket = tickets[_contract][round];
        _wallet = ticket.wallet;
        _investment = ticket.investment;
        _stakeAmount = ticket.stakeAmount;
        _stake = ticket.stake;
        _happyNumber = ticket.happyNumber;
    }

    function numberTicketFromHash(address _contract, bytes32 _hash) public view returns (uint) {
        return numberTicket[_contract][_hash];
    }

    function findHappyNumber(uint step) public onlyWhitelist returns (uint) {
        uint happyNumber = getRandomNumber(step);
        emit FindedNumber(msg.sender, step, happyNumber);
        return happyNumber;
    }

    function getRandomNumber(uint step) internal view returns (uint randomNumber) {
        if (step > 0) {
            uint numberOne = uint8(getByteByIndex(30, blockhash(block.number-1)));
            uint numberTwo = uint8(getByteByIndex(29, blockhash(block.number-2)));
            uint numberThree = uint8(getByteByIndex(28, blockhash(block.number-3)));
            uint numberFor = uint8(getByteByIndex(10, blockhash(block.number-4)));
            uint random = 0;
            if (step < 5) {
                random = numberTwo.add(numberFor).add(numberThree);
            }
            if (step >= 5 && step < 970000) {
                random = numberOne.mul(numberTwo);
                random = random.add(numberFor);
                random = random.mul(numberThree).sub(numberFor);
            }
            if (step >= 970000 && step < 96000000) {
                random = numberOne.mul(numberTwo).mul(numberFor);
                random = random.add(numberFor);
                random = random.mul(numberThree).sub(numberFor);
            }
            if (step >= 96000000) {
                random = numberOne.mul(numberTwo).mul(numberFor);
                random = random.mul(numberOne).add(numberFor);
                random = random.mul(numberThree).mul(numberTwo).sub(numberFor);
            }
            randomNumber = random % step;
            return randomNumber + 1;
        } else {
            return 0;
        }
    }

    function randomBytes(uint blockn, address entropyAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32(blockn),entropyAddress));
    }

    function getByteByIndex(uint number, bytes32 strBytes) private pure returns (byte lastByte) {
        require(number < 32 && number >= 0);
        lastByte = strBytes[number];
    }

    function setWhitelist(address _contract, bool _status) onlyParentContract public {
        whitelist[_contract] = _status;
    }

    function finish() external onlyOwner {
        address payable __owner = owner();
        selfdestruct(__owner);
    }

    function setParentContract(address _contract, bool _status) onlyOwner public {
        parentContract[_contract] = _status;
    }
}