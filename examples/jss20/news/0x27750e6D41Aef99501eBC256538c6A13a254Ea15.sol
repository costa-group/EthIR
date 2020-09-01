pragma solidity ^0.4.23;
/*
 *             ╔═╗┌─┐┌─┐┬┌─┐┬┌─┐┬   ┌─────────────────────────┐ ╦ ╦┌─┐┌┐ ╔═╗┬┌┬┐┌─┐
 *             ║ ║├┤ ├┤ ││  │├─┤│   │KOL Community Foundation │ ║║║├┤ ├┴┐╚═╗│ │ ├┤
 *             ╚═╝└  └  ┴└─┘┴┴ ┴┴─┘ └─┬─────────────────────┬─┘ ╚╩╝└─┘└─┘╚═╝┴ ┴ └─┘
 *   ┌────────────────────────────────┘                     └──────────────────────────────┐
 *   │    ┌─────────────────────────────────────────────────────────────────────────────┐  │
 *   └────┤ Dev:Jack Koe ├───────────┤ Special for:KOL Fund ├──────────────┤ 20200212   ├──┘
 *        └─────────────────────────────────────────────────────────────────────────────┘
 */
library SafeMath {

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract UERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract UERC20 is UERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract KERC20Basic {
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract KERC20 is KERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);
  function querySuperNode(address _addr)
    public returns(bool);
  function queryNode(address _addr)
    public view returns(bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {

  address public owner;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract KOLUSDTFund is Ownable{
  using SafeMath for uint256;
  string public name = "KOL USDT Foundation";
  string public symbol = "KOLUSDTFund";
  KERC20 public kol;
  UERC20 public usdt;

  uint256 public dealTime =  3 days;
  uint256 public missionId = 0;
  uint256 public constant TENKOL = 100000 * (10 ** 18);
  uint256 public constant TENUSDT = 100000 * (10 ** 6);


  uint16 public constant halfSuperNodes = 11;
  uint16 public constant minSuperNodes = 15;

  mapping(address => mapping(uint256 => bool)) private Voter;

  constructor(address _kolAddress,address _usdtAddress) public {
    kol = KERC20(_kolAddress);
    usdt = UERC20(_usdtAddress);
  }

  event MissionPassed(uint256 _missionId,bytes32 _name);
  event OfferingFinished(uint256 _missionId,uint256 _totalAmount,uint256 _length);
  event MissionLaunched(bytes32 _name,uint256 _missionId,address _whoLaunch);

  modifier onlySuperNode() {
    require(kol.querySuperNode(msg.sender));
      _;
  }

/*
isKol:true, mean kol
isKol:false, mean usdt
*/
  struct KolMission{
    bool isKol;
    uint256 startTime;
    uint256 endTime;
    uint256 totalAmount;
    uint256 offeringAmount;
    bytes32 name;
    uint16 agreeSuperNodes;
    uint16 refuseSuperNodes;
    bool superPassed;
    bool done;
  }
  mapping (uint256 => KolMission) private missionList;

  struct KolOffering{
    address target;
    uint256 targetAmount;
  }
  KolOffering[] private kolOfferings;
  mapping(uint256 => KolOffering[]) private offeringList;

  function missionPassed(uint256 _missionId) private {
    emit MissionPassed(_missionId,missionList[_missionId].name);
  }
  function createKolMission(bytes32 _name,uint256 _totalAmount,bool _isKol) onlySuperNode public {
      bytes32 iName = _name;
      missionList[missionId] = KolMission(_isKol,
                                          uint256(now),
                                          uint256(now + dealTime),
                                          _totalAmount,
                                          0,
                                          iName,
                                          0,
                                          0,
                                          false,
                                          false);

      missionId++;
      emit MissionLaunched(iName,missionId-1,msg.sender);
  }
  function voteMission(uint256 _missionId,bool _agree) onlySuperNode public{
    require(now < missionList[_missionId].endTime);
    require(kol.querySuperNode(msg.sender));
    require(!missionList[_missionId].done);
    require(!Voter[msg.sender][_missionId]);

    uint16 minSuperNodesNum = minSuperNodes;
    uint16 passSuperNodes = halfSuperNodes;

    uint256 TEN;
    if (missionList[_missionId].isKol){
      TEN = TENKOL;
    }else{
      TEN = TENUSDT;
    }

    if (missionList[_missionId].totalAmount >= TEN){
      passSuperNodes = minSuperNodes;
    }

    if(_agree == true){
      missionList[_missionId].agreeSuperNodes++;
    }
    else{
      missionList[_missionId].refuseSuperNodes++;
    }
    if (missionList[_missionId].agreeSuperNodes >= passSuperNodes) {
        missionList[_missionId].superPassed = true;
        missionPassed(_missionId);
    }else if (missionList[_missionId].refuseSuperNodes >= passSuperNodes) {
        missionList[_missionId].done = true;
    }
    Voter[msg.sender][_missionId] = true;
  }
  function addKolOffering(uint256 _missionId,address _target,uint256 _targetAmount) onlySuperNode public{
    require(!missionList[_missionId].done);
    if (missionList[_missionId].isKol){
      require(kol.queryNode(_target)||kol.querySuperNode(_target));
    }
    require(missionList[_missionId].offeringAmount.add(_targetAmount) <= missionList[_missionId].totalAmount);
    offeringList[_missionId].push(KolOffering(_target,_targetAmount));
    missionList[_missionId].offeringAmount = missionList[_missionId].offeringAmount.add(_targetAmount);

  }
  function excuteVote(uint256 _missionId) onlyOwner public {
    require(!missionList[_missionId].done);
    require(uint256(now) < (missionList[_missionId].endTime + uint256(dealTime)));
    require(missionList[_missionId].superPassed);
    require(missionList[_missionId].totalAmount == missionList[_missionId].offeringAmount);

    bool isKol = missionList[_missionId].isKol;
    for (uint m = 0; m < offeringList[_missionId].length; m++){
      if (isKol){
        kol.transfer(offeringList[_missionId][m].target, offeringList[_missionId][m].targetAmount);
      }else{
        usdt.transfer(offeringList[_missionId][m].target, offeringList[_missionId][m].targetAmount);
      }

    }

    missionList[_missionId].done = true;
    emit OfferingFinished(_missionId,missionList[_missionId].offeringAmount,offeringList[_missionId].length);

  }
  function getMission1(uint256 _missionId) public view returns(bool,
                                                            uint256,
                                                            uint256,
                                                            uint256,
                                                            uint256,
                                                            bytes32){
    return(missionList[_missionId].isKol,
            missionList[_missionId].startTime,
            missionList[_missionId].endTime,
            missionList[_missionId].totalAmount,
            missionList[_missionId].offeringAmount,
            missionList[_missionId].name);
  }
  function getMission2(uint256 _missionId) public view returns(uint16,
                                                              uint16,
                                                              bool,
                                                              bool){
    return(
          missionList[_missionId].agreeSuperNodes,
          missionList[_missionId].refuseSuperNodes,
          missionList[_missionId].superPassed,
          missionList[_missionId].done);
  }
  function getOfferings(uint256 _missionId,uint256 _id) public view returns(address,uint256,uint256){
    return(offeringList[_missionId][_id].target,offeringList[_missionId][_id].targetAmount,offeringList[_missionId].length);
  }
  function voted(address _node,uint256 _missionId) public view returns(bool){
    return Voter[_node][_missionId];
  }

}