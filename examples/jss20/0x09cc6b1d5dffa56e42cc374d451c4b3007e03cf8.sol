// File: @digix/cacp-contracts/contracts/ACOwned.sol

pragma solidity ^0.4.19;

/// @title Owner based access control
/// @author DigixGlobal

contract ACOwned {

  address public owner;
  address public new_owner;
  bool is_ac_owned_init;

  /// @dev Modifier to check if msg.sender is the contract owner
  modifier if_owner() {
    require(is_owner());
    _;
  }

  function init_ac_owned()
           internal
           returns (bool _success)
  {
    if (is_ac_owned_init == false) {
      owner = msg.sender;
      is_ac_owned_init = true;
    }
    _success = true;
  }

  function is_owner()
           private
           constant
           returns (bool _is_owner)
  {
    _is_owner = (msg.sender == owner);
  }

  function change_owner(address _new_owner)
           if_owner()
           public
           returns (bool _success)
  {
    new_owner = _new_owner;
    _success = true;
  }

  function claim_ownership()
           public
           returns (bool _success)
  {
    require(msg.sender == new_owner);
    owner = new_owner;
    _success = true;
  }

}

// File: @digix/cacp-contracts/contracts/ACGroups.sol

pragma solidity ^0.4.19;


/// @title Owner based access control
/// @author DigixGlobal

contract ACGroups is ACOwned {

  bool is_ac_groups_init = false;

  struct Group {
    mapping(address => bool) members;
  }

  mapping (bytes32 => Group) groups;

  modifier if_group(bytes32 _group_name) {
    require(groups[_group_name].members[msg.sender]);
    _;
  }

  function init_ac_groups()
           internal
           returns (bool _success)
  {
    if(is_ac_owned_init == false) {
      init_ac_owned();
    }
    if(is_ac_groups_init == false) {
      groups["admins"].members[msg.sender] = true;
      is_ac_groups_init = true;
    }
    _success = true;
  }

  function register_admin(address _newadmin)
           if_owner
           public
           returns (bool _success)
  {
    groups["admins"].members[_newadmin] = true;
    _success = true;
  }

  function unregister_admin(address _oldadmin)
           if_owner
           public
           returns (bool _success)
  {
    groups["admins"].members[_oldadmin] = false;
    _success = true;
  }

  function add_user_to_group(bytes32 _group, address _user)
           if_group("admins")
           public
           returns (bool _success)
  {
    require(_group != "admins");
    groups[_group].members[_user] = true;
    _success = true;
  }

  function delete_user_from_group(bytes32 _group, address _user)
           if_group("admins")
           public
           returns (bool _success)
  {
    require(_group != "admins");
    groups[_group].members[_user] = false;
    _success = true;
  }

  function is_group_member_of(bytes32 _group, address _user)
           public
           constant
           returns (bool _ismember)
  {
    _ismember = groups[_group].members[_user];
  }

  function claim_ownership()
           public
           returns (bool _success)
  {
    // revoke admins role of old owner, add new owner to admins
    groups["admins"].members[owner] = false;
    groups["admins"].members[new_owner] = true;
    _success = super.claim_ownership();
  }
}

// File: @digix/cacp-contracts/contracts/Constants.sol

pragma solidity ^0.4.19;

/// @title Some useful constants
/// @author DigixGlobal

contract Constants {
  address constant NULL_ADDRESS = address(0x0);
  uint256 constant ZERO = uint256(0);
  bytes32 constant EMPTY = bytes32(0x0);
}

// File: @digix/cacp-contracts/contracts/ContractResolver.sol

pragma solidity ^0.4.19;



/// @title Contract Name Registry
/// @author DigixGlobal

contract ContractResolver is ACGroups, Constants {

  mapping (bytes32 => address) contracts;
  event RegisterEvent(bytes32 indexed _contract_name,
                      address indexed _contract_address);
  event UnRegisterEvent(bytes32 indexed _contract_name);
  bool public locked;
  bool public time_locked;
  uint public grace_period;

  modifier unless_registered(bytes32 _key) {
    require(contracts[_key] == NULL_ADDRESS);
    _;
  }

  modifier if_owner_origin() {
    require(tx.origin == owner);
    _;
  }

  /// Function modifier to check if msg.sender corresponds to the resolved address of a given key
  /// @param _contract The resolver key
  modifier if_sender_is(bytes32 _contract) {
    require(msg.sender == get_contract(_contract));
    _;
  }

  modifier locked_after_period() {
    if (time_locked == false) {
      _;
    } else {
      require(grace_period >= now);
      _;
    }
  }

  modifier if_not_locked() {
    require(locked == false);
    _;
  }

  /// @dev ContractResolver constructor will perform the following: 1. Set msg.sender as the contract owner.  2. Adds msg.sender to the default groups 'admins' and 'nsadmins'
  function ContractResolver() public
  {
    require(init_ac_groups());
    groups["nsadmins"].members[owner] = true;
    locked = false;
  }

  /// TODO: this function can basically do everything register_contract can do (except for emitting an event). Maybe we should require that this function can only be called by a contract?
  /// @dev Called at contract initialization
  /// @param _key bytestring for CACP name
  /// @param _contract_address The address of the contract to be registered
  /// @return _success if the operation is successful
  function init_register_contract(bytes32 _key, address _contract_address)
           if_owner_origin()
           if_not_locked()
           unless_registered(_key)
           locked_after_period()
           public
           returns (bool _success)
  {
    contracts[_key] = _contract_address;
    _success = true;
  }

  /// @dev Lock the resolver from any further modifications.  This can only be called from an account that is part of the nsadmins group
  /// @return _success if the operation is successful
  function lock_resolver()
           if_group("nsadmins")
           public
           returns (bool _success)
  {
    locked = true;
    _success = true;
  }

  /// @dev Unlock the resolver to allow further modifications.  This can only be called from an account that is part of the nsadmins group
  /// @return _success if the operation is successful
  function unlock_resolver()
           if_group("nsadmins")
           public
           returns (bool _success)
  {
     locked = false;
     _success = true;
  }

  /// @dev Enable time locking. This is potentially dangerous and must be from the owner
  /// @param _grace_period the unix timestamp when the resolver is locked forever
  function enable_time_locking(uint _grace_period)
           if_owner()
           locked_after_period()
           public
           returns (bool _success)
  {
    grace_period = _grace_period;
    time_locked = true;
    _success = true;
  }

  /// @dev Register a contract.  This can only be called from an account that is part of the nsadmins group
  /// @param _key the bytestring of the contract name
  /// @param _contract the address of the contract
  /// @return _success if the operation is successful
  function register_contract(bytes32 _key, address _contract)
           if_group("nsadmins")
           if_owner_origin()
           if_not_locked()
           locked_after_period()
           unless_registered(_key)
           public
           returns (bool _success)
  {
    contracts[_key] = _contract;
    RegisterEvent(_key, _contract);
    _success = true;
  }

  /// @dev Unregister a contract.  This can only be called from the contract with the key itself, which should be destroyed in the process
  /// this must also be originated from the owner of this ContractResolver as well.
  /// @param _key the bytestring of the contract name
  /// @return _success if the operation is successful
  function unregister_contract(bytes32 _key)
           locked_after_period()
           if_owner_origin()
           if_not_locked()
           if_sender_is(_key)
           public
           returns (bool _success)
  {
    delete contracts[_key];
    UnRegisterEvent(_key);
    _success = true;
  }

  /// @dev Get address of a contract
  /// @param _key the bytestring name of the contract to look up
  /// @return _contract the address of the contract
  function get_contract(bytes32 _key)
           public
           constant
           returns (address _contract)
  {
    require(contracts[_key] != NULL_ADDRESS);
    _contract = contracts[_key];
  }

  function claim_ownership()
           public
           returns (bool _success)
  {
    // revoke nsadmins role of old owner, add new owner to nsadmins
    groups["nsadmins"].members[owner] = false;
    groups["nsadmins"].members[new_owner] = true;
    _success = super.claim_ownership();
  }
}

// File: @digix/cacp-contracts/contracts/ResolverClient.sol

pragma solidity ^0.4.19;



/// @title Contract Resolver Interface
/// @author DigixGlobal

contract ResolverClient {

  /// The address of the resolver contract for this project
  address public resolver;
  bytes32 public key;

  /// Make our own address available to us as a constant
  address public CONTRACT_ADDRESS;

  /// Function modifier to check if msg.sender corresponds to the resolved address of a given key
  /// @param _contract The resolver key
  modifier if_sender_is(bytes32 _contract) {
    require(msg.sender == ContractResolver(resolver).get_contract(_contract));
    _;
  }

  /// Function modifier to check resolver's locking status.
  modifier unless_resolver_is_locked() {
    require(is_locked() == false);
    _;
  }

  /// @dev Initialize new contract
  /// @param _key the resolver key for this contract
  /// @return _success if the initialization is successful
  function init(bytes32 _key, address _resolver)
           internal
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(_resolver).locked();
    if (_is_locked == false) {
      CONTRACT_ADDRESS = address(this);
      resolver = _resolver;
      key = _key;
      require(ContractResolver(resolver).init_register_contract(key, CONTRACT_ADDRESS));
      _success = true;
    }  else {
      _success = false;
    }
  }

  /// @dev Destroy the contract and unregister self from the ContractResolver
  /// @dev Can only be called by the owner of ContractResolver
  function destroy()
           public
           returns (bool _success)
  {
    bool _is_locked = ContractResolver(resolver).locked();
    require(!_is_locked);

    address _owner_of_contract_resolver = ContractResolver(resolver).owner();
    require(msg.sender == _owner_of_contract_resolver);

    _success = ContractResolver(resolver).unregister_contract(key);
    require(_success);

    selfdestruct(_owner_of_contract_resolver);
  }

  /// @dev Check if resolver is locked
  /// @return _locked if the resolver is currently locked
  function is_locked()
           private
           constant
           returns (bool _locked)
  {
    _locked = ContractResolver(resolver).locked();
  }

  /// @dev Get the address of a contract
  /// @param _key the resolver key to look up
  /// @return _contract the address of the contract
  function get_contract(bytes32 _key)
           public
           constant
           returns (address _contract)
  {
    _contract = ContractResolver(resolver).get_contract(_key);
  }
}

// File: contracts/common/DigixConstants.sol

pragma solidity ^0.4.19;

contract DigixConstants {
    /// general constants
    uint256 constant SECONDS_IN_A_DAY = 24 * 60 * 60;

    /// asset events
    uint256 constant ASSET_EVENT_CREATED_VENDOR_ORDER = 1;
    uint256 constant ASSET_EVENT_CREATED_TRANSFER_ORDER = 2;
    uint256 constant ASSET_EVENT_CREATED_REPLACEMENT_ORDER = 3;
    uint256 constant ASSET_EVENT_FULFILLED_VENDOR_ORDER = 4;
    uint256 constant ASSET_EVENT_FULFILLED_TRANSFER_ORDER = 5;
    uint256 constant ASSET_EVENT_FULFILLED_REPLACEMENT_ORDER = 6;
    uint256 constant ASSET_EVENT_MINTED = 7;
    uint256 constant ASSET_EVENT_MINTED_REPLACEMENT = 8;
    uint256 constant ASSET_EVENT_RECASTED = 9;
    uint256 constant ASSET_EVENT_REDEEMED = 10;
    uint256 constant ASSET_EVENT_FAILED_AUDIT = 11;
    uint256 constant ASSET_EVENT_ADMIN_FAILED = 12;
    uint256 constant ASSET_EVENT_REMINTED = 13;

    /// roles
    uint256 constant ROLE_ZERO_ANYONE = 0;
    uint256 constant ROLE_ROOT = 1;
    uint256 constant ROLE_VENDOR = 2;
    uint256 constant ROLE_XFERAUTH = 3;
    uint256 constant ROLE_POPADMIN = 4;
    uint256 constant ROLE_CUSTODIAN = 5;
    uint256 constant ROLE_AUDITOR = 6;
    uint256 constant ROLE_MARKETPLACE_ADMIN = 7;
    uint256 constant ROLE_KYC_ADMIN = 8;
    uint256 constant ROLE_FEES_ADMIN = 9;
    uint256 constant ROLE_DOCS_UPLOADER = 10;
    uint256 constant ROLE_KYC_RECASTER = 11;
    uint256 constant ROLE_FEES_DISTRIBUTION_ADMIN = 12;

    /// states
    uint256 constant STATE_ZERO_UNDEFINED = 0;
    uint256 constant STATE_CREATED = 1;
    uint256 constant STATE_VENDOR_ORDER = 2;
    uint256 constant STATE_TRANSFER = 3;
    uint256 constant STATE_CUSTODIAN_DELIVERY = 4;
    uint256 constant STATE_MINTED = 5;
    uint256 constant STATE_AUDIT_FAILURE = 6;
    uint256 constant STATE_REPLACEMENT_ORDER = 7;
    uint256 constant STATE_REPLACEMENT_DELIVERY = 8;
    uint256 constant STATE_RECASTED = 9;
    uint256 constant STATE_REDEEMED = 10;
    uint256 constant STATE_ADMIN_FAILURE = 11;



    /// interactive contracts
    bytes32 constant CONTRACT_INTERACTIVE_ASSETS_EXPLORER = "i:asset:explorer";
    bytes32 constant CONTRACT_INTERACTIVE_DIGIX_DIRECTORY = "i:directory";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE = "i:mp";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN = "i:mpadmin";
    bytes32 constant CONTRACT_INTERACTIVE_POPADMIN = "i:popadmin";
    bytes32 constant CONTRACT_INTERACTIVE_PRODUCTS_LIST = "i:products";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN = "i:token";
    bytes32 constant CONTRACT_INTERACTIVE_BULK_WRAPPER = "i:bulk-wrapper";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN_CONFIG = "i:token:config";
    bytes32 constant CONTRACT_INTERACTIVE_TOKEN_INFORMATION = "i:token:information";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_INFORMATION = "i:mp:information";
    bytes32 constant CONTRACT_INTERACTIVE_IDENTITY = "i:identity";


    /// controller contracts
    bytes32 constant CONTRACT_CONTROLLER_ASSETS = "c:asset";
    bytes32 constant CONTRACT_CONTROLLER_ASSETS_RECAST = "c:asset:recast";
    bytes32 constant CONTRACT_CONTROLLER_ASSETS_EXPLORER = "c:explorer";
    bytes32 constant CONTRACT_CONTROLLER_DIGIX_DIRECTORY = "c:directory";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE = "c:mp";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN = "c:mpadmin";
    bytes32 constant CONTRACT_CONTROLLER_PRODUCTS_LIST = "c:products";

    bytes32 constant CONTRACT_CONTROLLER_TOKEN_APPROVAL = "c:token:approval";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_CONFIG = "c:token:config";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_INFO = "c:token:info";
    bytes32 constant CONTRACT_CONTROLLER_TOKEN_TRANSFER = "c:token:transfer";

    bytes32 constant CONTRACT_CONTROLLER_JOB_ID = "c:jobid";
    bytes32 constant CONTRACT_CONTROLLER_IDENTITY = "c:identity";

    /// storage contracts
    bytes32 constant CONTRACT_STORAGE_ASSETS = "s:asset";
    bytes32 constant CONTRACT_STORAGE_ASSET_EVENTS = "s:asset:events";
    bytes32 constant CONTRACT_STORAGE_DIGIX_DIRECTORY = "s:directory";
    bytes32 constant CONTRACT_STORAGE_MARKETPLACE = "s:mp";
    bytes32 constant CONTRACT_STORAGE_PRODUCTS_LIST = "s:products";
    bytes32 constant CONTRACT_STORAGE_GOLD_TOKEN = "s:goldtoken";
    bytes32 constant CONTRACT_STORAGE_JOB_ID = "s:jobid";
    bytes32 constant CONTRACT_STORAGE_IDENTITY = "s:identity";

    /// service contracts
    bytes32 constant CONTRACT_SERVICE_TOKEN_DEMURRAGE = "sv:tdemurrage";
    bytes32 constant CONTRACT_SERVICE_MARKETPLACE = "sv:mp";
    bytes32 constant CONTRACT_SERVICE_DIRECTORY = "sv:directory";

    /// fees distributors
    bytes32 constant CONTRACT_DEMURRAGE_FEES_DISTRIBUTOR = "fees:distributor:demurrage";
    bytes32 constant CONTRACT_RECAST_FEES_DISTRIBUTOR = "fees:distributor:recast";
    bytes32 constant CONTRACT_TRANSFER_FEES_DISTRIBUTOR = "fees:distributor:transfer";

}

// File: contracts/common/DigixConstantsElectron.sol

pragma solidity ^0.4.19;

contract DigixConstantsElectron {
    uint256 constant ROLE_ELECTRON_MARKETPLACE_ADMIN = 13; // This role is for confirming the fiat purchases in Electron
    uint256 constant ROLE_ASSET_RECAST_SIGNER = 14; // This role is for signing KYC information during a recast operation

    /// storage contracts
    bytes32 constant CONTRACT_STORAGE_MARKETPLACE_ELECTRON = "s:mp:electron";
    bytes32 constant CONTRACT_STORAGE_ASSETS_ELECTRON = "s:assets:electron";
    bytes32 constant CONTRACT_SERVICE_VERIFICATION = "service:verification";
    bytes32 constant CONTRACT_CONTROLLER_ASSETS_ELECTRON = "c:assets:electron";
    bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN_ELECTRON = "c:mpadmin:electron";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ELECTRON = "i:mp:electron";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN_ELECTRON = "i:mpadmin:electron";
    bytes32 constant CONTRACT_INTERACTIVE_ASSETS_EXPLORER_ELECTRON = "i:assets:explorer:electron";

    uint256 constant TOKEN_INDEX_FIAT = 1;
    uint256 constant TOKEN_INDEX_ETHER = 2;
    uint256 constant TOKEN_INDEX_DAI = 3;

    uint256 constant MAX_INTEGER = uint256(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    uint256 constant DUMMY_NONCE = 123;
    /* bytes32 constant CONTRACT_CONTROLLER_MARKETPLACE_ADMIN_EXTRAS = "c:mpadmin:extras";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_V2 = "i:mp:v2";
    bytes32 constant CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN_EXTRAS = "i:mpadmin:extras"; */
}

// File: @digix/solidity-collections/contracts/lib/DoublyLinkedList.sol

pragma solidity ^0.4.19;

library DoublyLinkedList {

  struct Item {
    bytes32 item;
    uint256 previous_index;
    uint256 next_index;
  }

  struct Data {
    uint256 first_index;
    uint256 last_index;
    uint256 count;
    mapping(bytes32 => uint256) item_index;
    mapping(uint256 => bool) valid_indexes;
    Item[] collection;
  }

  struct IndexedUint {
    mapping(bytes32 => Data) data;
  }

  struct IndexedAddress {
    mapping(bytes32 => Data) data;
  }

  struct IndexedBytes {
    mapping(bytes32 => Data) data;
  }

  struct Address {
    Data data;
  }

  struct Bytes {
    Data data;
  }

  struct Uint {
    Data data;
  }

  uint256 constant NONE = uint256(0);
  bytes32 constant EMPTY_BYTES = bytes32(0x0);
  address constant NULL_ADDRESS = address(0x0);

  function find(Data storage self, bytes32 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    if ((self.item_index[_item] == NONE) && (self.count == NONE)) {
      _item_index = NONE;
    } else {
      _item_index = self.item_index[_item];
    }
  }

  function get(Data storage self, uint256 _item_index)
           public
           constant
           returns (bytes32 _item)
  {
    if (self.valid_indexes[_item_index] == true) {
      _item = self.collection[_item_index - 1].item;
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function append(Data storage self, bytes32 _data)
           internal
           returns (bool _success)
  {
    if (find(self, _data) != NONE || _data == bytes32("")) { // rejects addition of empty values
      _success = false;
    } else {
      uint256 _index = uint256(self.collection.push(Item({item: _data, previous_index: self.last_index, next_index: NONE})));
      if (self.last_index == NONE) {
        if ((self.first_index != NONE) || (self.count != NONE)) {
          revert();
        } else {
          self.first_index = self.last_index = _index;
          self.count = 1;
        }
      } else {
        self.collection[self.last_index - 1].next_index = _index;
        self.last_index = _index;
        self.count++;
      }
      self.valid_indexes[_index] = true;
      self.item_index[_data] = _index;
      _success = true;
    }
  }

  function remove(Data storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    if (self.valid_indexes[_index] == true) {
      Item memory item = self.collection[_index - 1];
      if (item.previous_index == NONE) {
        self.first_index = item.next_index;
      } else {
        self.collection[item.previous_index - 1].next_index = item.next_index;
      }

      if (item.next_index == NONE) {
        self.last_index = item.previous_index;
      } else {
        self.collection[item.next_index - 1].previous_index = item.previous_index;
      }
      delete self.collection[_index - 1];
      self.valid_indexes[_index] = false;
      delete self.item_index[item.item];
      self.count--;
      _success = true;
    } else {
      _success = false;
    }
  }

  function remove_item(Data storage self, bytes32 _item)
           internal
           returns (bool _success)
  {
    uint256 _item_index = find(self, _item);
    if (_item_index != NONE) {
      require(remove(self, _item_index));
      _success = true;
    } else {
      _success = false;
    }
    return _success;
  }

  function total(Data storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = self.count;
  }

  function start(Data storage self)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = self.first_index;
    return _item_index;
  }

  function start_item(Data storage self)
           public
           constant
           returns (bytes32 _item)
  {
    uint256 _item_index = start(self);
    if (_item_index != NONE) {
      _item = get(self, _item_index);
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function end(Data storage self)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = self.last_index;
    return _item_index;
  }

  function end_item(Data storage self)
           public
           constant
           returns (bytes32 _item)
  {
    uint256 _item_index = end(self);
    if (_item_index != NONE) {
      _item = get(self, _item_index);
    } else {
      _item = EMPTY_BYTES;
    }
  }

  function valid(Data storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = self.valid_indexes[_item_index];
    //_yes = ((_item_index - 1) < self.collection.length);
  }

  function valid_item(Data storage self, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    uint256 _item_index = self.item_index[_item];
    _yes = self.valid_indexes[_item_index];
  }

  function previous(Data storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    if (self.valid_indexes[_current_index] == true) {
      _previous_index = self.collection[_current_index - 1].previous_index;
    } else {
      _previous_index = NONE;
    }
  }

  function previous_item(Data storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    uint256 _current_index = find(self, _current_item);
    if (_current_index != NONE) {
      uint256 _previous_index = previous(self, _current_index);
      _previous_item = get(self, _previous_index);
    } else {
      _previous_item = EMPTY_BYTES;
    }
  }

  function next(Data storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    if (self.valid_indexes[_current_index] == true) {
      _next_index = self.collection[_current_index - 1].next_index;
    } else {
      _next_index = NONE;
    }
  }

  function next_item(Data storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    uint256 _current_index = find(self, _current_item);
    if (_current_index != NONE) {
      uint256 _next_index = next(self, _current_index);
      _next_item = get(self, _next_index);
    } else {
      _next_item = EMPTY_BYTES;
    }
  }

  function find(Uint storage self, uint256 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, bytes32(_item));
  }

  function get(Uint storage self, uint256 _item_index)
           public
           constant
           returns (uint256 _item)
  {
    _item = uint256(get(self.data, _item_index));
  }


  function append(Uint storage self, uint256 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, bytes32(_data));
  }

  function remove(Uint storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }

  function remove_item(Uint storage self, uint256 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, bytes32(_item));
  }

  function total(Uint storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Uint storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Uint storage self)
           public
           constant
           returns (uint256 _start_item)
  {
    _start_item = uint256(start_item(self.data));
  }


  function end(Uint storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Uint storage self)
           public
           constant
           returns (uint256 _end_item)
  {
    _end_item = uint256(end_item(self.data));
  }

  function valid(Uint storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Uint storage self, uint256 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, bytes32(_item));
  }

  function previous(Uint storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Uint storage self, uint256 _current_item)
           public
           constant
           returns (uint256 _previous_item)
  {
    _previous_item = uint256(previous_item(self.data, bytes32(_current_item)));
  }

  function next(Uint storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Uint storage self, uint256 _current_item)
           public
           constant
           returns (uint256 _next_item)
  {
    _next_item = uint256(next_item(self.data, bytes32(_current_item)));
  }

  function find(Address storage self, address _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, bytes32(_item));
  }

  function get(Address storage self, uint256 _item_index)
           public
           constant
           returns (address _item)
  {
    _item = address(get(self.data, _item_index));
  }


  function find(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data[_collection_index], bytes32(_item));
  }

  function get(IndexedUint storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (uint256 _item)
  {
    _item = uint256(get(self.data[_collection_index], _item_index));
  }


  function append(IndexedUint storage self, bytes32 _collection_index, uint256 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedUint storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }

  function remove_item(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _start_item)
  {
    _start_item = uint256(start_item(self.data[_collection_index]));
  }


  function end(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedUint storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _end_item)
  {
    _end_item = uint256(end_item(self.data[_collection_index]));
  }

  function valid(IndexedUint storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedUint storage self, bytes32 _collection_index, uint256 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedUint storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedUint storage self, bytes32 _collection_index, uint256 _current_item)
           public
           constant
           returns (uint256 _previous_item)
  {
    _previous_item = uint256(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedUint storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedUint storage self, bytes32 _collection_index, uint256 _current_item)
           public
           constant
           returns (uint256 _next_item)
  {
    _next_item = uint256(next_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function append(Address storage self, address _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, bytes32(_data));
  }

  function remove(Address storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }


  function remove_item(Address storage self, address _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, bytes32(_item));
  }

  function total(Address storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Address storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Address storage self)
           public
           constant
           returns (address _start_item)
  {
    _start_item = address(start_item(self.data));
  }


  function end(Address storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Address storage self)
           public
           constant
           returns (address _end_item)
  {
    _end_item = address(end_item(self.data));
  }

  function valid(Address storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Address storage self, address _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, bytes32(_item));
  }

  function previous(Address storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Address storage self, address _current_item)
           public
           constant
           returns (address _previous_item)
  {
    _previous_item = address(previous_item(self.data, bytes32(_current_item)));
  }

  function next(Address storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Address storage self, address _current_item)
           public
           constant
           returns (address _next_item)
  {
    _next_item = address(next_item(self.data, bytes32(_current_item)));
  }

  function append(IndexedAddress storage self, bytes32 _collection_index, address _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedAddress storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }


  function remove_item(IndexedAddress storage self, bytes32 _collection_index, address _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (address _start_item)
  {
    _start_item = address(start_item(self.data[_collection_index]));
  }


  function end(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedAddress storage self, bytes32 _collection_index)
           public
           constant
           returns (address _end_item)
  {
    _end_item = address(end_item(self.data[_collection_index]));
  }

  function valid(IndexedAddress storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedAddress storage self, bytes32 _collection_index, address _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedAddress storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedAddress storage self, bytes32 _collection_index, address _current_item)
           public
           constant
           returns (address _previous_item)
  {
    _previous_item = address(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedAddress storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedAddress storage self, bytes32 _collection_index, address _current_item)
           public
           constant
           returns (address _next_item)
  {
    _next_item = address(next_item(self.data[_collection_index], bytes32(_current_item)));
  }


  function find(Bytes storage self, bytes32 _item)
           public
           constant
           returns (uint256 _item_index)
  {
    _item_index = find(self.data, _item);
  }

  function get(Bytes storage self, uint256 _item_index)
           public
           constant
           returns (bytes32 _item)
  {
    _item = get(self.data, _item_index);
  }


  function append(Bytes storage self, bytes32 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data, _data);
  }

  function remove(Bytes storage self, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data, _index);
  }


  function remove_item(Bytes storage self, bytes32 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data, _item);
  }

  function total(Bytes storage self)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data);
  }

  function start(Bytes storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data);
  }

  function start_item(Bytes storage self)
           public
           constant
           returns (bytes32 _start_item)
  {
    _start_item = start_item(self.data);
  }


  function end(Bytes storage self)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data);
  }

  function end_item(Bytes storage self)
           public
           constant
           returns (bytes32 _end_item)
  {
    _end_item = end_item(self.data);
  }

  function valid(Bytes storage self, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data, _item_index);
  }

  function valid_item(Bytes storage self, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data, _item);
  }

  function previous(Bytes storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data, _current_index);
  }

  function previous_item(Bytes storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    _previous_item = previous_item(self.data, _current_item);
  }

  function next(Bytes storage self, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data, _current_index);
  }

  function next_item(Bytes storage self, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    _next_item = next_item(self.data, _current_item);
  }

  function append(IndexedBytes storage self, bytes32 _collection_index, bytes32 _data)
           public
           returns (bool _success)
  {
    _success = append(self.data[_collection_index], bytes32(_data));
  }

  function remove(IndexedBytes storage self, bytes32 _collection_index, uint256 _index)
           internal
           returns (bool _success)
  {
    _success = remove(self.data[_collection_index], _index);
  }


  function remove_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _item)
           public
           returns (bool _success)
  {
    _success = remove_item(self.data[_collection_index], bytes32(_item));
  }

  function total(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = total(self.data[_collection_index]);
  }

  function start(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = start(self.data[_collection_index]);
  }

  function start_item(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (bytes32 _start_item)
  {
    _start_item = bytes32(start_item(self.data[_collection_index]));
  }


  function end(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (uint256 _index)
  {
    _index = end(self.data[_collection_index]);
  }

  function end_item(IndexedBytes storage self, bytes32 _collection_index)
           public
           constant
           returns (bytes32 _end_item)
  {
    _end_item = bytes32(end_item(self.data[_collection_index]));
  }

  function valid(IndexedBytes storage self, bytes32 _collection_index, uint256 _item_index)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid(self.data[_collection_index], _item_index);
  }

  function valid_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _item)
           public
           constant
           returns (bool _yes)
  {
    _yes = valid_item(self.data[_collection_index], bytes32(_item));
  }

  function previous(IndexedBytes storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _previous_index)
  {
    _previous_index = previous(self.data[_collection_index], _current_index);
  }

  function previous_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _current_item)
           public
           constant
           returns (bytes32 _previous_item)
  {
    _previous_item = bytes32(previous_item(self.data[_collection_index], bytes32(_current_item)));
  }

  function next(IndexedBytes storage self, bytes32 _collection_index, uint256 _current_index)
           public
           constant
           returns (uint256 _next_index)
  {
    _next_index = next(self.data[_collection_index], _current_index);
  }

  function next_item(IndexedBytes storage self, bytes32 _collection_index, bytes32 _current_item)
           public
           constant
           returns (bytes32 _next_item)
  {
    _next_item = bytes32(next_item(self.data[_collection_index], bytes32(_current_item)));
  }


}

// File: @digix/solidity-statemachine/contracts/lib/StateMachine.sol

pragma solidity ^0.4.19;


library StateMachine {

  using DoublyLinkedList for DoublyLinkedList.Bytes;

  struct System {
    mapping(bytes32 => Item) items;
    mapping(address => uint256) to_role;
    mapping(uint256 => mapping (uint256 => mapping(uint256 => bool))) access_control;
    mapping(uint256 => DoublyLinkedList.Bytes) lists_by_state;
    mapping(uint256 => bytes32) state_ids_to_name;
    mapping(uint256 => bytes32) role_ids_to_name;
    DoublyLinkedList.Bytes global_list;
    bytes32 seed;
  }

  struct Item {
    uint256 state;
  }

  function set_state_name(System storage _system, uint256 _state_id, bytes32 _state_name)
           internal
           returns (bool _success)
  {
    _system.state_ids_to_name[_state_id] = _state_name;
    _success = true;
  }

  function get_state_name(System storage _system, uint256 _state_id)
           internal
           constant
           returns (bytes32 _state_name)
  {
    if (_state_id == 0) {
      _state_name = bytes32("none");
    } else {
      _state_name = _system.state_ids_to_name[_state_id];
    }
  }

  function get_item_state_id(System storage _system, bytes32 _item)
           internal
           constant
           returns (uint256 _state_id)
  {
    _state_id = _system.items[_item].state;
  }

  function get_item_state_name(System storage _system, bytes32 _item)
           internal
           constant
           returns (bytes32 _state_name)
  {
    _state_name = get_state_name(_system, get_item_state_id(_system, _item));
  }

  function set_role_name(System storage _system, uint256 _role_id, bytes32 _role_name)
           internal
           returns (bool _success)
  {
    _system.role_ids_to_name[_role_id] = _role_name;
    _success = true;
  }

  function get_role_name(System storage _system, uint256 _role_id)
           internal
           constant
           returns (bytes32 _role_name)
  {
    if (_role_id == 0) {
      _role_name = bytes32("none");
    } else {
      _role_name = _system.role_ids_to_name[_role_id];
    }
  }

  function get_entity_role_id(System storage _system, address _entity)
           internal
           constant
           returns (uint256 _role_id)
  {
    _role_id = _system.to_role[_entity];
  }

  function set_role(System storage _system, address _entity, uint256 _role_id)
           internal
           returns (bool _success)
  {
    _system.to_role[_entity] = _role_id;
    _success = true;
  }

  function unset_role(System storage _system, address _entity)
           internal
           returns (bool _success)
  {
    if (_system.to_role[_entity] == 0) {
      _success = false;
    } else {
      delete _system.to_role[_entity];
      _success = true;
    }
  }

  function grant_access(System storage _system, uint256 _by_role, uint256 _from_state, uint256 _to_state)
           internal
           returns (bool _success)
  {
    if (_system.access_control[_by_role][_from_state][_to_state] == false) {
      _system.access_control[_by_role][_from_state][_to_state] = true;
      _success = true;
    } else {
      _success = false;
    }
  }

  function revoke_access(System storage _system, uint256 _by_role, uint256 _from_state, uint256 _to_state)
           internal
           returns (bool _success)
  {
    if(_system.access_control[_by_role][_from_state][_to_state] == true) {
      _system.access_control[_by_role][_from_state][_to_state] = false;
      _success = true;
    } else {
      _success = false;
    }
  }

  function init(System storage _system)
           internal
           returns (bool _success)
  {
    require(_system.seed == bytes32(0x0));
    _system.seed = bytes32(address(this));
    _success = true;
  }

  function get_new_identifier(System storage _system)
           internal
           returns (bytes32 _new_id)
  {
    require(_system.seed != bytes32(0x0));
    _system.seed = keccak256(_system.seed, now);
    _new_id = _system.seed;
  }

  function create_item(System storage _system, uint256 _by_role)
           internal
           returns (bool _success, bytes32 _item)
  {
    require(_system.seed != bytes32(0x0)); // system must be init-ed first, and hence seed must already have value
    if (_system.access_control[_by_role][0][1] == true) {
      _item = get_new_identifier(_system);
      _system.items[_item].state = 1;
      require(_system.global_list.append(_item));
      require(_system.lists_by_state[1].append(_item));
      _success = true;
    } else {
      _success = false;
      _item = bytes32(0x0);
    }
  }

  function change_item_state(System storage _system, uint256 _by_role, bytes32 _item, uint256 _to_state)
           internal
           returns (bool _success, uint256 _from_state, uint256 _new_state)
  {

    _from_state = _system.items[_item].state;

    bool _append_success;
    bool _remove_success;
    _new_state = _from_state;
    _success = false;

    if (_system.access_control[0][_from_state][_to_state] == true) {
      _by_role = 0;
    }

    if (_system.access_control[_by_role][_from_state][_to_state] == true) {
      _system.items[_item].state = _to_state;
      _append_success = _system.lists_by_state[_to_state].append(_item);
      _remove_success = _system.lists_by_state[_from_state].remove_item(_item);
      _new_state = _system.items[_item].state;
      _success = (_append_success && _remove_success);
    }
  }

  function total_in_state(System storage _system, uint256 _state_id)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = _system.lists_by_state[_state_id].total();
  }

  function total(System storage _system)
           public
           constant
           returns (uint256 _global_count)
  {
    _global_count = _system.global_list.total();
  }

  function get_first_in_global(System storage _system)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.global_list.start_item();
  }

  function get_last_in_global(System storage _system)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.global_list.end_item();
  }

  function get_next_from_in_global(System storage _system, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.global_list.next_item(_current_item);
  }

  function get_previous_from_in_global(System storage _system, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.global_list.previous_item(_current_item);
  }

  function get_first_in_state(System storage _system, uint256 _state_id)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.lists_by_state[_state_id].start_item();
  }

  function get_last_in_state(System storage _system, uint256 _state_id)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.lists_by_state[_state_id].end_item();
  }

  function get_next_from_in_state(System storage _system, uint256 _state_id, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.lists_by_state[_state_id].next_item(_current_item);
  }

  function get_previous_from_in_state(System storage _system, uint256 _state_id, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = _system.lists_by_state[_state_id].previous_item(_current_item);
  }

  function check_role_access(System storage _system, uint256 _role_id, uint256 _from_state, uint256 _to_state)
           public
           constant
           returns (bool _yes)
  {
    _yes = _system.access_control[_role_id][_from_state][_to_state];
  }
}

// File: @digix/solidity-collections/contracts/abstract/IndexedBytesIteratorStorage.sol

pragma solidity ^0.4.19;


/**
  @title Indexed Bytes Iterator Storage
  @author DigixGlobal Pte Ltd
  @notice This contract utilizes: [Doubly Linked List](/DoublyLinkedList)
*/
contract IndexedBytesIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.IndexedBytes;

  /**
    @notice Reads the first item from an Indexed Bytes Doubly Linked List
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_item":"The first item from the specified `_list`"}
  */
  function read_first_from_indexed_bytesarray(DoublyLinkedList.IndexedBytes storage _list, bytes32 _collection_index)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.start_item(_collection_index);
  }

  /**
    @notice Reads the last item from an Indexed Bytes Doubly Linked List
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_item":"The last item from the specified `_list`"}
  */
  function read_last_from_indexed_bytesarray(DoublyLinkedList.IndexedBytes storage _list, bytes32 _collection_index)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.end_item(_collection_index);
  }

  /**
    @notice Reads the next item from an Indexed Bytes Doubly Linked List
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @param _current_item The current item to be used as base line
    @return {"_item":"The next item from the specified `_current_item`"}
  */
  function read_next_from_indexed_bytesarray(DoublyLinkedList.IndexedBytes storage _list, bytes32 _collection_index, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.next_item(_collection_index, _current_item);
  }

  /**
    @notice Reads the previous item from an Indexed Bytes Doubly Linked List
    @param _list The source list
    @param _collection_index Collection Index
    @param _current_item The current item to be used as base line
    @return {"_item":"The previous item from the specified `_current_item`"}
  */
  function read_previous_from_indexed_bytesarray(DoublyLinkedList.IndexedBytes storage _list, bytes32 _collection_index, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.previous_item(_collection_index, _current_item);
  }

  /**
    @notice Reads the list of Indexed Bytes and returns length of the list
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_count":""}
  */
  function read_total_indexed_bytesarray(DoublyLinkedList.IndexedBytes storage _list, bytes32 _collection_index)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total(_collection_index);
  }

}

// File: @digix/solidity-collections/contracts/abstract/BytesIteratorStorage.sol

pragma solidity ^0.4.19;



/**
  @title Bytes Iterator Storage
  @author DigixGlobal Pte Ltd
*/
contract BytesIteratorStorage {

  // Initialize Doubly Linked List of Bytes
  using DoublyLinkedList for DoublyLinkedList.Bytes;

  /**
    @notice Reads the first item from the list of Bytes
    @param _list The source list
    @return {"_item": "The first item from the list"}
  */
  function read_first_from_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.start_item();
  }

  /**
    @notice Reads the last item from the list of Bytes
    @param _list The source list
    @return {"_item": "The last item from the list"}
  */
  function read_last_from_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.end_item();
  }

  /**
    @notice Reads the next item on the list of Bytes
    @param _list The source list
    @param _current_item The current item to be used as base line
    @return {"_item": "The next item from the list based on the specieid `_current_item`"}
    TODO: Need to verify what happens if the specified `_current_item` is the last item from the list
  */
  function read_next_from_bytesarray(DoublyLinkedList.Bytes storage _list, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.next_item(_current_item);
  }

  /**
    @notice Reads the previous item on the list of Bytes
    @param _list The source list
    @param _current_item The current item to be used as base line
    @return {"_item": "The previous item from the list based on the spcified `_current_item`"}
    TODO: Need to verify what happens if the specified `_current_item` is the first item from the list
  */
  function read_previous_from_bytesarray(DoublyLinkedList.Bytes storage _list, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _list.previous_item(_current_item);
  }

  /**
    @notice Reads the list of Bytes and returns the length of the list
    @param _list The source list
    @return {"count": "`uint256` The lenght of the list"}

  */
  function read_total_bytesarray(DoublyLinkedList.Bytes storage _list)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total();
  }

}

// File: contracts/storage/AssetsStorage.sol

pragma solidity ^0.4.19;







contract AssetsStorage is ResolverClient, IndexedBytesIteratorStorage, BytesIteratorStorage, DigixConstants {

  using StateMachine for StateMachine.System;
  using DoublyLinkedList for DoublyLinkedList.IndexedBytes;
  using DoublyLinkedList for DoublyLinkedList.Bytes;

  struct Item {
    uint256 product_id;
    uint256 ng_weight;
    uint256 effective_ng_weight;
    bytes32 serial;
    uint256 time_minted;
    uint256 redeem_deadline;
    address mint_target;
    address redeem_for;
    bytes32 replaced_by; // id of the item that replaces this item if it fails audit
    bytes32 replaces; // id of the item that this item replaces
  }

  struct System {
    StateMachine.System state_machine;
    DoublyLinkedList.Bytes global_audit_documents;
    DoublyLinkedList.IndexedBytes asset_documents;
    DoublyLinkedList.IndexedBytes user_recasts;
    mapping (bytes32 => Item) items_by_id;
    uint256 last_global_audit_time;
    uint256 redeem_period;              // Recaster has to redeem the asset within redeem_period days
    // last_asset_with_serial[serial_no] is the asset id of the latest asset that was added into the system with that serial_no
    // note that a gold bar with the same serial number can go through multiple cycles of minting and redeeming
    // and last_asset_with_serial records the asset id in the last cycle
    mapping (bytes32 => bytes32) last_asset_with_serial;
  }

  System system;

  function AssetsStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_ASSETS, _resolver));
    require(system.state_machine.init());
    system.redeem_period = 31; // default to 31 days

    // roles
    system.state_machine.set_role_name(ROLE_VENDOR, "vendor");
    system.state_machine.set_role_name(ROLE_XFERAUTH, "xferauth");
    system.state_machine.set_role_name(ROLE_POPADMIN, "popadmin");
    system.state_machine.set_role_name(ROLE_CUSTODIAN, "custodian");
    system.state_machine.set_role_name(ROLE_AUDITOR, "auditor");

    // state names
    system.state_machine.set_state_name(STATE_CREATED, "created");
    system.state_machine.set_state_name(STATE_VENDOR_ORDER, "vendor_order");
    system.state_machine.set_state_name(STATE_TRANSFER, "transfer");
    system.state_machine.set_state_name(STATE_CUSTODIAN_DELIVERY, "custodian_delivery");
    system.state_machine.set_state_name(STATE_MINTED, "minted");
    system.state_machine.set_state_name(STATE_AUDIT_FAILURE, "audit_failure");
    system.state_machine.set_state_name(STATE_REPLACEMENT_ORDER, "replacement_order");
    system.state_machine.set_state_name(STATE_REPLACEMENT_DELIVERY, "replacement_delivery");
    system.state_machine.set_state_name(STATE_RECASTED, "recasted");
    system.state_machine.set_state_name(STATE_REDEEMED, "redeemed");
    system.state_machine.set_state_name(STATE_ADMIN_FAILURE, "admin_failure");

    // popadmin: create an asset item
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_ZERO_UNDEFINED, STATE_CREATED);

    // popadmin: change a newly created asset to 'vendor_order'
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_CREATED, STATE_VENDOR_ORDER);

    // popadmin: change a newly created asset to 'transfer'
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_CREATED, STATE_TRANSFER);

    // vendor: vendor_order to custodian_delivery
    system.state_machine.grant_access(ROLE_VENDOR, STATE_VENDOR_ORDER, STATE_CUSTODIAN_DELIVERY);

    // xferauth: transfer to custodian_delivery
    system.state_machine.grant_access(ROLE_XFERAUTH, STATE_TRANSFER, STATE_CUSTODIAN_DELIVERY);

    // custodian: custodian_delivery to minted
    system.state_machine.grant_access(ROLE_CUSTODIAN, STATE_CUSTODIAN_DELIVERY, STATE_MINTED);

    // auditor: minted to audit_failure
    system.state_machine.grant_access(ROLE_AUDITOR, STATE_MINTED, STATE_AUDIT_FAILURE);

    // popadmin: created to replacement_order
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_CREATED, STATE_REPLACEMENT_ORDER);

    // vendor: replacement_order to replacement_delivery
    system.state_machine.grant_access(ROLE_VENDOR, STATE_REPLACEMENT_ORDER, STATE_REPLACEMENT_DELIVERY);

    // popadmin: vendor_order to admin_failure
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_VENDOR_ORDER, STATE_ADMIN_FAILURE);

    // popadmin: transfer to admin_failure
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_TRANSFER, STATE_ADMIN_FAILURE);

    // popadmin: custodian_delivery to admin_failure
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_CUSTODIAN_DELIVERY, STATE_ADMIN_FAILURE);

    // popadmin: replacement_order to admin_failure
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_REPLACEMENT_ORDER, STATE_ADMIN_FAILURE);

    // popadmin: replacement_delivery to admin_failure
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_REPLACEMENT_DELIVERY, STATE_ADMIN_FAILURE);

    // custodian: replacement_delivery to minted
    system.state_machine.grant_access(ROLE_CUSTODIAN, STATE_REPLACEMENT_DELIVERY, STATE_MINTED);

    // any: minted to recasted
    system.state_machine.grant_access(ROLE_ZERO_ANYONE, STATE_MINTED, STATE_RECASTED);

    // popadmin: recasted to redeemed
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_RECASTED, STATE_REDEEMED);

    // popadmin: recasted to minted
    system.state_machine.grant_access(ROLE_POPADMIN, STATE_RECASTED, STATE_MINTED);

    // kycrecaster: recasted to minted (only if reminted by recaster)
    system.state_machine.grant_access(ROLE_KYC_RECASTER, STATE_RECASTED, STATE_MINTED);
  }

  function read_asset_info(bytes32 _item)
           public
           constant
           returns (uint256 _product_id, uint256 _ng_weight, uint256 _effective_ng_weight,
                    bytes32 _serial, uint256 _state_id, uint256 _documents_count, uint256 _time_minted, uint256 _redeem_deadline)
  {
    _product_id = system.items_by_id[_item].product_id;
    _ng_weight = system.items_by_id[_item].ng_weight;
    _effective_ng_weight = system.items_by_id[_item].effective_ng_weight;
    _serial = system.items_by_id[_item].serial;
    _state_id = system.state_machine.get_item_state_id(_item);
    _documents_count = read_total_asset_documents(_item);
    _time_minted = system.items_by_id[_item].time_minted;
    _redeem_deadline = system.items_by_id[_item].redeem_deadline;
  }

  function read_last_asset_with_serial(bytes32 _serial)
           public
           constant
           returns (bytes32 _asset_id)
  {
    _asset_id = system.last_asset_with_serial[_serial];
  }

  function read_asset_state(bytes32 _item)
           public
           constant
           returns (uint256 _state_id)
  {
    _state_id = system.state_machine.get_item_state_id(_item);
  }

  function read_redeem_period()
           public
           constant
           returns (uint256 _redeem_period)
  {
    _redeem_period = system.redeem_period;
  }

  function read_asset_details(bytes32 _item)
           public
           constant
           returns (address _mint_target, address _redeem_for, bytes32 _replaced_by, bytes32 _replaces)
  {
    _mint_target = system.items_by_id[_item].mint_target;
    _redeem_for = system.items_by_id[_item].redeem_for;
    _replaced_by = system.items_by_id[_item].replaced_by;
    _replaces = system.items_by_id[_item].replaces;
  }

  function read_last_global_audit_time()
           public
           constant
           returns (uint256 _last_global_audit_time)
  {
    _last_global_audit_time = system.last_global_audit_time;
  }

  function read_state_name(uint256 _state_id)
           public
           constant
           returns (bytes32 _state_name)
  {
    _state_name = system.state_machine.get_state_name(_state_id);
  }

  function read_item_state_name(bytes32 _item)
           public
           constant
           returns (bytes32 _state_name)
  {
    _state_name = read_state_name(system.state_machine.get_item_state_id(_item));
  }

  function read_first_item_in_state(bytes32 _state_id)
           public
           constant
           returns (bytes32 _item)
  {
    _item = system.state_machine.get_first_in_state(uint256(_state_id));
  }

  function read_last_item_in_state(bytes32 _state_id)
           public
           constant
           returns (bytes32 _item)
  {
    _item = system.state_machine.get_last_in_state(uint256(_state_id));
  }

  function read_next_item_from_item_in_state(bytes32 _state_id, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = system.state_machine.get_next_from_in_state(uint256(_state_id), _current_item);
  }

  function read_previous_item_from_item_in_state(bytes32 _state_id, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = system.state_machine.get_previous_from_in_state(uint256(_state_id), _current_item);
  }

  function read_total_items_in_state(bytes32 _state_id)
           public
           constant
           returns (uint256 _total_items)
  {
    _total_items = system.state_machine.total_in_state(uint256(_state_id));
  }


  function read_total_asset_documents(bytes32 _item)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = read_total_indexed_bytesarray(system.asset_documents, _item);
  }

  function read_first_asset_document(bytes32 _item)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_first_from_indexed_bytesarray(system.asset_documents, _item);
  }

  function read_last_asset_document(bytes32 _item)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_last_from_indexed_bytesarray(system.asset_documents, _item);
  }

  function read_next_asset_document_from_document(bytes32 _item, bytes32 _current_document)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_next_from_indexed_bytesarray(system.asset_documents, _item, _current_document);
  }


  function read_previous_asset_document_from_document(bytes32 _item, bytes32 _current_document)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_previous_from_indexed_bytesarray(system.asset_documents, _item, _current_document);
  }

  function read_first_global_audit()
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_first_from_bytesarray(system.global_audit_documents);
  }

  function read_last_global_audit()
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_last_from_bytesarray(system.global_audit_documents);
  }

  function read_next_global_audit_from_audit(bytes32 _current_document)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_next_from_bytesarray(system.global_audit_documents, _current_document);
  }


  function read_previous_global_audit_from_audit(bytes32 _current_document)
           public
           constant
           returns (bytes32 _document)
  {
    _document = read_previous_from_bytesarray(system.global_audit_documents, _current_document);
  }

  function read_total_global_audits()
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = system.global_audit_documents.total();
  }

  function read_user_first_recast(bytes32 _user)
           public
           constant
           returns (bytes32 _item)
  {
    _item = read_first_from_indexed_bytesarray(system.user_recasts, _user);
  }

  function read_user_last_recast(bytes32 _user)
           public
           constant
           returns (bytes32 _item)
  {
    _item = read_last_from_indexed_bytesarray(system.user_recasts, _user);
  }

  function read_user_next_recast_from_item(bytes32 _user, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = read_next_from_indexed_bytesarray(system.user_recasts, _user, _current_item);
  }

  function read_user_previous_recast_from_item(bytes32 _user, bytes32 _current_item)
           public
           constant
           returns (bytes32 _item)
  {
    _item = read_previous_from_indexed_bytesarray(system.user_recasts, _user, _current_item);
  }

  function read_user_total_recasts(bytes32 _user)
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = read_total_indexed_bytesarray(system.user_recasts, _user);
  }

  function create_global_audit(bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    _success = system.global_audit_documents.append(_document);
    require(_success);
    system.last_global_audit_time = now;
  }

  /**
  @notice create a new asset item to the `vendor_order` state
  */
  function create_init_item(uint256 _role_id, uint256 _product_id, uint256 _ng_weight, uint256 _effective_ng_weight, address _mint_target)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, bytes32 _item)
  {
    (_success, _item) = system.state_machine.create_item(_role_id);
    require(_success);
    system.state_machine.change_item_state(_role_id, _item, STATE_VENDOR_ORDER);
    system.items_by_id[_item].product_id = _product_id;
    system.items_by_id[_item].ng_weight = _ng_weight;
    system.items_by_id[_item].effective_ng_weight = _effective_ng_weight;
    system.items_by_id[_item].mint_target = _mint_target;
  }

  /**
  @notice create a new asset item to be transfered in, set it to `transfer` state
  */
  function create_init_item_transfer(uint256 _role_id, uint256 _product_id, uint256 _ng_weight, uint256 _effective_ng_weight, address _mint_target)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, bytes32 _item)
  {
    (_success, _item) = system.state_machine.create_item(_role_id);
    require(_success);
    system.state_machine.change_item_state(_role_id, _item, STATE_TRANSFER);
    system.items_by_id[_item].product_id = _product_id;
    system.items_by_id[_item].ng_weight = _ng_weight;
    system.items_by_id[_item].effective_ng_weight = _effective_ng_weight;
    system.items_by_id[_item].mint_target = _mint_target;
  }

  function internal_check_duplicate_serial_when_fulfilling_order(bytes32 _item, bytes32 _serial)
           internal
  {
    bytes32 _last_asset_with_same_serial = system.last_asset_with_serial[_serial];
    if (_last_asset_with_same_serial != bytes32(0x0)) {
      uint256 _existing_asset_state_id = system.state_machine.get_item_state_id(_last_asset_with_same_serial);
      require(_existing_asset_state_id == STATE_ADMIN_FAILURE
        || _existing_asset_state_id == STATE_AUDIT_FAILURE
        || _existing_asset_state_id == STATE_REDEEMED);
    }
    system.last_asset_with_serial[_serial] = _item;
  }

  /**
  @notice Update an item from either `vendor_order` or `transfer` state to `custodian_delivery` state;
          Save the asset's serial and the related document
  */
  function update_item_fulfill(uint256 _role_id, bytes32 _item, bytes32 _serial, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, uint256 _from_state, uint256 _new_state)
  {
    (_success, _from_state, _new_state) = system.state_machine.change_item_state(_role_id, _item, STATE_CUSTODIAN_DELIVERY);
    require(_success);
    internal_check_duplicate_serial_when_fulfilling_order(_item, _serial);
    system.asset_documents.append(_item, _document);
    system.items_by_id[_item].serial = _serial;
  }

  /// @notice (custodian) accepts an asset item to the `minted` state
  function update_item_mint(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, address _mint_target, uint256 _effective_ng_weight, uint256 _from_state, uint256 _new_state)
  {
    _mint_target = system.items_by_id[_item].mint_target;
    _effective_ng_weight = system.items_by_id[_item].effective_ng_weight;
    (_success, _from_state, _new_state) = system.state_machine.change_item_state(_role_id, _item, STATE_MINTED);
    require(_success);
    system.items_by_id[_item].time_minted = now;
    system.asset_documents.append(_item, _document);
  }

  /// @notice update a minted asset to the `recasted` state
  function update_item_recast(uint256 _role_id, bytes32 _item, address _redeem_for, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           returns (bool _success)
  {
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_RECASTED);
    require(_success);
    system.items_by_id[_item].redeem_for = _redeem_for;
    system.items_by_id[_item].redeem_deadline = now + system.redeem_period * SECONDS_IN_A_DAY;
    system.user_recasts.append(bytes32(_redeem_for), _item);
    system.asset_documents.append(_item, _document);
  }

  /// @notice update a recasted item to the `redeemed` state
  function update_item_redeem(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_REDEEMED);
    require(_success);
    address _redeem_for = system.items_by_id[_item].redeem_for;
    system.user_recasts.remove_item(bytes32(_redeem_for), _item);
    system.asset_documents.append(_item, _document);
  }

  /// @notice update a recasted item to the `minted` state
  function update_item_remint(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_MINTED);
    require(_success);
    address _redeem_for = system.items_by_id[_item].redeem_for;
    system.user_recasts.remove_item(bytes32(_redeem_for), _item);
    system.items_by_id[_item].redeem_for = address(0x0); // reset the redeem_for field of this minted asset
    system.asset_documents.append(_item, _document);
  }

  function update_item_to_audit_failure(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, uint256 _from_state, uint256 _new_state)
  {
    (_success, _from_state, _new_state) = system.state_machine.change_item_state(_role_id, _item, STATE_AUDIT_FAILURE);
    require(_success);
    system.asset_documents.append(_item, _document);
  }

  /// @notice (popadmin) create a new asset item to replace an item that failed audit, mark it as `replacement_order`
  function create_init_item_as_replacement(uint256 _role_id, uint256 _product_id, uint256 _ng_weight, uint256 _effective_ng_weight, bytes32 _old_item)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, bytes32 _replacement_item)
  {
    (_success, _replacement_item) = system.state_machine.create_item(_role_id);
    require(_success);
    system.state_machine.change_item_state(_role_id, _replacement_item, STATE_REPLACEMENT_ORDER);
    system.items_by_id[_replacement_item].product_id = _product_id;
    system.items_by_id[_replacement_item].ng_weight = _ng_weight;
    system.items_by_id[_replacement_item].effective_ng_weight = _effective_ng_weight;
    system.items_by_id[_replacement_item].replaces = _old_item;
    system.items_by_id[_old_item].replaced_by = _replacement_item;
  }

  /// @notice (vendor) change the state of an asset item from `replacement_order` to `replacement_delivery`
  function update_item_fulfill_replacement(uint256 _role_id, bytes32 _item, bytes32 _serial, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_REPLACEMENT_DELIVERY);
    require(_success);
    internal_check_duplicate_serial_when_fulfilling_order(_item, _serial);
    system.asset_documents.append(_item, _document);
    system.items_by_id[_item].serial = _serial;
  }

  /// @notice (custodian) accepts an asset item from `replacement_delivery` state to `minted` state
  function update_item_mint_replacement(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success, uint256 _effective_ng_weight)
  {
    _effective_ng_weight = system.items_by_id[_item].effective_ng_weight;
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_MINTED);
    require(_success);
    system.items_by_id[_item].time_minted = now;
    system.asset_documents.append(_item, _document);
  }

  /// @notice (popadmin) fail an asset that has not been minted
  function update_item_admin_fail(uint256 _role_id, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    (_success,,) = system.state_machine.change_item_state(_role_id, _item, STATE_ADMIN_FAILURE);
    require(_success);
    system.asset_documents.append(_item, _document);
  }

  function update_item_add_document(bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           returns (bool _success)
  {
    _success = system.asset_documents.append(_item, _document);
    require(_success);
  }

  function update_redeem_period(uint256 _redeem_period)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           public
           returns (bool _success)
  {
    system.redeem_period = _redeem_period;
    _success = true;
  }
}

// File: contracts/storage/AssetEventsStorage.sol

pragma solidity ^0.4.19;



contract AssetEventsStorage is ResolverClient, DigixConstants {
  struct PoPEvent {
    uint256 event_type;
    uint256 timestamp;
  }

  struct AssetEventsData {
    PoPEvent[] events;
    uint256 count;
  }

  mapping(bytes32 => AssetEventsData) system;

  function AssetEventsStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_ASSET_EVENTS, _resolver));
  }

  function add_asset_event(bytes32 _asset_item, uint256 _event_type)
           public
           returns (bool _success)
  {
    require(msg.sender == get_contract(CONTRACT_CONTROLLER_ASSETS) || msg.sender == get_contract(CONTRACT_CONTROLLER_ASSETS_RECAST));
    uint256 _event_count = system[_asset_item].count;
    system[_asset_item].events.push(PoPEvent(_event_type, now));
    system[_asset_item].count = _event_count + 1;
    _success = true;
  }

  function read_asset_events_count(bytes32 _asset_item)
           public
           constant
           returns (uint256 _count)
  {
    _count = system[_asset_item].count;
  }

  function read_asset_event_details(bytes32 _asset_item, uint256 _index)
           public
           constant
           returns (uint256 _event_type, uint256 _timestamp)
  {
    _event_type = system[_asset_item].events[_index].event_type;
    _timestamp = system[_asset_item].events[_index].timestamp;
  }

}

// File: contracts/storage/GoldTokenStorage.sol

pragma solidity ^0.4.19;



contract GoldTokenStorage is ResolverClient, DigixConstants {

  struct FeeConfiguration {
    uint256 base;
    uint256 rate;
  }

  struct GlobalConfig {
    bytes32 current_version;
    bool no_demurrage_fee;
    bool no_transfer_fee;
    uint256 minimum_transfer_amount;
    Fees fees;
  }

  struct Fees {
    FeeConfiguration demurrage;
    FeeConfiguration recast;
    FeeConfiguration transfer;
  }

  struct Collectors {
    address demurrage;
    address recast;
    address transfer;
  }

  struct UserConfig {
    bool no_demurrage_fee;
    bool no_transfer_fee;
    bool no_recast_fee;
  }

  struct UserData {
    uint256 last_payment_date;
    uint256 raw_balance;
    mapping (address => uint256) spender_allowances;
  }

  struct User {
    UserConfig config;
    UserData data;
  }

  struct System {
    Collectors collectors;
    GlobalConfig config;
    uint256 total_supply;
    uint256 effective_total_supply;
    mapping (address => User) users;
  }

  System system;

  function GoldTokenStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_GOLD_TOKEN, _resolver));

    address _demurrage_collector;
    address _transfer_collector;
    address _recast_collector;

    assembly {
      _demurrage_collector := create(0,0,0)
      _transfer_collector := create(0,0,0)
      _recast_collector := create(0,0,0)
    }
    system.collectors.demurrage = _demurrage_collector;
    system.collectors.recast = _recast_collector;
    system.collectors.transfer = _transfer_collector;
    system.config.fees.demurrage.base = 10000000;
    system.config.fees.demurrage.rate = 165;
    system.config.fees.recast.base = 100000000000;
    system.config.fees.recast.rate = 1000000000;
    system.config.fees.transfer.base = 10000;
    system.config.fees.transfer.rate = 13;
    system.config.minimum_transfer_amount = 1000000;
    system.config.no_demurrage_fee = false;
    system.config.no_transfer_fee = false;
    system.config.current_version = "1.0.0";
    system.total_supply = 0;
    system.effective_total_supply = 0;
  }


 /////////////////////////////////////////////////////
///    functions to read global configs           ///
/////////////////////////////////////////////////////

  /// @notice read the total number of tokens
  function read_total_supply()
           constant
           public
           returns (uint256 _total_supply)
  {
    _total_supply = system.total_supply;
  }

  /// @notice read the effective total, which is the number of nanograms of gold that is backing the Gold tokens
  function read_effective_total_supply()
           constant
           public
           returns (uint256 _effective_total_supply)
  {
    _effective_total_supply = system.effective_total_supply;
  }

  /// @notice read both the total_supply and effective_total_supply
  function read_supply()
           constant
           public
           returns (uint256 _total_supply, uint256 _effective_total_supply)
  {
    _total_supply = read_total_supply();
    _effective_total_supply = read_effective_total_supply();
  }

  /// @notice read general global configs: no_demurrage_fee, no_transfer_fee, minimum_transfer_amount, current_version
  function read_general_config()
           constant
           public
           returns (bytes32 _current_version, bool _no_demurrage_fee, bool _no_transfer_fee, uint256 _minimum_transfer_amount)
  {
    _current_version = system.config.current_version;
    _no_demurrage_fee = system.config.no_demurrage_fee;
    _no_transfer_fee = system.config.no_transfer_fee;
    _minimum_transfer_amount = system.config.minimum_transfer_amount;
  }

  function read_collectors_addresses()
           constant
           public
           returns (address[3] _collectors)
  {
    /* _collectors = new address[](3); */
    _collectors[0] = system.collectors.demurrage;
    _collectors[1] = system.collectors.recast;
    _collectors[2] = system.collectors.transfer;
  }


 ///////////////////////////////////////////////
///    functions to read users' configs     ///
///////////////////////////////////////////////

  /// @notice read all details of a user
  function read_user(address _account)
           public
           constant
           returns (bool _exists,
                    uint256 _raw_balance,
                    uint256 _payment_date,
                    bool _no_demurrage_fee,
                    bool _no_recast_fee,
                    bool _no_transfer_fee)
  {
    _exists = (system.users[_account].data.last_payment_date > 0);
    _raw_balance = system.users[_account].data.raw_balance;
    _payment_date = system.users[_account].data.last_payment_date;
    (_no_demurrage_fee, _no_transfer_fee, _no_recast_fee) = read_user_fees_configs(_account);
  }

  function read_user_fees_configs(address _account)
           public
           constant
           returns (bool _no_demurrage_fee,
                    bool _no_transfer_fee,
                    bool _no_recast_fee)
  {
    _no_demurrage_fee = system.users[_account].config.no_demurrage_fee;
    _no_transfer_fee = system.users[_account].config.no_transfer_fee;
    _no_recast_fee = system.users[_account].config.no_recast_fee;
  }

  /// @notice read a user's spender allowance
  function read_account_spender_allowance(address _account,
                                          address _spender)
           public
           constant
           returns (uint256 _spender_allowance)
  {
    _spender_allowance = system.users[_account].data.spender_allowances[_spender];
  }


 //////////////////////////////////////////////////
///    Update functions regarding users        ///
//////////////////////////////////////////////////

  /// @notice called by TokenApprovalController to update an account's spender allowance of a _spender
  function update_account_spender_allowance(address _account,
                                            address _spender,
                                            uint256 _new_allowance)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_APPROVAL)
           public
           returns (bool _success)
  {
    system.users[_account].data.spender_allowances[_spender] = _new_allowance;
    _success = true;
  }

  /// @notice update the _user balance and the global total supply after minting some tokens
  function update_balances_after_mint(address _user, uint256 _user_new_balance, uint256 _new_total_supply, uint256 _new_effective_total_supply)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           public
           returns (bool _success)
  {
    system.users[_user].data.raw_balance = _user_new_balance;
    system.total_supply = _new_total_supply;
    system.effective_total_supply = _new_effective_total_supply;
    _success = true;
  }

  /// @notice update a user's fees configs
  function update_user_fees_configs(address _user, bool _no_demurrage_fee, bool _no_transfer_fee, bool _no_recast_fee)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
           returns (bool _success)
  {
    system.users[_user].config.no_demurrage_fee = _no_demurrage_fee;
    system.users[_user].config.no_transfer_fee = _no_transfer_fee;
    system.users[_user].config.no_recast_fee = _no_recast_fee;
    _success = true;
  }


 ///////////////////////////////////////////////////////////
///    Update functions to change global configs        ///
///////////////////////////////////////////////////////////

  /// @notice called by AssetsController to update the effective supply (when an item failed audit or is replaced)
  function update_effective_supply(uint256 _effective_total_supply)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           public
           returns (bool _success)
  {
    system.effective_total_supply = _effective_total_supply;
    _success = true;
  }

  /// @notice update configs for recast fees
  function update_config_recast(uint256 _base, uint256 _rate)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
           returns (bool _success)
  {
    system.config.fees.recast.base = _base;
    system.config.fees.recast.rate = _rate;
    _success = true;
  }

  /// @notice update configs for demurrage fees
  function update_config_demurrage(uint256 _base, uint256 _rate, bool _no_demurrage_fee)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
           returns (bool _success)
  {
    system.config.fees.demurrage.base = _base;
    system.config.fees.demurrage.rate = _rate;
    system.config.no_demurrage_fee = _no_demurrage_fee;
    _success = true;
  }

  /// @notice update configs for transfer fees
  function update_config_transfer(uint256 _base, uint256 _rate, bool _no_transfer_fee, uint256 _minimum_transfer_amount)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
           returns (bool _success)
  {
    system.config.fees.transfer.base = _base;
    system.config.fees.transfer.rate = _rate;
    system.config.no_transfer_fee = _no_transfer_fee;
    system.config.minimum_transfer_amount = _minimum_transfer_amount;
    _success = true;
  }


 /////////////////////////////////////////////
///    Demurrage-related functions        ///
/////////////////////////////////////////////

  /// @notice called by TokenDemurrageService to get the global demurrage configs
  function read_demurrage_config()
           constant
           public
           returns (uint256 _collector_balance,
                    uint256 _base,
                    uint256 _rate,
                    address _collector)
  {
    _collector_balance = system.users[system.collectors.demurrage].data.raw_balance;
    bool _global_demurrage_disabled = system.config.no_demurrage_fee;
    _collector = system.collectors.demurrage;

    if (_global_demurrage_disabled) {
      _base = 0;
      _rate = 0;
    } else {
      _base = system.config.fees.demurrage.base;
      _rate = system.config.fees.demurrage.rate;
    }
  }

  function read_demurrage_config_underlying()
           public
           constant
           returns (uint256 _base,
                    uint256 _rate,
                    address _collector,
                    bool _no_demurrage_fee)
  {
    _base = system.config.fees.demurrage.base;
    _rate = system.config.fees.demurrage.rate;
    _collector = system.collectors.demurrage;
    _no_demurrage_fee = system.config.no_demurrage_fee;
  }

  /// @notice called by TokenDemurrageService to get the user's information needed to deduct his demurrage fees
  function read_user_for_demurrage(address _account)
           public
           constant
           returns (uint256 _raw_balance, uint256 _payment_date, bool _no_demurrage_fee)
  {
    _raw_balance = system.users[_account].data.raw_balance;
    _payment_date = system.users[_account].data.last_payment_date;
    _no_demurrage_fee = system.users[_account].config.no_demurrage_fee || system.config.no_demurrage_fee;
  }

  /// @notice called by TokenDemurrageService to deduct demurrage fees from a user's balance
  function update_user_for_demurrage(address _user, uint256 _user_new_balance, uint256 _user_new_payment_date, uint256 _collector_new_balance)
           if_sender_is(CONTRACT_SERVICE_TOKEN_DEMURRAGE)
           public
           returns (bool _success)
  {
    system.users[system.collectors.demurrage].data.raw_balance = _collector_new_balance;
    system.users[_user].data.raw_balance = _user_new_balance;
    system.users[_user].data.last_payment_date = _user_new_payment_date;
    _success = true;
  }


 ////////////////////////////////////////
///    Recast-related functions      ///
////////////////////////////////////////

  /// @notice called by AssetsController to read global info to recast an asset item
  function read_recast_config()
           constant
           public
           returns (uint256 _base,
                    uint256 _rate,
                    uint256 _total_supply,
                    uint256 _effective_total_supply,
                    address _collector,
                    uint256 _collector_balance)
  {
    _base = system.config.fees.recast.base;
    _rate = system.config.fees.recast.rate;
    _total_supply = system.total_supply;
    _effective_total_supply = system.effective_total_supply;
    _collector = system.collectors.recast;
    _collector_balance = system.users[system.collectors.recast].data.raw_balance;
  }

  /// @notice called by AssetsController to read a user's configs for recasting assets
  function read_user_for_recast(address _account)
           public
           constant
           returns (uint256 _raw_balance, bool _no_recast_fee)
  {
    _raw_balance = system.users[_account].data.raw_balance;
    _no_recast_fee = system.users[_account].config.no_recast_fee;
  }

  /// @notice called by AssetsController to recast an asset item
  function update_balances_after_recast(address _recaster,
                               uint256 _recaster_new_balance,
                               uint256 _recast_fee_collector_new_balance,
                               uint256 _new_total_supply,
                               uint256 _new_effective_total_supply)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           public
           returns (bool _success)
  {
    system.users[_recaster].data.raw_balance = _recaster_new_balance;
    system.users[system.collectors.recast].data.raw_balance = _recast_fee_collector_new_balance;
    system.total_supply = _new_total_supply;
    system.effective_total_supply = _new_effective_total_supply;
    _success = true;
  }


 ////////////////////////////////////////
///    Transfer-related functions    ///
////////////////////////////////////////

  /// @notice called by TokenTransferController to read global configs for transfering tokens
  function read_transfer_config()
           public
           constant
           returns (uint256 _collector_balance,
                    uint256 _base,
                    uint256 _rate,
                    address _collector,
                    bool _no_transfer_fee,
                    uint256 _minimum_transfer_amount)
  {
    _collector_balance = system.users[system.collectors.transfer].data.raw_balance;
    _base = system.config.fees.transfer.base;
    _rate = system.config.fees.transfer.rate;
    _collector = system.collectors.transfer;
    _no_transfer_fee = system.config.no_transfer_fee;
    _minimum_transfer_amount = system.config.minimum_transfer_amount;
  }

  /// @notice called by TokenTransferController to read a user's configs for tranfering tokens
  function read_user_for_transfer(address _account)
           public
           constant
           returns (uint256 _raw_balance, bool _no_transfer_fee)
  {
    _raw_balance = system.users[_account].data.raw_balance;
    _no_transfer_fee = system.users[_account].config.no_transfer_fee;
  }

  /// @notice called by TokenTransferController to update user balances after transfering
  function update_transfer_balance(address _sender, uint256 _sender_new_balance, address _recipient,
                                   uint256 _recipient_new_balance, uint256 _transfer_fee_collector_new_balance)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_TRANSFER)
           public
           returns (bool _success)
  {
    system.users[_sender].data.raw_balance = _sender_new_balance;
    system.users[_recipient].data.raw_balance = _recipient_new_balance;
    system.users[system.collectors.transfer].data.raw_balance = _transfer_fee_collector_new_balance;
    _success = true;
  }

  /// @notice called by TokenTransferController to update balances after transfering from
  function update_transfer_from_balance(address _sender, uint256 _sender_new_balance, address _recipient,
                                        uint256 _recipient_new_balance, uint256 _transfer_fee_collector_new_balance,
                                        address _spender, uint256 _spender_new_allowance)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_TRANSFER)
           public
           returns (bool _success)
  {
    system.users[_sender].data.raw_balance = _sender_new_balance;
    system.users[_recipient].data.raw_balance = _recipient_new_balance;
    system.users[system.collectors.transfer].data.raw_balance = _transfer_fee_collector_new_balance;
    system.users[_sender].data.spender_allowances[_spender] = _spender_new_allowance;
    _success = true;
  }

  ////////////////////////////////////////
 ///    transfer fees to distributors  ///
 ////////////////////////////////////////
  function internal_move_balance(address _from, address _to)
           internal
           returns (uint256 _fees)
  {
    _fees = system.users[_from].data.raw_balance;
    system.users[_to].data.raw_balance += _fees;
    system.users[_from].data.raw_balance = 0;
  }

  function move_fees_to_distributors(address _demurrage_fees_distributor, address _recast_fees_distributor, address _transfer_fees_distributor)
          if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
          public
          returns (bool _success, uint256[3] _fees_array)
  {
    /* _fees_array = new uint256[](3); */
    _fees_array[0] = internal_move_balance(system.collectors.demurrage, _demurrage_fees_distributor);
    _fees_array[1] = internal_move_balance(system.collectors.recast, _recast_fees_distributor);
    _fees_array[2] = internal_move_balance(system.collectors.transfer, _transfer_fees_distributor);
    _success = true;
  }

}

// File: contracts/storage/IdentityStorage.sol

pragma solidity ^0.4.19;



contract IdentityStorage is ResolverClient, DigixConstants {

  struct User {
    uint256 id_expiration;
    bytes32 doc;  // Our current system doesnt use this yet, but we might need it in the future
  }

  mapping(address => User) users;

  function IdentityStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_IDENTITY, _resolver));
  }

  function read_user(address _user)
           public
           constant
           returns (uint256 _id_expiration, bytes32 _doc)
  {
    _id_expiration = users[_user].id_expiration;
    _doc = users[_user].doc;
  }

  function read_user_kyc_valid(address _user)
           public
           constant
           returns (bool _kyc_valid)
  {
    _kyc_valid = users[_user].id_expiration > now;
  }

  function update_user_id_expiration(address _user, uint256 _id_expiration)
           if_sender_is(CONTRACT_CONTROLLER_IDENTITY)
           public
           returns (bool _success)
  {
    users[_user].id_expiration = _id_expiration;
    _success = true;
  }

  function update_user_doc(address _user, bytes32 _doc)
           if_sender_is(CONTRACT_CONTROLLER_IDENTITY)
           public
           returns (bool _success)
  {
    users[_user].doc = _doc;
    _success = true;
  }

}

// File: @digix/solidity-core-libraries/contracts/MathUtils.sol

pragma solidity ^0.4.19;

/// @title Digix Math Library
/// @author DigixGlobal

library MathUtils {

  /*modifier if_safe_to_add(uint256 _x, uint256 _y) {
    require(is_safe_to_add(_x, _y) == true);
    _;
  }

  modifier if_safe_to_subtract(uint256 _x, uint256 _y) {
    require(is_safe_to_subtract(_x, _y) == true);
    _;
  }*/

  /*uint256 constant ONE_DAY = 1 days;*/

  /// DEPRECATED
  /// @notice Call with two integers to determine if they are safe to add
  /// @dev Catches integer overflow
  /// param _a Integer to add
  /// param _b Integer to add
  /// @return _issafe True if the integers are safe to add
  /*function is_safe_to_add(uint256 _a, uint256 _b)
           public
           constant
           returns (bool _is_safe)
  {
    _is_safe = (_a + _b >= _a);
    return _is_safe;
  }*/

  /// @notice Returns sum of two safely-added integers
  /// @dev Uses `safeToAdd` internally; throws if unsafe
  /// @param _a Integer to add
  /// @param _b Integer to add
  /// @return _result Sum of inputs
  function add(uint256 _a, uint256 _b)
           public
           pure
           returns (uint256 _result)
  {
    _result = _a + _b;
    require(_result > _a);
  }

  /// DEPRECATED
  /// @notice Call with two integers to determine if they are safe to subtract
  /// @dev Catches integer overflow
  /// param _a Integer to subtract from
  /// param _b Integer to subtract
  /// @return _issafe True if the integers are safe to subtract
  /*function is_safe_to_subtract(uint256 _a, uint256 _b)
           public
           constant
           returns (bool _is_safe)
  {
    _is_safe = (_b <= _a);
    return _is_safe;
  }*/

  /// @notice Returns result of two safely-subtracted integers
  /// @dev Uses `safeToSubtract` internally; throws if unsafe
  /// @param _a Integer to subtract from
  /// @param _b Integer to subtract
  /// @return _result Result of subtraction
  function subtract(uint256 _a, uint256 _b)
           public
           pure
           returns (uint _result)
  {
    require(_a >= _b);
    _result = _a - _b;
  }

  /// DEPRECATED
  ///# @notice Calculates the rate of ???
  ///# @dev `((_unit * _a) + _b / 2) / _b`
  ///# paramm _a ??
  ///# paramm _b ??
  ///# paramm _places Number of decimal places
  ///# @return _result Result of subtraction
  /*function rate_of(uint256 _a, uint256 _b, uint256 _places)
           public
           constant
           returns (uint256 _result)
  {
    var _unit = 10 ** _places;
    _result = add((_unit * _a), (_b / 2)) / _b;
    return _result;
  }*/

  /// DEPRECATED
  ///# @notice Calculates the rate from ???
  ///# @dev `(_amount * _baserate) / (10 ** _places)`
  ///# paramm _amount ??
  ///# paramm _baserate ??
  ///# paramm _places ??
  ///# @return _fee Calculated Fee
  /*function from_rate(uint256 _amount, uint256 _baserate, uint256 _places)
           returns (uint256 _fee)
  {
    _fee = ((_amount * _baserate) / (10 ** _places));
    return _fee;
  }*/

  /// DEPRECATED
  ///# @notice Calculate demurrage time values
  ///# paramm _current_time Current block time
  ///# paramm _last_payment_date Last demurrage payment date
  ///# @return {
  ///   "_next_payment_date": "Next payment date as unix time",
  ///   "_demurrage_days": "Demurrage days calculated"
  /// }
  /*function calculate_demurrage_time(uint256 _current_time, uint256 _last_payment_date)
           returns (uint256 _next_payment_date, uint256 _demurrage_days)
  {
    var _time_difference = subtract(_current_time, _last_payment_date);
    _demurrage_days = _time_difference / (1 days);
    var _remainder = _time_difference % (1 days);
    var _demurrage_seconds = _demurrage_days * (1 days);
    _next_payment_date = subtract(add(_last_payment_date, _demurrage_seconds), _remainder);
    return (_next_payment_date, _demurrage_days);
  }*/

  /// DEPRECATED
  ///# @notice Calculate demurrage fee
  ///# paramm _demurrage_days Days since last demurrage payment
  ///# paramm _unit_size Minimum amount for demurrage fees
  ///# paramm _fee_per_unit Amount of daily demurrage to deduct for every `_demurrage_minimum`
  ///# paramm _raw_balance Account balance
  ///# @return _demurrage_fee The demurrage fee due
  /*function calculate_demurrage_fee(uint256 _demurrage_days, uint256 _unit_size, uint256 _fee_per_unit, uint256 _raw_balance)
           returns (uint256 _demurrage_fee)
  {
    if (_demurrage_days == 0) {
      _demurrage_fee = 0;
    } else {
      var _billable_amount = (_raw_balance / _unit_size);
      _demurrage_fee = (_billable_amount * _demurrage_days * _fee_per_unit);
    }
    return _demurrage_fee;
  }*/

  /// DEPRECATED
  ///# @notice Get demurrage info
  ///# paramm _current_time Current block time
  ///# paramm _last_payment_date Last demurrage payment date
  ///# paramm _raw_balance Account balance
  ///# paramm _unit_size Minimum amount needed to charge demurrage fees
  ///# paramm _fee_per_unit The amount of daily demurrage deduct for every `_minimum_for_demurrage`
  /// @return {
  ///    "_demurrage_fee": "Fee charged against current balance",
  ///    "_demurrage_days": "Demurrage days calculated",
  ///    "_billable_amount": "Amount eligible for demurrage calculation",
  ///    "_next_payment_date": "Timestamp to use for next payment date"
  /// }
  /*function get_demurrage_info(uint256 _current_time, uint256 _last_payment_date, uint256 _raw_balance, uint256 _unit_size, uint256 _fee_per_unit)
           returns (uint256 _demurrage_fee, uint256 _demurrage_days, uint256 _balance_after, uint256 _next_payment_date)
  {
    _demurrage_days = (subtract(_current_time, _last_payment_date)) / ONE_DAY;
    uint256 _billable_amount = (_raw_balance / _unit_size);
    if (_demurrage_days == 0) {
      _demurrage_fee = 0;
      _next_payment_date = _last_payment_date;
      _balance_after = _raw_balance;
    } else {
      _demurrage_fee = (_billable_amount * _demurrage_days * _fee_per_unit);
      var _remainder = subtract(_current_time, _last_payment_date) % ONE_DAY;
      _next_payment_date = subtract(add(_last_payment_date, (_demurrage_days * ONE_DAY)), _remainder);
      _balance_after = subtract(_raw_balance, _demurrage_fee);
    }
    return (_demurrage_fee, _demurrage_days, _balance_after, _next_payment_date);
  }*/

  /// DEPRECATED
  ///# @notice Calculate Transaction Fee
  ///# paramm _sending_amount The amount being sent
  ///# paramm _unit_size The minimum amount that can be sent
  ///# paramm _fee_per_unit The fee per unit
  ///# @return _tx_fee The transaction fee due
  /*function get_tx_fee(uint256 _sending_amount, uint256 _unit_size, uint256 _fee_per_unit)
           returns (uint256 _tx_fee)
  {
    _tx_fee = (_sending_amount / _unit_size) * _fee_per_unit;
    return _tx_fee;
  }*/

  function calculate_recast_fee(uint256 _asset_weight, uint256 _unit_size, uint256 _fee_per_unit)
           public
           pure
           returns (uint256 _recast_fee)
  {
    uint256 _weight_times_fee_per_unit = _asset_weight * _fee_per_unit;
    require(_weight_times_fee_per_unit / _asset_weight == _fee_per_unit);
    _recast_fee = _weight_times_fee_per_unit / _unit_size;
    return _recast_fee;
  }

}

// File: @digix/solidity-core-libraries/contracts/Types.sol

pragma solidity ^0.4.19;

library Types {

  struct MutableUint {
    uint256 pre;
    uint256 post;
  }

  struct MutableTimestamp {
    MutableUint time;
    uint256 in_units;
  }

  function advance_by(MutableTimestamp memory _original, uint256 _units)
           internal
           constant
           returns (MutableTimestamp _transformed)
  {
    _transformed = _original;
    require(now >= _original.time.pre);
    uint256 _lapsed = now - _original.time.pre;
    _transformed.in_units = _lapsed / _units;
    uint256 _ticks = _transformed.in_units * _units;
    if (_transformed.in_units == 0) {
      _transformed.time.post = _original.time.pre;
    } else {
      _transformed.time = add(_transformed.time, _ticks);
    }
  }

  // DEPRECATED
  /*function add_two(MutableUint memory _original, uint256 _first, uint256 _second)
           internal
           constant
           returns (MutableUint _transformed)
  {
    require((_original.pre + _first + _second) >= _original.pre);
    _transformed = _original;
    _transformed.post = (_original.pre + _first + _second);
  }*/

  function subtract_two(MutableUint memory _original, uint256 _first, uint256 _second)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require(_original.pre >= _first);
    uint256 _after_first = _original.pre - _first;
    require(_after_first >= _second);
    _transformed = _original;
    _original.post = (_after_first - _second);
  }

  function subtract_and_add(MutableUint memory _original, uint256 _to_subtract, uint256 _to_add)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require(_original.pre >= _to_subtract);
    uint256 _after_subtract = _original.pre - _to_subtract;
    require((_after_subtract + _to_add) >= _after_subtract);
    _transformed.post = _after_subtract + _to_add;
  }

  /// DEPRECATED
  /*function increment(MutableUint memory _original)
           internal
           constant
           returns (MutableUint _transformed)
  {
    _transformed = _original;
    _transformed.post = _original.pre + 1;
  }*/

  /// DEPRECATED
  /*function decrement(MutableUint memory _original)
           internal
           constant
           returns (MutableUint _transformed)
  {
    _transformed = _original;
    require((_original.pre + 1) > _original.pre);
    _transformed.post = _original.pre - 1;
  }*/

  function add_and_subtract(MutableUint memory _original, uint256 _to_add, uint256 _to_subtract)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require((_original.pre + _to_add) >= _original.pre);
    uint256 _after_add = _original.pre + _to_add;
    require(_after_add >= _to_subtract);
    _transformed = _original;
    _transformed.post = (_after_add - _to_subtract);
  }

  function add(MutableUint memory _original, uint256 _amount)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require((_original.pre + _amount) >= _original.pre);
    _transformed = _original;
    _transformed.post = _original.pre + _amount;
  }

  function subtract(MutableUint memory _original, uint256 _amount)
           internal
           pure
           returns (MutableUint _transformed)
  {
    require(_amount <= _original.pre);
    _transformed = _original;
    _transformed.post = _original.pre - _amount;
  }

  function swap(MutableUint memory _original_a, MutableUint memory _original_b)
           internal
           pure
           returns (MutableUint _transformed_a, MutableUint _transformed_b)
  {
    _transformed_a = _original_a;
    _transformed_b = _original_b;
    _transformed_a.post = _original_b.pre;
    _transformed_b.post = _original_a.pre;
  }

  /*function transfer(MutableUint memory _original_from, MutableUint memory _original_to, uint256 _amount)
           internal
           constant
           returns (MutableUint _transformed_from, MutableUint _transformed_to)
  {
    _original_from = _transformed_from;
    _original_to = _transformed_to;
    _transformed_from.post = subtract(_transformed_from, _amount).post;
    _transformed_to.post = add(_transformed_to, _amount).post;
  }*/

}

// File: contracts/common/TokenLoggerCallback.sol

pragma solidity ^0.4.19;



contract TokenLoggerCallback is ResolverClient, DigixConstants {

  event Transfer(address indexed _from,  address indexed _to,  uint256 _value);
  event Approval(address indexed _owner,  address indexed _spender,  uint256 _value);

  function log_mint(address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS)
           public
  {
    Transfer(address(0x0), _to, _value);
  }

  function log_recast_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_recast(address _from, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
           public
  {
    Transfer(_from, address(0x0), _value);
  }

  function log_demurrage_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_SERVICE_TOKEN_DEMURRAGE)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_move_fees(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_CONFIG)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_transfer(address _from, address _to, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_TRANSFER)
           public
  {
    Transfer(_from, _to, _value);
  }

  function log_approve(address _owner, address _spender, uint256 _value)
           if_sender_is(CONTRACT_CONTROLLER_TOKEN_APPROVAL)
           public
  {
    Approval(_owner, _spender, _value);
  }

}

// File: contracts/service/TokenDemurrageService.sol

pragma solidity ^0.4.19;







contract TokenDemurrageService is ResolverClient, DigixConstants {

  using Types for Types.MutableUint;
  using Types for Types.MutableTimestamp;

  struct User {
    address account;
    bool no_demurrage_fee;
    Types.MutableUint balance;
    Types.MutableTimestamp payment_date;
  }

  struct Config {
    Types.MutableUint collector_balance;
    uint256 base;
    uint256 rate;
    address collector;
  }

  struct Demurrage {
    Config config;
    User user;
    uint256 collected_fee;
  }

  function TokenDemurrageService(address _resolver) public
  {
    require(init(CONTRACT_SERVICE_TOKEN_DEMURRAGE, _resolver));
  }

  function gold_token_storage()
           internal
           constant
           returns (GoldTokenStorage _contract)
  {
    _contract = GoldTokenStorage(get_contract(CONTRACT_STORAGE_GOLD_TOKEN));
  }

  function get_demurrage_data(address _user)
           internal
           constant
           returns (Demurrage _demurrage)
  {
    (_demurrage.config.collector_balance.pre, _demurrage.config.base, _demurrage.config.rate, _demurrage.config.collector) =
      gold_token_storage().read_demurrage_config();
    _demurrage.user.account = _user;
    (_demurrage.user.balance.pre, _demurrage.user.payment_date.time.pre, _demurrage.user.no_demurrage_fee) = gold_token_storage().read_user_for_demurrage(_user);
  }

  function calculate_demurrage(Demurrage memory _demurrage)
           internal
           constant
           returns (Demurrage _calculated)
  {
    if (_demurrage.user.payment_date.time.pre == 0) {
      _demurrage.user.payment_date.time.pre = now;
    }
    if (_demurrage.user.no_demurrage_fee == true || _demurrage.user.account == _demurrage.config.collector) { // demurrage collector is never deducted for demurrage
      _demurrage.user.balance.post = _demurrage.user.balance.pre;
      _demurrage.config.collector_balance.post = _demurrage.config.collector_balance.pre;
      _demurrage.user.payment_date.time.post = now;
    } else {
      _demurrage.user.payment_date = _demurrage.user.payment_date.advance_by(1 days);
      if (_demurrage.user.payment_date.in_units == 0) {
        _demurrage.user.balance.post = _demurrage.user.balance.pre;
        _demurrage.config.collector_balance.post = _demurrage.config.collector_balance.pre;
      } else {
        _demurrage.collected_fee = (_demurrage.user.payment_date.in_units * _demurrage.user.balance.pre * _demurrage.config.rate) / _demurrage.config.base;
        _demurrage.user.balance = _demurrage.user.balance.subtract(_demurrage.collected_fee);
        _demurrage.config.collector_balance = _demurrage.config.collector_balance.add(_demurrage.collected_fee);
      }
    }
    _calculated = _demurrage;
  }

  function show_demurraged_balance(address _user)
           public
           constant
           returns ( uint256 _actual_balance)
  {
    Demurrage memory _demurrage = get_demurrage_data(_user);
    _demurrage = calculate_demurrage(_demurrage);
    _actual_balance = _demurrage.user.balance.post;
  }

  function deduct_demurrage(address _user)
           public
           returns (bool _success)
  {
    Demurrage memory _demurrage = get_demurrage_data(_user);
    _demurrage = calculate_demurrage(_demurrage);
    require(gold_token_storage().update_user_for_demurrage(_demurrage.user.account, _demurrage.user.balance.post, _demurrage.user.payment_date.time.post, _demurrage.config.collector_balance.post) == true);
    if (_demurrage.collected_fee > 0) {
      TokenLoggerCallback(get_contract(CONTRACT_INTERACTIVE_TOKEN)).log_demurrage_fees(_user, _demurrage.config.collector, _demurrage.collected_fee);
    }
    _success = true;
  }

  function bulk_deduct_demurrage(address[] _users)
           public
           returns (bool _success)
  {
    uint256 _length = _users.length;
    for (uint256 i=0;i<_length; i++) {
      deduct_demurrage(_users[i]);
    }
    _success = true;
  }

}

// File: contracts/common/ERCTwenty.sol

pragma solidity ^0.4.19;

contract ERCTwenty {
  function decimals() constant public returns (uint _decimals);
  function totalSupply() constant public returns (uint supply);
  function balanceOf( address who ) constant public returns (uint value);
  function allowance( address owner, address spender ) constant public returns (uint _allowance);
  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);
  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}

// File: contracts/storage/MarketplaceStorage.sol

pragma solidity ^0.4.19;




// Contracts that need to be deployed for this contract to work:
//    DoublyLinkedList, CoreStorage, MathUtils, TokenTransferController, TokenInfoController,
//    TokenDemurrageService, TokenApprovalController, Token, ContractResolver

contract MarketplaceStorage is ResolverClient, DigixConstants {

  struct Config {
    uint256 global_daily_dgx_ng_limit;
    uint256 minimum_purchase_dgx_ng;
    uint256 maximum_block_drift;
    address payment_collector;
    uint256 max_dgx_available_daily;
    uint256 price_floor_wei_per_dgx_mg;
  }

  struct Purchase {
    address recipient; // the recipient is not necessarily the user who purchased
    uint256 timestamp;
    uint256 amount;
    uint256 price;
  }

  struct User {
    uint256 overwrite_daily_dgx_ng_limit;
    Purchase[] purchases;
  }

  struct Marketplace {
    Config config;
    Purchase[] purchases;
    mapping (address => User) users;
    mapping (address => bool) approved_signers;
    mapping (uint => mapping (uint => bool)) used_nonces;
  }

  Marketplace marketplace;

  function MarketplaceStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_MARKETPLACE, _resolver));
    marketplace.config.global_daily_dgx_ng_limit = 102000000000;
    marketplace.config.minimum_purchase_dgx_ng = 10000000;
  }

  function token_contract()
           internal
           constant
           returns (ERCTwenty _contract)
  {
    _contract = ERCTwenty(get_contract(CONTRACT_INTERACTIVE_TOKEN));
  }

  function read_total_number_of_purchases()
           public
           constant
           returns (uint256 _total_number_of_purchases)
  {
    _total_number_of_purchases = marketplace.purchases.length;
  }

  function read_total_number_of_user_purchases(address _user)
           public
           constant
           returns (uint256 _total_number_of_user_purchases)
  {
    _total_number_of_user_purchases = marketplace.users[_user].purchases.length;
  }

  function read_purchase_at_index(uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    Purchase memory _purchase = marketplace.purchases[_index];
    _recipient = _purchase.recipient;
    _timestamp = _purchase.timestamp;
    _amount = _purchase.amount;
    _price = _purchase.price;
  }

  function read_user_purchase_at_index(address _user, uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    Purchase memory _purchase = marketplace.users[_user].purchases[_index];
    _recipient = _purchase.recipient;
    _timestamp = _purchase.timestamp;
    _amount = _purchase.amount;
    _price = _purchase.price;
  }

  function create_user(address _user, uint256 _overwrite_daily_dgx_ng_limit)
           if_sender_is(CONTRACT_CONTROLLER_IDENTITY)
           public
           returns (bool _success)
  {
    marketplace.users[_user].overwrite_daily_dgx_ng_limit = _overwrite_daily_dgx_ng_limit;
    _success = true;
  }

  function update_user_purchase(address _recipient_user, address _buyer, uint256 _purchase_amount, uint256 _purchase_price, uint256 _block_number, uint256 _nonce)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE)
           public
           returns (bool _success)
  {
    marketplace.used_nonces[_block_number][_nonce] = true;
    Purchase memory _purchase;
    _purchase.recipient = _recipient_user;
    _purchase.timestamp = now;
    _purchase.amount = _purchase_amount;
    _purchase.price = _purchase_price;
    marketplace.users[_buyer].purchases.push(_purchase);
    marketplace.purchases.push(_purchase);
    require(token_contract().transfer(_recipient_user, _purchase_amount) == true);
    _success = true;
  }

  function update_config(uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN)
           public
           returns (bool _success)
  {
    marketplace.config.global_daily_dgx_ng_limit = _global_daily_dgx_ng_limit;
    marketplace.config.minimum_purchase_dgx_ng = _minimum_purchase_dgx_ng;
    marketplace.config.payment_collector = _payment_collector;
    marketplace.config.maximum_block_drift = _maximum_block_drift;
    _success = true;
  }

  function move_inventory(address _destination, uint256 _amount)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN)
           public
           returns (bool _success)
  {
    require(token_contract().transfer(_destination, _amount));
    _success = true;
  }

  function update_max_dgx_available_daily(uint256 _max_dgx_available_daily)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN)
           public
           returns (bool _success)
  {
    marketplace.config.max_dgx_available_daily = _max_dgx_available_daily;
    _success = true;
  }

  function read_max_dgx_available_daily()
           public
           constant
           returns (uint256 _max_dgx_available_daily)
  {
    _max_dgx_available_daily = marketplace.config.max_dgx_available_daily;
  }

  function update_price_floor(uint256 _price_floor_wei_per_dgx_mg)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN)
           public
           returns (bool _success)
  {
    marketplace.config.price_floor_wei_per_dgx_mg = _price_floor_wei_per_dgx_mg;
    _success = true;
  }

  function read_price_floor()
           public
           constant
           returns (uint256 _price_floor_wei_per_dgx_mg)
  {
    _price_floor_wei_per_dgx_mg = marketplace.config.price_floor_wei_per_dgx_mg;
  }

  function update_signer_approval(address _signer, bool _approve)
           if_sender_is(CONTRACT_CONTROLLER_MARKETPLACE_ADMIN)
           public
           returns (bool _success)
  {
    marketplace.approved_signers[_signer] = _approve;
    _success = true;
  }

  function read_config()
           public
           constant
           returns (uint256 _global_daily_dgx_ng_limit, uint256 _minimum_purchase_dgx_ng, uint256 _maximum_block_drift, address _payment_collector)
  {
    _global_daily_dgx_ng_limit = marketplace.config.global_daily_dgx_ng_limit;
    _minimum_purchase_dgx_ng = marketplace.config.minimum_purchase_dgx_ng;
    _maximum_block_drift = marketplace.config.maximum_block_drift;
    _payment_collector = marketplace.config.payment_collector;
  }

  function read_is_approved_signer(address _signer)
           public
           constant
           returns (bool _yes)
  {
    _yes = marketplace.approved_signers[_signer];
  }

  function read_total_purchased_today(address _user)
           public
           constant
           returns (uint256 _total_purchased_today)
  {
    _total_purchased_today = 0;
    uint256 _i = marketplace.users[_user].purchases.length;
    while((_i >= 1) && (scope_timestamp_is_from_today(marketplace.users[_user].purchases[_i - 1].timestamp) == true)) {
      _total_purchased_today += marketplace.users[_user].purchases[_i - 1].amount;
      _i--;
    }
  }

  function read_total_global_purchased_today()
           public
           constant
           returns (uint256 _total_global_purchased_today)
  {
    _total_global_purchased_today = 0;
    uint256 _i = marketplace.purchases.length;
    while((_i >= 1) && (scope_timestamp_is_from_today(marketplace.purchases[_i - 1].timestamp) == true)) {
      _total_global_purchased_today += marketplace.purchases[_i - 1].amount;
      _i--;
    }
  }

  function read_dgx_inventory_balance_ng()
           public
           constant
           returns (uint256 _balance)
  {
    _balance = token_contract().balanceOf(address(this));
  }

  function scope_timestamp_is_from_today(uint256 _timestamp)
           public
           constant
           returns (bool _yes)
  {
    _yes = (_timestamp >= (now - 1 days));
  }

  function read_for_purchase(address _user, uint256 _block_number, uint256 _nonce, address _signer)
           public
           constant
           returns (uint256 _daily_dgx_limit, uint256 _total_purchased_today,
                    bool _used_nonce, bool _approved_signer)
  {
    _daily_dgx_limit = read_user_daily_limit(_user);
    _used_nonce = marketplace.used_nonces[_block_number][_nonce];
    _approved_signer = marketplace.approved_signers[_signer];
    _total_purchased_today = read_total_purchased_today(_user);
  }

  function read_user(address _user)
           public
           constant
           returns (uint256 _daily_dgx_limit, uint256 _total_purchased_today)
  {
    _daily_dgx_limit = read_user_daily_limit(_user);
    _total_purchased_today = read_total_purchased_today(_user);
  }

  /// user daily limit = max(user's overwrite_daily_dgx_ng_limit, global_daily_dgx_ng_limit)
  function read_user_daily_limit(address _user)
           public
           constant
           returns (uint256 _daily_dgx_limit)
  {
    _daily_dgx_limit = marketplace.users[_user].overwrite_daily_dgx_ng_limit;
    if (_daily_dgx_limit < marketplace.config.global_daily_dgx_ng_limit) {
      _daily_dgx_limit = marketplace.config.global_daily_dgx_ng_limit;
    }
  }

  function read_user_purchases_count(address _user)
           public
           constant
           returns (uint256 _count)
  {
    _count = marketplace.users[_user].purchases.length;
  }

  function read_user_purchase_details(address _user, uint256 _index)
           public
           constant
           returns (address _recipient, uint256 _timestamp, uint256 _amount, uint256 _price)
  {
    _recipient = marketplace.users[_user].purchases[_index].recipient;
    _timestamp = marketplace.users[_user].purchases[_index].timestamp;
    _amount = marketplace.users[_user].purchases[_index].amount;
    _price = marketplace.users[_user].purchases[_index].price;
  }
}

// File: @digix/solidity-collections/contracts/abstract/UintIteratorStorage.sol

pragma solidity ^0.4.19;


/**
  @title Uint Iterator Storage
  @author DigixGlobal Pte Ltd
*/
contract UintIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.Uint;

  /**
    @notice Returns the first item from a `DoublyLinkedList.Uint` list
    @param _list The DoublyLinkedList.Uint list
    @return {"_item": "The first item"}
  */
  function read_first_from_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.start_item();
  }

  /**
    @notice Returns the last item from a `DoublyLinkedList.Uint` list
    @param _list The DoublyLinkedList.Uint list
    @return {"_item": "The last item"}
  */
  function read_last_from_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.end_item();
  }

  /**
    @notice Returns the next item from a `DoublyLinkedList.Uint` list based on the specified `_current_item`
    @param _list The DoublyLinkedList.Uint list
    @param _current_item The current item
    @return {"_item": "The next item"}
  */
  function read_next_from_uints(DoublyLinkedList.Uint storage _list, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.next_item(_current_item);
  }

  /**
    @notice Returns the previous item from a `DoublyLinkedList.Uint` list based on the specified `_current_item`
    @param _list The DoublyLinkedList.Uint list
    @param _current_item The current item
    @return {"_item": "The previous item"}
  */
  function read_previous_from_uints(DoublyLinkedList.Uint storage _list, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _list.previous_item(_current_item);
  }

  /**
    @notice Returns the total count of itemsfrom a `DoublyLinkedList.Uint` list
    @param _list The DoublyLinkedList.Uint list
    @return {"_count": "The total count of items"}
  */
  function read_total_uints(DoublyLinkedList.Uint storage _list)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total();
  }

}

// File: contracts/storage/ProductsListStorage.sol

pragma solidity ^0.4.19;




contract ProductsListStorage is UintIteratorStorage, ResolverClient, DigixConstants {

  using DoublyLinkedList for DoublyLinkedList.Uint;

  struct System {
    mapping (uint256 => Product) products_by_id;
    DoublyLinkedList.Uint products_list;
  }

  struct Product {
    bytes32 document;
    bool enabled;
    uint256 ng_weight;
    uint256 effective_ng_weight;
  }

  System system;

  function ProductsListStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_PRODUCTS_LIST, _resolver));
  }

  /// @notice add a new product to the product list
  /// @param _document the dijix ipfs document
  /// @param _ng_weight the weight of the product
  /// @param _effective_ng_weight the effective weight of the product
  /// @return _success whether the product is successfully added
  /// @return _product_id the product id of the newly created product
  function create_product(bytes32 _document, uint256 _ng_weight, uint256 _effective_ng_weight)
           if_sender_is(CONTRACT_CONTROLLER_PRODUCTS_LIST)
           public
           returns (bool _success, uint256 _product_id)
  {
    require(_ng_weight > 0);
    require(_effective_ng_weight > 0);
    _product_id = system.products_list.total() + 1;
    system.products_by_id[_product_id].enabled = true;
    system.products_by_id[_product_id].document = _document;
    system.products_by_id[_product_id].ng_weight = _ng_weight;
    system.products_by_id[_product_id].effective_ng_weight = _effective_ng_weight;
    _success = system.products_list.append(_product_id);
  }

  /// @notice enable an existing disabled product in the product list
  /// @param _product_id the product id
  /// @return _success whether the product is successfully enabled
  function enable_product(uint256 _product_id)
           if_sender_is(CONTRACT_CONTROLLER_PRODUCTS_LIST)
           public
           returns (bool _success)
  {
    if (system.products_by_id[_product_id].enabled == true || system.products_by_id[_product_id].ng_weight == 0 ) {
      // if product is already enabled or product doesnt exist
      _success = false;
    } else {
      system.products_by_id[_product_id].enabled = true;
      _success = true;
    }
  }

  /// @notice disable an existing enabled product in the product list
  /// @param _product_id the product id
  /// @return _success whether the product is successfully disabled
  function disable_product(uint256 _product_id)
           if_sender_is(CONTRACT_CONTROLLER_PRODUCTS_LIST)
           public
           returns (bool _success)
  {
    if (system.products_by_id[_product_id].enabled == false) {
      _success = false;
    } else {
      system.products_by_id[_product_id].enabled = false;
      _success = true;
    }
  }


  /// @notice read information of an existing product
  /// @param _product_id the product id
  /// @return _document the dijix ipfs document
  /// @return _ng_weight the weight of the product
  /// @return _effective_ng_weight the effective weight of the product
  /// @return _enabled whether the product is enabled
  function read_product(uint256 _product_id)
           public
           constant
           returns (bytes32 _document, uint256 _ng_weight, uint256 _effective_ng_weight, bool _enabled)
  {
    if (system.products_by_id[_product_id].enabled == true) {
      _ng_weight = system.products_by_id[_product_id].ng_weight;
      _effective_ng_weight = system.products_by_id[_product_id].effective_ng_weight;
      _enabled = system.products_by_id[_product_id].enabled;
      _document = system.products_by_id[_product_id].document;
    } else {
      _ng_weight = 0;
      _effective_ng_weight = 0;
      _enabled = system.products_by_id[_product_id].enabled;
      _document = "";
    }
  }

  /// @notice read weight and effective weight of an existing product
  /// @param _product_id the product id
  /// @return _ng_weight the weight of the product
  /// @return _effective_ng_weight the effective weight of the product
  function read_product_ng_weight_and_effective_ng_weight(uint256 _product_id)
           public
           constant
           returns (uint256 _ng_weight, uint256 _effective_ng_weight)
  {
    if (system.products_by_id[_product_id].enabled == true) {
      _ng_weight = system.products_by_id[_product_id].ng_weight;
      _effective_ng_weight = system.products_by_id[_product_id].effective_ng_weight;
    } else {
      _ng_weight = 0;
      _effective_ng_weight = 0;
    }
  }

  /// @notice read the total number of products in product list
  /// @return _total_count total number of products
  function read_products_total()
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = read_total_uints(system.products_list);
  }

  /// @notice read the first product in product list
  /// @return _item first product
  function read_first_product()
           public
           constant
           returns (uint256 _item)
  {
    _item = read_first_from_uints(system.products_list);
  }

  /// @notice read the last product in product list
  /// @return _item last product
  function read_last_product()
           public
           constant
           returns (uint256 _item)
  {
    _item = read_last_from_uints(system.products_list);
  }

  /// @notice read the next product after some product
  /// @param _current_item the current item
  /// @return _item next product
  function read_next_from_product(uint256 _current_item)
           public
           constant
           returns (uint256 _item)
  {
    _item = read_next_from_uints(system.products_list, _current_item);
  }

  /// @notice read the previous product after some product
  /// @param _current_item the current item
  /// @return _item previous product
  function read_previous_from_product(uint256 _current_item)
           public
           constant
           returns (uint256 _item)
  {
    _item = read_previous_from_uints(system.products_list, _current_item);
  }
}

// File: @digix/cdap/contracts/service/DirectoryService.sol

pragma solidity ^0.4.19;

/**
@title Directory Service
@author DigixGlobal
*/
contract DirectoryService {

  /**
  @notice Returns the user's role id
  @param _read_role_id_function Function that returns a role id of a user
  @param _user Id of the user
  @return {"_role_id": "Role id of the user"}
  */
  function internal_get_user_role_id(function (address) external constant returns (uint256) _read_role_id_function, address _user)
           internal
           constant
           returns (uint256 _role_id)
  {
    _role_id = _read_role_id_function(_user);
  }
}

// File: @digix/solidity-collections/contracts/abstract/IndexedAddressIteratorStorage.sol

pragma solidity ^0.4.19;


/**
  @title Indexed Address IteratorStorage
  @author DigixGlobal Pte Ltd
  @notice This contract utilizes: [Doubly Linked List](/DoublyLinkedList)
*/
contract IndexedAddressIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.IndexedAddress;
  /**
    @notice Reads the first item from an Indexed Address Doubly Linked List
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_item" : "First item on the list"}
  */
  function read_first_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (address _item)
  {
    _item = _list.start_item(_collection_index);
  }

  /**
    @notice Reads the last item from an Indexed Address Doubly Linked list
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_item" : "First item on the list"}
  */
  function read_last_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (address _item)
  {
    _item = _list.end_item(_collection_index);
  }

  /**
    @notice Reads the next item from an Indexed Address Doubly Linked List based on the specified `_current_item`
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @param _current_item The current item to use as base line
    @return {"_item": "The next item on the list"}
  */
  function read_next_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.next_item(_collection_index, _current_item);
  }

  /**
    @notice Reads the previous item from an Index Address Doubly Linked List based on the specified `_current_item`
    @param _list The source list
    @param _collection_index Index of the Collection to evaluate
    @param _current_item The current item to use as base line
    @return {"_item" : "The previous item on the list"}
  */
  function read_previous_from_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index, address _current_item)
           internal
           constant
           returns (address _item)
  {
    _item = _list.previous_item(_collection_index, _current_item);
  }


  /**
    @notice Reads the total number of items in an Indexed Address Doubly Linked List
    @param _list  The source list
    @param _collection_index Index of the Collection to evaluate
    @return {"_count": "Length of the Doubly Linked list"}
  */
  function read_total_indexed_addresses(DoublyLinkedList.IndexedAddress storage _list, bytes32 _collection_index)
           internal
           constant
           returns (uint256 _count)
  {
    _count = _list.total(_collection_index);
  }

}

// File: @digix/cdap/contracts/storage/DirectoryStorage.sol

pragma solidity ^0.4.16;



/**
@title Directory Storage contains information of a directory
@author DigixGlobal
*/
contract DirectoryStorage is IndexedAddressIteratorStorage, UintIteratorStorage {

  using DoublyLinkedList for DoublyLinkedList.IndexedAddress;
  using DoublyLinkedList for DoublyLinkedList.Uint;

  struct User {
    bytes32 document;
    bool active;
  }

  struct Group {
    bytes32 name;
    bytes32 document;
    uint256 role_id;
    mapping(address => User) members_by_address;
  }

  struct System {
    DoublyLinkedList.Uint groups;
    DoublyLinkedList.IndexedAddress groups_collection;
    mapping (uint256 => Group) groups_by_id;
    mapping (address => uint256) group_ids_by_address;
    mapping (uint256 => bytes32) roles_by_id;
    bool initialized;
    uint256 total_groups;
  }

  System system;

  /**
  @notice Initializes directory settings
  @return _success If directory initialization is successful
  */
  function initialize_directory()
           internal
           returns (bool _success)
  {
    require(system.initialized == false);
    system.total_groups = 0;
    system.initialized = true;
    internal_create_role(1, "root");
    internal_create_group(1, "root", "");
    _success = internal_update_add_user_to_group(1, tx.origin, "");
  }

  /**
  @notice Creates a new role with the given information
  @param _role_id Id of the new role
  @param _name Name of the new role
  @return {"_success": "If creation of new role is successful"}
  */
  function internal_create_role(uint256 _role_id, bytes32 _name)
           internal
           returns (bool _success)
  {
    require(_role_id > 0);
    require(_name != bytes32(0x0));
    system.roles_by_id[_role_id] = _name;
    _success = true;
  }

  /**
  @notice Returns the role's name of a role id
  @param _role_id Id of the role
  @return {"_name": "Name of the role"}
  */
  function read_role(uint256 _role_id)
           public
           constant
           returns (bytes32 _name)
  {
    _name = system.roles_by_id[_role_id];
  }

  /**
  @notice Creates a new group with the given information
  @param _role_id Role id of the new group
  @param _name Name of the new group
  @param _document Document of the new group
  @return {
    "_success": "If creation of the new group is successful",
    "_group_id: "Id of the new group"
  }
  */
  function internal_create_group(uint256 _role_id, bytes32 _name, bytes32 _document)
           internal
           returns (bool _success, uint256 _group_id)
  {
    require(_role_id > 0);
    require(read_role(_role_id) != bytes32(0x0));
    _group_id = ++system.total_groups;
    system.groups.append(_group_id);
    system.groups_by_id[_group_id].role_id = _role_id;
    system.groups_by_id[_group_id].name = _name;
    system.groups_by_id[_group_id].document = _document;
    _success = true;
  }

  /**
  @notice Returns the group's information
  @param _group_id Id of the group
  @return {
    "_role_id": "Role id of the group",
    "_name: "Name of the group",
    "_document: "Document of the group"
  }
  */
  function read_group(uint256 _group_id)
           public
           constant
           returns (uint256 _role_id, bytes32 _name, bytes32 _document, uint256 _members_count)
  {
    if (system.groups.valid_item(_group_id)) {
      _role_id = system.groups_by_id[_group_id].role_id;
      _name = system.groups_by_id[_group_id].name;
      _document = system.groups_by_id[_group_id].document;
      _members_count = read_total_indexed_addresses(system.groups_collection, bytes32(_group_id));
    } else {
      _role_id = 0;
      _name = "invalid";
      _document = "";
      _members_count = 0;
    }
  }

  /**
  @notice Adds new user with the given information to a group
  @param _group_id Id of the group
  @param _user Address of the new user
  @param _document Information of the new user
  @return {"_success": "If adding new user to a group is successful"}
  */
  function internal_update_add_user_to_group(uint256 _group_id, address _user, bytes32 _document)
           internal
           returns (bool _success)
  {
    if (system.groups_by_id[_group_id].members_by_address[_user].active == false && system.group_ids_by_address[_user] == 0 && system.groups_by_id[_group_id].role_id != 0) {

      system.groups_by_id[_group_id].members_by_address[_user].active = true;
      system.group_ids_by_address[_user] = _group_id;
      system.groups_collection.append(bytes32(_group_id), _user);
      system.groups_by_id[_group_id].members_by_address[_user].document = _document;
      _success = true;
    } else {
      _success = false;
    }
  }

  /**
  @notice Removes user from its group
  @param _user Address of the user
  @return {"_success": "If removing of user is successful"}
  */
  function internal_destroy_group_user(address _user)
           internal
           returns (bool _success)
  {
    uint256 _group_id = system.group_ids_by_address[_user];
    if ((_group_id == 1) && (system.groups_collection.total(bytes32(_group_id)) == 1)) {
      _success = false;
    } else {
      system.groups_by_id[_group_id].members_by_address[_user].active = false;
      system.group_ids_by_address[_user] = 0;
      delete system.groups_by_id[_group_id].members_by_address[_user];
      _success = system.groups_collection.remove_item(bytes32(_group_id), _user);
    }
  }

  /**
  @notice Returns the role id of a user
  @param _user Address of a user
  @return {"_role_id": "Role id of the user"}
  */
  function read_user_role_id(address _user)
           constant
           public
           returns (uint256 _role_id)
  {
    uint256 _group_id = system.group_ids_by_address[_user];
    _role_id = system.groups_by_id[_group_id].role_id;
  }

  /**
  @notice Returns the user's information
  @param _user Address of the user
  @return {
    "_group_id": "Group id of the user",
    "_role_id": "Role id of the user",
    "_document": "Information of the user"
  }
  */
  function read_user(address _user)
           public
           constant
           returns (uint256 _group_id, uint256 _role_id, bytes32 _document)
  {
    _group_id = system.group_ids_by_address[_user];
    _role_id = system.groups_by_id[_group_id].role_id;
    _document = system.groups_by_id[_group_id].members_by_address[_user].document;
  }

  /**
  @notice Returns the id of the first group
  @return {"_group_id": "Id of the first group"}
  */
  function read_first_group()
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_first_from_uints(system.groups);
  }

  /**
  @notice Returns the id of the last group
  @return {"_group_id": "Id of the last group"}
  */
  function read_last_group()
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_last_from_uints(system.groups);
  }

  /**
  @notice Returns the id of the previous group depending on the given current group
  @param _current_group_id Id of the current group
  @return {"_group_id": "Id of the previous group"}
  */
  function read_previous_group_from_group(uint256 _current_group_id)
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_previous_from_uints(system.groups, _current_group_id);
  }

  /**
  @notice Returns the id of the next group depending on the given current group
  @param _current_group_id Id of the current group
  @return {"_group_id": "Id of the next group"}
  */
  function read_next_group_from_group(uint256 _current_group_id)
           view
           external
           returns (uint256 _group_id)
  {
    _group_id = read_next_from_uints(system.groups, _current_group_id);
  }

  /**
  @notice Returns the total number of groups
  @return {"_total_groups": "Total number of groups"}
  */
  function read_total_groups()
           view
           external
           returns (uint256 _total_groups)
  {
    _total_groups = read_total_uints(system.groups);
  }

  /**
  @notice Returns the first user of a group
  @param _group_id Id of the group
  @return {"_user": "Address of the user"}
  */
  function read_first_user_in_group(bytes32 _group_id)
           view
           external
           returns (address _user)
  {
    _user = read_first_from_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }

  /**
  @notice Returns the last user of a group
  @param _group_id Id of the group
  @return {"_user": "Address of the user"}
  */
  function read_last_user_in_group(bytes32 _group_id)
           view
           external
           returns (address _user)
  {
    _user = read_last_from_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }

  /**
  @notice Returns the next user of a group depending on the given current user
  @param _group_id Id of the group
  @param _current_user Address of the current user
  @return {"_user": "Address of the next user"}
  */
  function read_next_user_in_group(bytes32 _group_id, address _current_user)
           view
           external
           returns (address _user)
  {
    _user = read_next_from_indexed_addresses(system.groups_collection, bytes32(_group_id), _current_user);
  }

  /**
  @notice Returns the previous user of a group depending on the given current user
  @param _group_id Id of the group
  @param _current_user Address of the current user
  @return {"_user": "Address of the last user"}
  */
  function read_previous_user_in_group(bytes32 _group_id, address _current_user)
           view
           external
           returns (address _user)
  {
    _user = read_previous_from_indexed_addresses(system.groups_collection, bytes32(_group_id), _current_user);
  }

  /**
  @notice Returns the total number of users of a group
  @param _group_id Id of the group
  @return {"_total_users": "Total number of users"}
  */
  function read_total_users_in_group(bytes32 _group_id)
           view
           external
           returns (uint256 _total_users)
  {
    _total_users = read_total_indexed_addresses(system.groups_collection, bytes32(_group_id));
  }
}

// File: contracts/storage/DigixDirectoryStorage.sol

pragma solidity ^0.4.19;




contract DigixDirectoryStorage is DirectoryStorage, ResolverClient, DigixConstants {

  function DigixDirectoryStorage(address _resolver) public {
    require(init(CONTRACT_STORAGE_DIGIX_DIRECTORY, _resolver));
    require(initialize_directory());
  }

  function create_group(uint256 _role_id, bytes32 _name, bytes32 _document)
           if_sender_is(CONTRACT_CONTROLLER_DIGIX_DIRECTORY)
           public
           returns (bool _success, uint256 _group_id)
  {
    (_success, _group_id) = internal_create_group(_role_id, _name, _document);
    require(_success);
  }

  function create_role(uint256 _role_id, bytes32 _name)
           if_sender_is(CONTRACT_CONTROLLER_DIGIX_DIRECTORY)
           public
           returns (bool _success)
  {
    _success = internal_create_role(_role_id, _name);
    require(_success);
  }

  function update_add_user_to_group(uint256 _group_id, address _user, bytes32 _document)
           if_sender_is(CONTRACT_CONTROLLER_DIGIX_DIRECTORY)
           public
           returns (bool _success)
  {
    _success = internal_update_add_user_to_group(_group_id, _user, _document);
    require(_success);
  }

  function update_remove_group_user(address _user)
           if_sender_is(CONTRACT_CONTROLLER_DIGIX_DIRECTORY)
           public
           returns (bool _success)
  {
    _success = internal_destroy_group_user(_user);
    require(_success);
  }

}

// File: contracts/service/DigixDirectoryService.sol

pragma solidity ^0.4.19;





contract DigixDirectoryService is DirectoryService, ResolverClient, DigixConstants {

  function DigixDirectoryService(address _resolver) public
  {
    require(init(CONTRACT_SERVICE_DIRECTORY, _resolver));
  }

  function directory_storage()
           internal
           constant
           returns (DigixDirectoryStorage _contract)
  {
    _contract = DigixDirectoryStorage(get_contract(CONTRACT_STORAGE_DIGIX_DIRECTORY));
  }

  function get_user_role_id(address _user)
           public
           constant
           returns (uint256 _role_id)
  {
    _role_id = internal_get_user_role_id(directory_storage().read_user_role_id, _user);
  }

}

// File: contracts/common/Controller.sol

pragma solidity ^0.4.19;

/// @title Common controller functions
/// @author DigixGlobal Pte Ltd












contract Controller is ResolverClient, DigixConstants {

  function products_list_storage()
           internal
           constant
           returns (ProductsListStorage _contract)
  {
    _contract = ProductsListStorage(get_contract(CONTRACT_STORAGE_PRODUCTS_LIST));
  }

  function digix_directory_service()
           internal
           constant
           returns (DigixDirectoryService _contract)
  {
    _contract = DigixDirectoryService(get_contract(CONTRACT_SERVICE_DIRECTORY));
  }

  function token_demurrage_service()
           internal
           constant
           returns (TokenDemurrageService _contract)
  {
    _contract = TokenDemurrageService(get_contract(CONTRACT_SERVICE_TOKEN_DEMURRAGE));
  }

  function assets_storage()
           internal
           constant
           returns (AssetsStorage _contract)
  {
    _contract = AssetsStorage(get_contract(CONTRACT_STORAGE_ASSETS));
  }

  function marketplace_storage()
           internal
           constant
           returns (MarketplaceStorage _contract)
  {
    _contract = MarketplaceStorage(get_contract(CONTRACT_STORAGE_MARKETPLACE));
  }

  function gold_token_storage()
           internal
           constant
           returns (GoldTokenStorage _contract)
  {
    _contract = GoldTokenStorage(get_contract(CONTRACT_STORAGE_GOLD_TOKEN));
  }

  function asset_events_storage()
           internal
           constant
           returns (AssetEventsStorage _contract)
  {
    _contract = AssetEventsStorage(get_contract(CONTRACT_STORAGE_ASSET_EVENTS));
  }

  function identity_storage()
           internal
           constant
           returns (IdentityStorage _contract)
  {
    _contract = IdentityStorage(get_contract(CONTRACT_STORAGE_IDENTITY));
  }


  modifier if_caller_is_role(address _caller, uint256 _intended_role_id) {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == _intended_role_id);
    _;
  }

}

// File: contracts/storage/JobIdStorage.sol

pragma solidity ^0.4.19;



contract JobIdStorage is ResolverClient, DigixConstants {

  mapping (bytes32 => bool) used_job_ids;
  mapping (bytes32 => bool) failed_job_ids;

  function JobIdStorage(address _resolver) public
  {
    require(init(CONTRACT_STORAGE_JOB_ID, _resolver));
  }

  function read_if_job_id_is_used(bytes32 _job_id)
           public
           constant
           returns (bool _is_used)
  {
    _is_used = used_job_ids[_job_id];
  }

  function read_if_job_id_is_failed(bytes32 _job_id)
           public
           constant
           returns (bool _is_used)
  {
    _is_used = failed_job_ids[_job_id];
  }

  function set_job_id_as_used(bytes32 _job_id)
           if_sender_is(CONTRACT_CONTROLLER_JOB_ID)
           public
           returns (bool _success)
  {
    used_job_ids[_job_id] = true;
    _success = true;
  }

  function set_job_id_as_failed(bytes32 _job_id)
           if_sender_is(CONTRACT_CONTROLLER_JOB_ID)
           public
           returns (bool _success)
  {
    failed_job_ids[_job_id] = true;
    _success = true;
  }

}

// File: contracts/controller/JobIdController.sol

pragma solidity ^0.4.19;



contract JobIdController is Controller {

  function JobIdController(address _resolver) public
  {
    require(init(CONTRACT_CONTROLLER_JOB_ID, _resolver));
  }

  function job_id_storage()
           internal
           constant
           returns (JobIdStorage _contract)
  {
     _contract = JobIdStorage(get_contract(CONTRACT_STORAGE_JOB_ID));
  }

  function mark_job_id_as_used(bytes32 _job_id)
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           public
           returns (bool _success)
  {
    _success = job_id_storage().set_job_id_as_used(_job_id);
  }

  function mark_job_id_as_failed(address _caller, bytes32 _job_id)
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           public
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_POPADMIN);
    // make sure the job id is not already used
    bool _job_id_is_used = job_id_storage().read_if_job_id_is_used(_job_id);
    require(!_job_id_is_used);
    _success = job_id_storage().set_job_id_as_failed(_job_id);
  }
}

// File: @digix/solidity-collections/contracts/abstract/UintIteratorController.sol

pragma solidity ^0.4.19;

/**
  @title Uint Iterator Interactive
  @author DigixGlobal Pte Ltd
*/


contract UintIteratorController {

  /**
    @notice Returns the first item from the list
    @param _function Function that returns the first item
    @return {"_item": "The first item"}
  */
  function get_first_from_uints(function () constant external returns (uint256) _function)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _function();
  }

  /**
    @notice Returns the last item from the list
    @param _function Function that returns the last item
    @return {"_item": "The last item"}
  */
  function get_last_from_uints(function () constant external returns (uint256) _function)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _function();
  }

  /**
    @notice Returns the next item from the list based on the `_current_item`
    @param _function Function that returns the next item
    @param _current_item The current item
    @return {"_item": "The next item"}
  */
  function get_next_from_uints(function (uint256) constant external returns (uint256) _function, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _function(_current_item);
  }

  /**
    @notice Returns the previous item from the list based on the `_current_item`
    @param _function Function that returns the previous item
    @param _current_item The current item
    @return {"_item": "The next item"}
  */
  function get_previous_from_uints(function (uint256) constant external returns (uint256) _function, uint256 _current_item)
           internal
           constant
           returns (uint256 _item)
  {
    _item = _function(_current_item);
  }

  /**
    @notice Returns the total number of items from the list
    @param _function Function that returns the total number of items
    @return {"_total_count": "The total number of items"}
  */
  function get_total_uints(function () constant external returns (uint256) _function)
           internal
           constant
           returns (uint256 _total_count)
  {
    _total_count = _function();
  }

}

// File: contracts/controller/ProductsListController.sol

pragma solidity ^0.4.19;




contract ProductsListController is Controller, UintIteratorController {

  function ProductsListController(address _resolver) public
  {
    require(init(CONTRACT_CONTROLLER_PRODUCTS_LIST, _resolver));
  }

  /// @notice add a new product to the product list
  /// @param _document the dijix ipfs document
  /// @param _ng_weight the weight of the product
  /// @param _effective_ng_weight the effective weight of the product
  /// @return _success whether the product is successfully added
  /// @return _product_id the product id of the newly created product
  function put_product(bytes32 _document, uint256 _ng_weight, uint256 _effective_ng_weight)
           if_sender_is(CONTRACT_INTERACTIVE_PRODUCTS_LIST)
           public
           returns (bool _success, uint256 _product_id)
  {
    (_success, _product_id) = products_list_storage().create_product(_document, _ng_weight, _effective_ng_weight);
  }

  /// @notice get information of an existing product
  /// @param _item the product id
  /// @return _document the dijix ipfs document
  /// @return _ng_weight the weight of the product
  /// @return _effective_ng_weight the effective weight of the product
  /// @return _enabled whether the product is enabled
  function get_product(uint256 _item)
           public
           constant
           returns (bytes32 _document, uint256 _ng_weight, uint256 _effective_ng_weight, bool _enabled)
  {
    (_document, _ng_weight, _effective_ng_weight, _enabled) = products_list_storage().read_product(_item);
  }

  /// @notice enable an existing disabled product in the product list
  /// @param _item the product id
  /// @return _success whether the product is successfully enabled
  function enable_product(uint256 _item)
           if_sender_is(CONTRACT_INTERACTIVE_PRODUCTS_LIST)
           public
           returns (bool _success)
  {
    _success = products_list_storage().enable_product(_item);
  }

  /// @notice disable an existing enabled product in the product list
  /// @param _item the product id
  /// @return _success whether the product is successfully disabled
  function disable_product(uint256 _item)
           if_sender_is(CONTRACT_INTERACTIVE_PRODUCTS_LIST)
           public
           returns (bool _success)
  {
    _success = products_list_storage().disable_product(_item);
  }

  /// @notice get the total number of products in product list
  /// @return _total_count total number of products
  function get_products_total()
           public
           constant
           returns (uint256 _total_count)
  {
    _total_count = get_total_uints(products_list_storage().read_products_total);
  }

  /// @notice get the first product in product list
  /// @return _item first product
  function get_first_product()
           public
           constant
           returns (uint256 _item)
  {
    _item = get_first_from_uints(products_list_storage().read_first_product);
  }

  /// @notice get the last product in product list
  /// @return _item last product
  function get_last_product()
           public
           constant
           returns (uint256 _item)
  {
    _item = get_last_from_uints(products_list_storage().read_last_product);
  }

  /// @notice get the next product after some product
  /// @param _current_item the current item
  /// @return _item next product
  function get_next_from_product(uint256 _current_item)
           public
           constant
           returns (uint256 _item)
  {
    _item = get_next_from_uints(products_list_storage().read_next_from_product, _current_item);
  }

  /// @notice get the previous product after some product
  /// @param _current_item the current item
  /// @return _item previous product
  function get_previous_from_product(uint256 _current_item)
           public
           constant
           returns (uint256 _item)
  {
    _item = get_previous_from_uints(products_list_storage().read_previous_from_product, _current_item);
  }

}

// File: @digix/solidity-collections/contracts/abstract/IndexedBytesIteratorController.sol

pragma solidity ^0.4.19;


/**
  @title Indexed Bytes Iterator Controller
  @author DigixGlobal Pte Ltd
  @notice This contract utilizes: [Indexed Bytes Iterator Storage](/IndexedBytesIteratorStorage)
*/
contract IndexedBytesIteratorController {

  /**
    @notice Gets the first item from an indexed Bytes Doubly Linked List
    @param _function Function that returns the first item in the collection
    @param _collection_index Index of the Collection to evaluate
    @return {"_item":"First item in the list"}
  */
  function get_first_from_indexed_bytesarray(function (bytes32) constant external returns (bytes32) _function, bytes32 _collection_index)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_collection_index);
  }

  /**
    @notice Gets the last item from an indexed Bytes Doubly Linked List
    @param _function Function that returns the last item in the collection
    @param _collection_index Index of the Collection to evaluate
    @return {"_item": "The last item in the list"}
  */
  function get_last_from_indexed_bytesarray(function (bytes32) constant external returns (bytes32) _function, bytes32 _collection_index)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_collection_index);
  }

  /**
    @notice Gets the next item from an indexed Bytes Doubly Linked List using the spcified `_current_item`
    @param _function Function that returns the next item in the collection
    @param _collection_index Index of the Collection to evaluate
    @param _current_item The current item to be used as base line
    @return {"_item":"The next item in the list"}
  */
  function get_next_from_indexed_bytesarray(function (bytes32, bytes32) constant external returns (bytes32) _function, bytes32 _collection_index, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_collection_index, _current_item);
  }

  /**
    @notice Gets the previous item from an indexed Bytes Doubly Linked List using the spcified `_current_item`
    @param _function Function that returns the previous item in the collection
    @param _collection_index Index of the Collection to evaluate
    @param _current_item The current item to be used as base line
    @return {"_item":"The previous item in the list"}
  */
  function get_previous_from_indexed_bytesarray(function (bytes32, bytes32) constant external returns (bytes32) _function, bytes32 _collection_index, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_collection_index, _current_item);
  }

  /**
    @notice Gets the total number of items in an Indexed Bytes Doubly Linked List
    @param _function Function that returns the length of the collection
    @param _collection_index Index of the Collection to evaluate
    @return {"_total_count":"length of the Doubly Linked List"}
  */
  function get_total_indexed_bytesarray(function (bytes32) constant external returns (uint256) _function, bytes32 _collection_index)
           internal
           constant
           returns (uint256 _total_count)
  {
    _total_count = _function(_collection_index);
  }

}

// File: contracts/controller/AssetsController.sol

pragma solidity ^0.4.19;








contract AssetsController is IndexedBytesIteratorController, Controller {

  using Types for Types.MutableUint;

  function AssetsController(address _resolver) public
  {
    require(init(CONTRACT_CONTROLLER_ASSETS, _resolver));
  }

  function products_list_controller()
           internal
           constant
           returns (ProductsListController _contract)
  {
    _contract = ProductsListController(get_contract(CONTRACT_CONTROLLER_PRODUCTS_LIST));
  }

  /// @notice called by popadmin to create a new asset item and put it to `vendor_order` state
  function put_init_item(address _caller, uint256 _product_id, address _mint_target)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, bytes32 _item)
  {
     uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
     bool _enabled;
     uint256 _ng_weight;
     uint256 _effective_ng_weight;
     require(_mint_target != address(0x0));

     (,_ng_weight,_effective_ng_weight,_enabled) = products_list_controller().get_product(_product_id);
     require(_enabled);
     (_success, _item) = assets_storage().create_init_item(_role_id, _product_id, _ng_weight, _effective_ng_weight, _mint_target);
     if (_success) {
       asset_events_storage().add_asset_event(_item, ASSET_EVENT_CREATED_VENDOR_ORDER);
     }
  }

  function put_init_item_transfer(address _caller, uint256 _product_id, address _mint_target)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, bytes32 _item)
  {
     uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
     bool _enabled;
     uint256 _ng_weight;
     uint256 _effective_ng_weight;
     require(_mint_target != address(0x0));

     (,_ng_weight,_effective_ng_weight,_enabled) = products_list_controller().get_product(_product_id);
     require(_enabled);
     (_success, _item) = assets_storage().create_init_item_transfer(_role_id, _product_id, _ng_weight, _effective_ng_weight, _mint_target);
     if (_success) {
       asset_events_storage().add_asset_event(_item, ASSET_EVENT_CREATED_TRANSFER_ORDER);
     }
  }

  function put_global_audit(address _caller, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_AUDITOR);
    _success = assets_storage().create_global_audit(_document);
  }

  /// @notice called by a vendor to fulfill a vendor order, or by an xferauth to fulfill a transfered-in item
  function patch_item_fulfill_order(address _caller, bytes32 _item, bytes32 _serial, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, uint256 _from_state, uint256 _new_state)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    (_success, _from_state, _new_state) = assets_storage().update_item_fulfill(_role_id, _item, _serial, _document);
    if (_success) {
      if (_role_id == ROLE_VENDOR) {  // if this is a vendor
        asset_events_storage().add_asset_event(_item, ASSET_EVENT_FULFILLED_VENDOR_ORDER);
      } else {
        asset_events_storage().add_asset_event(_item, ASSET_EVENT_FULFILLED_TRANSFER_ORDER);
      }
    }
  }

  /// @notice called by a custodian to accept an asset into their vault, hence minting new tokens
  function patch_item_mint(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, address _mint_target, uint256 _effective_ng_weight, uint256 _from_state, uint256 _new_state)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    (_success, _mint_target, _effective_ng_weight, _from_state, _new_state) = assets_storage().update_item_mint(_role_id, _item, _document);
    if (_success) {
      require(token_demurrage_service().deduct_demurrage(_mint_target));
      Types.MutableUint memory _user_balance;
      Types.MutableUint memory _total_supply;
      Types.MutableUint memory _effective_total_supply;

      _user_balance.pre = token_demurrage_service().show_demurraged_balance(_mint_target);
      (_total_supply.pre, _effective_total_supply.pre) = gold_token_storage().read_supply();

      _user_balance = _user_balance.add(_effective_ng_weight);
      _total_supply = _total_supply.add(_effective_ng_weight);
      _effective_total_supply = _effective_total_supply.add(_effective_ng_weight);

      require(gold_token_storage().update_balances_after_mint(_mint_target, _user_balance.post, _total_supply.post, _effective_total_supply.post));
      asset_events_storage().add_asset_event(_item, ASSET_EVENT_MINTED);
      TokenLoggerCallback(get_contract(CONTRACT_INTERACTIVE_TOKEN)).log_mint(_mint_target, _effective_ng_weight);
    }
  }

  /// @notice called by popadmin to let a KYC approved user who has previously recasted to get a gold bar
  function patch_item_redeem(address _caller, bytes32 _item, address _redeem_user, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    address _redeem_for;
    uint256 _redeem_deadline;

    (,,,,,,,_redeem_deadline) = assets_storage().read_asset_info(_item);
    (,_redeem_for,,) = assets_storage().read_asset_details(_item);
    require(_redeem_for == _redeem_user); // make sure that _redeem_user matches _redeem_for of the asset item
    require(now < _redeem_deadline); // must redeem before the redeem deadline;

    _success = assets_storage().update_item_redeem(_role_id, _item, _document);
    if (_success) {
      asset_events_storage().add_asset_event(_item, ASSET_EVENT_REDEEMED);
    }
  }

  /// @notice (an auditor) change an asset item's state to `audit_failure`
  /// @param _caller the address of the caller (should be an auditor)
  /// @param _item the id of the asset item to be marked as `audit_failure`
  /// @param _document the support document supplied by the auditor
  /// @return _success whether the item is successfully marked as `audit_failure`
  /// @return _from_state the old state of the asset item (should be `minted`)
  /// @return _to_state the new state of the asset item (should be `audit_failure`)
  function patch_item_to_audit_failure(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, uint256 _from_state, uint256 _new_state)
  {
    // update token effective supply, set state, add document
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    (_success, _from_state, _new_state) = assets_storage().update_item_to_audit_failure(_role_id, _item, _document);
    if (_success) {
      uint256 _effective_ng_weight;
      ( ,,_effective_ng_weight,,,,,) = assets_storage().read_asset_info(_item);
      uint256 _effective_total_supply = gold_token_storage().read_effective_total_supply();
      _effective_total_supply = MathUtils.subtract(_effective_total_supply, _effective_ng_weight);
      _success = _success && gold_token_storage().update_effective_supply(_effective_total_supply);
      if (_success) {
        asset_events_storage().add_asset_event(_item, ASSET_EVENT_FAILED_AUDIT);
      }
    }
  }

  /// @notice (a popadmin/the recaster) remint a recasted asset to the recaster
  function patch_item_remint(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    address _recaster;
    uint256 _effective_ng_weight;
    uint256 _redeem_deadline;
    (,,_effective_ng_weight,,,,,_redeem_deadline) = assets_storage().read_asset_info(_item);
    (,_recaster,,) = assets_storage().read_asset_details(_item);
    require(token_demurrage_service().deduct_demurrage(_recaster));

    // must be a popadmin after 30 days, or the recaster himself
    if (_role_id == ROLE_POPADMIN) {
      require(now > _redeem_deadline);
    } else {
      require(_caller == _recaster);
      _role_id = ROLE_KYC_RECASTER;
    }
    _success = assets_storage().update_item_remint(_role_id, _item, _document);

    // now mint back the bar, update effective and total supply
    Types.MutableUint memory _user_balance;
    Types.MutableUint memory _total_supply;
    Types.MutableUint memory _effective_total_supply;

    _user_balance.pre = token_demurrage_service().show_demurraged_balance(_recaster);
    (_total_supply.pre, _effective_total_supply.pre) = gold_token_storage().read_supply();

    _user_balance = _user_balance.add(_effective_ng_weight);
    _total_supply = _total_supply.add(_effective_ng_weight);
    _effective_total_supply = _effective_total_supply.add(_effective_ng_weight);

    require(gold_token_storage().update_balances_after_mint(_recaster, _user_balance.post, _total_supply.post, _effective_total_supply.post));
    asset_events_storage().add_asset_event(_item, ASSET_EVENT_REMINTED);
    TokenLoggerCallback(get_contract(CONTRACT_INTERACTIVE_TOKEN)).log_mint(_recaster, _effective_ng_weight);
  }

  struct Replacement {
    bool product_enabled;
    uint256 product_effective_ng_weight;
    uint256 product_ng_weight;
    uint256 failed_item_effective_ng_weight;
    uint256 failed_item_state_id;
    bytes32 current_replacement_item;
    uint256 state_of_current_replacement_item;
  }
  /// @notice (popadmin) create a new asset item to replace an item that failed audit
  function put_init_item_as_replacement(address _caller, uint256 _product_id, bytes32 _old_item)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, bytes32 _replacement_item)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    Replacement memory _replacement;

    ( ,,_replacement.failed_item_effective_ng_weight,,_replacement.failed_item_state_id,,,) = assets_storage().read_asset_info(_old_item);
    (,,_replacement.current_replacement_item,) = assets_storage().read_asset_details(_old_item);
    (,_replacement.product_ng_weight, _replacement.product_effective_ng_weight, _replacement.product_enabled) = products_list_controller().get_product(_product_id);

    if (_replacement.current_replacement_item != 0) {
      // the failed item A is already being replaced by some asset B
      // we will only allow re-replacing A if B is currently in admin_failure
      _replacement.state_of_current_replacement_item = assets_storage().read_asset_state(_replacement.current_replacement_item);
      require(_replacement.state_of_current_replacement_item == STATE_ADMIN_FAILURE);
    }

    if (_replacement.product_enabled && _replacement.failed_item_state_id == STATE_AUDIT_FAILURE && _replacement.failed_item_effective_ng_weight == _replacement.product_effective_ng_weight) {
      (_success, _replacement_item) = assets_storage().create_init_item_as_replacement(_role_id, _product_id, _replacement.product_ng_weight, _replacement.product_effective_ng_weight, _old_item);
      if (_success) {
        asset_events_storage().add_asset_event(_replacement_item, ASSET_EVENT_CREATED_REPLACEMENT_ORDER);
      }
    } else {
      _success = false;
      _replacement_item = "";
    }
  }

  /// @notice (vendor) change the state of an asset item from `replacement_order` to `replacement_delivery`
  function patch_item_fulfill_replacement_order(address _caller, bytes32 _item, bytes32 _serial, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    _success = assets_storage().update_item_fulfill_replacement(_role_id, _item, _serial, _document);
    if (_success) {
      asset_events_storage().add_asset_event(_item, ASSET_EVENT_FULFILLED_REPLACEMENT_ORDER);
    }
  }

  /// @notice (custodian) accepts an asset item from `replacement_delivery` state to `minted`
  function patch_item_mint_replacement(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success, uint256 _effective_ng_weight)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    (_success, _effective_ng_weight) = assets_storage().update_item_mint_replacement(_role_id, _item, _document);
    if (_success) {
      uint256 _effective_total_supply = gold_token_storage().read_effective_total_supply();
      _effective_total_supply = MathUtils.add(_effective_total_supply, _effective_ng_weight);
      require(gold_token_storage().update_effective_supply(_effective_total_supply));
      asset_events_storage().add_asset_event(_item, ASSET_EVENT_MINTED_REPLACEMENT);
    }
  }

  /// @notice (popadmin) change an asset item that has not been minted to `audit_failure`
  function patch_item_admin_fail(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    _success = assets_storage().update_item_admin_fail(_role_id, _item, _document);
    if (_success) {
      asset_events_storage().add_asset_event(_item, ASSET_EVENT_ADMIN_FAILED);
    }
  }

  function patch_item_add_document(address _caller, bytes32 _item, bytes32 _document)
           public
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    if (_role_id == ROLE_POPADMIN) {
      _success = assets_storage().update_item_add_document(_item, _document);
    } else {
      _success = false;
    }
  }

  function change_redeem_period(address _caller, uint256 _redeem_period)
           if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
           public
           returns (bool _success)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_POPADMIN);
    _success = assets_storage().update_redeem_period(_redeem_period);
  }
}

// File: contracts/service/VerificationService.sol

pragma solidity ^0.4.19;



contract VerificationService is ResolverClient, DigixConstantsElectron  {

    function VerificationService(address _resolver) public {
        require(init(CONTRACT_SERVICE_VERIFICATION, _resolver));
    }

    struct Message {
        bytes userAddress;
        bytes kycTier;
        bytes kycExpiry;
        bytes blockNumber;
        bytes price;
    }

    struct KycMessage {
        bytes userAddress;
        bytes kycTier;
        bytes kycExpiry;
        bytes blockNumber;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function convertToBytes(
        address user_address,
        uint kyc_tier,
        uint kyc_expiry,
        uint block_number,
        uint price
    )
        internal
        pure
        returns (Message)
    {
        return Message(
            addressToBytes(user_address),
            intToBytes(kyc_tier),
            intToBytes(kyc_expiry),
            intToBytes(block_number),
            intToBytes(price)
        );
    }

    function convertKycMessageToBytes(
        address user_address,
        uint kyc_tier,
        uint kyc_expiry,
        uint block_number
    )
        internal
        pure
        returns (KycMessage)
    {
        return KycMessage(
            addressToBytes(user_address),
            intToBytes(kyc_tier),
            intToBytes(kyc_expiry),
            intToBytes(block_number)
        );
    }

    function verify_user_kyc(
        address user_address,
        uint kyc_tier,
        uint kyc_expiry,
        uint block_number,
        bytes signature,
        address signer
    )
        public
        pure
        returns (bool)
    {
        bytes memory delimiter = new bytes(1);
        delimiter[0] = 0x3a;

        KycMessage memory _m = convertKycMessageToBytes(user_address, kyc_tier, kyc_expiry, block_number);

        bytes memory lengthBytes = intToBytes(_m.userAddress.length + _m.kycTier.length + _m.kycExpiry.length + _m.blockNumber.length + 4);

        bytes memory message = concat_bytes(
            concat_bytes(
                concat_bytes("\x19Ethereum Signed Message:\n", lengthBytes),
                concat_bytes(delimiter, _m.userAddress)
            ),
            concat_bytes(
                concat_bytes(
                    concat_bytes(delimiter, _m.kycTier),
                    concat_bytes(delimiter, _m.kycExpiry)
                ),
                concat_bytes(delimiter, _m.blockNumber)
            )
        );

        Signature memory _s = parse_signature(signature);
        return ecrecover(keccak256(message), _s.v, _s.r, _s.s) == signer;
    }

    function verify_signed_price(
        address user_address,
        uint kyc_tier,
        uint kyc_expiry,
        uint block_number,
        uint price,
        bytes signature,
        address signer
    )
        public
        pure
        returns (bool)
    {
        bytes memory delimiter = new bytes(1);
        delimiter[0] = 0x3a;

        Message memory _m = convertToBytes(user_address, kyc_tier, kyc_expiry, block_number, price);

        bytes memory lengthBytes = intToBytes(_m.userAddress.length + _m.kycTier.length + _m.kycExpiry.length + _m.blockNumber.length + _m.price.length + 5);

        bytes memory message = concat_bytes(
            concat_bytes(
                concat_bytes("\x19Ethereum Signed Message:\n", lengthBytes),
                concat_bytes(
                    concat_bytes(delimiter, _m.userAddress),
                      concat_bytes(delimiter, _m.kycTier)
                )
            ),
            concat_bytes(
                concat_bytes(
                    concat_bytes(delimiter, _m.kycExpiry),
                    concat_bytes(delimiter, _m.blockNumber)
                ),
                concat_bytes(delimiter, _m.price)
            )
        );

        Signature memory _s = parse_signature(signature);
        return ecrecover(keccak256(message), _s.v, _s.r, _s.s) == signer;
    }

    function parse_signature(bytes _sigbytes) internal pure returns (Signature) {
        bytes32 _r;
        bytes32 _s;
        uint8 _v;

        assembly {
            _r := mload(add(_sigbytes, 32))
            _s := mload(add(_sigbytes, 64))
            _v := byte(0, mload(add(_sigbytes, 96)))
        }
        if (_v < 27) {
            _v += 27;
        }

        require(_v == 27 || _v == 28);
        return Signature(_r, _s, _v);
    }

    function concat_bytes(bytes b1, bytes b2) internal pure returns (bytes b) {
        b = new bytes(b1.length + b2.length);

        for (uint i=0; i<b1.length;i++) {
            b[i] = b1[i];
        }
        for (i=0; i<b2.length; i++) {
            b[i + b1.length] = b2[i];
        }
    }

    function addressToBytes(address a) internal pure returns (bytes result) {
        bytes32 temp = bytes32(a);
        result = new bytes(40);
        for (uint i=0;i<20;i++) {
            result[i*2] = hexToChar(uint8(temp[12+i]) / 16);
            result[i*2+1] = hexToChar(uint8(temp[12+i]) % 16);
        }
    }

    function hexToChar(uint8 hexadecimal) internal pure returns (byte c) {
        if (hexadecimal >= 10) {
            c = byte(hexadecimal + 97 - 10); // 97 = 'a'
        } else {
            c = byte(hexadecimal + 48); // 48 = '0'
        }
    }

    function intToBytes(uint256 number) internal pure returns (bytes result) {
        require(number > 0);
        bytes memory fullString = new bytes(32);
        uint l = 0;
        while (number != 0) {
            fullString[l++] = byte(number % 10 + 48);
            number = number / 10;
        }

        result = new bytes(l);

        for (uint i=0;i<l;i++) {
            result[i] = fullString[l-i-1];
        }
    }
}

// File: contracts/storage/AssetsStorageElectron.sol

pragma solidity ^0.4.19;






contract AssetsStorageElectron is ResolverClient, BytesIteratorStorage, DigixConstants, DigixConstantsElectron {

  using DoublyLinkedList for DoublyLinkedList.Bytes;

  uint256 public recast_block_threshold;
  mapping (bytes32 => bytes32) custodian_by_asset_id;
  mapping (bytes32 => bytes32) custodian_by_global_audit_doc;
  mapping (bytes32 => uint256) global_audit_timestamp;
  mapping (bytes32 => bool) valid_custodians;
  DoublyLinkedList.Bytes all_custodians;

  mapping(bytes32 => uint256) public remint_item_blocked_at;
  uint256 public remint_item_block_duration;

  function AssetsStorageElectron(address _resolver) public {
    require(init(CONTRACT_STORAGE_ASSETS_ELECTRON, _resolver));
    recast_block_threshold = 20;
    remint_item_block_duration = 1 days;
  }

  function set_remint_item_block_duration(uint256 _duration)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
  {
    remint_item_block_duration = _duration;
  }

  function set_remint_item_blocked_at(bytes32 _item, uint256 _timestamp)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_RECAST)
  {
    remint_item_blocked_at[_item] = _timestamp;
  }

  function add_custodian(bytes32 _custodian)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    if (valid_custodians[_custodian] == false) {
      valid_custodians[_custodian] = true;
      _success = all_custodians.append(_custodian);
    }
  }

  function set_asset_custodian(bytes32 _item, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    require(custodian_by_asset_id[_item] == bytes32(0x0));
    custodian_by_asset_id[_item] = _custodian;
    _success = true;
  }

  function set_audit_custodian(bytes32 _doc, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    require(custodian_by_global_audit_doc[_doc] == bytes32(0x0));
    custodian_by_global_audit_doc[_doc] = _custodian;
    _success = true;
  }

  function set_audit_timestamp(bytes32 _doc, uint256 _timestamp)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    require(global_audit_timestamp[_doc] == 0);
    global_audit_timestamp[_doc] = _timestamp;
    _success = true;
  }

  function set_recast_block_threshold(uint256 _block_threshold)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    recast_block_threshold = _block_threshold;
    _success = true;
  }

  function update_asset_custodian(bytes32 _item, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_CONTROLLER_ASSETS_ELECTRON)
    returns (bool _success)
  {
    require(custodian_by_asset_id[_item] != bytes32(0x0));
    custodian_by_asset_id[_item] = _custodian;
    _success = true;
  }

  function read_asset_custodian(bytes32 _item)
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = custodian_by_asset_id[_item];
  }

  function read_audit_custodian(bytes32 _doc)
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = custodian_by_global_audit_doc[_doc];
  }

  function read_audit_info(bytes32 _doc)
    public
    constant
    returns (bytes32 _custodian, uint256 _timestamp)
  {
    _custodian = custodian_by_global_audit_doc[_doc];
    _timestamp = global_audit_timestamp[_doc];
  }

  function is_valid_custodian(bytes32 _custodian)
    public
    constant
    returns (bool _valid)
  {
    _valid = valid_custodians[_custodian];
  }

  function read_first_custodian()
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = read_first_from_bytesarray(all_custodians);
  }

  function read_last_custodian()
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = read_last_from_bytesarray(all_custodians);
  }

  function read_next_custodian(bytes32 _custodian)
    public
    constant
    returns (bytes32 _next_custodian)
  {
    _next_custodian = read_next_from_bytesarray(all_custodians, _custodian);
  }

  function read_previous_custodian(bytes32 _custodian)
    public
    constant
    returns (bytes32 _previous_custodian)
  {
    _previous_custodian = read_previous_from_bytesarray(all_custodians, _custodian);
  }

  function read_total_custodians()
    public
    constant
    returns (uint256 _total_count)
  {
    _total_count = all_custodians.total();
  }
}

// File: contracts/controller_electron/AssetsRecastControllerElectron.sol

pragma solidity ^0.4.19;








contract AssetsRecastControllerElectron is IndexedBytesIteratorController, Controller, DigixConstantsElectron {

  using Types for Types.MutableUint;

  function AssetsRecastControllerElectron(address _resolver) public
  {
    require(init(CONTRACT_CONTROLLER_ASSETS_RECAST, _resolver));
  }

  function products_list_controller()
           internal
           constant
           returns (ProductsListController _contract)
  {
    _contract = ProductsListController(get_contract(CONTRACT_CONTROLLER_PRODUCTS_LIST));
  }

  function verification_service()
      internal
      constant
      returns (VerificationService _contract)
  {
      _contract = VerificationService(get_contract(CONTRACT_SERVICE_VERIFICATION));
  }

  function assets_storage_electron()
      internal
      constant
      returns (AssetsStorageElectron _contract)
  {
      _contract = AssetsStorageElectron(get_contract(CONTRACT_STORAGE_ASSETS_ELECTRON));
  }

  struct User {
    address account;
    Types.MutableUint balance;
    bool no_recast_fee;
    uint256 to_be_deducted;
  }

  struct Config {
    Types.MutableUint collector_balance;
    uint256 base;
    uint256 rate;
    address collector;
  }

  struct Recast {
    User user;
    Config config;
    Types.MutableUint total_supply;
    Types.MutableUint effective_total_supply;
    uint256 fee;
  }

  function calculate_recast_struct(
      address _recast_user,
      uint256 _effective_ng_weight
  )
      internal
      returns (Recast _recast)
  {
    require(token_demurrage_service().deduct_demurrage(_recast_user));

    (_recast.config.base, _recast.config.rate, _recast.total_supply.pre, _recast.effective_total_supply.pre, _recast.config.collector, _recast.config.collector_balance.pre) = gold_token_storage().read_recast_config();
    (_recast.user.balance.pre, _recast.user.no_recast_fee) = gold_token_storage().read_user_for_recast(_recast_user);

    // to_be_deducted is the amount to be deducted from user's balance after the recast
    _recast.user.to_be_deducted = _effective_ng_weight;

    if (_recast.user.no_recast_fee == false) {
      _recast.fee = MathUtils.calculate_recast_fee(_effective_ng_weight, _recast.config.base, _recast.config.rate);
      _recast.user.to_be_deducted = MathUtils.add(_recast.user.to_be_deducted, _recast.fee);
    } else {
      _recast.fee = 0; //just to make it explicit
    }
  }

  /// @notice check if kyc information is valid for this user
  function check_user_kyc(
      address _recaster,
      uint256 _kyc_tier,
      uint256 _kyc_expiry,
      uint256 _block_number,
      address _signer,
      bytes _signature
  )
      public
      constant
      if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
      returns (bool)
  {
      // verify that the signature is valid
      require(verification_service().verify_user_kyc(
          _recaster, _kyc_tier, _kyc_expiry,
          _block_number, _signature, _signer
      ));

      // make sure the block number is within the threshold for recast signatures
      uint256 threshold_allowed = assets_storage_electron().recast_block_threshold();
      require(_block_number + threshold_allowed >= block.number);

      // make sure the kyc data comes under kyc approved
      require((_kyc_tier == 2) && (_kyc_expiry > now));

      // make sure the signer is the valid role for this purpose
      uint256 _role_id = digix_directory_service().get_user_role_id(_signer);
      require(_role_id == ROLE_ASSET_RECAST_SIGNER);

      return true;
  }

  /// @notice called by a KYC approved user to recast an asset item
  function patch_item_recast(
      address _recast_user,
      bytes32 _item,
      bytes32 _document
  )
      public
      if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
      returns (bool _success, uint256 _effective_ng_weight)
  {
    Recast memory _recast;
    (,,_effective_ng_weight,,,,,) = assets_storage().read_asset_info(_item);

    _recast = calculate_recast_struct(_recast_user, _effective_ng_weight);

    require(_recast.config.collector != _recast_user); // disallow the recast collector to recast

    _recast.user.balance = _recast.user.balance.subtract(_recast.user.to_be_deducted);
    _recast.total_supply = _recast.total_supply.subtract(_effective_ng_weight);
    _recast.effective_total_supply = _recast.effective_total_supply.subtract(_effective_ng_weight);
    _recast.config.collector_balance = _recast.config.collector_balance.add(_recast.fee);

    require(gold_token_storage().update_balances_after_recast(_recast_user, _recast.user.balance.post, _recast.config.collector_balance.post, _recast.total_supply.post, _recast.effective_total_supply.post));
    // mark asset item in AssetsStorage as `recasted` only at the end
    require(assets_storage().update_item_recast(0, _item, _recast_user, _document));
    asset_events_storage().add_asset_event(_item, ASSET_EVENT_RECASTED);
    if (_recast.fee > 0) {
      TokenLoggerCallback(get_contract(CONTRACT_INTERACTIVE_TOKEN)).log_recast_fees(_recast_user, _recast.config.collector, _recast.fee);
    }
    TokenLoggerCallback(get_contract(CONTRACT_INTERACTIVE_TOKEN)).log_recast(_recast_user, _effective_ng_weight);
    _success = true;
  }

  function update_remint_item_block_duration(address _caller, uint256 _duration)
      public
      if_sender_is(CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN_ELECTRON)
  {
      uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
      require(_role_id == ROLE_ELECTRON_MARKETPLACE_ADMIN);

      assets_storage_electron().set_remint_item_block_duration(_duration);
  }

  function is_remint_item_blocked(bytes32 _item)
      public
      returns (bool _blocked)
  {
      uint256 _block_duration = assets_storage_electron().remint_item_block_duration();
      uint256 _blocked_at = assets_storage_electron().remint_item_blocked_at(_item);

      if (now < _blocked_at + _block_duration) {
        _blocked = true;
      }
  }

  function set_remint_item_blocked(address _caller, bytes32 _item)
      public
      if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
  {
      uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
      require(_role_id == ROLE_POPADMIN);

      require(assets_storage().read_asset_state(_item) == STATE_RECASTED);

      assets_storage_electron().set_remint_item_blocked_at(_item, now);
  }
}

// File: @digix/solidity-collections/contracts/abstract/BytesIteratorController.sol

pragma solidity ^0.4.19;


/**
  @title Bytes Iterator Controller
  @author DigixGlobal Pte Ltd
  @notice This contract utilizes: [Bytes Iterator Storage](/BytesIteratorStorage)
*/
contract BytesIteratorController {

  /**
    @notice Encapsulated function that gets the first item from the list of Bytes
    @param _function Function that returns the First item
    @return {"_item": "The first item"}
  */
  function get_first_from_bytesarray(function () constant external returns (bytes32) _function)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function();
  }

  /**
    @notice Encapsulated function that gets the last item from the list of Bytes
    @param _function Function that returns the Last item
    @return {"_item": "The last item"}
  */
  function get_last_from_bytesarray(function () constant external returns (bytes32) _function)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function();
  }

  /**
    @notice Encapsulated function that gets the next item from the list of Bytes based on the specified `_current_item`
    @param _function Function that returns the Next item
    @param _current_item The item to be used as base line
    @return {"_item": "The next item"}
  */
  function get_next_from_bytesarray(function (bytes32) constant external returns (bytes32) _function, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_current_item);
  }

   /**
    @notice Encapsulated function that gets the previous item from the list of Bytes based on the specified `_current_item`
    @param _function Function that returns the Previous item
    @param _current_item The item to be used as base line
    @return {"_item": "The previous item"}
  */
  function get_previous_from_bytesarray(function (bytes32) constant external returns (bytes32) _function, bytes32 _current_item)
           internal
           constant
           returns (bytes32 _item)
  {
    _item = _function(_current_item);
  }

  /**
    @notice Encapsulate function that gets the length of list
    @param _function Function that returns the length of the list
    @return {"_total_count": "Length of the list"}
  */
  function get_total_bytesarray(function () constant external returns (uint256) _function)
           internal
           constant
           returns (uint256 _total_count)
  {
    _total_count = _function();
  }

}

// File: contracts/controller_electron/AssetsControllerElectron.sol

pragma solidity ^0.4.19;





contract AssetsControllerElectron is Controller, BytesIteratorController, DigixConstantsElectron {

  function assets_storage_electron()
    internal
    constant
    returns (AssetsStorageElectron _contract)
  {
    _contract = AssetsStorageElectron(get_contract(CONTRACT_STORAGE_ASSETS_ELECTRON));
  }

  function AssetsControllerElectron(address _resolver) public {
    require(init(CONTRACT_CONTROLLER_ASSETS_ELECTRON, _resolver));
  }

  function put_custodian(address _caller, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_POPADMIN);
    require(assets_storage_electron().is_valid_custodian(_custodian) == false);
    require(assets_storage_electron().add_custodian(_custodian));
  }

  function put_asset_custodian(address _caller, bytes32 _item, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_POPADMIN);
    require(assets_storage_electron().is_valid_custodian(_custodian));
    require(assets_storage_electron().set_asset_custodian(_item, _custodian));
  }

  function put_audit_custodian(address _caller, bytes32 _audit_doc, bytes32 _custodian, uint256 _timestamp)
    public
    if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_AUDITOR);
    require(_timestamp < now);
    require(assets_storage_electron().is_valid_custodian(_custodian));
    require(assets_storage_electron().set_audit_custodian(_audit_doc, _custodian));
    require(assets_storage_electron().set_audit_timestamp(_audit_doc, _timestamp));
  }

  function put_recast_block_threshold(address _caller, uint256 _block_threshold)
    public
    if_sender_is(CONTRACT_INTERACTIVE_MARKETPLACE_ADMIN_ELECTRON)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_ELECTRON_MARKETPLACE_ADMIN);
    require(assets_storage_electron().set_recast_block_threshold(_block_threshold));
  }

  function update_asset_custodian(address _caller, bytes32 _item, bytes32 _custodian)
    public
    if_sender_is(CONTRACT_INTERACTIVE_POPADMIN)
  {
    uint256 _role_id = digix_directory_service().get_user_role_id(_caller);
    require(_role_id == ROLE_POPADMIN);
    require(assets_storage_electron().update_asset_custodian(_item, _custodian));
  }

  function get_first_custodian()
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = get_first_from_bytesarray(assets_storage_electron().read_first_custodian);
  }

  function get_last_custodian()
    public
    constant
    returns (bytes32 _custodian)
  {
    _custodian = get_last_from_bytesarray(assets_storage_electron().read_last_custodian);
  }

  function get_next_custodian(bytes32 _custodian)
    public
    constant
    returns (bytes32 _next_custodian)
  {
    _next_custodian = get_next_from_bytesarray(assets_storage_electron().read_next_custodian, _custodian);
  }

  function get_previous_custodian(bytes32 _custodian)
    public
    constant
    returns (bytes32 _previous_custodian)
  {
    _previous_custodian = get_previous_from_bytesarray(assets_storage_electron().read_previous_custodian, _custodian);
  }

  function get_total_custodians()
    public
    constant
    returns (uint256 _count_custodians)
  {
    _count_custodians = get_total_bytesarray(assets_storage_electron().read_total_custodians);
  }
}

// File: contracts/interactive_electron/PoPAdminElectron.sol

pragma solidity ^0.4.19;








/// @title Interactive functions to be called by POP admin role
/// @author Digix Holdings Pte Ltd
/// @notice Use this contract (POP admin role) for taking actions in the POP protocol
contract PoPAdminElectron is ResolverClient, DigixConstants, DigixConstantsElectron {

  event NewOrder(uint256 indexed _product_id, bytes32 indexed _item, address _mint_target, bytes32 _custodian);
  event NewTransferOrder(uint256 indexed _product_id, bytes32 indexed _item, address _mint_target);
  event NewReplacementOrder(uint256 indexed _product_id, bytes32 indexed _item);
  event OrderFulfillment(bytes32 indexed _item, bytes32 indexed _serial, bytes32 indexed _document);
  event MintToken(bytes32 indexed _item, bytes32 indexed _document);
  event AuditFailure(bytes32 indexed _item, bytes32 _document);
  event AdminFailure(bytes32 indexed _item, bytes32 _document);
  event AssetRedemption(bytes32 indexed _item, bytes32 _document);
  event AssetRecast(bytes32 indexed _item, address _recast_user, bytes32 _document);

  function PoPAdminElectron(address _resolver) public
  {
    require(init(CONTRACT_INTERACTIVE_POPADMIN, _resolver));
  }

  function assets_controller()
           internal
           constant
           returns (AssetsController _contract)
  {
     _contract = AssetsController(get_contract(CONTRACT_CONTROLLER_ASSETS));
  }

  function assets_storage()
           internal
           constant
           returns (AssetsStorage _contract)
  {
     _contract = AssetsStorage(get_contract(CONTRACT_STORAGE_ASSETS));
  }

  function assets_storage_electron()
           internal
           constant
           returns (AssetsStorageElectron _contract)
  {
     _contract = AssetsStorageElectron(get_contract(CONTRACT_STORAGE_ASSETS_ELECTRON));
  }

  function job_id_storage()
           internal
           constant
           returns (JobIdStorage _contract)
  {
     _contract = JobIdStorage(get_contract(CONTRACT_STORAGE_JOB_ID));
  }

  function job_id_controller()
           internal
           constant
           returns (JobIdController _contract)
  {
     _contract = JobIdController(get_contract(CONTRACT_CONTROLLER_JOB_ID));
  }

  function assets_recast_controller_electron()
           internal
           constant
           returns (AssetsRecastControllerElectron _contract)
  {
     _contract = AssetsRecastControllerElectron(get_contract(CONTRACT_CONTROLLER_ASSETS_RECAST));
  }

  function assets_controller_electron()
    internal
    constant
    returns (AssetsControllerElectron _contract)
  {
    _contract = AssetsControllerElectron(get_contract(CONTRACT_CONTROLLER_ASSETS_ELECTRON));
  }

  modifier check_and_update_job_id(bytes32 _job_id)
  {
    bool _job_id_is_used = job_id_storage().read_if_job_id_is_used(_job_id);
    bool _job_id_is_failed = job_id_storage().read_if_job_id_is_failed(_job_id);
    require(!_job_id_is_used);
    require(!_job_id_is_failed);
    _;
    require(job_id_controller().mark_job_id_as_used(_job_id));
  }


  /////////////////////////////////////////////////     newOrder

  /// The internal function that will actually call the controller
  function processNewOrder(address _caller, uint256 _product_id, address _mint_target, bytes32 _custodian)
           internal
           returns (bytes32 _item)
  {
    bool _success;
    (_success, _item) = assets_controller().put_init_item(_caller, _product_id, _mint_target);
    assets_controller_electron().put_asset_custodian(_caller, _item, _custodian);
    require(_success);
    NewOrder(_product_id, _item, _mint_target, _custodian);
  }

  /// @dev vendor orders in bulk
  /// @param _product_ids the IDs of products that have been provided by vendor
  /// @param _mint_targets addresses at which the DGX tokens will be minted after accepting this order in future
  /// @param _job_id the Job ID of the bulk operation (must not be used before, or marked as failed)
  /// @return {
  ///   "_success": "true if all the new order operations went successfully, throws if any one failed",
  ///   "_items": "the asset items that were created on processing the new orders"
  /// }
  function bulkNewOrder(uint256[] _product_ids, address[] _mint_targets, bytes32[] _custodians, bytes32 _job_id)
           check_and_update_job_id(_job_id)
           public
           returns (bool _success, bytes32[] _items)
  {
    address _caller = msg.sender;
    uint256 _length = _product_ids.length;
    _items = new bytes32[](_length);
    for (uint256 i=0;i<_length;i++) {
      _items[i] = processNewOrder(_caller, _product_ids[i], _mint_targets[i], _custodians[i]);
    }
    _success = true;
  }


  /////////////////////////////////////////////////     newTransferOrder

  /// The main function that will actually call the controller
  function processNewTransferOrder(address _caller, uint256 _product_id, address _mint_target)
           internal
           returns (bytes32 _item)
  {
    bool _success;
    (_success, _item) = assets_controller().put_init_item_transfer(_caller, _product_id, _mint_target);
    require(_success);
    NewTransferOrder(_product_id, _item, _mint_target);
  }

  /// @dev put new transfer orders in bulk
  /// @param _product_ids IDs of products
  /// @param _mint_targets Ethereum addresses at which tokens will be minted on processing transfer orders
  /// @param _job_id job ID of this bulk operation (must not be used before, or marked as failed)
  /// @return {
  ///   "_success": "true if all the transfer orders were processed successfully, throws if any one failed",
  ///   "_items": "the asset items that were created on the transfer orders"
  /// }
  function bulkNewTransferOrder(uint256[] _product_ids, address[] _mint_targets, bytes32 _job_id)
           check_and_update_job_id(_job_id)
           public
           returns (bool _success, bytes32[] _items)
  {
    address _caller = msg.sender;
    uint256 _length = _product_ids.length;
    _items = new bytes32[](_length);
    for (uint256 i=0;i<_length;i++) {
      _items[i] = processNewTransferOrder(_caller, _product_ids[i], _mint_targets[i]);
    }
    _success = true;
  }


  /////////////////////////////////////////////////     fulfillOrder

  /// The main function that will actually call the controller
  function processFulfillOrder(address _caller, bytes32 _item, bytes32 _serial, bytes32 _document)
           internal
  {
    bool _success;
    (_success,,) = assets_controller().patch_item_fulfill_order(_caller, _item, _serial, _document);
    require(_success);
    OrderFulfillment(_item, _serial, _document);
  }

  /// @dev fulfull orders of asset items in bulk
  /// @param _items asset items whose order is to be fulfilled
  /// @param _serials serials of these asset items
  /// @param _documents IPFS hashes of the information regarding order fulfillment of asset items
  /// @return _success true if all fulfill orders were successful, throw is any one failed
  function bulkFulfillOrder(bytes32[] _items, bytes32[] _serials, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processFulfillOrder(_caller, _items[i], _serials[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     acceptDelivery

  /// The main function that will actually call the controller
  function processAcceptDelivery(address _caller, bytes32 _item, bytes32 _document)
           internal
           returns (address _mint_target, uint256 _effective_ng_weight)
  {
    bool _success;
    (_success, _mint_target, _effective_ng_weight,,) = assets_controller().patch_item_mint(_caller, _item, _document);
    require(_success);
    MintToken(_item, _document);
  }

  /// @dev accept delivery of asset item in bulk
  /// @param _items asset items delivered
  /// @param _documents IPFS hashes of the information regarding those asset items
  /// @return {
  ///   "_success": "true if all the delivery processes were successful, throws if any one failed",
  ///   "_mint_targets": "the ethereum addresses to which the equivalent DGX tokens were minted to, on accepting the delivery of these asset items",
  ///   "_effective_ng_weights": "the effective weights in nanograms of the accepted asset items, or the number of DGX tokens that were minted for each asset item"
  /// }
  function bulkAcceptDelivery(bytes32[] _items, bytes32[] _documents)
           public
           returns (bool _success, address[] _mint_targets, uint256[] _effective_ng_weights)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    _mint_targets = new address[](_length);
    _effective_ng_weights = new uint256[](_length);
    for (uint256 i=0;i<_length;i++) {
      (_mint_targets[i], _effective_ng_weights[i]) = processAcceptDelivery(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     redeemAsset

  /// The main function that will actually call the controller
  function processRedeemAsset(address _caller, bytes32 _item, address _redeem_user, bytes32 _document)
           internal
  {
    bool _success;
    _success = assets_controller().patch_item_redeem(_caller, _item, _redeem_user, _document);
    require(_success);
    AssetRedemption(_item, _document);
  }

  /// @dev redeem asset items in bulk
  /// @param _items asset items to be redeemed by user
  /// @param _users addresses of users who are redeeming those assets
  /// @param _documents IPFS hashes of the information in redeeming every item
  /// @return _success true if all the redeem processes done successfully, throws if any one failed
  function bulkRedeemAsset(bytes32[] _items, address[] _users, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processRedeemAsset(_caller, _items[i], _users[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     newReplacementOrder

  /// The main function that will actually call the controller
  /// @notice called by a popadmin to order a replacement for an item that has failed audit
  function processNewReplacementOrder(address _caller, bytes32 _failed_item, uint256 _replacement_product_id)
           internal
           returns (bytes32 _replacement_item)
  {
    bool _success;
    (_success, _replacement_item) = assets_controller().put_init_item_as_replacement(_caller, _replacement_product_id, _failed_item);
    require(_success);
    NewReplacementOrder(_replacement_product_id, _failed_item);
  }

  /// @dev put new replacement orders in bulk
  /// @param _failed_items asset items that have audit failed, that need to be replaced
  /// @param _product_ids IDs of products that will replace these failed items
  /// @param _job_id job ID of this bulk job (must not be re-used or marked as failed)
  /// @return {
  ///   "_success": "true if all the replacement orders were saved successfully",
  ///   "_replacement_items": "asset items that will be replacing the failed items"
  /// }
  function bulkNewReplacementOrder(bytes32[] _failed_items, uint256[] _product_ids, bytes32 _job_id)
           check_and_update_job_id(_job_id)
           public
           returns (bool _success, bytes32[] _replacement_items)
  {
    address _caller = msg.sender;
    uint256 _length = _failed_items.length;
    _replacement_items = new bytes32[](_length);
    for (uint256 i=0;i<_length;i++) {
      _replacement_items[i] = processNewReplacementOrder(_caller, _failed_items[i], _product_ids[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     fulfillReplacementOrder

  /// The main function that will actually call the controller
  /// @notice called by a vendor to fulfill a replacement order
  function processFulfillReplacementOrder(address _caller, bytes32 _item, bytes32 _serial, bytes32 _document)
           internal
  {
    bool _success;
    _success = assets_controller().patch_item_fulfill_replacement_order(_caller, _item, _serial, _document);
    require(_success);
    OrderFulfillment(_item, _serial, _document);
  }

  /// @dev fulfill the replacement orders for asset items in bulk
  /// @param _items asset items to be replaced
  /// @param _serials serial IDs of the asset items
  /// @param _documents IPFS hashes of the information for each fulfill replacement order
  /// @return _success true if every replacement order fulfilled successfully, throws if any one failed
  function bulkFulfillReplacementOrder(bytes32[] _items, bytes32[] _serials, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processFulfillReplacementOrder(_caller, _items[i], _serials[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     acceptReplacementDelivery

  /// The main function that will actually call the controller
  /// @notice called by a custodian to accept delivery of a replacement item
  function processAcceptReplacementDelivery(address _caller, bytes32 _item, bytes32 _document)
           internal
           returns (uint256 _effective_ng_weight)
  {
    bool _success;
    (_success, _effective_ng_weight) = assets_controller().patch_item_mint_replacement(_caller, _item, _document);
    require(_success);
    MintToken(_item, _document);
  }

  /// @dev mark replacement asset items as accepted
  /// @param _items asset items to be marked accepted for replacement delivery. These are the items that are replacing other failed assets
  /// @param _documents IPFS hashes of the information uploaded regarding this accepted replacement for other items
  /// @return {
  ///   "_success": "true if the bulk operation of acception the replacement items was successful, throws if any one operation failed",
  ///   "_effective_ng_weights": "effective nanogram weights of the gold, or the number of DGX tokens in these replacement asset items"
  /// }
  function bulkAcceptReplacementDelivery(bytes32[] _items, bytes32[] _documents)
           public
           returns (bool _success, uint256[] _effective_ng_weights)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    _effective_ng_weights = new uint256[](_length);
    for (uint256 i=0;i<_length;i++) {
      _effective_ng_weights[i] = processAcceptReplacementDelivery(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     reportAuditFailure

  /// The main function that will actually call the controller
  /// @notice called by an auditor to report that an asset item has failed audit
  function processReportAuditFailure(address _caller, bytes32 _item, bytes32 _document)
           internal
  {
    bool _success;
    (_success,,) = assets_controller().patch_item_to_audit_failure(_caller, _item, _document);
    require(_success);
    AuditFailure(_item, _document);
  }

  /// @dev set audit failure for asset items in bulk
  /// @param _items asset items to be market audit failure
  /// @param _documents IPFS hashes of the information while audit failure of these items
  /// @return _success true if all items successfully market audit failure, throws if any one item failed
  function bulkReportAuditFailure(bytes32[] _items, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processReportAuditFailure(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     adminFail

  /// The main function that will actually call the controller
  /// @notice called by a popadmin to fail an asset that has not been minted
  function processAdminFail(address _caller, bytes32 _item, bytes32 _document)
           internal
  {
    bool _success;
    _success = assets_controller().patch_item_admin_fail(_caller, _item, _document);
    require(_success);
    AdminFailure(_item, _document);
  }

  /// @dev fail multiple asset items in bulk
  /// @param _items asset items to be marked as failed
  /// @param _documents the IPFS hashes of the information linked to failing of these asset items
  /// @return _success true if all asset items were failed successfully, throws if any one of them could not be failed
  function bulkAdminFail(bytes32[] _items, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processAdminFail(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     remint

  /// The main function that will actually call the controller
  /// @notice called by a popadmin to fail an asset that has not been minted
  function processRemint(address _caller, bytes32 _item, bytes32 _document)
           internal
  {
    bool _success;
    require(assets_recast_controller_electron().is_remint_item_blocked(_item) == false);
    _success = assets_controller().patch_item_remint(_caller, _item, _document);
    require(_success);
    MintToken(_item, _document);
  }

  /// @dev remint assets that were not redeemed in time, or are reminted by the recaster
  /// @param _items asset items to be reminted
  /// @param _documents IPFS hashes of the information linked to reminting assets
  /// @return _success true if all assets were reminted successfully, throws if any one of them failed
  function bulkRemint(bytes32[] _items, bytes32[] _documents)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processRemint(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     recast
  function processRecastAsset(
    address _caller,
    bytes32 _item,
    bytes32 _document
  )
    internal
    returns (uint256 _effective_ng_weight)
  {
    bool _success;
    (_success, _effective_ng_weight) = assets_recast_controller_electron().patch_item_recast(
      _caller, _item, _document
    );
    require(_success);
    AssetRecast(_item, _caller, _document);
  }

  /// @dev recast assets in bulk
  /// @param _items the asset items to be recasted
  /// @param _documents the IPFS hashes of the information that is linked to recasting these asset items
  /// @return {
  ///   "_success": "true if all the recasts were done successfully. throws if any one was not successful",
  ///   "_effective_ng_weight": "the total effecive weights of the items that were recasted"
  /// }
  function bulkRecastAsset(
    bytes32[] _items,
    bytes32[] _documents,
    uint256 _kyc_tier,
    uint256 _kyc_expiry,
    uint256 _block_number,
    address _signer,
    bytes _signature
  )
    public
    returns (bool _success, uint256[] _effective_ng_weights)
  {
    address _caller = msg.sender;

    require(assets_recast_controller_electron().check_user_kyc(
      _caller, _kyc_tier, _kyc_expiry, _block_number, _signer, _signature
    ));

    uint256 _length = _items.length;
    _effective_ng_weights = new uint256[](_length);
    for (uint256 i=0;i<_length;i++) {
      _effective_ng_weights[i] = processRecastAsset(_caller, _items[i], _documents[i]);
    }
    _success = true;
  }

  /////////////////////////////////////////////////     append documents
  function processAppendNewDocument(address _caller, bytes32 _item, bytes32 _document)
           internal
  {
    require(assets_controller().patch_item_add_document(_caller, _item, _document));
  }

  /// TODO
  /// @dev append new documents for asset items with jobID
  /// @param _items assets items for which documents have to be added
  /// @param _documents the IPFS hashes of the informations
  /// @param _job_id jobID for this task (should not be already used, or marked as fail)
  /// @return _success true if documents were appended successfully
  function bulkAppendNewDocument(bytes32[] _items, bytes32[] _documents, bytes32 _job_id)
           check_and_update_job_id(_job_id)
           public
           returns (bool _success)
  {
    uint256 _length = _items.length;
    for (uint256 i=0;i<_length;i++) {
      processAppendNewDocument(msg.sender, _items[i], _documents[i]);
    }
    _success = true;
  }

  ////////////////////////////////////////////////// other functions

  /// TODO
  /// @dev add document for global audit
  /// @param _document the IPFS hash of the information that is to be uploaded
  /// @return _success true if audit doc was added successfully, throw otherwise
  function addGlobalAudit(bytes32 _document, bytes32 _custodian, uint256 _timestamp)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    _success = assets_controller().put_global_audit(_caller, _document);
    assets_controller_electron().put_audit_custodian(_caller, _document, _custodian, _timestamp);
  }

  /// @dev update the redeem period of any recasted asset
  /// @param _redeem_period the new redeem period
  /// @return _success true if updated successfully, throw otherwise
  function updateRedeemPeriod(uint256 _redeem_period)
           public
           returns (bool _success)
  {
    address _caller = msg.sender;
    _success = assets_controller().change_redeem_period(_caller, _redeem_period);
  }

  /// @dev check the status of job IDs, whether they are already used or marked as failed
  /// @param _job_ids job IDs, whose status to be checked
  /// @return {
  ///   "_used": "array of booleans, true if that job ID at that index is used, false otherwise",
  ///   "_failed": "array of booleans, true if job ID at that index is marked as fail, otherwise false"
  /// }
  function bulkCheckJobIds(bytes32[] _job_ids)
           public
           constant
           returns (bool[] _used, bool[] _failed)
  {
    uint256 _length = _job_ids.length;
    _used = new bool[](_length);
    _failed = new bool[](_length);

    for (uint256 i=0;i<_length;i++) {
      _used[i] = job_id_storage().read_if_job_id_is_used(_job_ids[i]);
      _failed[i] = job_id_storage().read_if_job_id_is_failed(_job_ids[i]);
    }
  }

  function failJobId(bytes32 _job_id)
           internal
  {
    require(job_id_controller().mark_job_id_as_failed(msg.sender, _job_id));
  }

  /// @dev mark these job IDs as failed in bulk
  /// @param _job_ids the job IDs to be marked as failed
  /// @return _success true if job IDs were marked as fail successfully
  function bulkFailJobId(bytes32[] _job_ids)
           public
           returns (bool _success)
  {
    uint256 _length = _job_ids.length;
    for (uint256 i=0;i<_length;i++) {
      failJobId(_job_ids[i]);
    }
    _success = true;
  }

  function processAddCustodian(address _caller, bytes32 _custodian)
    internal
  {
    assets_controller_electron().put_custodian(_caller, _custodian);
  }

  function bulkAddCustodian(bytes32[] _custodians)
    public
    returns (bool _success)
  {
    uint256 _length = _custodians.length;
    for (uint256 i=0;i<_length;i++) {
      processAddCustodian(msg.sender, _custodians[i]);
    }
    _success = true;
  }

  function bulkAddAssetCustodian(bytes32[] _items, bytes32 _custodian)
    public
    returns (bool _success)
  {
    uint256 _length = _items.length;
    for (uint256 i = 0; i < _length; i++) {
      assets_controller_electron().put_asset_custodian(msg.sender, _items[i], _custodian);
    }
    _success = true;
  }

  function bulkAddAuditCustodian(bytes32[] _docs, uint256[] _timestamps, bytes32 _custodian)
    public
    returns (bool _success)
  {
    uint256 _length = _docs.length;
    for (uint256 i = 0; i < _length; i++) {
      assets_controller_electron().put_audit_custodian(msg.sender, _docs[i], _custodian, _timestamps[i]);
    }
    _success = true;
  }

  function bulkUpdateAssetCustodian(bytes32[] _items, bytes32 _custodian)
    public
    returns (bool _success)
  {
    require(assets_storage_electron().is_valid_custodian(_custodian));
    uint256 _length = _items.length;
    for (uint256 i = 0; i < _length; i++) {
      assets_controller_electron().update_asset_custodian(msg.sender, _items[i], _custodian);
    }
    _success = true;
  }

  function bulkBlockAssetRemint(bytes32[] _items)
    public
    returns (bool _success)
  {
    uint256 _length = _items.length;
    for (uint256 i = 0; i < _length; i++) {
      assets_recast_controller_electron().set_remint_item_blocked(msg.sender, _items[i]);
    }
    _success = true;
  }
}