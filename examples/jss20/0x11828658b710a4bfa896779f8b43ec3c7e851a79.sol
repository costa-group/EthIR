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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface ISmartexUID {
  function addUser(address addr) external returns (uint256);
  function userExists(uint256 id) external view returns (bool);
  function getIDByAddress(address addr) external view returns (uint256);
  function getAddressByID(uint256 id) external view returns (address);

  event NewUser(address indexed addr, uint256 indexed id, uint256 time);
}

contract SmartexUID is ISmartexUID, Ownable {
  struct User {
    uint256 id;
    bool exists;
    uint256 registered;
  }

  mapping (address => User) public users;

  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 constant private SMARTEX_UID_INTERFACE_HASH =
        0x5a4c6394bd517002e989261e4e45550e407682bcf6894da75da3069c13cae07a;

  uint256 private _currentID;
  mapping (uint256 => address) private _wallets;

  constructor() public {}

  function currentID() public view returns (uint256) {
    return _currentID;
  }

  function userExists(uint256 id) public view returns (bool) {
    return _wallets[id] != address(0);
  }

  function getIDByAddress(address addr) public view returns (uint256) {
    return users[addr].id;
  }

  function getAddressByID(uint256 id) public view returns (address) {
    return _wallets[id];
  }

  function addUser(address addr) public returns (uint256) {
    address implementer = ERC1820_REGISTRY.getInterfaceImplementer(_msgSender(), SMARTEX_UID_INTERFACE_HASH);

    require(implementer != address(0), "The caller has no implementer for SmartexUID");

    if (users[addr].exists) {
      return users[addr].id;
    }

    _currentID++;

    users[addr] = User({
      id: _currentID,
      exists: true,
      registered: now
    });

    _wallets[_currentID] = addr;

    emit NewUser(addr, _currentID, now);

    return _currentID;
  }
}