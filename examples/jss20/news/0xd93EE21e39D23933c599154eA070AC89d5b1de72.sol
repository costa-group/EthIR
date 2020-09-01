pragma solidity ^0.5.11;


contract Ownable {
  address payable public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  constructor() public {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }



  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract GroupAdmin is Ownable {
    event AdminGranted(address indexed grantee);
    event AdminRevoked(address indexed grantee);
    address[] public admins;

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), 'must be admin');
        _;
    }


    function grant(address[] memory newAdmins) public onlyAdmin{
        for(uint i = 0; i < newAdmins.length; i++){
            admins.push(newAdmins[i]);
            emit AdminGranted(newAdmins[i]);
        }
    }


    function revoke(address[] memory oldAdmins) public onlyAdmin{
        for(uint oldIdx = 0; oldIdx < oldAdmins.length; oldIdx++){
            for (uint idx = 0; idx < admins.length; idx++) {
                if (admins[idx] == oldAdmins[oldIdx]) {
                    admins[idx] = admins[admins.length - 1];
                    admins.length--;
                    emit AdminRevoked(oldAdmins[oldIdx]);
                    break;
                }
            }
        }
    }


    function getAdmins() public view returns(address[] memory){

        return admins;
    }


    function numOfAdmins() public view returns(uint){
        return admins.length;
    }


    function isAdmin(address admin) public view returns(bool){
        if (admin == owner) return true;

        for (uint i = 0; i<admins.length; i++){
            if (admins[i] == admin){
                return true;
            }
        }
        return false;
    }
}

interface Conference {

    event AdminGranted(address indexed grantee);
    event AdminRevoked(address indexed grantee);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event RegisterEvent(address addr, uint256 index);
    event FinalizeEvent(uint256[] maps, uint256 payout, uint256 endedAt);
    event WithdrawEvent(address addr, uint256 payout);
    event CancelEvent(uint256 endedAt);
    event ClearEvent(address addr, uint256 leftOver);
    event UpdateParticipantLimit(uint256 limit);



    function owner() view external returns (address);

    function name() view external returns (string memory);
    function deposit() view external returns (uint256);
    function limitOfParticipants() view external returns (uint256);
    function registered() view external returns (uint256);
    function ended() view external returns (bool);
    function cancelled() view external returns (bool);
    function endedAt() view external returns (uint256);
    function totalAttended() view external returns (uint256);
    function coolingPeriod() view external returns (uint256);
    function payoutAmount() view external returns (uint256);
    function participants(address participant) view external returns (
        uint256 index,
        address payable addr,
        bool paid
    );
    function participantsIndex(uint256) view external returns(address);


    function transferOwnership(address payable newOwner) external;

    function grant(address[] calldata newAdmins) external;
    function revoke(address[] calldata oldAdmins) external;
    function getAdmins() external view returns(address[] memory);
    function numOfAdmins() external view returns(uint);
    function isAdmin(address admin) external view returns(bool);


    function register() external payable;
    function withdraw() external;
    function totalBalance() view external returns (uint256);
    function isRegistered(address _addr) view external returns (bool);
    function isAttended(address _addr) external view returns (bool);
    function isPaid(address _addr) external view returns (bool);
    function cancel() external;
    function clear() external;
    function setLimitOfParticipants(uint256 _limitOfParticipants) external;
    function changeName(string calldata _name) external;
    function changeDeposit(uint256 _deposit) external;
    function finalize(uint256[] calldata _maps) external;
    function tokenAddress() external view returns (address);
}

contract AbstractConference is Conference, GroupAdmin {
    string public name;
    uint256 public deposit;
    uint256 public limitOfParticipants;
    uint256 public registered;
    bool public ended;
    bool public cancelled;
    uint256 public endedAt;
    uint256 public totalAttended;

    uint256 public coolingPeriod;
    uint256 public payoutAmount;
    uint256[] public attendanceMaps;

    mapping (address => Participant) public participants;
    mapping (uint256 => address) public participantsIndex;

    struct Participant {
        uint256 index;
        address payable addr;
        bool paid;
    }


    modifier onlyActive {
        require(!ended, 'already ended');
        _;
    }

    modifier noOneRegistered {
        require(registered == 0, 'people have already registered');
        _;
    }

    modifier onlyEnded {
        require(ended, 'not yet ended');
        _;
    }



    constructor (
        string memory _name,
        uint256 _deposit,
        uint256 _limitOfParticipants,
        uint256 _coolingPeriod,
        address payable _owner
    ) public {
        require(_owner != address(0), 'owner address is required');
        owner = _owner;
        name = _name;
        deposit = _deposit;
        limitOfParticipants = _limitOfParticipants;
        coolingPeriod = _coolingPeriod;
    }



    function register() external payable onlyActive{
        require(registered < limitOfParticipants, 'participant limit reached');
        require(!isRegistered(msg.sender), 'already registered');
        doDeposit(msg.sender, deposit);

        registered++;
        participantsIndex[registered] = msg.sender;
        participants[msg.sender] = Participant(registered, msg.sender, false);

        emit RegisterEvent(msg.sender, registered);
    }


    function withdraw() external onlyEnded {
        require(payoutAmount > 0, 'payout is 0');
        Participant storage participant = participants[msg.sender];
        require(participant.addr == msg.sender, 'forbidden access');
        require(cancelled || isAttended(msg.sender), 'event still active or you did not attend');
        require(participant.paid == false, 'already withdrawn');

        participant.paid = true;
        doWithdraw(msg.sender, payoutAmount);
        emit WithdrawEvent(msg.sender, payoutAmount);
    }



    function totalBalance() view public returns (uint256){
        revert('totalBalance must be impelmented in the child class');
    }


    function isRegistered(address _addr) view public returns (bool){
        return participants[_addr].addr != address(0);
    }


    function isAttended(address _addr) public view returns (bool){
        if (!isRegistered(_addr) || !ended) {
            return false;
        }

        else {
            Participant storage p = participants[_addr];
            uint256 pIndex = p.index - 1;
            uint256 map = attendanceMaps[uint256(pIndex / 256)];
            return (0 < (map & (2 ** (pIndex % 256))));
        }
    }


    function isPaid(address _addr) public view returns (bool){
        return isRegistered(_addr) && participants[_addr].paid;
    }




    function cancel() external onlyAdmin onlyActive{
        payoutAmount = deposit;
        cancelled = true;
        ended = true;
        endedAt = now;
        emit CancelEvent(endedAt);
    }


    function clear() external onlyAdmin onlyEnded{
        require(now > endedAt + coolingPeriod, 'still in cooling period');
        uint256 leftOver = totalBalance();
        doWithdraw(owner, leftOver);
        emit ClearEvent(owner, leftOver);
    }


    function setLimitOfParticipants(uint256 _limitOfParticipants) external onlyAdmin onlyActive{
        require(registered <= _limitOfParticipants, 'cannot lower than already registered');
        limitOfParticipants = _limitOfParticipants;

        emit UpdateParticipantLimit(limitOfParticipants);
    }


    function changeName(string calldata _name) external onlyAdmin noOneRegistered{
        name = _name;
    }


    function changeDeposit(uint256 _deposit) external onlyAdmin noOneRegistered{
        deposit = _deposit;
    }


    function finalize(uint256[] calldata _maps) external onlyAdmin onlyActive {
        uint256 totalBits = _maps.length * 256;
        require(totalBits >= registered && totalBits - registered < 256, 'incorrect no. of bitmaps provided');
        attendanceMaps = _maps;
        ended = true;
        endedAt = now;
        uint256 _totalAttended = 0;

        for (uint256 i = 0; i < attendanceMaps.length; i++) {
            uint256 map = attendanceMaps[i];

            while (map != 0) {
                map &= (map - 1);
                _totalAttended++;
            }
        }
        require(_totalAttended <= registered, 'should not have more attendees than registered');
        totalAttended = _totalAttended;

        if (totalAttended > 0) {
            payoutAmount = uint256(totalBalance()) / totalAttended;
        }

        emit FinalizeEvent(attendanceMaps, payoutAmount, endedAt);
    }

    function doDeposit(address , uint256  ) internal {
        revert('doDeposit must be impelmented in the child class');
    }

    function doWithdraw(address payable  , uint256  ) internal {
        revert('doWithdraw must be impelmented in the child class');
    }

    function tokenAddress() public view returns (address){
        revert('tokenAddress must be impelmented in the child class');
    }

}

interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Conference is AbstractConference {

    IERC20 public token;

    constructor(
        string memory _name,
        uint256 _deposit,
        uint256 _limitOfParticipants,
        uint256 _coolingPeriod,
        address payable _owner,
        address  _tokenAddress
    )
        AbstractConference(_name, _deposit, _limitOfParticipants, _coolingPeriod, _owner)
        public
    {
        require(_tokenAddress != address(0), 'token address is not set');
        token = IERC20(_tokenAddress);
    }


    function totalBalance() view public returns (uint256){
        return token.balanceOf(address(this));
    }

    function doWithdraw(address payable participant, uint256 amount) internal {
        token.transfer(participant, amount);
    }

    function doDeposit(address participant, uint256 amount) internal {
        require(msg.value == 0, 'ERC20Conference can not receive ETH');
        token.transferFrom(participant, address(this), amount);
    }

    function tokenAddress() public view returns (address){
        return address(token);
    }
}

interface DeployerInterface {
    function deploy(
        string calldata _name,
        uint256 _deposit,
        uint _limitOfParticipants,
        uint _coolingPeriod,
        address payable _ownerAddress,
        address _tokenAddress
    )external returns(Conference c);
}

contract ERC20Deployer is DeployerInterface{
    function deploy(
        string calldata _name,
        uint256 _deposit,
        uint _limitOfParticipants,
        uint _coolingPeriod,
        address payable _ownerAddress,
        address _tokenAddress
    )external returns(Conference c){
        c = new ERC20Conference(
            _name,
            _deposit,
            _limitOfParticipants,
            _coolingPeriod,
            _ownerAddress,
            _tokenAddress
        );
    }
}