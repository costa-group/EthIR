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

contract IReferStorage {
    function checkReferralLink(address _contract, address _referral, uint256 _amount, bytes memory _referrer) public;
    function getReferrerPercent(address _contractAddress) public view returns(uint);
    function depositFunds(address _contract) payable public;
}

contract IFundsStorage {
    function getPercentFund(address _contractAddress, uint _typeFund) public view returns(uint);
    function depositFunds(uint _typeFund, address _contract, address payable _player) payable public;
}

contract ITicketsStorage {
    function findHappyNumber(uint step) public returns (uint);
    function numberTicketFromHash(address _contract, bytes32 _hash) public view returns (uint);
    function save(address _contract, uint _round, address payable _wallet, uint _investment, uint _stake, uint8[] memory _percentArray, address payable _ownerWallet) public;
    function saveHash(address _contract, bytes32 _hash, uint _round) public;
    function setWhitelist(address _contract, bool _status) public;
    function update(address _contract, uint _round, uint _stakeAmount, uint _happyNumber) public;

    function ticketInfo(address _contract, uint round) public view returns (
        address payable _wallet,
        uint _investment,
        uint _stakeAmount,
        uint _stake,
        uint _happyNumber,
        uint8[] memory _percentArray,
        address payable _ownerWallet
    );
}

contract SundayLottery is Ownable {
    using SafeMath for uint;

    uint public constant MIN_BALANCE = 0.1 ether;
    uint public minPriceOfToken = 0.01 ether;
    uint private botComission = 0.002 ether;

    ITicketsStorage private m_tickets;
    IReferStorage private referStorage;
    IFundsStorage private fundsStorage;

    uint public contractOwnerPercent;
    uint public systemOwnerPercent;
    uint private lastBlock;

    address payable public contractOwnerWallet;
    address payable public systemOwnerWallet = 0xb43c6dCe7837eb67c058eD7BFA06A850B2a15B06;
    address public parentContract;
    address payable public botCroupier;

    address public myAccountToJpFund;
    address public myAccountToReferFund;
    address private controllerContract;

    uint private _currentNumberTicket;

    // more events for easy read from blockchain
    event LogBalanceChanged(uint when, uint balance);
    event LogWinnerDefine(uint round, address indexed wallet, uint amount, uint stake, uint happyNumber);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event Payment(uint amount, address indexed wallet);
    event FailedPayment(uint amount, address indexed wallet);
    event WithdrawOwnerContract(uint amount, address beneficiary);
    event ChangeValue(address indexed sender, uint newMinPrice, uint oldMinPrice);

    modifier balanceChanged {
        _;
        emit LogBalanceChanged(now, address(this).balance);
    }

    modifier onlyParentContract {
        require(msg.sender == parentContract, "onlyParentContract methods called by non - parent of contract.");
        _;
    }

    modifier onlyControllerContract {
        require(msg.sender == controllerContract, "only controller contract methods called by non - parent of contract.");
        _;
    }

    constructor(
        address payable _owner,
        address payable _contractOwnerWallet,
        uint _systemOwnerPercent,
        uint _contractOwnerPercent,
        address _addressReferStorage,
        address _addressFundStorage,
        address _addressTicketsStorage,
        address _myAccountToJpFund,
        address _myAccountToReferFund,
        address payable _botCroupier
    ) public
    Ownable(_owner)
    {
        require(_contractOwnerWallet != address(0) && _addressFundStorage != address(0)
        && _addressReferStorage != address(0) && _botCroupier != address(0));
        contractOwnerWallet = _contractOwnerWallet;
        systemOwnerPercent = _systemOwnerPercent < 10 ? 10 : _systemOwnerPercent;
        contractOwnerPercent = _contractOwnerPercent;
        parentContract = msg.sender;

        referStorage = IReferStorage(_addressReferStorage);
        fundsStorage = IFundsStorage(_addressFundStorage);
        m_tickets = ITicketsStorage(_addressTicketsStorage);

        if (_myAccountToJpFund != address(0)) {
            myAccountToJpFund = _myAccountToJpFund;
        } else {
            myAccountToJpFund = address(this);
        }
        if (_myAccountToReferFund != address(0)) {
            myAccountToReferFund = _myAccountToReferFund;
        } else {
            myAccountToReferFund = address(this);
        }

        _currentNumberTicket = 1;
        botCroupier = _botCroupier;
    }

    function() external payable {
    }

    function currentRound() public view returns (uint) {
        return _currentNumberTicket;
    }

    function getFundsAccounts() public view returns (address jpFundAddress, address referFundAddress) {
        jpFundAddress = myAccountToJpFund;
        referFundAddress = myAccountToReferFund;
    }

    function buyTicket(
        address _contract,
        address payable _wallet,
        uint _stake,
        bytes memory _referrerLink,
        bytes32 _hash,
        uint8[] memory _percentArray,
        address payable _ownerWallet
    ) public payable balanceChanged {
        uint currentBlock = block.number;
        uint investment = msg.value;
        require(_stake == 1 || _stake == 2);
        require(lastBlock < currentBlock);
        require(minPriceOfToken <= investment);
        require(balanceAll() >= MIN_BALANCE);

        referStorage.checkReferralLink(myAccountToReferFund, _wallet, investment, _referrerLink);
        m_tickets.save(_contract, _currentNumberTicket, _wallet, investment, _stake, _percentArray, _ownerWallet);
        m_tickets.saveHash(_contract, _hash, _currentNumberTicket);
        lastBlock = currentBlock;
        _currentNumberTicket++;
    }

    function makeTwist(address _contract, uint _numberReveal, address _playerWallet) public onlyControllerContract {
        uint numberTicket = _getNumberTicket(_contract, _numberReveal, _playerWallet);
        (address payable _wallet, uint _investment, bool _notMaked, bool _status, uint _stakeAmount, uint8[] memory _percentArray
        ) = _defineWinner(_contract, numberTicket, _playerWallet);
        if (_notMaked) {
            _sendPrize(_contract, numberTicket, _wallet, _investment, _status, _stakeAmount, _percentArray);
        }
        botCroupier.transfer(botComission);
    }

    function _defineWinner(address _contract, uint numberTicket, address _playerWallet) internal returns (
        address payable _wallet, uint _investment, bool _notMaked, bool _status, uint _stakeAmount, uint8[] memory _percentArray
    ) {
        (address payable wallet, uint investment,, uint stake, uint happyNumber,,) = getTicketInfo(_contract, numberTicket);
        if (happyNumber == 0) {
            _notMaked = true;
            _wallet = wallet;
            require(_wallet == _playerWallet);
            _investment = investment;
            happyNumber = m_tickets.findHappyNumber(2);
            (, , , , ,_percentArray,) = getTicketInfo(_contract, numberTicket);
            if (happyNumber == stake) {
                _status = true;
                _stakeAmount = calcStake(_investment, _percentArray);
            } else {
                _status = false;
                _stakeAmount = 0;
            }
            emit LogWinnerDefine(numberTicket, wallet, _stakeAmount, stake, happyNumber);
            m_tickets.update(_contract, numberTicket, _stakeAmount, happyNumber);
        } else {
            _notMaked = false;
        }
    }
    function _getNumberTicket(address _contract, uint _number, address _playerWallet) internal view returns (uint numberTicket) {
        bytes32 hash = keccak256(abi.encodePacked(bytes32(_number), _playerWallet));
        numberTicket = m_tickets.numberTicketFromHash(_contract, hash);
    }


    function _sendPrize(
        address _contract, uint _numberTicket, address payable _wallet, uint _investment, bool _status, uint _stakeAmount, uint8[] memory _percentArray
    ) internal {
        uint fullPercent = 1000;
        if (_status) {
            _sendToWallet(_stakeAmount, _wallet);
        }

        uint __referPercent = getAvailablePercent(referStorage.getReferrerPercent(myAccountToReferFund), _percentArray[4]);
        referStorage.depositFunds.value(_investment.mul(__referPercent).div(fullPercent))(myAccountToReferFund);

        fundsStorage.depositFunds.value(_investment.mul(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 0), _percentArray[0])).div(fullPercent))(0, myAccountToJpFund, _wallet);
        fundsStorage.depositFunds.value(_investment.mul(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 1), _percentArray[1])).div(fullPercent))(1, myAccountToJpFund, _wallet);
        fundsStorage.depositFunds.value(_investment.mul(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 2), _percentArray[2])).div(fullPercent))(2, myAccountToJpFund, _wallet);
        fundsStorage.depositFunds.value(_investment.mul(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 3), _percentArray[3])).div(fullPercent))(3, myAccountToJpFund, _wallet);

        uint __ownerPercent = getAvailablePercent(contractOwnerPercent, _percentArray[5]);
        if (__ownerPercent > __referPercent) {
            address payable __ownerWallet = _getOwnerWallet(_contract, _numberTicket, _percentArray);
            _sendToWallet(_investment.mul(__ownerPercent.sub(__referPercent)).div(fullPercent), __ownerWallet);
        }
        _sendToWallet(_investment.mul(systemOwnerPercent).div(fullPercent), systemOwnerWallet);
    }

    function _sendToWallet(uint _amount, address payable _wallet) internal {
        if (0 < _amount && _amount <= balanceAll()) {
            if (_wallet.send(_amount)) {
                emit Payment(_amount, _wallet);
            } else {
                emit FailedPayment(_amount, _wallet);
            }
        }
    }

    function payToMyGameContract(address payable _wallet) external onlyControllerContract {
        require(balanceAll() >= MIN_BALANCE*2);
        uint _amount = MIN_BALANCE + 4*minPriceOfToken;
        _sendToWallet(_amount, _wallet);
    }

    function withdrawFunds(uint _amount, address payable _beneficiary) public onlyControllerContract {
        emit WithdrawOwnerContract(_amount, _beneficiary);
        _sendToWallet(_amount, _beneficiary);
    }

    function getTicketInfo(address _contract, uint round) public view returns (
        address payable _wallet, uint _investment, uint _stakeAmount, uint _stake, uint _happyNumber, uint8[] memory _percentArray, address payable _ownerWallet
    ) {
        (_wallet, _investment, _stakeAmount, _stake, _happyNumber, _percentArray, _ownerWallet) = m_tickets.ticketInfo(_contract, round);
    }

    function calcMaxStake(uint8[] memory _percentArray) public view returns (uint _availableFunds) {
        if (balanceAll() >= MIN_BALANCE) {
            uint percentFull = 1000;
            uint percentAll = getPercentComission(_percentArray);
            _availableFunds = balanceAll().div(2);
            _availableFunds = _availableFunds.mul(percentFull.sub(percentAll)).div(percentFull);
            _availableFunds = _availableFunds.sub(botComission);
        } else {
            _availableFunds = 0;
        }
    }

    function calcStake(uint _amount, uint8[] memory _percentArray) public view returns (uint _availableFunds) {
        if (calcMaxStake(_percentArray) >= _amount && _amount > botComission && minPriceOfToken <= _amount && balanceAll() >= MIN_BALANCE) {
            uint percentFull = 1000;
            uint percentAll = getPercentComission(_percentArray);
            _availableFunds = _amount.mul(percentFull.sub(percentAll)).div(percentFull);
            _availableFunds = _availableFunds.add(_amount).sub(botComission);
        } else {
            _availableFunds = 0;
        }
    }

    function getPercentComission(uint8[] memory _percentArray) public view returns (uint _percentAll) {
        uint percentFund = getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 0), _percentArray[0]);
        percentFund = percentFund.add(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 1), _percentArray[1]));
        percentFund = percentFund.add(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 2), _percentArray[2]));
        percentFund = percentFund.add(getAvailablePercent(fundsStorage.getPercentFund(myAccountToJpFund, 3), _percentArray[3]));
        percentFund = percentFund.add(getAvailablePercent(contractOwnerPercent, _percentArray[5]));
        _percentAll = percentFund.add(systemOwnerPercent);
    }

    function getAvailablePercent(uint _percentFund, uint8 _memberArray) internal pure returns (uint _percent) {
        if (_memberArray > 0) {
            _percent = _memberArray > 100 ? 0 : uint(_memberArray);
        } else {
            _percent = _percentFund;
        }
    }

    function _getOwnerWallet(address _contract, uint _numberTicket, uint8[] memory _percentFund) internal view returns (address payable _wallet) {
        (, , , , , , address payable _ownerWallet) = getTicketInfo(_contract, _numberTicket);
        if (_ownerWallet == address(0) || _percentFund[5] == 0 || _percentFund[5] > 100) {
            _wallet = contractOwnerWallet;
        } else {
            _wallet = _ownerWallet;
        }
    }

    function balanceAll() public view returns (uint) {
        return address(this).balance;
    }

    function setContractOwnerWallet(address payable _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address payable _oldWallet = contractOwnerWallet;
        contractOwnerWallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function setControllerContract(address _newWallet) external onlyParentContract {
        require(_newWallet != address(0));
        address _oldWallet = controllerContract;
        controllerContract = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function setMinPriceOfToken(uint _newMinPrice) external onlyOwner {
        require(_newMinPrice > 0);
        uint _oldMinPrice = minPriceOfToken;
        minPriceOfToken = _newMinPrice;
        emit ChangeValue(msg.sender, _newMinPrice, _oldMinPrice);
    }

    function setBotComission(uint _newValue) external onlyControllerContract {
        require(_newValue > 0);
        uint _oldValue = botComission;
        botComission = _newValue;
        emit ChangeValue(msg.sender, _newValue, _oldValue);
    }

    function setsystemOwnerPercent(uint _newValue) external onlyControllerContract {
        require(_newValue > 0);
        systemOwnerPercent = _newValue;
    }

    function updateAddress(address payable _newWallet, uint _number) external onlyControllerContract {
        require(_newWallet != address(0));
        address _oldWallet = address(0);
        if (_number == 1) {
            _oldWallet = address(referStorage);
            referStorage = IReferStorage(_newWallet);
        }
        if (_number == 2) {
            _oldWallet = address(fundsStorage);
            fundsStorage = IFundsStorage(_newWallet);
        }
        if (_number == 3) {
            _oldWallet = address(m_tickets);
            m_tickets = ITicketsStorage(_newWallet);
        }
        if (_number == 4) {
            _oldWallet = botCroupier;
            botCroupier = _newWallet;
        }
        if (_number == 5) {
            _oldWallet = controllerContract;
            controllerContract = _newWallet;
        }
        if (_number == 6) {
            _oldWallet = systemOwnerWallet;
            systemOwnerWallet = _newWallet;
        }
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

}

contract HeadsOrTails {
    using SafeMath for uint;

    address payable public ownerContract;
    mapping(address => bool) private parentContract;

    address private addressReferStorage;
    address private addressFundStorage;
    address private addressTicketsStorage;
    address payable private botCroupier;

    uint public countContract;

    event MakeNewGameContract(address indexed owner, address indexed addressContract);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event WithdrawFund(uint amount, address indexed sender);

    modifier onlyOwnerContract() {
        require(msg.sender == ownerContract, "caller is not the owner");
        _;
    }

    modifier onlyParentContract {
        require(parentContract[msg.sender] || ownerContract == msg.sender, "onlyParentContract methods called by non - parent of contract.");
        _;
    }

    constructor(
        address payable _ownerContract,
        address payable _botCroupier
    ) public {
        ownerContract = _ownerContract;
        //ownerContract = msg.sender; //For test's
        botCroupier = _botCroupier;
    }

    function setParentContract(address _contract, bool _status) onlyOwnerContract public {
        parentContract[_contract] = _status;
    }

    function makeNewGame(
        address payable _ownerWallet,
        address payable _contractOwnerWallet,
        uint _systemOwnerPercent,
        uint _contractOwnerPercent,
        address _myAccountToJpFund, address _myAccountToReferFund
    ) onlyParentContract public returns(address payable) {
        require(_contractOwnerWallet != address(0));
        SundayLottery sundayLottery = new SundayLottery(
            _ownerWallet, _contractOwnerWallet, _systemOwnerPercent, _contractOwnerPercent,
            addressReferStorage, addressFundStorage, addressTicketsStorage,
            _myAccountToJpFund, _myAccountToReferFund, botCroupier);
        emit MakeNewGameContract(msg.sender, address(sundayLottery));
        countContract++;
        ITicketsStorage ticketStorage = ITicketsStorage(addressTicketsStorage);
        ticketStorage.setWhitelist(address(sundayLottery), true);
        sundayLottery.setControllerContract(msg.sender);
        return address(sundayLottery);
    }

    function withdrawFunds(uint _amount) external onlyOwnerContract {
        require(_amount <= address(this).balance, "Increase amount larger than balance.");
        emit WithdrawFund(_amount, msg.sender);
        ownerContract.transfer(_amount);
    }

    function setStorageAddress(address _addressFundStorage, address _addressReferStorage, address _addressTicketsStorage) external onlyOwnerContract {
        require(_addressReferStorage != address(0) && _addressFundStorage != address(0) && _addressTicketsStorage != address(0));
        addressFundStorage = _addressFundStorage;
        addressReferStorage = _addressReferStorage;
        addressTicketsStorage = _addressTicketsStorage;
    }

    function setCroupierWallet(address payable _newWallet) external onlyOwnerContract {
        require(_newWallet != address(0));
        address _oldWallet = botCroupier;
        botCroupier = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }
}