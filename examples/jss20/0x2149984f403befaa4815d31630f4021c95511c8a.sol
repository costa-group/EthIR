pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It's also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string memory roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string memory roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string memory roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string memory roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string memory roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It's recommended that you define constants in the contract,
 * @dev like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_PAUSE_ADMIN = "pauseAdmin";

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }
  modifier onlyPauseAdmin()
  {
    checkRole(msg.sender, ROLE_PAUSE_ADMIN);
    _;
  }
  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
    addRole(msg.sender, ROLE_PAUSE_ADMIN);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string memory roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string memory roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

abstract contract DragonsETH {
    struct Dragon {
        uint256 gen1;
        uint8 stage; // 0 - Dead, 1 - Egg, 2 - Young Dragon 
        uint8 currentAction; // 0 - free, 1 - fight place, 0xFF - Necropolis,  2 - random fight,
                             // 3 - breed market, 4 - breed auction, 5 - random breed, 6 - market place ...
        uint240 gen2;
        uint256 nextBlock2Action;
    }

    Dragon[] public dragons;
    mapping(uint256 => string) public dragonName;
    
    function ownerOf(uint256 _tokenId) virtual public view returns (address);
    function tokensOf(address _owner) virtual external view returns (uint256[] memory);
    //function balanceOf(address _owner) public view returns (uint256);
}

contract DragonsStats {
    struct parent {
        uint128 parentOne;
        uint128 parentTwo;
    }
    
    struct lastAction {
        uint8  lastActionID;
        uint248 lastActionDragonID;
    }
    
    struct dragonStat {
        uint32 fightWin;
        uint32 fightLose;
        uint32 children;
        uint32 fightToDeathWin;
        uint32 mutagenFace;
        uint32 mutagenFight;
        uint32 genLabFace;
        uint32 genLabFight;
    }
    mapping(uint256 => uint256) public birthBlock;
    mapping(uint256 => uint256) public deathBlock;
    mapping(uint256 => parent)  public parents;
    mapping(uint256 => lastAction) public lastActions;
    mapping(uint256 => dragonStat) public dragonStats;
    
    
}

abstract contract FixMarketPlace {
    function getOwnedDragonToSale(address _owner) virtual external view returns(uint256[] memory);
}

contract Proxy4DAPP is RBACWithAdmin {
    DragonsETH public mainContract;
    DragonsStats public statsContract;
    FixMarketPlace public fmpContractAddress;
    bytes constant firstPartPictureName = "dragon_";
    
    constructor(address _addressMainContract, address _addressDragonsStats) public {
        mainContract = DragonsETH(_addressMainContract);
        statsContract = DragonsStats(_addressDragonsStats);
    }
    function getDragons(uint256[] calldata _dragonIDs) external view returns(uint256[] memory) {
        if (_dragonIDs.length == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](_dragonIDs.length * 17 + 1/*CHAGE IT*/);
            result[0] = block.number;
            for (uint256 dragonIndex = 0; dragonIndex < _dragonIDs.length; dragonIndex++) {
                uint256 dragonID = _dragonIDs[dragonIndex];
                result[dragonIndex * 17 + 1] = dragonID;
                result[dragonIndex * 17 + 2] = uint256(mainContract.ownerOf(dragonID));
                uint8 tmp;
                uint8 currentAction;
                uint240 gen2;
                (result[dragonIndex * 17 + 3]/*gen1*/,tmp,currentAction,gen2,result[dragonIndex * 17 + 4]/*nextBlock2Action*/) = mainContract.dragons(dragonID);
                result[dragonIndex * 17 + 5] = uint256(tmp); // stage
                result[dragonIndex * 17 + 6] = uint256(currentAction);
                result[dragonIndex * 17 + 7] = uint256(gen2);
                uint248 lastActionDragonID;
                (tmp, lastActionDragonID) = statsContract.lastActions(dragonID);
                result[dragonIndex * 17 + 8] = uint256(tmp); // lastActionID
                result[dragonIndex * 17 + 9] = uint256(lastActionDragonID);
                uint32 fightWin;
                uint32 fightLose;
                uint32 children;
                uint32 fightToDeathWin;
                uint32 mutagenFight;
                uint32 genLabFight;
                uint32 mutagenFace;
                uint32 genLabFace;
                (fightWin,fightLose,children,fightToDeathWin,mutagenFace,mutagenFight,genLabFace,genLabFight) = statsContract.dragonStats(dragonID);
                result[dragonIndex * 17 + 10] = uint256(fightWin);
                result[dragonIndex * 17 + 11] = uint256(fightLose);
                result[dragonIndex * 17 + 12] = uint256(children);
                result[dragonIndex * 17 + 13] = uint256(fightToDeathWin);
                result[dragonIndex * 17 + 14] = uint256(mutagenFace);
                result[dragonIndex * 17 + 15] = uint256(mutagenFight);
                result[dragonIndex * 17 + 16] = uint256(genLabFace);
                result[dragonIndex * 17 + 17] = uint256(genLabFight);
            }

            return result; 
        }
    }
    function getDragonsName(uint256[] calldata _dragonIDs) external view returns(string[] memory) {
        uint256 dragonCount = _dragonIDs.length;
        if (dragonCount == 0) {
            return new string[](0);
        } else {
            string[] memory result = new string[](dragonCount);
            
            for (uint256 dragonIndex = 0; dragonIndex < dragonCount; dragonIndex++) {
                result[dragonIndex] = mainContract.dragonName(_dragonIDs[dragonIndex]);
            }
            return result;
        }
    }
    function getDragonsNameB32(uint256[] calldata _dragonIDs) external view returns(bytes32[] memory) {
        uint256 dragonCount = _dragonIDs.length;
        if (dragonCount == 0) {
            return new bytes32[](0);
        } else {
            bytes32[] memory result = new bytes32[](dragonCount);
            
            for (uint256 dragonIndex = 0; dragonIndex < dragonCount; dragonIndex++) {
                bytes memory tempEmptyStringTest = bytes(mainContract.dragonName(_dragonIDs[dragonIndex]));
                bytes32 tmp;
                if (tempEmptyStringTest.length == 0) {
                    result[dragonIndex] = 0x0;
                } else {

                    assembly {
                        tmp := mload(add(tempEmptyStringTest, 32))
                    }
                    result[dragonIndex] = tmp;
                }
            }
            return result;
        }
    }
    function getDragonsStats(uint256[] calldata _dragonIDs) external view returns(uint256[] memory) {
        uint256 dragonCount = _dragonIDs.length;
        if (dragonCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](dragonCount * 6);
            uint256 resultIndex = 0;

            for (uint256 dragonIndex = 0; dragonIndex < dragonCount; dragonIndex++) {
                uint256 dragonID = _dragonIDs[dragonIndex];
                result[resultIndex++] = dragonID;
                result[resultIndex++] = uint256(mainContract.ownerOf(dragonID));
                uint128 parentOne;
                uint128 parentTwo;
                (parentOne, parentTwo) = statsContract.parents(dragonID);
                result[resultIndex++] = uint256(parentOne);
                result[resultIndex++] = uint256(parentTwo);
                result[resultIndex++] = statsContract.birthBlock(dragonID);
                result[resultIndex++] = statsContract.deathBlock(dragonID);
            }
            return result;
        }
    }
    function tokensOf(address _owner) external view returns (uint256[] memory) {
        uint256[] memory tmpMain = mainContract.tokensOf(_owner);
        uint256[] memory tmpFMP;
        if (address(fmpContractAddress) != address(0)) {
            tmpFMP = fmpContractAddress.getOwnedDragonToSale(_owner);
        } else {
            tmpFMP = new uint256[](0);
        }
        if (tmpFMP.length + tmpMain.length == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tmpFMP.length + tmpMain.length);
            uint256 index = 0;
            for (; index < tmpMain.length; index++) {
                result[index] = tmpMain[index];
            }

            uint256 j = 0;
            while (j < tmpFMP.length) {
                result[index++] = tmpFMP[j++];
            }
            return result;
        }
    }
    function changeFMPcontractAddress(address _fmpContractAddress) external onlyAdmin {
        fmpContractAddress = FixMarketPlace(_fmpContractAddress);
    }
    function pictureName(uint256  _tokenId) external pure returns (string memory) {
        bytes memory tmpBytes = new bytes(96);
        uint256 i = 0;
        uint256 tokenId = _tokenId;
        // for same use case need "if (tokenId == 0)" 
        while (tokenId != 0) {
            uint256 remainderDiv = tokenId % 10;
            tokenId = tokenId / 10;
            tmpBytes[i++] = byte(uint8(48 + remainderDiv));
        }
 
        bytes memory resaultBytes = new bytes(firstPartPictureName.length + i);
        uint256 j;
        for (j = 0; j < firstPartPictureName.length; j++) {
            resaultBytes[j] = firstPartPictureName[j];
        }
        
        i--;
        
        for (j = 0; j <= i; j++) {
            resaultBytes[j + firstPartPictureName.length] = tmpBytes[i - j];
        }
        
        return string(resaultBytes);
    }
}