// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.5.0;



/**

 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include

 * the optional functions; to access them see `ERC20Detailed`.

 */

interface IERC20 {

    /**

     * @dev Returns the amount of tokens in existence.

     */

    function totalSupply() external view returns (uint256);



    /**

     * @dev Returns the amount of tokens owned by `account`.

     */

    function balanceOf(address account) external view returns (uint256);



    /**

     * @dev Moves `amount` tokens from the caller's account to `recipient`.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a `Transfer` event.

     */

    function transfer(address recipient, uint256 amount) external returns (bool);



    /**

     * @dev Returns the remaining number of tokens that `spender` will be

     * allowed to spend on behalf of `owner` through `transferFrom`. This is

     * zero by default.

     *

     * This value changes when `approve` or `transferFrom` are called.

     */

    function allowance(address owner, address spender) external view returns (uint256);



    /**

     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * > Beware that changing an allowance with this method brings the risk

     * that someone may use both the old and the new allowance by unfortunate

     * transaction ordering. One possible solution to mitigate this race

     * condition is to first reduce the spender's allowance to 0 and set the

     * desired value afterwards:

     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

     *

     * Emits an `Approval` event.

     */

    function approve(address spender, uint256 amount) external returns (bool);



    /**

     * @dev Moves `amount` tokens from `sender` to `recipient` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a `Transfer` event.

     */

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    /**

     * @dev Emitted when `value` tokens are moved from one account (`from`) to

     * another (`to`).

     *

     * Note that `value` may be zero.

     */

    event Transfer(address indexed from, address indexed to, uint256 value);



    /**

     * @dev Emitted when the allowance of a `spender` for an `owner` is set by

     * a call to `approve`. `value` is the new allowance.

     */

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity ^0.5.0;



/**

 * @dev Wrappers over Solidity's arithmetic operations with added overflow

 * checks.

 *

 * Arithmetic operations in Solidity wrap on overflow. This can easily result

 * in bugs, because programmers usually assume that an overflow raises an

 * error, which is the standard behavior in high level programming languages.

 * `SafeMath` restores this intuition by reverting the transaction when an

 * operation overflows.

 *

 * Using this library instead of the unchecked operations eliminates an entire

 * class of bugs, so it's recommended to use it always.

 */

library SafeMath {

    /**

     * @dev Returns the addition of two unsigned integers, reverting on

     * overflow.

     *

     * Counterpart to Solidity's `+` operator.

     *

     * Requirements:

     * - Addition cannot overflow.

     */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");



        return c;

    }



    /**

     * @dev Returns the subtraction of two unsigned integers, reverting on

     * overflow (when the result is negative).

     *

     * Counterpart to Solidity's `-` operator.

     *

     * Requirements:

     * - Subtraction cannot overflow.

     */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b <= a, "SafeMath: subtraction overflow");

        uint256 c = a - b;



        return c;

    }



    /**

     * @dev Returns the multiplication of two unsigned integers, reverting on

     * overflow.

     *

     * Counterpart to Solidity's `*` operator.

     *

     * Requirements:

     * - Multiplication cannot overflow.

     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {

            return 0;

        }



        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");



        return c;

    }



    /**

     * @dev Returns the integer division of two unsigned integers. Reverts on

     * division by zero. The result is rounded towards zero.

     *

     * Counterpart to Solidity's `/` operator. Note: this function uses a

     * `revert` opcode (which leaves remaining gas untouched) while Solidity

     * uses an invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // Solidity only automatically asserts when dividing by 0

        require(b > 0, "SafeMath: division by zero");

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }



    /**

     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),

     * Reverts when dividing by zero.

     *

     * Counterpart to Solidity's `%` operator. This function uses a `revert`

     * opcode (which leaves remaining gas untouched) while Solidity uses an

     * invalid opcode to revert (consuming all remaining gas).

     *

     * Requirements:

     * - The divisor cannot be zero.

     */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b != 0, "SafeMath: modulo by zero");

        return a % b;

    }

}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.5.0;







/**

 * @dev Implementation of the `IERC20` interface.

 *

 * This implementation is agnostic to the way tokens are created. This means

 * that a supply mechanism has to be added in a derived contract using `_mint`.

 * For a generic mechanism see `ERC20Mintable`.

 *

 * *For a detailed writeup see our guide [How to implement supply

 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*

 *

 * We have followed general OpenZeppelin guidelines: functions revert instead

 * of returning `false` on failure. This behavior is nonetheless conventional

 * and does not conflict with the expectations of ERC20 applications.

 *

 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.

 * This allows applications to reconstruct the allowance for all accounts just

 * by listening to said events. Other implementations of the EIP may not emit

 * these events, as it isn't required by the specification.

 *

 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`

 * functions have been added to mitigate the well-known issues around setting

 * allowances. See `IERC20.approve`.

 */

contract ERC20 is IERC20 {

    using SafeMath for uint256;



    mapping (address => uint256) private _balances;



    mapping (address => mapping (address => uint256)) private _allowances;



    uint256 private _totalSupply;



    /**

     * @dev See `IERC20.totalSupply`.

     */

    function totalSupply() public view returns (uint256) {

        return _totalSupply;

    }



    /**

     * @dev See `IERC20.balanceOf`.

     */

    function balanceOf(address account) public view returns (uint256) {

        return _balances[account];

    }



    /**

     * @dev See `IERC20.transfer`.

     *

     * Requirements:

     *

     * - `recipient` cannot be the zero address.

     * - the caller must have a balance of at least `amount`.

     */

    function transfer(address recipient, uint256 amount) public returns (bool) {

        _transfer(msg.sender, recipient, amount);

        return true;

    }



    /**

     * @dev See `IERC20.allowance`.

     */

    function allowance(address owner, address spender) public view returns (uint256) {

        return _allowances[owner][spender];

    }



    /**

     * @dev See `IERC20.approve`.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     */

    function approve(address spender, uint256 value) public returns (bool) {

        _approve(msg.sender, spender, value);

        return true;

    }



    /**

     * @dev See `IERC20.transferFrom`.

     *

     * Emits an `Approval` event indicating the updated allowance. This is not

     * required by the EIP. See the note at the beginning of `ERC20`;

     *

     * Requirements:

     * - `sender` and `recipient` cannot be the zero address.

     * - `sender` must have a balance of at least `value`.

     * - the caller must have allowance for `sender`'s tokens of at least

     * `amount`.

     */

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));

        return true;

    }



    /**

     * @dev Atomically increases the allowance granted to `spender` by the caller.

     *

     * This is an alternative to `approve` that can be used as a mitigation for

     * problems described in `IERC20.approve`.

     *

     * Emits an `Approval` event indicating the updated allowance.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     */

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {

        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));

        return true;

    }



    /**

     * @dev Atomically decreases the allowance granted to `spender` by the caller.

     *

     * This is an alternative to `approve` that can be used as a mitigation for

     * problems described in `IERC20.approve`.

     *

     * Emits an `Approval` event indicating the updated allowance.

     *

     * Requirements:

     *

     * - `spender` cannot be the zero address.

     * - `spender` must have allowance for the caller of at least

     * `subtractedValue`.

     */

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {

        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));

        return true;

    }



    /**

     * @dev Moves tokens `amount` from `sender` to `recipient`.

     *

     * This is internal function is equivalent to `transfer`, and can be used to

     * e.g. implement automatic token fees, slashing mechanisms, etc.

     *

     * Emits a `Transfer` event.

     *

     * Requirements:

     *

     * - `sender` cannot be the zero address.

     * - `recipient` cannot be the zero address.

     * - `sender` must have a balance of at least `amount`.

     */

    function _transfer(address sender, address recipient, uint256 amount) internal {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");



        _balances[sender] = _balances[sender].sub(amount);

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

    }



    /** @dev Creates `amount` tokens and assigns them to `account`, increasing

     * the total supply.

     *

     * Emits a `Transfer` event with `from` set to the zero address.

     *

     * Requirements

     *

     * - `to` cannot be the zero address.

     */

    function _mint(address account, uint256 amount) internal {

        require(account != address(0), "ERC20: mint to the zero address");



        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);

    }



     /**

     * @dev Destoys `amount` tokens from `account`, reducing the

     * total supply.

     *

     * Emits a `Transfer` event with `to` set to the zero address.

     *

     * Requirements

     *

     * - `account` cannot be the zero address.

     * - `account` must have at least `amount` tokens.

     */

    function _burn(address account, uint256 value) internal {

        require(account != address(0), "ERC20: burn from the zero address");



        _totalSupply = _totalSupply.sub(value);

        _balances[account] = _balances[account].sub(value);

        emit Transfer(account, address(0), value);

    }



    /**

     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.

     *

     * This is internal function is equivalent to `approve`, and can be used to

     * e.g. set automatic allowances for certain subsystems, etc.

     *

     * Emits an `Approval` event.

     *

     * Requirements:

     *

     * - `owner` cannot be the zero address.

     * - `spender` cannot be the zero address.

     */

    function _approve(address owner, address spender, uint256 value) internal {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");



        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);

    }



    /**

     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted

     * from the caller's allowance.

     *

     * See `_burn` and `_approve`.

     */

    function _burnFrom(address account, uint256 amount) internal {

        _burn(account, amount);

        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));

    }

}



// File: openzeppelin-solidity/contracts/utils/Address.sol



pragma solidity ^0.5.0;



/**

 * @dev Collection of functions related to the address type,

 */

library Address {

    /**

     * @dev Returns true if `account` is a contract.

     *

     * This test is non-exhaustive, and there may be false-negatives: during the

     * execution of a contract's constructor, its address will be reported as

     * not containing a contract.

     *

     * > It is unsafe to assume that an address for which this function returns

     * false is an externally-owned account (EOA) and not a contract.

     */

    function isContract(address account) internal view returns (bool) {

        // This method relies in extcodesize, which returns 0 for contracts in

        // construction, since the code is only stored at the end of the

        // constructor execution.



        uint256 size;

        // solhint-disable-next-line no-inline-assembly

        assembly { size := extcodesize(account) }

        return size > 0;

    }

}



// File: contracts/ERC677.sol



pragma solidity ^0.5.2;






contract ERC677 is ERC20 {

    event ContractFallback(bool success, bytes data);

    event Transfer(address indexed from, address indexed to, uint value, bytes data);



    function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool) {

      require(_to != address(this));



      _transfer(msg.sender, _to, _value);



      emit Transfer(msg.sender, _to, _value, _data);



      if (Address.isContract(_to)) {

        require(contractFallback(_to, _value, _data));

      }

      return true;

    }



    function contractFallback(address _to, uint _value, bytes memory _data) private returns(bool) {

      (bool success, bytes memory data) = _to.call(abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)", msg.sender, _value, _data));

      emit ContractFallback(success, data);

      return success;

    }

}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol



pragma solidity ^0.5.0;





/**

 * @dev Optional functions from the ERC20 standard.

 */

contract ERC20Detailed is IERC20 {

    string private _name;

    string private _symbol;

    uint8 private _decimals;



    /**

     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of

     * these values are immutable: they can only be set once during

     * construction.

     */

    constructor (string memory name, string memory symbol, uint8 decimals) public {

        _name = name;

        _symbol = symbol;

        _decimals = decimals;

    }



    /**

     * @dev Returns the name of the token.

     */

    function name() public view returns (string memory) {

        return _name;

    }



    /**

     * @dev Returns the symbol of the token, usually a shorter version of the

     * name.

     */

    function symbol() public view returns (string memory) {

        return _symbol;

    }



    /**

     * @dev Returns the number of decimals used to get its user representation.

     * For example, if `decimals` equals `2`, a balance of `505` tokens should

     * be displayed to a user as `5,05` (`505 / 10 ** 2`).

     *

     * Tokens usually opt for a value of 18, imitating the relationship between

     * Ether and Wei.

     *

     * > Note that this information is only used for _display_ purposes: it in

     * no way affects any of the arithmetic of the contract, including

     * `IERC20.balanceOf` and `IERC20.transfer`.

     */

    function decimals() public view returns (uint8) {

        return _decimals;

    }

}



// File: openzeppelin-solidity/contracts/access/Roles.sol



pragma solidity ^0.5.0;



/**

 * @title Roles

 * @dev Library for managing addresses assigned to a Role.

 */

library Roles {

    struct Role {

        mapping (address => bool) bearer;

    }



    /**

     * @dev Give an account access to this role.

     */

    function add(Role storage role, address account) internal {

        require(!has(role, account), "Roles: account already has role");

        role.bearer[account] = true;

    }



    /**

     * @dev Remove an account's access to this role.

     */

    function remove(Role storage role, address account) internal {

        require(has(role, account), "Roles: account does not have role");

        role.bearer[account] = false;

    }



    /**

     * @dev Check if an account has this role.

     * @return bool

     */

    function has(Role storage role, address account) internal view returns (bool) {

        require(account != address(0), "Roles: account is the zero address");

        return role.bearer[account];

    }

}



// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol



pragma solidity ^0.5.0;





contract MinterRole {

    using Roles for Roles.Role;



    event MinterAdded(address indexed account);

    event MinterRemoved(address indexed account);



    Roles.Role private _minters;



    constructor () internal {

        _addMinter(msg.sender);

    }



    modifier onlyMinter() {

        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");

        _;

    }



    function isMinter(address account) public view returns (bool) {

        return _minters.has(account);

    }



    function addMinter(address account) public onlyMinter {

        _addMinter(account);

    }



    function renounceMinter() public {

        _removeMinter(msg.sender);

    }



    function _addMinter(address account) internal {

        _minters.add(account);

        emit MinterAdded(account);

    }



    function _removeMinter(address account) internal {

        _minters.remove(account);

        emit MinterRemoved(account);

    }

}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol



pragma solidity ^0.5.0;







/**

 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,

 * which have permission to mint (create) new tokens as they see fit.

 *

 * At construction, the deployer of the contract is the only minter.

 */

contract ERC20Mintable is ERC20, MinterRole {

    /**

     * @dev See `ERC20._mint`.

     *

     * Requirements:

     *

     * - the caller must have the `MinterRole`.

     */

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {

        _mint(account, amount);

        return true;

    }

}



// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol



pragma solidity ^0.5.0;





/**

 * @dev Extension of `ERC20` that allows token holders to destroy both their own

 * tokens and those that they have an allowance for, in a way that can be

 * recognized off-chain (via event analysis).

 */

contract ERC20Burnable is ERC20 {

    /**

     * @dev Destoys `amount` tokens from the caller.

     *

     * See `ERC20._burn`.

     */

    function burn(uint256 amount) public {

        _burn(msg.sender, amount);

    }



    /**

     * @dev See `ERC20._burnFrom`.

     */

    function burnFrom(address account, uint256 amount) public {

        _burnFrom(account, amount);

    }

}



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



// File: contracts/compound/ICErc20.sol



/**

Copyright 2019 PoolTogether LLC



This file is part of PoolTogether.



PoolTogether is free software: you can redistribute it and/or modify

it under the terms of the GNU General Public License as published by

the Free Software Foundation under version 3 of the License.



PoolTogether is distributed in the hope that it will be useful,

but WITHOUT ANY WARRANTY; without even the implied warranty of

MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the

GNU General Public License for more details.



You should have received a copy of the GNU General Public License

along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.

*/



pragma solidity ^0.5.2;


contract ICErc20 {

    address public underlying;

    function mint(uint256 mintAmount) external returns (uint);

    function balanceOfUnderlying(address owner) external view returns (uint);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

}



// File: contracts/DAIPointsToken.sol



pragma solidity ^0.5.2;




















/**

* @title DAIPoints token contract

* @author LiorRabin

*/

contract DAIPointsToken is ERC677, ERC20Detailed, ERC20Mintable, ERC20Burnable, Ownable {

  using SafeMath for uint256;



  uint256 public constant DECIMALS = 10 ** 18;



  IERC20 public dai;

  ICErc20 public compound;

  uint256 public daiToDaipConversionRate = 100;

  address public bridge;

  uint256 public fee;



  constructor (address _dai, address _compound) public

    ERC20Detailed('DAIPoints', 'DAIp', 18) {

      setDAI(_dai);

      setCompound(_compound);

    }



  /**

  * @dev Function to be called by owner only to set the DAI token address

  * @param _address DAI token address

  */

  function setDAI(address _address) public onlyOwner {

    require(_address != address(0) && Address.isContract(_address));

    dai = IERC20(_address);

  }



  /**

  * @dev Function to be called by owner only to set the Compound address

  * @param _address Compound address

  */

  function setCompound(address _address) public onlyOwner {

    require(_address != address(0) && Address.isContract(_address));

    compound = ICErc20(_address);

  }



  /**

  * @dev Function to be called by owner only to set the fee

  * @param _fee Fee amount

  */

  function setFee(uint256 _fee) public onlyOwner {

    require(fee <= DECIMALS);

    fee = _fee;

  }



  /**

  * @dev Function to be called by owner only to set the bridge address

  * @param _address bridge address

  */

  function setBridge(address _address) public onlyOwner {

    require(_address != address(0) && Address.isContract(_address));

    bridge = _address;

  }



  /**

  * @dev Function to be called by owner only to set the DAI to DAIPoints conversion rate

  * @param _rate amount of DAIPoints equal to 1 DAI

  */

  function setConversionRate(uint256 _rate) public onlyOwner {

    require(_rate > 0);

    daiToDaipConversionRate = _rate;

  }



  /**

  * @dev Get DAIPoints (minted) in exchange for DAI, according to the conversion rate

  * @param _amount amount (in wei) of DAI to be transferred from msg.sender balance to this contract's balance

  */

  function getDAIPoints(uint256 _amount) public bridgeExists returns(bool) {

    getDAIPointsToAddress(_amount, msg.sender);

  }



  /**

  * @dev Get DAIPoints (minted) in exchange for DAI and send to specific address, according to the conversion rate

  * @param _amount amount (in wei) of DAI to be transferred from msg.sender balance to this contract's balance

  * @param _recipient address address to receive the _amount

  */

  function getDAIPointsToAddress(uint256 _amount, address _recipient) public bridgeExists returns(bool) {

    // Transfer DAI into this contract

    require(dai.transferFrom(msg.sender, address(this), _amount), "DAI/transferFrom");



    // Mint DAIPoints

    uint256 daipAmount = _amount.mul(daiToDaipConversionRate);

    _mint(address(this), daipAmount);



    // Transfer DAIPoints (on other side) to _recipient using the bridge

    require(ERC677(address(this)).transferAndCall(bridge, daipAmount, abi.encodePacked(_recipient)), "DAIPoints/transferAndCall");



    // Deposit into Compound

    require(dai.approve(address(compound), _amount), "DAI/approve");

    require(compound.mint(_amount) == 0, "Compound/mint");



    return true;

  }



  /**

  * @dev Override ERC20 transfer function

  * @param _recipient address to receive the _amount exchanged into DAI

  * @param _amount amount (in wei) of DAIPoints to be exchanged into DAI and transferred to _recipient

  */

  function transfer(address _recipient, uint256 _amount) public returns (bool) {

    uint256 daiAmount = _amount.div(daiToDaipConversionRate);



    // Withdraw from Compound and transfer

    require(compound.redeemUnderlying(daiAmount) == 0, "Compound/redeemUnderlying");



    // Burn DAIPoints

    _burn(msg.sender, _amount);



    // Transfer DAI to the recipient

    require(dai.approve(address(this), daiAmount), "DAI/approve");

    require(dai.transferFrom(address(this), _recipient, daiAmount), "DAI/transferFrom");



    return true;

  }



  /**

  * @dev Function to be called by owner only to reward DAIPoints (per DAI interest in Compound)

  * @param _winner address to receive reward

  */

  function reward(address _winner) public onlyOwner bridgeExists {

    // Calculate the gross winnings, fee and reward amount (in DAI)

    uint256 grossWinningsAmount = _grossWinnings();

    uint256 rewardAmount = grossWinningsAmount.mul(DECIMALS.sub(fee)).div(DECIMALS);

    uint256 feeAmount = grossWinningsAmount.sub(rewardAmount);



    // Mint DAIPoints

    uint256 daipRewardAmount = rewardAmount.mul(daiToDaipConversionRate);

    _mint(address(this), daipRewardAmount);



    // Transfer reward (on other side) to the winner using the bridge

    require(ERC677(address(this)).transferAndCall(bridge, daipRewardAmount, abi.encodePacked(_winner)), "DAIPoints/transferAndCall");



    // Transfer fee (in DAI) to the owner

    if (feeAmount > 0) {

      // Withdraw from Compound and transfer

      require(compound.redeemUnderlying(feeAmount) == 0, "Compound/redeemUnderlying");



      // Transfer DAI to the recipient

      require(dai.approve(address(this), feeAmount), "DAI/approve");

      require(dai.transferFrom(address(this), owner(), feeAmount), "DAI/transferFrom");

    }

  }



  function _grossWinnings() private view returns(uint256) {

    (uint256 error, uint256 compoundBalance, uint256 borrowBalance, uint256 exchangeRateMantissa) = compound.getAccountSnapshot(address(this));

    require(error == 0);

    uint256 compoundValue = compoundBalance.mul(exchangeRateMantissa).div(1e18);



    uint256 totalSupply = ERC20(address(this)).totalSupply().div(daiToDaipConversionRate);



    return compoundValue.sub(totalSupply);

  }



  /**

  * @dev This modifier verifies that the change initiated has not been finalized yet

  */

  modifier bridgeExists() {

    require(bridge != address(0));

    _;

  }

}