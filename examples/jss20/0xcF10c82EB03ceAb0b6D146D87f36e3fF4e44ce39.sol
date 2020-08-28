// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ERC721/el/forging/ForgePathCatalog.sol

pragma solidity 0.5.0;


contract ForgePathCatalog is Ownable {    

    // Forge Types
    // 1 - EL Gen 1 Token + EL Gen 1 Token = EL Gen 1 Token
    // 2 - ERC721 Address + ERC721 Address = EL Gen 1 Token
    // 3 - ERC721 Address + EL Gen 1 Token = EL Gen 1 Token
    // 4 - ERC1155 Token + ERC1155 Token = EL Gen 1 Token
    // 5 - ERC1155 Token + EL Gen 1 Token = EL Gen 1 Token
    // 6 - ERC1155 Token + ERC721 Address = EL Gen 1 Token

    struct ForgePathDataCommon {
      uint8 forgeType;
      uint256 weiCost;
      uint256 elementeumCost;
      uint256 forgedItem;
    }

    uint256 private nextForgePathIndex = 0;
    string[] public forgePathNames;
    mapping (uint256 => uint256) private forgePathIndexMap;
    mapping (string => uint256) private forgePathNameIdMap;    
    mapping (uint256 => string) private forgePathIdNameMap;    

    mapping (uint256 => ForgePathDataCommon) internal forgePathMapCommon;

    constructor() public 
      Ownable()
    {      
    }    

    function() external payable {
        revert("Fallback function is not permitted.");
    }

    function destroyContract() external {
        _requireOnlyOwner();
        address payable payableOwner = address(uint160(owner()));
        selfdestruct(payableOwner);
    }

    function hasPathDefinitionByName(string calldata pathName) external view returns (bool) {
        return _hasPathDefinitionByName(pathName);
    }

    function hasPathDefinition(uint256 pathId) external view returns (bool) {
        return _hasPathDefinition(pathId);
    }

    function getNumberOfPathDefinitions() external view returns (uint256) {
        return forgePathNames.length;
    }        

    function getForgePathId(string memory pathName) public view returns (uint256) {
      require(_hasPathDefinitionByName(pathName), "path not defined");
      return forgePathNameIdMap[pathName];
    }

    function getForgePathNameAtIndex(uint256 index) external view returns (string memory) {
      require(index < forgePathNames.length, "Index Out Of Range");
      string memory pathName = forgePathNames[index]; 
      require(_hasPathDefinitionByName(pathName), "path not defined");
      return pathName;
    }

    function getForgePathIdAtIndex(uint256 index) external view returns (uint256) {
      require(index < forgePathNames.length, "Index Out Of Range");
      string memory pathName = forgePathNames[index]; 
      require(_hasPathDefinitionByName(pathName), "path not defined");
      return forgePathNameIdMap[pathName];
    }    

    function getForgeType(uint256 pathId) external view returns (uint8) {
      return _getForgeType(pathId);
    }    

    function getForgePathDetailsCommon(uint256 pathId) external view returns (uint256, uint256, uint256) {
      ForgePathDataCommon memory forgePathDataCommon = _getForgePathDataCommon(pathId);
      return 
      (
        forgePathDataCommon.weiCost,
        forgePathDataCommon.elementeumCost,
        forgePathDataCommon.forgedItem
      );
    }

    function _hasPathDefinitionByName(string memory pathName) internal view returns (bool) {
        return forgePathNameIdMap[pathName] != 0;
    }

    function _hasPathDefinition(uint256 pathId) internal view returns (bool) {
        bytes memory tempEmptyStringTest = bytes(forgePathIdNameMap[pathId]);
        return tempEmptyStringTest.length != 0;
    }

    function _getForgePathNameAtIndex(uint256 pathIndex) internal view returns (string memory) {
        return forgePathNames[pathIndex];
    }

    function _getForgeType(uint256 pathId) internal view returns (uint8) {
      require(_hasPathDefinition(pathId), "path not defined");
      return forgePathMapCommon[pathId].forgeType;
    }

    function registerForgePathCommon(string memory pathName, uint8 forgeType, uint256 weiCost, uint256 elementeumCost, uint256 forgedItem) internal {
        _requireOnlyOwner();
        require(!_hasPathDefinitionByName(pathName), "path already defined");
        require(bytes(pathName).length < 32, "path name may not exceed 31 characters");

        nextForgePathIndex++;
        forgePathIndexMap[nextForgePathIndex] = forgePathNames.length;
        forgePathNameIdMap[pathName] = nextForgePathIndex;
        forgePathIdNameMap[nextForgePathIndex] = pathName;
        forgePathNames.push(pathName);

        forgePathMapCommon[nextForgePathIndex].forgeType = forgeType;
        forgePathMapCommon[nextForgePathIndex].weiCost = weiCost;
        forgePathMapCommon[nextForgePathIndex].elementeumCost = elementeumCost;
        forgePathMapCommon[nextForgePathIndex].forgedItem = forgedItem;
    }

    function unregisterForgePathCommon(string memory pathName) internal {
        _requireOnlyOwner();
        require(_hasPathDefinitionByName(pathName), "path not defined");

        uint256 pathId = forgePathNameIdMap[pathName];      
        uint256 pathIndex = forgePathIndexMap[pathId];

        delete forgePathIndexMap[pathId];
        delete forgePathNameIdMap[pathName];
        delete forgePathIdNameMap[pathId];
        delete forgePathMapCommon[pathId];

        string memory tmp = _getForgePathNameAtIndex(pathIndex);      
        string memory priorLastPathName = _getForgePathNameAtIndex(forgePathNames.length - 1);
        uint256 priorLastPathId = forgePathNameIdMap[priorLastPathName];      
        forgePathNames[pathIndex] = forgePathNames[forgePathNames.length - 1];
        forgePathNames[forgePathNames.length - 1] = tmp;
        forgePathIndexMap[priorLastPathId] = pathIndex;
        delete forgePathNames[forgePathNames.length - 1];
        forgePathNames.length--;     
    }                

    function _getForgePathDataCommon(uint256 pathId) internal view returns (ForgePathDataCommon memory) {
      require(_hasPathDefinition(pathId), "path not defined");
      return forgePathMapCommon[pathId];
    }

    function _requireOnlyOwner() internal view {
      require(isOwner(), "Ownable: caller is not the owner");
    }
}

// File: contracts/ERC721/el/forging/IForgePathCatalogCombined.sol

pragma solidity 0.5.0;

interface IForgePathCatalogCombined {        
    function getNumberOfPathDefinitions() external view returns (uint256);
    function getForgePathNameAtIndex(uint256 index) external view returns (string memory);
    function getForgePathIdAtIndex(uint256 index) external view returns (uint256);

    function getForgeType(uint256 pathId) external view returns (uint8);
    function getForgePathDetailsCommon(uint256 pathId) external view returns (uint256, uint256, uint256);
    function getForgePathDetailsTwoGen1Tokens(uint256 pathId) external view returns (uint256, uint256, bool, bool);
    function getForgePathDetailsTwoERC721Addresses(uint256 pathId) external view returns (address, address);
    function getForgePathDetailsERC721AddressWithGen1Token(uint256 pathId) external view returns (address, uint256, bool);
    function getForgePathDetailsTwoERC1155Tokens(uint256 pathId) external view returns (uint256, uint256, bool, bool, bool, bool);
    function getForgePathDetailsERC1155WithGen1Token(uint256 pathId) external view returns (uint256, uint256, bool, bool, bool);
    function getForgePathDetailsERC1155WithERC721Address(uint256 pathId) external view returns (uint256, address, bool, bool);
}

// File: contracts/ERC721/el/forging/ForgePathCatalogCombined.sol

pragma solidity 0.5.0;



contract ForgePathCatalogCombined is IForgePathCatalogCombined, ForgePathCatalog {    

    struct ForgePathDataTwoGen1Tokens {
      uint256 material1;
      uint256 material2;
      bool burnMaterial1;
      bool burnMaterial2;
    }

    struct ForgePathDataTwoERC721Addresses {
      address material1;
      address material2;
    }

    struct ForgePathDataERC721AddressWithGen1Token {
      address material1;
      uint256 material2;
      bool burnMaterial2;
    }

    struct ForgePathDataTwoERC1155Tokens {
      uint256 material1;
      uint256 material2;
      bool meltMaterial1;
      bool meltMaterial2;
      bool material1IsNonFungible;
      bool material2IsNonFungible;
    }

    struct ForgePathDataERC1155WithGen1Token {
      uint256 material1;
      uint256 material2;
      bool meltMaterial1;
      bool burnMaterial2;
      bool material1IsNonFungible;      
    }

    struct ForgePathDataERC1155WithERC721Address {
      uint256 material1;
      address material2;
      bool meltMaterial1;
      bool material1IsNonFungible;
    }

    mapping (uint256 => ForgePathDataTwoGen1Tokens) private forgePathMapTwoGen1Tokens;
    mapping (uint256 => ForgePathDataTwoERC721Addresses) private forgePathMapTwoERC721Addresses;
    mapping (uint256 => ForgePathDataERC721AddressWithGen1Token) private forgePathMapERC721AddressWithGen1Token;
    mapping (uint256 => ForgePathDataTwoERC1155Tokens) private forgePathMapTwoERC1155Tokens;
    mapping (uint256 => ForgePathDataERC1155WithGen1Token) private forgePathMapERC1155WithGen1Token;
    mapping (uint256 => ForgePathDataERC1155WithERC721Address) private forgePathMapERC1155WithERC721Address;

    constructor() public 
      ForgePathCatalog()
    {      
    }    

    function unregisterForgePath(string calldata pathName) external {        
        uint256 forgePathId = getForgePathId(pathName);
        uint8 forgeType = _getForgeType(forgePathId);        
        unregisterForgePathCommon(pathName);      

        if(forgeType == 1) {
          delete forgePathMapTwoGen1Tokens[forgePathId];    
        } else if(forgeType == 2) {
          delete forgePathMapTwoERC721Addresses[forgePathId];    
        } else if(forgeType == 3) {
          delete forgePathMapERC721AddressWithGen1Token[forgePathId];    
        } else if(forgeType == 4) {
          delete forgePathMapTwoERC1155Tokens[forgePathId];    
        } else if(forgeType == 5) {
          delete forgePathMapERC1155WithGen1Token[forgePathId];     
        } else if(forgeType == 6) {
          delete forgePathMapERC1155WithERC721Address[forgePathId];    
        } else {
          revert("Non-existent forge type");
        }
    }    

    function registerForgePathTwoGen1Tokens(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem, 
      uint256 material1, 
      uint256 material2,       
      bool burnMaterial1,       
      bool burnMaterial2) 
      external {
        registerForgePathCommon(pathName, 1, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);             
        
        forgePathMapTwoGen1Tokens[forgePathId].material1 = material1;
        forgePathMapTwoGen1Tokens[forgePathId].material2 = material2;
        forgePathMapTwoGen1Tokens[forgePathId].burnMaterial1 = burnMaterial1;
        forgePathMapTwoGen1Tokens[forgePathId].burnMaterial2 = burnMaterial2;        
    }        

    function getForgePathDetailsTwoGen1Tokens(uint256 pathId) external view returns (uint256, uint256, bool, bool) {              
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataTwoGen1Tokens memory forgePathData = forgePathMapTwoGen1Tokens[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2,
        forgePathData.burnMaterial1,
        forgePathData.burnMaterial2        
      );
    }    

    function registerForgePathTwoERC721Addresses(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem, 
      address material1, 
      address material2) 
      external {
        registerForgePathCommon(pathName, 2, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);             
        
        forgePathMapTwoERC721Addresses[forgePathId].material1 = material1;
        forgePathMapTwoERC721Addresses[forgePathId].material2 = material2;
    }        

    function getForgePathDetailsTwoERC721Addresses(uint256 pathId) external view returns (address, address) {
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataTwoERC721Addresses memory forgePathData = forgePathMapTwoERC721Addresses[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2
      );
    }

    function registerForgePathERC721AddressWithGen1Token(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem,
      address material1, 
      uint256 material2,             
      bool burnMaterial2) 
      external {
        registerForgePathCommon(pathName, 3, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);

        forgePathMapERC721AddressWithGen1Token[forgePathId].material1 = material1;
        forgePathMapERC721AddressWithGen1Token[forgePathId].material2 = material2;
        forgePathMapERC721AddressWithGen1Token[forgePathId].burnMaterial2 = burnMaterial2;
    }    

    function getForgePathDetailsERC721AddressWithGen1Token(uint256 pathId) external view returns (address, uint256, bool) {
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataERC721AddressWithGen1Token memory forgePathData = forgePathMapERC721AddressWithGen1Token[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2,
        forgePathData.burnMaterial2
      );
    }

    function registerForgePathTwoERC1155Tokens(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem, 
      uint256 material1, 
      uint256 material2,       
      bool meltMaterial1, 
      bool meltMaterial2, 
      bool material1IsNonFungible, 
      bool material2IsNonFungible) 
      external {
        registerForgePathCommon(pathName, 4, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);                

        forgePathMapTwoERC1155Tokens[forgePathId].material1 = material1;
        forgePathMapTwoERC1155Tokens[forgePathId].material2 = material2;
        forgePathMapTwoERC1155Tokens[forgePathId].meltMaterial1 = meltMaterial1;
        forgePathMapTwoERC1155Tokens[forgePathId].meltMaterial2 = meltMaterial2;
        forgePathMapTwoERC1155Tokens[forgePathId].material1IsNonFungible = material1IsNonFungible;
        forgePathMapTwoERC1155Tokens[forgePathId].material2IsNonFungible = material2IsNonFungible;
    }  

    function getForgePathDetailsTwoERC1155Tokens(uint256 pathId) external view returns (uint256, uint256, bool, bool, bool, bool) {
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataTwoERC1155Tokens memory forgePathData = forgePathMapTwoERC1155Tokens[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2,
        forgePathData.meltMaterial1,
        forgePathData.meltMaterial2,
        forgePathData.material1IsNonFungible,
        forgePathData.material2IsNonFungible
      );
    }

    function registerForgePathERC1155WithGen1Token(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem, 
      uint256 material1, 
      uint256 material2,       
      bool meltMaterial1, 
      bool burnMaterial2,
      bool material1IsNonFungible) 
      external {
        registerForgePathCommon(pathName, 5, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);             

        forgePathMapERC1155WithGen1Token[forgePathId].material1 = material1;
        forgePathMapERC1155WithGen1Token[forgePathId].material2 = material2;
        forgePathMapERC1155WithGen1Token[forgePathId].meltMaterial1 = meltMaterial1;
        forgePathMapERC1155WithGen1Token[forgePathId].burnMaterial2 = burnMaterial2;
        forgePathMapERC1155WithGen1Token[forgePathId].material1IsNonFungible = material1IsNonFungible;        
    }        

    function getForgePathDetailsERC1155WithGen1Token(uint256 pathId) external view returns (uint256, uint256, bool, bool, bool) {
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataERC1155WithGen1Token memory forgePathData = forgePathMapERC1155WithGen1Token[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2,
        forgePathData.meltMaterial1,
        forgePathData.burnMaterial2,
        forgePathData.material1IsNonFungible
      );
    }

    function registerForgePathERC1155WithERC721Address(
      string calldata pathName,
      uint256 weiCost,
      uint256 elementeumCost,
      uint256 forgedItem, 
      uint256 material1, 
      address material2, 
      bool meltMaterial1, 
      bool material1IsNonFungible) 
      external {
        registerForgePathCommon(pathName, 6, weiCost, elementeumCost, forgedItem);
        uint256 forgePathId = getForgePathId(pathName);            

        forgePathMapERC1155WithERC721Address[forgePathId].material1 = material1;
        forgePathMapERC1155WithERC721Address[forgePathId].material2 = material2;
        forgePathMapERC1155WithERC721Address[forgePathId].meltMaterial1 = meltMaterial1;
        forgePathMapERC1155WithERC721Address[forgePathId].material1IsNonFungible = material1IsNonFungible;
    }        

    function getForgePathDetailsERC1155WithERC721Address(uint256 pathId) external view returns (uint256, address, bool, bool) {
      require(_hasPathDefinition(pathId), "path not defined");
      ForgePathDataERC1155WithERC721Address memory forgePathData = forgePathMapERC1155WithERC721Address[pathId];
      return 
      (
        forgePathData.material1,
        forgePathData.material2,
        forgePathData.meltMaterial1,
        forgePathData.material1IsNonFungible
      );
    }
}