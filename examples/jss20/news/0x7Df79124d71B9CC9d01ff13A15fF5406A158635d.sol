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
    function setReferrerPercent(address _contractAddress, uint _newPercent) public;

    function setWhitelist(address _newUser, bool _status) public;

    function withdrawFunds(uint _amount, address _beneficiary, address _contract) public;
}

contract IFundsStorage {
    function getPercentFund(address _contractAddress, uint _typeFund) public view returns(uint);

    function setPercentFund(address _contractAddress, uint _typeFund, uint _newPercent) public;

    function withdrawFunds(uint _typeFund, address _contract, uint _amount, address payable _beneficiary) public;

    function setWhitelist(address _newUser, bool _status) public;
}

contract ISundayLottery {
    function buyTicket(
        address _contract,
        address payable _wallet,
        uint _stake,
        bytes memory _referrerLink,
        bytes32 _hash,
        uint8[] memory _percentArray,
        address payable _ownerWallet
    ) public payable;

    function getTicketInfo(address _contract, uint round) public view returns (
        address payable _wallet,
        uint _investment,
        uint _stakeAmount,
        uint _stake,
        uint _happyNumber,
        uint8[] memory _percentArray,
        address payable _ownerWallet
    );

    function currentRound() public view returns (uint);

    function makeTwist(address _contract, uint _numberReveal, address _playerWallet) public;

    function withdrawFunds(uint _amount, address payable _beneficiary) public;

    function balanceAll() public view returns (uint);

    function calcMaxStake(uint8[] memory _percentArray) public view returns (uint _availableFunds);

    function calcStake(uint _amount, uint8[] memory _percentArray) public view returns (uint _availableFunds);

    function setSystemOwnerPercent(uint _newValue) external;

    function setBotComission(uint _newValue) external;

    function updateAddress(address _newWallet, uint _number) external;

    function payToMyGameContract(address payable _wallet) external;
}

contract IHeadsOrTails {
    function makeNewGame(
        address payable _ownerWallet,
        address payable _contractOwnerWallet,
        uint _systemOwnerPercent,
        uint _percentOwner,
        address _myAccountToJpFund, address _myAccountToReferFund
    ) public returns(address payable);
}

contract Controller is Ownable {
    using SafeMath for uint;

    address public addressReferStorage;
    address public addressFundStorage;
    address public addressHeadsOrTails;

    address[] private _arrayContractOwners;
    //owner -> list of contracts
    mapping(address => address payable []) private _listOfContract;
    //owner -> list of contracts

    mapping(address => address payable []) private _listOfJoinedMyGame;
    //owner -> list of contracts

    mapping(address => address) private _ownerByContract;
    //address of contract -> owner

    mapping(address => bool) public myGameWhitelist;

    address public croupier;
    uint public indexMyGame;

    IReferStorage private referStorage;
    IFundsStorage private fundsStorage;
    IHeadsOrTails private headsOrTails;

    event MakeNewGameContract(address indexed owner, address indexed addressContract);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event WithdrawFund(string logMessage, uint amount, address indexed sender, address indexed addressContract, uint additional);

    modifier onlyCroupier {
        require(msg.sender == croupier || isOwner(), "only croupier methods, called by non-croupier.");
        _;
    }

    constructor(
        address _croupier
    ) public
    Ownable(msg.sender)
    {
        croupier = _croupier;
    }

    function makeNewGame(
        address payable _ownerWallet,
        address payable _contractOwnerWallet,
        uint _systemOwnerPercent,
        uint _percentOwner,
        uint _percentReferrer,
        uint _percentFundDay, uint _percentFundWeek, uint _percentFundMonth, uint _percentFundYear,
        address _myAccountToJpFund, address _myAccountToReferFund,
        bool isMyGame
    ) public {
        require(_percentOwner >= _percentReferrer);
        require(_contractOwnerWallet != address(0));
        address myGameAddress;
        if (_systemOwnerPercent > 100) {
            _systemOwnerPercent = 100;
        }
        if (countContractByOwner(owner()) > 0) {
            myGameAddress = getAddressContract(owner(), indexMyGame);
        }

        if (isMyGame == true) {
            require(myGameWhitelist[msg.sender]);
            _myAccountToJpFund = myGameAddress;
            _myAccountToReferFund = myGameAddress;
            _ownerWallet = owner();
        }

        address payable newContractAddress = headsOrTails.makeNewGame(
            _ownerWallet,
            _contractOwnerWallet,
                _systemOwnerPercent,
            _percentOwner,
            _myAccountToJpFund, _myAccountToReferFund
        );

        if (isMyGame == false) {

            settingJpPercentNewGameContract(
                newContractAddress, _myAccountToJpFund,
                _percentFundDay, _percentFundWeek, _percentFundMonth, _percentFundYear
            );
            settingReferPercentNewGameContract(
                newContractAddress, _myAccountToReferFund,
                _percentReferrer
            );

            _checkNewOwner(_ownerWallet);
            _listOfContract[msg.sender].push(newContractAddress);
        } else {
            _listOfContract[_ownerWallet].push(newContractAddress);
            _listOfJoinedMyGame[msg.sender].push(newContractAddress);
            _getSundayLottery(_ownerWallet, indexMyGame).payToMyGameContract(newContractAddress);
        }

        _ownerByContract[newContractAddress] = _ownerWallet;
        fundsStorage.setWhitelist(newContractAddress, true);
        referStorage.setWhitelist(newContractAddress, true);

        emit MakeNewGameContract(msg.sender, newContractAddress);
    }

    function settingJpPercentNewGameContract(
        address payable _newContractAddress,
        address _myAccountToJpFund,
        uint _percentFundDay, uint _percentFundWeek, uint _percentFundMonth, uint _percentFundYear
    ) internal {
        address accountToJpFund = _myAccountToJpFund;

        if (_myAccountToJpFund == address(0)) {
            accountToJpFund = _newContractAddress;
        }

        setJpFundPercent(accountToJpFund, 0, _percentFundDay);
        setJpFundPercent(accountToJpFund, 1, _percentFundWeek);
        setJpFundPercent(accountToJpFund, 2, _percentFundMonth);
        setJpFundPercent(accountToJpFund, 3, _percentFundYear);
    }

    function settingReferPercentNewGameContract(
        address payable _newContractAddress,
        address _myAccountToReferFund,
        uint _percentReferrer
    ) internal {
        address accountToReferFund = _myAccountToReferFund;
        if (_myAccountToReferFund == address(0)) {
            accountToReferFund = _newContractAddress;
        }
        referStorage.setReferrerPercent(accountToReferFund, _percentReferrer);
    }

    function setJpFundPercent(address _accountToJpFund, uint _fundType, uint _percent) internal {
        if (_percent > 0) {
            fundsStorage.setPercentFund(_accountToJpFund, _fundType, _percent);
        }
    }

    /**
    * Aceess to game contract
    */

    function buyTicket(
        address payable _owner,
        uint _index,
        address payable _wallet,
        uint _stake,
        bytes calldata _referrerLink,
        bytes32 _hash,
        uint8[] calldata _percentArray,
        address payable _ownerWallet
    ) external payable {
        address payable contractAddress = getAddressContract(_owner, _index);
        _getSundayLottery(_owner, _index).buyTicket.value(msg.value)(contractAddress, _wallet, _stake, _referrerLink, _hash, _percentArray, _ownerWallet);
    }

    function getAddressContract(address _owner, uint _index) public view returns (address payable) {
        return _listOfContract[_owner][_index];
    }

    function getJoinedMyGameContract(address _owner, uint _index) public view returns (address payable) {
        return _listOfJoinedMyGame[_owner][_index];
    }

    function _getSundayLottery(address payable _owner, uint _index) internal view returns (ISundayLottery ) {
        address payable addressContract = getAddressContract(_owner, _index);
        return ISundayLottery(addressContract);
    }

    function getTicketInfo(address payable _contractOwner, uint _index, uint round) public view returns
    (address payable _wallet, uint _investment, uint _stakeAmount, uint _stake, uint _happyNumber, uint8[] memory _percentArray, address payable _ownerWallet) {
        address payable contractAddress = getAddressContract(_contractOwner, _index);
        (_wallet, _investment, _stakeAmount, _stake, _happyNumber, _percentArray, _ownerWallet) = _getSundayLottery(_contractOwner, _index).getTicketInfo(contractAddress, round);
    }

    function getCurrentRound(address payable _contractOwner, uint _index) public view returns (uint) {
        return _getSundayLottery(_contractOwner, _index).currentRound();
    }

    function getCalcStake(address payable _contractOwner, uint _index, uint _amount, uint8[] memory _percentArray) public view returns (uint) {
        return _getSundayLottery(_contractOwner, _index).calcStake(_amount, _percentArray);
    }

    function getCalcMaxStake(address payable _contractOwner, uint _index, uint8[] memory _percentArray) public view returns (uint) {
        return _getSundayLottery(_contractOwner, _index).calcMaxStake(_percentArray);
    }

    function settleBet(address payable _contractOwner, uint _index, uint _reveal, address _playerWallet) onlyCroupier public {
        address payable contractAddress = getAddressContract(_contractOwner, _index);
        _getSundayLottery(_contractOwner, _index).makeTwist(contractAddress, _reveal, _playerWallet);
    }

    function setSystemOwnerPercent(address payable _contractOwner, uint _index, uint _newValue) onlyOwner public {
        _getSundayLottery(_contractOwner, _index).setSystemOwnerPercent(_newValue);
    }

    function setBotComission(address payable _contractOwner, uint _index, uint _newValue) onlyOwner public {
        _getSundayLottery(_contractOwner, _index).setBotComission(_newValue);
    }

    function updateGameImportantAddress(address payable _contractOwner, uint _index, address _newWallet, uint _number) onlyOwner public {
        _getSundayLottery(_contractOwner, _index).updateAddress(_newWallet, _number);
    }

    /**
    * Access to funds contract
    */
    function withdrawReferFunds(uint _amount, address _contract) public {
        require(_ownerByContract[_contract] == msg.sender);
        referStorage.withdrawFunds(_amount, msg.sender, _contract);
        emit WithdrawFund("Withdraw funds from refer contract", _amount, msg.sender, _contract, 0);
    }

    function withdrawJackpotFunds(uint _amount, address _contract, uint _typeFund) payable public {
        require(_ownerByContract[_contract] == msg.sender);
        fundsStorage.withdrawFunds(_typeFund, _contract, _amount, msg.sender);
        emit WithdrawFund("Withdraw funds from jackpot contract", _amount, msg.sender, _contract, _typeFund);
    }

    // from game contract
    function withdrawGameFunds(uint _indexContract, uint _amount) public {
        address addressContract = _listOfContract[msg.sender][_indexContract];
        require(countContractByOwner(msg.sender) > 0 );
        require(addressContract != address(0));
        require(_amount <= _getSundayLottery(msg.sender, _indexContract).balanceAll());
        _getSundayLottery(msg.sender, _indexContract).withdrawFunds(_amount, msg.sender);
        emit WithdrawFund("Withdraw funds from game contract", _amount, msg.sender, addressContract, _indexContract);
    }

    // to game contract
    function depositToContract(address _owner, uint _index) public payable {
        address payable addressContract = getAddressContract(_owner, _index);
        if (countContractByOwner(_owner) > 0 && addressContract != address(0)) {
            addressContract.transfer(msg.value);
        } else {
            revert();
        }
    }

    function withdrawParentContractFunds(uint _amount) external onlyOwner {
        require(_amount <= balanceAll(), "Increase amount larger than balance.");
        address payable owner = owner();
        owner.transfer(_amount);
    }

    /**
    * Aceess to Control functions
    */
    function setCroupierWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = croupier;
        croupier = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function setIndexMyGame(uint _newValue) onlyOwner public {
        indexMyGame = _newValue;
    }

    function setStorageAddress(address _addressFundStorage, address _addressReferStorage, address _addressHeadsOrTails) external onlyOwner {
        require(_addressReferStorage != address(0) && _addressFundStorage != address(0) && _addressHeadsOrTails != address(0));
        addressFundStorage = _addressFundStorage;
        addressReferStorage = _addressReferStorage;
        addressHeadsOrTails = _addressHeadsOrTails;

        fundsStorage = IFundsStorage(_addressFundStorage);
        referStorage = IReferStorage(_addressReferStorage);
        headsOrTails = IHeadsOrTails(addressHeadsOrTails);
    }

    function setMyGameWhitelist(address _newUser, bool _status) external onlyOwner {
        myGameWhitelist[_newUser] = _status;
    }

    function balanceAll() public view returns (uint) {
        return address(this).balance;
    }

    function balanceByGameContract(address payable _owner, uint _index) public view returns (uint) {
        return _getSundayLottery(_owner, _index).balanceAll();
    }

    function _checkNewOwner(address _owner) internal {
        if (_isNewOwner(_owner)) {
            _arrayContractOwners.push(_owner);
        }
    }

    function _isNewOwner(address _owner) internal view returns (bool) {
        return countContractByOwner(_owner) > 0 ? false : true;
    }

    function countOwnersContract() external view returns (uint) {
        return _arrayContractOwners.length;
    }

    function getOwnerContract(uint _index) external view returns (address) {
        return _arrayContractOwners[_index];
    }

    function countContractByOwner(address _owner) public view returns (uint) {
        return _listOfContract[_owner].length;
    }

    function countJoinedMyGameContractByOwner(address _owner) public view returns (uint) {
        return _listOfJoinedMyGame[_owner].length;
    }
}