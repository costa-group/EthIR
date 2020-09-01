pragma solidity ^0.4.23;

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/

contract BasicToken is ERC20Basic {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
}

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
  uint256 public userSupplyed;

  function transferFrom(address _from, address _to, uint _value) public {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/

contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title KOL Core Team Release Contract
 * @dev visit: https://github.com/jackoelv/KOL/
*/
contract KOLCoreTeam is Ownable{
    using SafeMath for uint256;

    StandardToken public token;
    mapping (address => uint256) public CoreTeamReleased;
    mapping (address => bool) private CoreAddr;
    mapping (address => uint8) private CoreRate;

    uint8 private constant rate = 10;
    uint8 public constant coreNum = 3;
    uint8 public settedCoreNum = 0;

    constructor(address _tokenAddress) public {
      token = StandardToken(_tokenAddress);
    }

    modifier onlyCore {
        require(CoreAddr[msg.sender]);
        _;
    }
    function setCoreAddr(address _coreAddr,uint8 _rate) onlyOwner public {
      require(settedCoreNum < coreNum);
      CoreAddr[_coreAddr] = true;
      CoreRate[_coreAddr] = _rate;
      settedCoreNum ++;
    }
    function changeCoreAddr(address _newCoreAddr) onlyCore public {
      CoreAddr[_newCoreAddr] = true;
      CoreRate[_newCoreAddr] = CoreRate[msg.sender];
      CoreAddr[msg.sender] = false;
      CoreTeamReleased[_newCoreAddr] = CoreTeamReleased[msg.sender];
    }

    function releaseKOL(uint256 _amount) onlyCore public {
      uint256 userSupplyed = token.userSupplyed();
      require( (CoreTeamReleased[msg.sender].add(_amount)).mul(rate) <=
                  (userSupplyed.mul(CoreRate[msg.sender])).div(100));
      token.transfer(msg.sender, _amount);
      CoreTeamReleased[msg.sender] = CoreTeamReleased[msg.sender].add(_amount);
    }
    function queryCore(address _coreAddr) public view returns (bool,uint8){
      return(CoreAddr[_coreAddr],CoreRate[_coreAddr]);
    }
    function queryCoreReleased(address _coreAddr) public view returns (uint256) {
      return(CoreTeamReleased[_coreAddr]);
    }

}