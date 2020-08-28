// File: contracts/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/utility/Owned.sol

pragma solidity 0.4.26;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      * 
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      * 
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts/utility/Utils.sol

pragma solidity 0.4.26;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    /**
      * constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

// File: contracts/utility/interfaces/IContractRegistry.sol

pragma solidity 0.4.26;

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}

// File: contracts/utility/ContractRegistryClient.sol

pragma solidity 0.4.26;




/**
  * @dev Base contract for ContractRegistry clients
*/
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant NON_STANDARD_TOKEN_REGISTRY = "NonStandardTokenRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 internal constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";
    bytes32 internal constant BANCOR_CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
    bool public adminOnly;                  // only an administrator can update the contract-registry

    /**
      * @dev verifies that the caller is mapped to the given contract name
      * 
      * @param _contractName    contract name
    */
    modifier only(bytes32 _contractName) {
        require(msg.sender == addressOf(_contractName));
        _;
    }

    /**
      * @dev initializes a new ContractRegistryClient instance
      * 
      * @param  _registry   address of a contract-registry contract
    */
    constructor(IContractRegistry _registry) internal validAddress(_registry) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
      * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(!adminOnly || isAdmin());

        // get the new contract-registry
        address newRegistry = addressOf(CONTRACT_REGISTRY);

        // verify that the new contract-registry is different and not zero
        require(newRegistry != address(registry) && newRegistry != address(0));

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(IContractRegistry(newRegistry).addressOf(CONTRACT_REGISTRY) != address(0));

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = IContractRegistry(newRegistry);
    }

    /**
      * @dev restores the previous contract-registry
    */
    function restoreRegistry() public {
        // verify that this function is permitted
        require(isAdmin());

        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
      * @dev restricts the permission to update the contract-registry
      * 
      * @param _adminOnly    indicates whether or not permission is restricted to administrator only
    */
    function restrictRegistryUpdate(bool _adminOnly) public {
        // verify that this function is permitted
        require(adminOnly != _adminOnly && isAdmin());

        // change the permission to update the contract-registry
        adminOnly = _adminOnly;
    }

    /**
      * @dev returns whether or not the caller is an administrator
     */
    function isAdmin() internal view returns (bool) {
        return msg.sender == owner;
    }

    /**
      * @dev returns the address associated with the given contract name
      * 
      * @param _contractName    contract name
      * 
      * @return contract address
    */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: contracts/converter/interfaces/IBancorConverterRegistryData.sol

pragma solidity 0.4.26;

interface IBancorConverterRegistryData {
    function addSmartToken(address _smartToken) external;
    function removeSmartToken(address _smartToken) external;
    function addLiquidityPool(address _liquidityPool) external;
    function removeLiquidityPool(address _liquidityPool) external;
    function addConvertibleToken(address _convertibleToken, address _smartToken) external;
    function removeConvertibleToken(address _convertibleToken, address _smartToken) external;
    function getSmartTokenCount() external view returns (uint);
    function getSmartTokens() external view returns (address[]);
    function getSmartToken(uint _index) external view returns (address);
    function isSmartToken(address _value) external view returns (bool);
    function getLiquidityPoolCount() external view returns (uint);
    function getLiquidityPools() external view returns (address[]);
    function getLiquidityPool(uint _index) external view returns (address);
    function isLiquidityPool(address _value) external view returns (bool);
    function getConvertibleTokenCount() external view returns (uint);
    function getConvertibleTokens() external view returns (address[]);
    function getConvertibleToken(uint _index) external view returns (address);
    function isConvertibleToken(address _value) external view returns (bool);
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint);
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[]);
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address);
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool);
}

// File: contracts/converter/BancorConverterRegistryData.sol

pragma solidity 0.4.26;



/*
 *  The BancorConverterRegistryData contract is an integral part of the Bancor converter registry
 *  as it serves as the database contract that holds all registry data.
 *
 *  The registry is separated into two different contracts for upgradability - the data contract
 *  is harder to upgrade as it requires migrating all registry data into a new contract, while
 *  the registry contract itself can be easily upgraded.
 *
 *  For that same reason, the data contract is simple and contains no logic beyond the basic data
 *  access utilities that it exposes.
*/
contract BancorConverterRegistryData is IBancorConverterRegistryData, ContractRegistryClient {
    struct Item {
        bool valid;
        uint index;
    }

    struct Items {
        address[] array;
        mapping(address => Item) table;
    }

    struct List {
        uint index;
        Items items;
    }

    struct Lists {
        address[] array;
        mapping(address => List) table;
    }

    Items smartTokens;
    Items liquidityPools;
    Lists convertibleTokens;

    /**
      * @dev initializes a new BancorConverterRegistryData instance
      * 
      * @param _registry address of a contract registry contract
    */
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
    }

    /**
      * @dev adds a smart token
      * 
      * @param _smartToken smart token
    */
    function addSmartToken(address _smartToken) external only(BANCOR_CONVERTER_REGISTRY) {
        addItem(smartTokens, _smartToken);
    }

    /**
      * @dev removes a smart token
      * 
      * @param _smartToken smart token
    */
    function removeSmartToken(address _smartToken) external only(BANCOR_CONVERTER_REGISTRY) {
        removeItem(smartTokens, _smartToken);
    }

    /**
      * @dev adds a liquidity pool
      * 
      * @param _liquidityPool liquidity pool
    */
    function addLiquidityPool(address _liquidityPool) external only(BANCOR_CONVERTER_REGISTRY) {
        addItem(liquidityPools, _liquidityPool);
    }

    /**
      * @dev removes a liquidity pool
      * 
      * @param _liquidityPool liquidity pool
    */
    function removeLiquidityPool(address _liquidityPool) external only(BANCOR_CONVERTER_REGISTRY) {
        removeItem(liquidityPools, _liquidityPool);
    }

    /**
      * @dev adds a convertible token
      * 
      * @param _convertibleToken convertible token
      * @param _smartToken associated smart token
    */
    function addConvertibleToken(address _convertibleToken, address _smartToken) external only(BANCOR_CONVERTER_REGISTRY) {
        List storage list = convertibleTokens.table[_convertibleToken];
        if (list.items.array.length == 0) {
            list.index = convertibleTokens.array.push(_convertibleToken) - 1;
        }
        addItem(list.items, _smartToken);
    }

    /**
      * @dev removes a convertible token
      * 
      * @param _convertibleToken convertible token
      * @param _smartToken associated smart token
    */
    function removeConvertibleToken(address _convertibleToken, address _smartToken) external only(BANCOR_CONVERTER_REGISTRY) {
        List storage list = convertibleTokens.table[_convertibleToken];
        removeItem(list.items, _smartToken);
        if (list.items.array.length == 0) {
            address lastConvertibleToken = convertibleTokens.array[convertibleTokens.array.length - 1];
            convertibleTokens.table[lastConvertibleToken].index = list.index;
            convertibleTokens.array[list.index] = lastConvertibleToken;
            convertibleTokens.array.length--;
            delete convertibleTokens.table[_convertibleToken];
        }
    }

    /**
      * @dev returns the number of smart tokens
      * 
      * @return number of smart tokens
    */
    function getSmartTokenCount() external view returns (uint) {
        return smartTokens.array.length;
    }

    /**
      * @dev returns the list of smart tokens
      * 
      * @return list of smart tokens
    */
    function getSmartTokens() external view returns (address[]) {
        return smartTokens.array;
    }

    /**
      * @dev returns the smart token at a given index
      * 
      * @param _index index
      * @return smart token at the given index
    */
    function getSmartToken(uint _index) external view returns (address) {
        return smartTokens.array[_index];
    }

    /**
      * @dev checks whether or not a given value is a smart token
      * 
      * @param _value value
      * @return true if the given value is a smart token, false if not
    */
    function isSmartToken(address _value) external view returns (bool) {
        return smartTokens.table[_value].valid;
    }

    /**
      * @dev returns the number of liquidity pools
      * 
      * @return number of liquidity pools
    */
    function getLiquidityPoolCount() external view returns (uint) {
        return liquidityPools.array.length;
    }

    /**
      * @dev returns the list of liquidity pools
      * 
      * @return list of liquidity pools
    */
    function getLiquidityPools() external view returns (address[]) {
        return liquidityPools.array;
    }

    /**
      * @dev returns the liquidity pool at a given index
      * 
      * @param _index index
      * @return liquidity pool at the given index
    */
    function getLiquidityPool(uint _index) external view returns (address) {
        return liquidityPools.array[_index];
    }

    /**
      * @dev checks whether or not a given value is a liquidity pool
      * 
      * @param _value value
      * @return true if the given value is a liquidity pool, false if not
    */
    function isLiquidityPool(address _value) external view returns (bool) {
        return liquidityPools.table[_value].valid;
    }

    /**
      * @dev returns the number of convertible tokens
      * 
      * @return number of convertible tokens
    */
    function getConvertibleTokenCount() external view returns (uint) {
        return convertibleTokens.array.length;
    }

    /**
      * @dev returns the list of convertible tokens
      * 
      * @return list of convertible tokens
    */
    function getConvertibleTokens() external view returns (address[]) {
        return convertibleTokens.array;
    }

    /**
      * @dev returns the convertible token at a given index
      * 
      * @param _index index
      * @return convertible token at the given index
    */
    function getConvertibleToken(uint _index) external view returns (address) {
        return convertibleTokens.array[_index];
    }

    /**
      * @dev checks whether or not a given value is a convertible token
      * 
      * @param _value value
      * @return true if the given value is a convertible token, false if not
    */
    function isConvertibleToken(address _value) external view returns (bool) {
        return convertibleTokens.table[_value].items.array.length > 0;
    }

    /**
      * @dev returns the number of smart tokens associated with a given convertible token
      * 
      * @param _convertibleToken convertible token
      * @return number of smart tokens associated with the given convertible token
    */
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint) {
        return convertibleTokens.table[_convertibleToken].items.array.length;
    }

    /**
      * @dev returns the list of smart tokens associated with a given convertible token
      * 
      * @param _convertibleToken convertible token
      * @return list of smart tokens associated with the given convertible token
    */
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[]) {
        return convertibleTokens.table[_convertibleToken].items.array;
    }

    /**
      * @dev returns the smart token associated with a given convertible token at a given index
      * 
      * @param _index index
      * @return smart token associated with the given convertible token at the given index
    */
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address) {
        return convertibleTokens.table[_convertibleToken].items.array[_index];
    }

    /**
      * @dev checks whether or not a given value is a smart token of a given convertible token
      * 
      * @param _convertibleToken convertible token
      * @param _value value
      * @return true if the given value is a smart token of the given convertible token, false it not
    */
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool) {
        return convertibleTokens.table[_convertibleToken].items.table[_value].valid;
    }

    /**
      * @dev adds an item to a list of items
      * 
      * @param _items list of items
      * @param _value item's value
    */
    function addItem(Items storage _items, address _value) internal {
        Item storage item = _items.table[_value];
        require(item.valid == false);

        item.index = _items.array.push(_value) - 1;
        item.valid = true;
    }

    /**
      * @dev removes an item from a list of items
      * 
      * @param _items list of items
      * @param _value item's value
    */
    function removeItem(Items storage _items, address _value) internal {
        Item storage item = _items.table[_value];
        require(item.valid == true);

        address lastValue = _items.array[_items.array.length - 1];
        _items.table[lastValue].index = item.index;
        _items.array[item.index] = lastValue;
        _items.array.length--;
        delete _items.table[_value];
    }
}