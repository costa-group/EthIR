pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC1820Registry {
    function setManager(address account, address newManager) external;

    function getManager(address account) external view returns (address);

    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    function updateERC165Cache(address account, bytes4 interfaceId) external;

    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

interface IERC777Recipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function granularity() external view returns (uint256);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function send(address recipient, uint256 amount, bytes calldata data) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount, bytes calldata data) external;

    function burn(uint256 amount, bytes calldata data) external;

    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function authorizeOperator(address operator) external;

    function revokeOperator(address operator) external;

    function defaultOperators() external view returns (address[] memory);

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface ISmartexUID {
  function addUser(address addr) external returns (uint256);
  function userExists(uint256 id) external view returns (bool);
  function getIDByAddress(address addr) external view returns (uint256);
  function getAddressByID(uint256 id) external view returns (address);

  event NewUser(address indexed addr, uint256 indexed id, uint256 time);
}

interface ISmartexOracle {
  function currentETHPrice() external view returns (uint256);
  function lastETHPriceUpdate() external view returns (uint256);

  function currentTokenPrice() external view returns (uint256);
  function lastTokenPriceUpdate() external view returns (uint256);

  function setETHPrice(uint256 price) external;
  function updateTokenPrice() external;

  event ETHPriceUpdated(uint256 price, uint256 timestamp);
  event TokenPriceUpdated(uint256 price, uint256 timestamp);
}

contract SmartexBase is Context, IERC777Recipient {
  using SafeMath for uint256;
  using Address for address;

  struct User {
    bool exists;
    uint256 id;
    uint256 uplineID;
    uint256 referrerID;
    bool isBurner;
    uint256 holdings;
    address[] downlines;
    address[] referrals;
    mapping (uint8 => uint8) levelPayments;
    mapping (uint8 => bool) levels;
  }

  mapping (address => User) public users;
  mapping (address => bool) public authorizedCallers;

  bool internal _burnersSet;

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  address private _creator;
  uint256 private _currentUserID;
  uint8 constant private MAX_LEVEL = 3;

  IERC777 private _token;
  ISmartexUID private _suid;
  ISmartexOracle private _oracle;

  bytes32 constant private SMARTEX_UID_INTERFACE_HASH =
        0x5a4c6394bd517002e989261e4e45550e407682bcf6894da75da3069c13cae07a;

  bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  mapping (uint8 => uint256) internal _levelUSDPrices;
  mapping (uint256 => address) private _wallets;

  event RegisterUser(address indexed user, address indexed inviter, address indexed upline, uint256 id, uint256 amount, uint256 time);
  event BuyLevel(address indexed user, uint8 indexed level, bool autoBuy, uint256 amount, uint256 time);

  event GetLevelProfit(address indexed user, address indexed downline, uint8 indexed level, uint256 amount, uint256 time);
  event LostLevelProfit(address indexed user, address indexed downline, uint8 indexed level, uint256 amount, uint256 time);
  event BurnLevelProfit(address indexed user, address indexed downline, uint8 indexed level, uint256 amount, uint256 time);

  modifier onlyCreator() {
    require(_msgSender() == _creator, "Caller is not the creator");
    _;
  }

  modifier onlyAuthorizedCaller() {
    require(_msgSender() == _creator || authorizedCallers[_msgSender()], "Caller is not authorized");
    _;
  }

  constructor(IERC777 token) public {
    _token = token;

    _currentUserID++;

    address msgSender = _msgSender();

    _creator = msgSender;
    users[msgSender] = _newUser(0, 0, true);
    _wallets[_currentUserID] = msgSender;

    users[msgSender].levels[1] = true;
    users[msgSender].levels[2] = true;
    users[msgSender].levels[3] = true;

    ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), SMARTEX_UID_INTERFACE_HASH, address(this));
  }

  function creator() public view returns (address) {
    return _creator;
  }

  function currentUserID() public view returns (uint256) {
    return _currentUserID;
  }

  function token() public view returns (IERC777) {
    return _token;
  }

  function setSUID(ISmartexUID suid) public onlyCreator {
    _suid = suid;
  }

  function suid() public view returns (ISmartexUID) {
    return _suid;
  }

  function setOracle(ISmartexOracle oracle) public onlyCreator {
    _oracle = oracle;
  }

  function oracle() public view returns (ISmartexOracle) {
    return _oracle;
  }

  function wallet(uint256 id) public view returns (address) {
    return _wallets[id];
  }

  function levelPrice(uint8 level) public view returns (uint256) {
    return uint256(10 ** 18).mul(_levelUSDPrices[level]).div(_oracle.currentTokenPrice());
  }

  function levelPrices() public view returns (uint256, uint256, uint256) {
    return (levelPrice(1), levelPrice(2), levelPrice(3));
  }

  function userUpline(address user, uint8 height) public view returns (address) {
    if (height == 0 || user == address(0)) {
      return user;
    }

    return userUpline(_wallets[users[user].uplineID], height - 1);
  }

  function userLevelPayments(address user, uint8 level) public view returns (uint8) {
    return users[user].levelPayments[level];
  }

  function userLevels(address user) public view returns (bool, bool, bool) {
    return (users[user].levels[1], users[user].levels[2], users[user].levels[3]);
  }

  function userHoldings(address user) public view returns (uint256) {
    return users[user].holdings;
  }

  function userDownlines(address user) public view returns (address[] memory) {
    return users[user].downlines;
  }

  function userReferrals(address user) public view returns (address[] memory) {
    return users[user].referrals;
  }

  function userHasLevel(address user, uint8 level) public view returns (bool) {
    return users[user].levels[level];
  }

  function setAuthorizedCaller(address caller, bool allowed) public onlyCreator {
    authorizedCallers[caller] = allowed;
  }

  function addBurner(address burner) public onlyCreator {
    require(!_burnersSet, "Burners are already set");

    uint256 uplineID = _getUplineID();

    _currentUserID++;

    if (_currentUserID == 63) {
      _burnersSet = true;
    }

    users[burner] = _newUser(uplineID, uplineID, true);
    _wallets[_currentUserID] = burner;

    users[burner].levels[1] = true;
    users[burner].levels[2] = true;
    users[burner].levels[3] = true;

    users[_wallets[uplineID]].downlines.push(burner);
    
    users[_wallets[uplineID]].referrals.push(burner);

    emit RegisterUser(burner, _wallets[uplineID], _wallets[uplineID], _currentUserID, levelPrice(1), now);
  }

  function tokensReceived(address operator, address from, address to, uint256 amount, bytes memory data, bytes memory operatorData) public {
    require(_burnersSet, "Burners are not set");
    require(address(_token) == _msgSender(), "Invalid token");
    require(operator == from, "Transfers from operators are not allowed");
    require(!from.isContract(), "Transfers from contracts are not allowed");

    uint8 level = MAX_LEVEL;

    while (level > 0 && amount != levelPrice(level)) level--;

    require(level > 0, "Invalid amount has sent");

    if (users[from].exists) {
      _buyLevel(from, level);
      return;
    }

    require(level == 1, "You should buy first level");

    address referrer = _bytesToAddress(data);
    _registerUser(from, users[referrer].id);
  }

  function _registerUser(address newUser, uint256 referrerID) private {
    referrerID = (referrerID > 0 && referrerID <= _currentUserID) ? referrerID : 63;
    uint256 uplineID = _getUplineID();

    _currentUserID++;

    users[newUser] = _newUser(referrerID, uplineID, false);
    _wallets[_currentUserID] = newUser;
    users[newUser].levels[1] = true;

    users[_wallets[uplineID]].downlines.push(newUser);

    users[_wallets[referrerID]].referrals.push(newUser);

    address referrer = _wallets[referrerID];

    if (!users[referrer].isBurner && !referrer.isContract() && users[_wallets[referrerID]].referrals.length > 2) {
      _token.mint(referrer, levelPrice(1).div(2), abi.encodePacked(newUser));
    }

    if (address(_suid) != address(0)) {
      _suid.addUser(newUser);
    }

    _transferLevelPayment(1, newUser, newUser);
    emit RegisterUser(newUser, _wallets[referrerID], _wallets[uplineID], _currentUserID, levelPrice(1), now);
  }

  function _buyLevel(address user, uint8 level) private {
    require(!users[user].levels[level], "You already bought this level");

    for (uint8 lvl = level - 1; lvl > 0; lvl--) {
      require(users[user].levels[lvl], "Buy the previous level");
    }

    users[user].levels[level] = true;

    _releaseUserHoldings(user, level);

    _transferLevelPayment(level, user, user);
    emit BuyLevel(user, level, false, levelPrice(level), now);
  }

  function _autoBuy(address user, uint8 level) private {
    uint256 price = levelPrice(level);

    require(users[user].holdings >= price, "Not enough holdings for autobuy");

    uint256 change = users[user].holdings.sub(price);

    if (! users[user].levels[level]) {
      users[user].levels[level] = true;
    }

    users[user].holdings = 0;
    delete users[user].levelPayments[level - 1];

    _transferLevelPayment(level, user, user);

    _token.transfer(user, change);

    emit BuyLevel(user, level, true, price, now);
  }

  function _transferLevelPayment(uint8 level, address _user, address originalSender) private {
    address referrer = userUpline(_user, level);

    if (referrer == address(0)) {
      referrer = _creator;
    }

    User storage user = users[referrer];

    uint256 amount = levelPrice(level);

    if (
      referrer.isContract() ||
      (
        !user.isBurner &&
        (user.referrals.length < 2 || ! user.levels[level])
      )
    ) {
      emit LostLevelProfit(referrer, originalSender, level, amount, now);
      _transferLevelPayment(level, referrer, originalSender);
      return;
    }

    if (user.isBurner) {
      _token.burn(amount, "Smartex burn profit");
      emit BurnLevelProfit(referrer, originalSender, level, amount, now);
      return;
    }

    if (level != MAX_LEVEL && ! users[referrer].levels[level + 1]) {
      user.levelPayments[level]++;
    }

    if (
      ! user.levels[level + 1] &&
      (level == 1 || (level == 2 && user.levelPayments[2] > 2))
    ) {
      user.holdings = user.holdings.add(amount);

      emit GetLevelProfit(referrer, originalSender, level, amount, now);

      if (levelPrice(level + 1) <= user.holdings) {
        _autoBuy(referrer, (level + 1));
      }

      return;
    }

    _token.transfer(referrer, amount);
    emit GetLevelProfit(referrer, originalSender, level, amount, now);
  }


  function _getUplineID() private view returns (uint256 uplineID) {
    uplineID = users[_wallets[_currentUserID]].uplineID;

    if (_currentUserID % 2 != 0) {
      uplineID += 1;
    }
  }

  function _releaseUserHoldings(address user, uint8 level) private {
    User storage _user = users[user];
    uint256 amount = _user.holdings;

    if (_user.levelPayments[level] == 0 && amount == 0) {
      return;
    }

    _user.holdings = 0;
    delete _user.levelPayments[level];

    _token.transfer(user, amount);
  }

  function _newUser(uint256 referrerID, uint256 uplineID, bool isBurner) private view returns (User memory) {
    return User({
      exists: true,
      id: _currentUserID,
      referrerID: referrerID,
      uplineID: uplineID,
      isBurner: isBurner,
      holdings: 0,
      downlines: new address[](0),
      referrals: new address[](0)
    });
  }

  function _bytesToAddress(bytes memory _addr) private pure returns (address addr) {
    assembly {
      addr := mload(add(_addr, 20))
    }
  }
}

contract SmartexMobium is SmartexBase {
  constructor(IERC777 token) public SmartexBase(token) {
    _levelUSDPrices[1] = 200 * (10 ** 8);
    _levelUSDPrices[2] = 300 * (10 ** 8);
    _levelUSDPrices[3] = 500 * (10 ** 8);
  }
}