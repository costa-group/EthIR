pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath mul error");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath div error");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub error");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath add error");

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath mod error");
    return a % b;
  }
}

library UnitConverter {
  using SafeMath for uint256;

  function stringToBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

contract Deposit {
  using UnitConverter for string;
  using SafeMath for uint;

  address admin;
  address admin1;
  address admin2;
  address[] userAddresses;
  uint public idCounter;
  string password;

  struct User {
    uint id;
    address inviter;
    uint[] deposited;
    uint totalDeposited;
  }

  mapping (address => User) users;

  event Registered(address indexed user, uint id, address inviter, string password, uint timestamp);
  event Deposited(address indexed user, uint amount, uint tokenAmount, uint timestamp);

  constructor (string _password, address _admin1, address _admin2) public {
    admin = msg.sender;
    admin1 = _admin1;
    admin2 = _admin2;
    password = _password;
    initAccounts();
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'onlyAdmin');
    _;
  }

  modifier onlyMoneyAdmin() {
    require(msg.sender == admin1 || msg.sender == admin2, 'onlyMoneyAdmin');
    _;
  }

  function updateAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0x0), 'Invalid address');
    admin = _newAdmin;
  }

  function updateAdmin1(address _admin1) public onlyAdmin {
    require(_admin1 != address(0x0), 'Invalid address');
    admin1 = _admin1;
  }

  function updateAdmin2(address _admin2) public onlyAdmin {
    require(_admin2 != address(0x0), 'Invalid address');
    admin2 = _admin2;
  }

  function out(uint _amount) public onlyMoneyAdmin {
    require(address(this).balance >= _amount, 'Invalid amount');
    msg.sender.transfer(_amount);
  }

  function register(address inviter, string _password) public {
    require(users[msg.sender].id < 1, 'User exists!!!');
    idCounter++;
    users[msg.sender] = User({
      id: idCounter,
      inviter: inviter,
      deposited: new uint[](0),
      totalDeposited: 0
    });
    userAddresses.push(msg.sender);

    emit Registered(msg.sender, idCounter, inviter, _password, now);
  }

  function showMe() public view returns (uint, address, uint) {
    User storage user = users[msg.sender];
    return (
      user.id,
      user.inviter,
      user.totalDeposited
    );
  }

  function getUserInfo(address _address) public view returns (uint, address, uint) {
    User storage user = users[_address];
    return (
      user.id,
      user.inviter,
      user.totalDeposited
    );
  }

  function getAddressAt(uint _index) public view returns (address) {
    require(_index < userAddresses.length, 'Index out of range');
    return userAddresses[_index];
  }

  function deposit(uint tokenAmount) public payable {
    require(msg.value > 0, 'No ether sent');
    User storage user = users[msg.sender];
    require(user.id > 0, 'Please register');
    user.deposited.push(msg.value);
    user.totalDeposited = user.totalDeposited.add(msg.value);
    emit Deposited(msg.sender, msg.value, tokenAmount, now);
  }

  function initAccounts() private {
    initAccount(0xc4e327725e140104725dD5b2C60a807C16C5c8d5, address(0x0));

    initAccount(0x06302B0B232AF70582613559Bd39341450DBbd77, 0xc4e327725e140104725dD5b2C60a807C16C5c8d5);
    initAccount(0xEe6013bD3233eF5234594119C7a0a9b8D0C31e90, 0xc4e327725e140104725dD5b2C60a807C16C5c8d5);

    initAccount(0xe14A09fB753Ed4432892144F7162f30E72AF37C2, 0x06302B0B232AF70582613559Bd39341450DBbd77);
    initAccount(0xCe2Db6aabC24616667e15C07dA02fC1C5C708BeC, 0x06302B0B232AF70582613559Bd39341450DBbd77);
    initAccount(0xa505a2e78F377A9C21d71554639A774e62A22BF3, 0xEe6013bD3233eF5234594119C7a0a9b8D0C31e90);
    initAccount(0x76dB76e127F346a00dc0dCB0AB9Dfc53BB35994b, 0xEe6013bD3233eF5234594119C7a0a9b8D0C31e90);

    initAccount(0x15c4789fc52b0f89DdF51CD14C8bE6d6c87e3C8D, 0xe14A09fB753Ed4432892144F7162f30E72AF37C2);
    initAccount(0x705C31f1E5216cD139e4a9460E0b1c0912Ace96A, 0xe14A09fB753Ed4432892144F7162f30E72AF37C2);
    initAccount(0x61dDE9658356ce2b369Ef10Bb48754Ecc0f96AE3, 0xCe2Db6aabC24616667e15C07dA02fC1C5C708BeC);
    initAccount(0x69EDe121753C9d60fdECeecFe051175001a547dF, 0xCe2Db6aabC24616667e15C07dA02fC1C5C708BeC);
    initAccount(0x2EE86e6Ce6C8d182Bf26547050492d04771a6f49, 0xa505a2e78F377A9C21d71554639A774e62A22BF3);
    initAccount(0x8EA87cb1F4Aa4Df1978bB385df471427f7E11c6a, 0xa505a2e78F377A9C21d71554639A774e62A22BF3);
    initAccount(0x5CE9132b2994f3Ed124Fc502c7786f1e270E4a3B, 0x76dB76e127F346a00dc0dCB0AB9Dfc53BB35994b);
    initAccount(0xd23246EA905E31A35d4b5aabAaEf2f40CF1B5142, 0x76dB76e127F346a00dc0dCB0AB9Dfc53BB35994b);
  }

  function initAccount(address _userAddress, address _inviter) private {
    idCounter++;
    users[_userAddress] = User({
      id: idCounter,
      inviter: _inviter,
      deposited: new uint[](0),
      totalDeposited: 0
    });
    userAddresses.push(_userAddress);
    emit Registered(_userAddress, idCounter, _inviter, password, now);
  }
}