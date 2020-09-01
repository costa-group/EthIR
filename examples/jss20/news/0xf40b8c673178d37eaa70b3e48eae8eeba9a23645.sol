pragma solidity 0.6.1;


interface Proxy {

  
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external;
    
}

interface ERC721 {

  
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

library SafeMath {

  
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    
    
    
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    
  }

  
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}

contract Abilitable {
  using SafeMath for uint;

  
  string constant NOT_AUTHORIZED = "017001";
  string constant INVALID_INPUT = "017002";

  
  uint8 constant SUPER_ABILITY = 1;

  
  uint8 constant ALLOW_SUPER_ABILITY = 2;

  
  uint8 constant EMPTY_SLOT_1 = 4;

  
  uint8 constant EMPTY_SLOT_2 = 8;

  
  uint8 constant ALL_DEFAULT_ABILITIES = 15;

  
  mapping(address => uint256) public addressToAbility;

  
  event SetAbilities(
    address indexed _target,
    uint256 indexed _abilities
  );

  
  modifier hasAbilities(
    uint256 _abilities
  )
  {
    require(_abilities > 0, INVALID_INPUT);
    require(
      addressToAbility[msg.sender] & _abilities == _abilities,
      NOT_AUTHORIZED
    );
    _;
  }

  
  constructor()
    public
  {
    addressToAbility[msg.sender] = ALL_DEFAULT_ABILITIES;
  }

  
  function grantAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(SUPER_ABILITY)
  {
    addressToAbility[_target] |= _abilities;
    emit SetAbilities(_target, addressToAbility[_target]);
  }

  
  function revokeAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(SUPER_ABILITY)
  {
    addressToAbility[_target] &= ~_abilities;
    emit SetAbilities(_target, addressToAbility[_target]);
  }

  
  function setAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(SUPER_ABILITY)
  {
    addressToAbility[_target] = _abilities;
    emit SetAbilities(_target, _abilities);
  }

  
  function isAble(
    address _target,
    uint256 _abilities
  )
    external
    view
    returns (bool)
  {
    require(_abilities > 0, INVALID_INPUT);
    return (addressToAbility[_target] & _abilities) == _abilities;
  }

}

contract NFTokenTransferProxy is
  Proxy,
  Abilitable
{

  
  uint8 constant ABILITY_TO_EXECUTE = 16;

  
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external
    override
    hasAbilities(ABILITY_TO_EXECUTE)
  {
    ERC721(_target).transferFrom(_a, _b, _c);
  }

}