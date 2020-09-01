pragma solidity >0.4.99 <0.6.0;
pragma experimental ABIEncoderV2;
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
    constructor (address payable newOwner) public {
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

contract ITicketsStorage {
    function findHappyNumber(uint step) public returns (uint);
}


contract Funds is Ownable {
    using SafeMath for uint;
    ITicketsStorage private m_tickets;

    uint private ticketPrice = 0.00001 ether;
    uint private botComission = 0.002 ether;
    address payable public croupier;

    mapping(address => bool) public administrators;
    mapping(address => bool) public whitelist;
    mapping(address => bool) private parentContract;

    mapping(uint => mapping(address => uint)) private funds;
    //type fund -> contract address -> amount

    //types of fund:
    // 0 - day, 1 - week, 2 - month, 3 - year
    enum FundType {DAY, WEEK, MONTH, YEAR}
    FundType fundType;

    mapping(address => mapping(uint => uint)) private _percent;
    // contractAddress -> type fund -> percent

    struct Winner {
        uint happyTicket;
        uint amount;
        address wallet;
        uint playerIndex;
        uint daySeek;
    }
    mapping(address => mapping(uint => mapping(uint => Winner))) private winners;
    // contractAddress -> fundType -> number day -> Winner

    struct Player {
        address payable wallet;
        uint startNumber;
        uint endNumber;
    }
    mapping(address => mapping(uint => mapping(uint => Player[]))) private playersByDay;
    // contractAddress -> fundType -> number day -> Player

    modifier onlyAdministratorOrWhitelist(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress] || whitelist[_customerAddress] || isOwner());
        _;
    }

    modifier onlyParentContract {
        require(parentContract[msg.sender] || isOwner(), "onlyParentContract methods called by non - parent of contract.");
        _;
    }

    modifier onlyCroupier {
        require(msg.sender == croupier || isOwner(), "only croupier methods, called by non-croupier.");
        _;
    }

    event AddedPlayer(uint numberDay, address indexed contractAddress, uint _fundType, address indexed addressPlayer);
    event SendPrizeToWinnerWallet(address indexed contractAddress, uint fundType, uint dayStart, address indexed addressPlayer, uint amount);
    event PutAmountToFund(address indexed contractAddress, uint amount, uint fundType, address indexed sender);
    event GetAmountFromFund(address indexed contractAddress, uint amount, uint fundType, address indexed beneficiary, address indexed sender);
    event DistribBonusOk(address indexed contractAddress, uint fundType, uint dayStart);
    event DistribBonusFail(address indexed contractAddress, uint fundType, uint dayStart);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event WriteWinner(address indexed contractAddress, uint fundType, uint dayStart, uint happyTicket, uint countPlayers);
    event ChangeValue(address indexed sender, uint newMinPrice, uint oldMinPrice);

    constructor() public
    Ownable(msg.sender)
    { }

    function() external payable {
    }

    function addPlayer(address payable _player, address _contract, uint _fundType, uint _ethValue) internal {
        require(_player != address(0) && _contract != address(0));
        uint numberDay = getDayNumber(now);
        uint start = 0;
        uint length = countPlayerByDay(_contract, _fundType, numberDay);
        if (length > 0) {
            (,,start) = playerInfo(_contract, _fundType, numberDay, (length-1));
            start = start.add(1);
        }

        playersByDay[_contract][_fundType][numberDay].push(Player({
            wallet : _player,
            startNumber : start,
            endNumber : start.add(_ethValue.div(ticketPrice))
            }));

        emit AddedPlayer(numberDay, _contract, _fundType, _player);
    }

    function countPlayerByDay(address _contract, uint _fundType, uint _numberDay) public view returns (uint) {
        return playersByDay[_contract][_fundType][_numberDay].length;
    }

    function getPlayerByDay(address _contract, uint _fundType, uint _numberDay, uint _index) public view returns
    (Player memory player) {
        return playersByDay[_contract][_fundType][_numberDay][_index];
    }

    function depositFunds(uint _fundType, address _contract, address payable _player) onlyAdministratorOrWhitelist payable public {
        require(_contract != address(0));
        uint amount = msg.value;
        if (amount > 0) {
            funds[_fundType][_contract] = funds[_fundType][_contract].add(amount);
            addPlayer(_player, _contract, _fundType, amount);
            emit PutAmountToFund(_contract, amount, _fundType, msg.sender);
        }
    }

    function withdrawFunds(uint _fundType, address _contract, uint _amount, address payable _beneficiary) onlyParentContract public {
        require(_contract != address(0));
        require(balanceAll() >= _amount && _amount > 0);
        require(funds[_fundType][_contract] >= _amount);

        funds[_fundType][_contract] = funds[_fundType][_contract].sub(_amount);
        _beneficiary.transfer(_amount);
        emit GetAmountFromFund(_contract, _amount, _fundType, _beneficiary, msg.sender);
    }

    function getDayNumber(uint256 _date) public pure returns (uint256 result) {
        result = _date.div(1 days);
    }

    function getCurrentDayNumber() public view returns (uint256 result) {
        result = now.div(1 days);
    }

    function _writeWinner(address _contract, uint _fundType, uint _dayStart, uint _happyTicket, uint _daySeek) internal {
        Winner storage winner = winners[_contract][_fundType][_dayStart];
        winner.happyTicket = _happyTicket;
        winner.amount = funds[_fundType][_contract].mul(4).div(5);
        winner.daySeek = _daySeek;
    }

    function _defineWinnerOfDay(address _contract, uint _dayStart) internal {
        _defineWinner(_contract, uint(FundType.DAY), _dayStart, 0);
    }

    function _defineWinnerOfWeek(address _contract, uint _dayStart) internal {
        uint daySeek = getRandomNumber(6);
        _defineWinner(_contract, uint(FundType.WEEK), _dayStart, daySeek);
    }

    function _defineWinnerOfMonth(address _contract, uint _dayStart) internal {
        uint daySeek = getRandomNumber(30);
        _defineWinner(_contract, uint(FundType.MONTH), _dayStart, daySeek);
    }

    function _defineWinnerOfYear(address _contract, uint _dayStart) internal {
        uint daySeek = getRandomNumber(365);
        _defineWinner(_contract, uint(FundType.YEAR), _dayStart, daySeek);
    }

    function _defineWinner(address _contract, uint _fundType, uint _dayStart, uint _daySeek) internal {
        require(_dayStart >= _daySeek);
        _getTicketDayWinner(_contract, _fundType, _dayStart, _daySeek);
    }

    function _getTicketDayWinner(address _contract, uint _fundType, uint _dayStart, uint _daySeek) internal {
        uint countPlayers = countPlayerByDay(_contract, _fundType, _dayStart.sub(_daySeek));
        uint ticketsCount = 0;
        uint _happyTicket = 0;
        if (countPlayers > 0) {
            (,,ticketsCount) = playerInfo(_contract, _fundType, _dayStart.sub(_daySeek), countPlayers-1);
        } else {
            _daySeek = 0;
            countPlayers = countPlayerByDay(_contract, _fundType, _dayStart);
            if(countPlayers > 0) {
                (,,ticketsCount) = playerInfo(_contract, _fundType, _dayStart, countPlayers-1);
            }
        }
        _happyTicket = getRandomNumber(ticketsCount);
        if (_happyTicket > 0) {
            _writeWinner(_contract, _fundType, _dayStart, _happyTicket, _daySeek);
            emit WriteWinner(_contract, _fundType, _dayStart, _happyTicket, countPlayers);
        }
    }

    function _sendCroupier(address _contract, uint _fundType) internal {
        uint fundAmount = funds[_fundType][_contract];
        if (fundAmount > botComission) { //for test's
            if (croupier.send(botComission)) {
                funds[_fundType][_contract] = funds[_fundType][_contract].sub(botComission);
            }
        }
    }

    function getRandomNumber(uint value) internal returns (uint) {
        if (address(m_tickets) != address(0) ) {
            return m_tickets.findHappyNumber(value);
        } else {
            return 0;
        }
    }

    function setAdministrator(address _newAdmin, bool _status) onlyOwner public {
        administrators[_newAdmin] = _status;
    }

    function setWhitelist(address _newUser, bool _status) onlyParentContract public {
        whitelist[_newUser] = _status;
    }

    function setParentContract(address _contract, bool _status) onlyOwner public {
        parentContract[_contract] = _status;
    }

    function setCroupierWallet(address payable _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address payable _oldWallet = croupier;
        croupier = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function balanceAll() public view returns (uint) {
        return address(this).balance;
    }

    function balanceOfFund(uint _fundType, address _contract) public view returns (uint _balance) {
        _balance = funds[_fundType][_contract];
    }

    function makeBonus(uint _fundType, address _contract, uint _dayStart) onlyCroupier public {
        require(_fundType >= 0 && _fundType < 4);
        _distribBonus(_fundType, _contract, _dayStart);
        _sendCroupier(_contract, _fundType);
    }

    function sendBonus(uint _fundType, address _contract, uint _dayStart, uint _playerIndex) onlyCroupier public {
        require(_fundType >= 0 && _fundType < 4);
        if (countPlayerByDay(_contract, _fundType, _dayStart) > 0) {
            Winner storage winner = winners[_contract][_fundType][_dayStart];
            (address payable playerWallet,,) = playerInfo(_contract, _fundType, _dayStart, _playerIndex);
            winner.wallet = playerWallet;
            winner.playerIndex = _playerIndex;
            uint bonus = winner.amount;
            funds[_fundType][_contract] = funds[_fundType][_contract].sub(bonus);
            _transferPrize(_contract, _fundType, _dayStart, playerWallet, bonus);
            _sendCroupier(_contract, _fundType);
        }
    }

    function _transferPrize(address _contract, uint _fundType, uint _dayStart, address payable _wallet, uint _bonus) internal {
        if (_wallet != address(0) && _bonus > 0 && _bonus <= balanceAll()) {
            _wallet.transfer(_bonus);
            emit SendPrizeToWinnerWallet(_contract, _fundType, _dayStart, _wallet, _bonus);
        }
    }

    function _distribBonus(uint _fundType, address _contract, uint _dayStart) internal {
        if(funds[_fundType][_contract] > 0) {
            if (_fundType == uint(FundType.DAY)) {
                _defineWinnerOfDay(_contract, _dayStart);
            }
            if (_fundType == uint(FundType.WEEK)) {
                _defineWinnerOfWeek(_contract, _dayStart);
            }
            if (_fundType == uint(FundType.MONTH)) {
                _defineWinnerOfMonth(_contract, _dayStart);
            }
            if (_fundType == uint(FundType.YEAR)) {
                _defineWinnerOfYear(_contract, _dayStart);
            }
            emit DistribBonusOk(_contract, _fundType, _dayStart);
        } else {
            emit DistribBonusFail(_contract, _fundType, _dayStart);
        }
    }

    function setPercentFund(address _contractAddress, uint _fundType, uint _newPercent) onlyParentContract public {
        require(_newPercent >= 0);
        _percent[_contractAddress][_fundType] = _newPercent;
    }

    function getPercentFund(address _contractAddress, uint _fundType) public view returns(uint) {
        return _percent[_contractAddress][_fundType];
    }

    function setTicketsStorage(address _addressTicketsStorage) external onlyOwner {
        require(_addressTicketsStorage != address(0));
        m_tickets = ITicketsStorage(_addressTicketsStorage);
    }

    function finish() external onlyOwner {
        address payable __owner = owner();
        selfdestruct(__owner);
    }

    function winnerInfo(address _contractAddress, uint _fundType, uint _dayNumber) public view returns (
        address _wallet,
        uint _happyTicket,
        uint _amount,
        uint _playerIndex,
        uint _daySeek
    ) {
        Winner memory winner = winners[_contractAddress][_fundType][_dayNumber];
        _wallet = winner.wallet;
        _happyTicket = winner.happyTicket;
        _amount = winner.amount;
        _playerIndex = winner.playerIndex;
        _daySeek = winner.daySeek;
    }

    function playerInfo(address _contractAddress, uint _fundType, uint _dayNumber, uint _index) public view returns (
        address payable _wallet,
        uint _startNumber,
        uint _endNumber
    ) {
        if (playersByDay[_contractAddress][_fundType][_dayNumber].length > 0) {
            Player memory player = playersByDay[_contractAddress][_fundType][_dayNumber][_index];
            _wallet = player.wallet;
            _startNumber = player.startNumber;
            _endNumber = player.endNumber;
        }
    }

    function setBotComission(uint _newValue) external onlyOwner {
        require(_newValue > 0);
        uint _oldValue = botComission;
        botComission = _newValue;
        emit ChangeValue(msg.sender, _newValue, _oldValue);
    }

}