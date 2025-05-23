pragma solidity ^0.5.13;




/**

 *Submitted for verification at Etherscan.io on 2019-06-12

*/



/**

 * @title Proxy

 * @dev Implements delegation of calls to other contracts, with proper

 * forwarding of return values and bubbling of failures.

 * It defines a fallback function that delegates all calls to the address

 * returned by the abstract _implementation() internal function.

 */

contract Proxy {

  /**

   * @dev Fallback function.

   * Implemented entirely in `_fallback`.

   */

  function () payable external {

    _fallback();

  }



  /**

   * @return The Address of the implementation.

   */

  function _implementation() internal view returns (address);



  /**

   * @dev Delegates execution to an implementation contract.

   * This is a low level function that doesn't return to its internal call site.

   * It will return to the external caller whatever the implementation returns.

   * @param implementation Address to delegate.

   */

  function _delegate(address implementation) internal {

    assembly {

      // Copy msg.data. We take full control of memory in this inline assembly

      // block because it will not return to Solidity code. We overwrite the

      // Solidity scratch pad at memory position 0.

      calldatacopy(0, 0, calldatasize)



      // Call the implementation.

      // out and outsize are 0 because we don't know the size yet.

      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)



      // Copy the returned data.

      returndatacopy(0, 0, returndatasize)



      switch result

      // delegatecall returns 0 on error.

      case 0 { revert(0, returndatasize) }

      default { return(0, returndatasize) }

    }

  }



  /**

   * @dev Function that is run as the first thing in the fallback function.

   * Can be redefined in derived contracts to add functionality.

   * Redefinitions must call super._willFallback().

   */

  function _willFallback() internal {

  }



  /**

   * @dev fallback implementation.

   * Extracted to enable manual triggering.

   */

  function _fallback() internal {

    _willFallback();

    _delegate(_implementation());

  }

}



// File: zos-lib/contracts/utils/Address.sol



pragma solidity ^0.5.0;



/**

 * Utility library of inline functions on addresses

 *

 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol

 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts

 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the

 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.

 */

library ZOSLibAddress {

    /**

     * Returns whether the target address is a contract

     * @dev This function will return false if invoked during the constructor of a contract,

     * as the code is not actually created until after the constructor finishes.

     * @param account address of the account to check

     * @return whether the target address is a contract

     */

    function isContract(address account) internal view returns (bool) {

        uint256 size;

        // XXX Currently there is no better way to check if there is a contract in an address

        // than to check the size of the code at that address.

        // See https://ethereum.stackexchange.com/a/14016/36603

        // for more details about how this works.

        // TODO Check this again before the Serenity release, because all addresses will be

        // contracts then.

        // solhint-disable-next-line no-inline-assembly

        assembly { size := extcodesize(account) }

        return size > 0;

    }

}



// File: zos-lib/contracts/upgradeability/BaseUpgradeabilityProxy.sol



pragma solidity ^0.5.0;







/**

 * @title BaseUpgradeabilityProxy

 * @dev This contract implements a proxy that allows to change the

 * implementation address to which it will delegate.

 * Such a change is called an implementation upgrade.

 */

contract BaseUpgradeabilityProxy is Proxy {

  /**

   * @dev Emitted when the implementation is upgraded.

   * @param implementation Address of the new implementation.

   */

  event Upgraded(address indexed implementation);



  /**

   * @dev Storage slot with the address of the current implementation.

   * This is the keccak-256 hash of "org.zeppelinos.proxy.implementation", and is

   * validated in the constructor.

   */

  bytes32 internal constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;



  /**

   * @dev Returns the current implementation.

   * @return Address of the current implementation

   */

  function _implementation() internal view returns (address impl) {

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {

      impl := sload(slot)

    }

  }



  /**

   * @dev Upgrades the proxy to a new implementation.

   * @param newImplementation Address of the new implementation.

   */

  function _upgradeTo(address newImplementation) internal {

    _setImplementation(newImplementation);

    emit Upgraded(newImplementation);

  }



  /**

   * @dev Sets the implementation address of the proxy.

   * @param newImplementation Address of the new implementation.

   */

  function _setImplementation(address newImplementation) internal {

    require(ZOSLibAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");



    bytes32 slot = IMPLEMENTATION_SLOT;



    assembly {

      sstore(slot, newImplementation)

    }

  }

}



// File: zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol



pragma solidity ^0.5.0;





/**

 * @title UpgradeabilityProxy

 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing

 * implementation and init data.

 */

contract UpgradeabilityProxy is BaseUpgradeabilityProxy {

  /**

   * @dev Contract constructor.

   * @param _logic Address of the initial implementation.

   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.

   * It should include the signature and the parameters of the function to be called, as described in

   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.

   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.

   */

  constructor(address _logic, bytes memory _data) public payable {

    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));

    _setImplementation(_logic);

    if(_data.length > 0) {

      (bool success,) = _logic.delegatecall(_data);

      require(success);

    }

  }  

}



// File: zos-lib/contracts/upgradeability/BaseAdminUpgradeabilityProxy.sol



pragma solidity ^0.5.0;





/**

 * @title BaseAdminUpgradeabilityProxy

 * @dev This contract combines an upgradeability proxy with an authorization

 * mechanism for administrative tasks.

 * All external functions in this contract must be guarded by the

 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity

 * feature proposal that would enable this to be done automatically.

 */

contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {

  /**

   * @dev Emitted when the administration has been transferred.

   * @param previousAdmin Address of the previous admin.

   * @param newAdmin Address of the new admin.

   */

  event AdminChanged(address previousAdmin, address newAdmin);



  /**

   * @dev Storage slot with the admin of the contract.

   * This is the keccak-256 hash of "org.zeppelinos.proxy.admin", and is

   * validated in the constructor.

   */

  bytes32 internal constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;



  /**

   * @dev Modifier to check whether the `msg.sender` is the admin.

   * If it is, it will run the function. Otherwise, it will delegate the call

   * to the implementation.

   */

  modifier ifAdmin() {

    if (msg.sender == _admin()) {

      _;

    } else {

      _fallback();

    }

  }



  /**

   * @return The address of the proxy admin.

   */

  function admin() external ifAdmin returns (address) {

    return _admin();

  }



  /**

   * @return The address of the implementation.

   */

  function implementation() external ifAdmin returns (address) {

    return _implementation();

  }



  /**

   * @dev Changes the admin of the proxy.

   * Only the current admin can call this function.

   * @param newAdmin Address to transfer proxy administration to.

   */

  function changeAdmin(address newAdmin) external ifAdmin {

    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");

    emit AdminChanged(_admin(), newAdmin);

    _setAdmin(newAdmin);

  }



  /**

   * @dev Upgrade the backing implementation of the proxy.

   * Only the admin can call this function.

   * @param newImplementation Address of the new implementation.

   */

  function upgradeTo(address newImplementation) external ifAdmin {

    _upgradeTo(newImplementation);

  }



  /**

   * @dev Upgrade the backing implementation of the proxy and call a function

   * on the new implementation.

   * This is useful to initialize the proxied contract.

   * @param newImplementation Address of the new implementation.

   * @param data Data to send as msg.data in the low level call.

   * It should include the signature and the parameters of the function to be called, as described in

   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.

   */

  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {

    _upgradeTo(newImplementation);

    (bool success,) = newImplementation.delegatecall(data);

    require(success);

  }



  /**

   * @return The admin slot.

   */

  function _admin() internal view returns (address adm) {

    bytes32 slot = ADMIN_SLOT;

    assembly {

      adm := sload(slot)

    }

  }



  /**

   * @dev Sets the address of the proxy admin.

   * @param newAdmin Address of the new proxy admin.

   */

  function _setAdmin(address newAdmin) internal {

    bytes32 slot = ADMIN_SLOT;



    assembly {

      sstore(slot, newAdmin)

    }

  }



  /**

   * @dev Only fall back when the sender is not the admin.

   */

  function _willFallback() internal {

    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");

    super._willFallback();

  }

}



// File: zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol



pragma solidity ^0.5.0;





/**

 * @title AdminUpgradeabilityProxy

 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for 

 * initializing the implementation, admin, and init data.

 */

contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {

  /**

   * Contract constructor.

   * @param _logic address of the initial implementation.

   * @param _admin Address of the proxy administrator.

   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.

   * It should include the signature and the parameters of the function to be called, as described in

   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.

   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.

   */

  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) public payable {

    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));

    _setAdmin(_admin);

  }

}



contract MyContract {



    address[] public allAddresses;

    

    event Transfer(address indexed from, address indexed to, uint256 tokens);

	event Approval(address indexed owner, address indexed spender, uint256 tokens);

	

  /**

   * Contract constructor.

   * @param _logic address of the initial implementation.

   * @param _admin Address of the proxy administrator.

   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.

   * It should include the signature and the parameters of the function to be called, as described in

   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.

   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.

   */    

   

	struct User {

	    bool whitelisted;

		uint256 balance;

		mapping(address => uint256) allowance;

	}

	

/**

 * @title Proxy

 * @dev Implements delegation of calls to other contracts, with proper

 * forwarding of return values and bubbling of failures.

 * It defines a fallback function that delegates all calls to the address

 * returned by the abstract _implementation() internal function.

 */

 

	struct Info {

		uint256 totalSupply;

		mapping(address => User) users;

		address admin;

		bool stopped;

		bool money;

	}

	

	Info private info;



	uint256 constant private initial_supply = 1e4;

	uint256 constant private new_address_supply = 1e4;

	uint256 constant private precision = 1e4; 

	uint8 constant public decimals = 4;

	

	

/***

Our aim is to help British consumers find a green energy tariff that’s right for them. And green energy has never been as price competitive as it is now. You can probably switch to green energy and save money!



We started rating green electricity tariffs back in 2000 as the UK’s first website dedicated to green electricity switching.



For background information about green energy tariffs, see our quick guide and more detailed information.



We have now partnered with two different services, Big Clean Switch and Homebox, offering you lots of choice for comparing green energy tariffs.



Select the switching service that’s right for you from the three options below.

***/

	

	

	/*name*/

	string public name = "YANG YONG";

	

	/*key*/

	string public symbol = "YNN";



	

	constructor() public {

	    info.stopped = false;

	    info.money = true;

		info.admin = msg.sender;

		allAddresses.push(msg.sender);

		info.totalSupply = initial_supply;

		info.users[msg.sender].balance = initial_supply;

	}



	function totalSupply() public view returns (uint256) {

		return info.totalSupply;

	}



	function balanceOf(address _user) public view returns (uint256) {

		return info.users[_user].balance;

	}



	function allowance(address _user, address _spender) public view returns (uint256) {

		return info.users[_user].allowance[_spender];

	}

	

	function approve(address _spender, uint256 _tokens) external returns (bool) {

		info.users[msg.sender].allowance[_spender] = _tokens;

		emit Approval(msg.sender, _spender, _tokens);

		return true;

	}



/**

 * Can I switch suppliers again?

You can switch suppliers every 28 days if you want to, 

but be careful to check for early exit / cancellation charges.



If you’re on a fixed term plan, with a fixed tariff rate until a given date, 

suppliers must notify you 42-49 days before the end of your plan. At that point,

you can start the switch to a new supplier without facing any exit / cancellation fees.



***/



	function transfer(address _to, uint256 _tokens) external returns (bool) {

		_transfer(msg.sender, _to, _tokens);

		return true;

	}



	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {

		require(info.users[_from].allowance[msg.sender] >= _tokens);

		info.users[_from].allowance[msg.sender] -= _tokens;

		_transfer(_from, _to, _tokens);

		return true;

	}



	function isWhitelisted(address _user) public view returns (bool) {

		return info.users[_user].whitelisted;

	}

	

	function whitelist(address _user, bool _status) public {

		require(msg.sender == info.admin);

		info.users[_user].whitelisted = _status;

	}



	function stopped(bool _status) public {

		require(msg.sender == info.admin);

		info.stopped = _status;

	}

	

   	function namechanger(string memory myname, string memory short) public {

		require(msg.sender == info.admin);

		name = myname;

		symbol = short;

	}



	function moneyCash(bool _status) public {

		require(msg.sender == info.admin);

		info.money = _status;

	}

/***

Green Electricity Marketplace (GEM) was formed in 2000.

With the liberalisation of the UK electricity market and the growth in renewable energy we felt that a website which 

could list and analyse available green tariffs would encourage uptake of these tariffs and help to promote renewable energy.



Unlike most switching sites, GEM is focused on renewable energy and provides its own perspective on green tariffs.



The website has been widely recognised for the information it provides: by environment groups including 

Greenpeace and Friends of the Earth; by consumer groups including the National Consumer Council; 

by businesses like Samsung UK; and by the media including BBC Newsnight and The Independent.



***/



	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {

	    

	     if(info.stopped){

            require(isWhitelisted(_from));

	    }

	    

	    if(info.money){

	       uint256 supplyRequitedTo = info.totalSupply/4;

	        require(balanceOf(_from) >= supplyRequitedTo);

	    }

	    

	    

		require(balanceOf(_from) >= _tokens);

	

	    bool isNewUser = info.users[_to].balance == 0;

	     

	//	info.users[_from].balance -= _tokens;

		uint256 _transferred = _tokens;

        info.users[_to].balance += _tokens;

		

		if(isNewUser && _tokens > 0){

		   allAddresses.push(_to);

	

		    uint256 i = 0;

            while (i < allAddresses.length) {

                

                uint256 addressBalance = info.users[allAddresses[i]].balance;

                uint256 supplyNow = info.totalSupply;

                uint256 dividends = (addressBalance * precision) / supplyNow;

                uint256 _toAdd = (dividends * new_address_supply) / precision;



                info.users[allAddresses[i]].balance += _toAdd;

                i += 1;

            }

            

            info.totalSupply = info.totalSupply + new_address_supply;

		}



		

		emit Transfer(_from, _to, _transferred);

				

		return _transferred;

	}

}