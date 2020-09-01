
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
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
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts/interfaces/IAZTEC.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title IAZTEC
 * @author AZTEC
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
contract IAZTEC {
    enum ProofCategory {
        NULL,
        BALANCED,
        MINT,
        BURN,
        UTILITY
    }

    enum NoteStatus {
        DOES_NOT_EXIST,
        UNSPENT,
        SPENT
    }
    // proofEpoch = 1 | proofCategory = 1 | proofId = 1
    // 1 * 256**(2) + 1 * 256**(1) ++ 1 * 256**(0)
    uint24 public constant JOIN_SPLIT_PROOF = 65793;

    // proofEpoch = 1 | proofCategory = 2 | proofId = 1
    // (1 * 256**(2)) + (2 * 256**(1)) + (1 * 256**(0))
    uint24 public constant MINT_PROOF = 66049;

    // proofEpoch = 1 | proofCategory = 3 | proofId = 1
    // (1 * 256**(2)) + (3 * 256**(1)) + (1 * 256**(0))
    uint24 public constant BURN_PROOF = 66305;

    // proofEpoch = 1 | proofCategory = 4 | proofId = 2
    // (1 * 256**(2)) + (4 * 256**(1)) + (2 * 256**(0))
    uint24 public constant PRIVATE_RANGE_PROOF = 66562;

        // proofEpoch = 1 | proofCategory = 4 | proofId = 3
    // (1 * 256**(2)) + (4 * 256**(1)) + (2 * 256**(0))
    uint24 public constant PUBLIC_RANGE_PROOF = 66563;

    // proofEpoch = 1 | proofCategory = 4 | proofId = 1
    // (1 * 256**(2)) + (4 * 256**(1)) + (2 * 256**(0))
    uint24 public constant DIVIDEND_PROOF = 66561;
}

// File: contracts/libs/VersioningUtils.sol

pragma solidity >= 0.5.0 <0.6.0;

/**
 * @title VersioningUtils
 * @author AZTEC
 * @dev Library of versioning utility functions
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
library VersioningUtils {

    /**
     * @dev We compress three uint8 numbers into only one uint24 to save gas.
     * @param version The compressed uint24 number.
     * @return A tuple (uint8, uint8, uint8) representing the the deconstructed version.
     */
    function getVersionComponents(uint24 version) internal pure returns (uint8 first, uint8 second, uint8 third) {
        assembly {
            third := and(version, 0xff)
            second := and(div(version, 0x100), 0xff)
            first := and(div(version, 0x10000), 0xff)
        }
        return (first, second, third);
    }
}

// File: contracts/interfaces/IERC20Mintable.sol

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title IERC20Mintable
 * @dev Interface for ERC20 with minting function
 * Sourced from OpenZeppelin 
 * (https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/IERC20.sol) 
 * and with an added mint() function. The mint function is necessary because a ZkAssetMintable 
 * may need to be able to mint from the linked note registry token. This need arises when the 
 * total supply does not meet the extracted value
 * (due to having called confidentialMint())
 */
interface IERC20Mintable {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function mint(address _to, uint256 _value) external returns (bool);   


    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ACE/noteRegistry/interfaces/NoteRegistryBehaviour.sol

pragma solidity >=0.5.0 <0.6.0;




/**
 * @title NoteRegistryBehaviour interface which defines the base API
        which must be implemented for every behaviour contract.
 * @author AZTEC
 * @dev This interface will mostly be used by ACE, in order to have an API to
        interact with note registries through proxies.
 * The implementation of all write methods should have an onlyOwner modifier.
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
contract NoteRegistryBehaviour is Ownable, IAZTEC {
    using SafeMath for uint256;

    bool public isActiveBehaviour;
    bool public initialised;
    address public dataLocation;

    constructor () Ownable() public {
        isActiveBehaviour = true;
    }

    /**
        * @dev Initialises the data of a noteRegistry. Should be called exactly once.
        *
        * @param _newOwner - the address which the initialise call will transfer ownership to
        * @param _scalingFactor - defines the number of tokens that an AZTEC note value of 1 maps to.
        * @param _canAdjustSupply - whether the noteRegistry can make use of minting and burning
        * @param _canConvert - whether the noteRegistry can transfer value from private to public
            representation and vice versa
    */
    function initialise(
        address _newOwner,
        uint256 _scalingFactor,
        bool _canAdjustSupply,
        bool _canConvert
    ) public;

    /**
        * @dev Fetches data of the registry
        *
        * @return scalingFactor - defines the number of tokens that an AZTEC note value of 1 maps to.
        * @return confidentialTotalMinted - the hash of the AZTEC note representing the total amount
            which has been minted.
        * @return confidentialTotalBurned - the hash of the AZTEC note representing the total amount
            which has been burned.
        * @return canConvert - the boolean whih defines if the noteRegistry can convert between
            public and private.
        * @return canConvert - the boolean whih defines if the noteRegistry can make use of
            minting and burning methods.
    */
    function getRegistry() public view returns (
        uint256 scalingFactor,
        bytes32 confidentialTotalMinted,
        bytes32 confidentialTotalBurned,
        bool canConvert,
        bool canAdjustSupply
    );

    /**
        * @dev Enacts the state modifications needed given a successfully validated burn proof
        *
        * @param _proofOutputs - the output of the burn validator
    */
    function burn(bytes memory _proofOutputs) public;

    /**
        * @dev Enacts the state modifications needed given a successfully validated mint proof
        *
        * @param _proofOutputs - the output of the mint validator
    */
    function mint(bytes memory _proofOutputs) public;

    /**
        * @dev Enacts the state modifications needed given the output of a successfully validated proof.
        * The _proofId param is used by the behaviour contract to (if needed) restrict the versions of proofs
        * which the note registry supports, useful in case the proofOutputs schema changes for example.
        *
        * @param _proof - the id of the proof
        * @param _proofOutput - the output of the proof validator
        *
        * @return publicOwner - the non-ACE party involved in this transaction. Either current or desired
        *   owner of public tokens
        * @return transferValue - the total public token value to transfer. Seperate value to abstract
        *   away scaling factors in first version of AZTEC
        * @return publicValue - the kPublic value to be used in zero-knowledge proofs
    */
    function updateNoteRegistry(
        uint24 _proof,
        bytes memory _proofOutput
    ) public returns (
        address publicOwner,
        uint256 transferValue,
        int256 publicValue
    );

    /**
        * @dev Sets confidentialTotalMinted to a new value. The value must be the hash of a note;
        *
        * @param _newTotalNoteHash - the hash of the note representing the total minted value for an asset.
    */
    function setConfidentialTotalMinted(bytes32 _newTotalNoteHash) internal returns (bytes32);

    /**
        * @dev Sets confidentialTotalBurned to a new value. The value must be the hash of a note;
        *
        * @param _newTotalNoteHash - the hash of the note representing the total burned value for an asset.
    */
    function setConfidentialTotalBurned(bytes32 _newTotalNoteHash) internal returns (bytes32);

    /**
        * @dev Gets a defined note from the note registry, and returns the deconstructed object.
            This is to avoid the interface to be
        * _too_ opninated on types, even though it does require any subsequent note type to have
            (or be able to mock) the return fields.
        *
        * @param _noteHash - the hash of the note being fetched
        *
        * @return status - whether a note has been spent or not
        * @return createdOn - timestamp of the creation time of the note
        * @return destroyedOn - timestamp of the time the note was destroyed (if it has been destroyed, 0 otherwise)
        * @return noteOwner - address of the stored owner of the note
    */
    function getNote(bytes32 _noteHash) public view returns (
        uint8 status,
        uint40 createdOn,
        uint40 destroyedOn,
        address noteOwner
    );

    /**
        * @dev Internal function to update the noteRegistry given a bytes array.
        *
        * @param _inputNotes - a bytes array containing notes
    */
    function updateInputNotes(bytes memory _inputNotes) internal;

    /**
        * @dev Internal function to update the noteRegistry given a bytes array.
        *
        * @param _outputNotes - a bytes array containing notes
    */
    function updateOutputNotes(bytes memory _outputNotes) internal;

    /**
        * @dev Internal function to create a new note object.
        *
        * @param _noteHash - the noteHash
        * @param _noteOwner - the address of the owner of the note
    */
    function createNote(bytes32 _noteHash, address _noteOwner) internal;

    /**
        * @dev Internal function to delete a note object.
        *
        * @param _noteHash - the noteHash
        * @param _noteOwner - the address of the owner of the note
    */
    function deleteNote(bytes32 _noteHash, address _noteOwner) internal;

    /**
        * @dev Public function used during slow release phase to manually enable an asset.
    */
    function makeAvailable() public;
}

// File: contracts/interfaces/ProxyAdmin.sol

pragma solidity ^0.5.0;

/**
 * @title ProxyAdmin
 * @dev Minimal interface for the proxy contract
 */
contract ProxyAdmin {
    function admin() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function changeAdmin(address _newAdmin) external;
}

// File: contracts/ACE/noteRegistry/interfaces/NoteRegistryFactory.sol

pragma solidity >=0.5.0 <0.6.0;






/**
 * @title NoteRegistryFactory
 * @author AZTEC
 * @dev Interface definition for factories. Factory contracts have the responsibility of managing the full lifecycle of
 * Behaviour contracts, from deploy to eventual upgrade. They are owned by ACE, and all methods should only be callable
 * by ACE.
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 **/
contract NoteRegistryFactory is IAZTEC, Ownable  {
    event NoteRegistryDeployed(address behaviourContract);

    constructor(address _aceAddress) public Ownable() {
        transferOwnership(_aceAddress);
    }

    function deployNewBehaviourInstance() public returns (address);

    function handoverBehaviour(address _proxy, address _newImplementation, address _newProxyAdmin) public onlyOwner {
        require(ProxyAdmin(_proxy).admin() == address(this), "this is not the admin of the proxy");
        ProxyAdmin(_proxy).upgradeTo(_newImplementation);
        ProxyAdmin(_proxy).changeAdmin(_newProxyAdmin);
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/Proxies/Proxy.sol

pragma solidity ^0.5.0;

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

// File: contracts/Proxies/BaseUpgradeabilityProxy.sol

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
    * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    * validated in the constructor.
    */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
        require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
        sstore(slot, newImplementation)
        }
    }
}

// File: contracts/Proxies/UpgradeabilityProxy.sol

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
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            (bool success,) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// File: contracts/Proxies/BaseAdminUpgradeabilityProxy.sol

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
    * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    * validated in the constructor.
    */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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

// File: contracts/Proxies/AdminUpgradeabilityProxy.sol

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
        assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
        require(_admin != address(0x0), "Cannot set the admin address to address(0x0)");
        _setAdmin(_admin);
    }
}

// File: contracts/ACE/noteRegistry/NoteRegistryManager.sol

pragma solidity >=0.5.0 <0.6.0;










/**
 * @title NoteRegistryManager
 * @author AZTEC
 * @dev NoteRegistryManager will be inherrited by ACE, and its purpose is to manage the entire
        lifecycle of noteRegistries and of
        factories. It defines the methods which are used to deploy and upgrade registries, the methods
        to enact state changes sent by
        the owner of a registry, and it also manages the list of factories which are available.
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
contract NoteRegistryManager is IAZTEC, Ownable {
    using SafeMath for uint256;
    using VersioningUtils for uint24;

    /**
    * @dev event transmitted if and when a factory gets registered.
    */
    event SetFactory(
        uint8 indexed epoch,
        uint8 indexed cryptoSystem,
        uint8 indexed assetType,
        address factoryAddress
    );

    event CreateNoteRegistry(
        address registryOwner,
        address registryAddress,
        uint256 scalingFactor,
        address linkedTokenAddress,
        bool canAdjustSupply,
        bool canConvert
    );

    event UpgradeNoteRegistry(
        address registryOwner,
        address proxyAddress,
        address newBehaviourAddress
    );

    // Every user has their own note registry

    struct NoteRegistry {
        NoteRegistryBehaviour behaviour;
        IERC20Mintable linkedToken;
        uint24 latestFactory;
        uint256 totalSupply;
        uint256 totalSupplemented;
        mapping(address => mapping(bytes32 => uint256)) publicApprovals;
    }

    mapping(address => NoteRegistry) public registries;

    /**
    * @dev index of available factories, using very similar structure to proof registry in ACE.sol.
    * The structure of the index is (epoch, cryptoSystem, assetType).
    */
    address[0x100][0x100][0x10000] factories;


    uint8 public defaultRegistryEpoch = 1;
    uint8 public defaultCryptoSystem = 1;

    mapping(bytes32 => bool) public validatedProofs;

    /**
    * @dev Increment the default registry epoch
    */
    function incrementDefaultRegistryEpoch() public onlyOwner {
        defaultRegistryEpoch = defaultRegistryEpoch + 1;
    }

    /**
    * @dev Set the default crypto system to be used
    * @param _defaultCryptoSystem - default crypto system identifier
    */
    function setDefaultCryptoSystem(uint8 _defaultCryptoSystem) public onlyOwner {
        defaultCryptoSystem = _defaultCryptoSystem;
    }

    /**
    * @dev Register a new Factory, iff no factory for that ID exists.
            The epoch of any new factory must be at least as big as
            the default registry epoch. Each asset type for each cryptosystem for
            each epoch should have a note registry
    *
    * @param _factoryId - uint24 which contains 3 uint8s representing (epoch, cryptoSystem, assetType)
    * @param _factoryAddress - address of the deployed factory
    */
    function setFactory(uint24 _factoryId, address _factoryAddress) public onlyOwner {
        require(_factoryAddress != address(0x0), "expected the factory contract to exist");
        (uint8 epoch, uint8 cryptoSystem, uint8 assetType) = _factoryId.getVersionComponents();
        require(factories[epoch][cryptoSystem][assetType] == address(0x0), "existing factories cannot be modified");
        factories[epoch][cryptoSystem][assetType] = _factoryAddress;
        emit SetFactory(epoch, cryptoSystem, assetType, _factoryAddress);
    }

    /**
    * @dev Get the factory address associated with a particular factoryId. Fail if resulting address is 0x0.
    *
    * @param _factoryId - uint24 which contains 3 uint8s representing (epoch, cryptoSystem, assetType)
    */
    function getFactoryAddress(uint24 _factoryId) public view returns (address factoryAddress) {
        bool queryInvalid;
        assembly {
            // To compute the storage key for factoryAddress[epoch][cryptoSystem][assetType], we do the following:
            // 1. get the factoryAddress slot
            // 2. add (epoch * 0x10000) to the slot
            // 3. add (cryptoSystem * 0x100) to the slot
            // 4. add (assetType) to the slot
            // i.e. the range of storage pointers allocated to factoryAddress ranges from
            // factoryAddress_slot to (0xffff * 0x10000 + 0xff * 0x100 + 0xff = factoryAddress_slot 0xffffffff)

            // Conveniently, the multiplications we have to perform on epoch, cryptoSystem and assetType correspond
            // to their byte positions in _factoryId.
            // i.e. (epoch * 0x10000) = and(_factoryId, 0xff0000)
            // and  (cryptoSystem * 0x100) = and(_factoryId, 0xff00)
            // and  (assetType) = and(_factoryId, 0xff)

            // Putting this all together. The storage slot offset from '_factoryId' is...
            // (_factoryId & 0xffff0000) + (_factoryId & 0xff00) + (_factoryId & 0xff)
            // i.e. the storage slot offset IS the value of _factoryId
            factoryAddress := sload(add(_factoryId, factories_slot))

            queryInvalid := iszero(factoryAddress)
        }

        // wrap both require checks in a single if test. This means the happy path only has 1 conditional jump
        if (queryInvalid) {
            require(factoryAddress != address(0x0), "expected the factory address to exist");
        }
    }

    /**
    * @dev called when a mintable and convertible asset wants to perform an
            action which puts the zero-knowledge and public
            balance out of balance. For example, if minting in zero-knowledge, some
            public tokens need to be added to the pool
            managed by ACE, otherwise any private->public conversion runs the risk of not
            having any public tokens to send.
    *
    * @param _value the value to be added
    */
    function supplementTokens(uint256 _value) external {
        NoteRegistry storage registry = registries[msg.sender];
        require(address(registry.behaviour) != address(0x0), "note registry does not exist");
        registry.totalSupply = registry.totalSupply.add(_value);
        registry.totalSupplemented = registry.totalSupplemented.add(_value);
        (
            uint256 scalingFactor,
            ,,
            bool canConvert,
            bool canAdjustSupply
        ) = registry.behaviour.getRegistry();
        require(canConvert == true, "note registry does not have conversion rights");
        require(canAdjustSupply == true, "note registry does not have mint and burn rights");
        registry.linkedToken.transferFrom(msg.sender, address(this), _value.mul(scalingFactor));
    }

    /**
    * @dev Query the ACE for a previously validated proof
    * @notice This is a virtual function, that must be overwritten by the contract that inherits from NoteRegistry
    *
    * @param _proof - unique identifier for the proof in question and being validated
    * @param _proofHash - keccak256 hash of a bytes proofOutput argument. Used to identify the proof in question
    * @param _sender - address of the entity that originally validated the proof
    * @return boolean - true if the proof has previously been validated, false if not
    */
    function validateProofByHash(uint24 _proof, bytes32 _proofHash, address _sender) public view returns (bool);

    /**
    * @dev Default noteRegistry creation method. Doesn't take the id of the factory to use,
            but generates it based on defaults and on the passed flags.
    *
    * @param _linkedTokenAddress - address of any erc20 linked token (can not be 0x0 if canConvert is true)
    * @param _scalingFactor - defines the number of tokens that an AZTEC note value of 1 maps to.
    * @param _canAdjustSupply - whether the noteRegistry can make use of minting and burning
    * @param _canConvert - whether the noteRegistry can transfer value from private to public
        representation and vice versa
    */
    function createNoteRegistry(
        address _linkedTokenAddress,
        uint256 _scalingFactor,
        bool _canAdjustSupply,
        bool _canConvert
    ) public {
        uint8 assetType = getAssetTypeFromFlags(_canConvert, _canAdjustSupply);

        uint24 factoryId = computeVersionFromComponents(defaultRegistryEpoch, defaultCryptoSystem, assetType);

        createNoteRegistry(
            _linkedTokenAddress,
            _scalingFactor,
            _canAdjustSupply,
            _canConvert,
            factoryId
        );
    }

    /**
    * @dev NoteRegistry creation method. Takes an id of the factory to use.
    *
    * @param _linkedTokenAddress - address of any erc20 linked token (can not be 0x0 if canConvert is true)
    * @param _scalingFactor - defines the number of tokens that an AZTEC note value of 1 maps to.
    * @param _canAdjustSupply - whether the noteRegistry can make use of minting and burning
    * @param _canConvert - whether the noteRegistry can transfer value from private to public
        representation and vice versa
    * @param _factoryId - uint24 which contains 3 uint8s representing (epoch, cryptoSystem, assetType)
    */
    function createNoteRegistry(
        address _linkedTokenAddress,
        uint256 _scalingFactor,
        bool _canAdjustSupply,
        bool _canConvert,
        uint24 _factoryId
    ) public {
        require(address(registries[msg.sender].behaviour) == address(0x0),
            "address already has a linked note registry");
        if (_canConvert) {
            require(_linkedTokenAddress != address(0x0), "expected the linked token address to exist");
        }
        (,, uint8 assetType) = _factoryId.getVersionComponents();
        // assetType is 0b00 where the bits represent (canAdjust, canConvert),
        // so assetType can be one of 1, 2, 3 where
        // 0 == no convert/no adjust (invalid)
        // 1 == can convert/no adjust
        // 2 == no convert/can adjust
        // 3 == can convert/can adjust
        uint8 flagAssetType = getAssetTypeFromFlags(_canConvert, _canAdjustSupply);
        require (flagAssetType != uint8(0), "can not create asset with convert and adjust flags set to false");
        require (flagAssetType == assetType, "expected note registry to match flags");

        address factory = getFactoryAddress(_factoryId);

        address behaviourAddress = NoteRegistryFactory(factory).deployNewBehaviourInstance();

        bytes memory behaviourInitialisation = abi.encodeWithSignature(
            "initialise(address,uint256,bool,bool)",
            address(this),
            _scalingFactor,
            _canAdjustSupply,
            _canConvert
        );
        address proxy = address(new AdminUpgradeabilityProxy(
            behaviourAddress,
            factory,
            behaviourInitialisation
        ));

        registries[msg.sender] = NoteRegistry({
            behaviour: NoteRegistryBehaviour(proxy),
            linkedToken: IERC20Mintable(_linkedTokenAddress),
            latestFactory: _factoryId,
            totalSupply: 0,
            totalSupplemented: 0
        });

        emit CreateNoteRegistry(
            msg.sender,
            proxy,
            _scalingFactor,
            _linkedTokenAddress,
            _canAdjustSupply,
            _canConvert
        );
    }

    /**
    * @dev Method to upgrade the registry linked with the msg.sender to a new factory, based on _factoryId.
    * The submitted _factoryId must be of epoch equal or greater than previous _factoryId, and of the same assetType.
    *
    * @param _factoryId - uint24 which contains 3 uint8s representing (epoch, cryptoSystem, assetType)
    */
    function upgradeNoteRegistry(
        uint24 _factoryId
    ) public {
        NoteRegistry storage registry = registries[msg.sender];
        require(address(registry.behaviour) != address(0x0), "note registry for sender doesn't exist");

        (uint8 epoch,, uint8 assetType) = _factoryId.getVersionComponents();
        uint24 oldFactoryId = registry.latestFactory;
        (uint8 oldEpoch,, uint8 oldAssetType) = oldFactoryId.getVersionComponents();
        require(epoch >= oldEpoch, "expected new registry to be of epoch equal or greater than existing registry");
        require(assetType == oldAssetType, "expected assetType to be the same for old and new registry");

        address factory = getFactoryAddress(_factoryId);
        address newBehaviour = NoteRegistryFactory(factory).deployNewBehaviourInstance();

        address oldFactory = getFactoryAddress(oldFactoryId);
        registry.latestFactory = _factoryId;

        NoteRegistryFactory(oldFactory).handoverBehaviour(address(registry.behaviour), newBehaviour, factory);
        emit UpgradeNoteRegistry(
            msg.sender,
            address(registry.behaviour),
            newBehaviour
        );
    }

    /**
    * @dev Internal method dealing with permissioning and transfer of public tokens.
    *
    * @param _publicOwner - the non-ACE party involved in this transaction. Either current or desired
    *   owner of public tokens
    * @param _transferValue - the total public token value to transfer. Seperate value to abstract
    *   away scaling factors in first version of AZTEC
    * @param _publicValue - the kPublic value to be used in zero-knowledge proofs
    * @param _proofHash - usef for permissioning, hash of the proof that this spend is enacting
    *
    */
    function transferPublicTokens(
        address _publicOwner,
        uint256 _transferValue,
        int256 _publicValue,
        bytes32 _proofHash
    )
        internal
    {
        NoteRegistry storage registry = registries[msg.sender];
        // if < 0, depositing
        // else withdrawing
        if (_publicValue < 0) {
            uint256 approvalForAddressForHash = registry.publicApprovals[_publicOwner][_proofHash];
            registry.totalSupply = registry.totalSupply.add(uint256(-_publicValue));
            require(
                approvalForAddressForHash >= uint256(-_publicValue),
                "public owner has not validated a transfer of tokens"
            );

            registry.publicApprovals[_publicOwner][_proofHash] = approvalForAddressForHash.sub(uint256(-_publicValue));
            registry.linkedToken.transferFrom(
                _publicOwner,
                address(this),
                _transferValue);
        } else {
            registry.totalSupply = registry.totalSupply.sub(uint256(_publicValue));
            registry.linkedToken.transfer(
                _publicOwner,
                _transferValue
            );
        }
    }

    /**
    * @dev Update the state of the note registry according to transfer instructions issued by a
    * zero-knowledge proof. This method will verify that the relevant proof has been validated,
    * make sure the same proof has can't be re-used, and it then delegates to the relevant noteRegistry.
    *
    * @param _proof - unique identifier for a proof
    * @param _proofOutput - transfer instructions issued by a zero-knowledge proof
    * @param _proofSender - address of the entity sending the proof
    */
    function updateNoteRegistry(
        uint24 _proof,
        bytes memory _proofOutput,
        address _proofSender
    ) public {
        NoteRegistry memory registry = registries[msg.sender];
        require(address(registry.behaviour) != address(0x0), "note registry does not exist");
        bytes32 proofHash = keccak256(_proofOutput);
        bytes32 validatedProofHash = keccak256(abi.encode(proofHash, _proof, msg.sender));

        require(
            validateProofByHash(_proof, proofHash, _proofSender) == true,
            "ACE has not validated a matching proof"
        );
        // clear record of valid proof - stops re-entrancy attacks and saves some gas
        validatedProofs[validatedProofHash] = false;

        (
            address publicOwner,
            uint256 transferValue,
            int256 publicValue
        ) = registry.behaviour.updateNoteRegistry(_proof, _proofOutput);
        if (publicValue != 0) {
            transferPublicTokens(publicOwner, transferValue, publicValue, proofHash);
        }
    }

    /**
    * @dev Adds a public approval record to the noteRegistry, for use by ACE when it needs to transfer
        public tokens it holds to an external address. It needs to be associated with the hash of a proof.
    */
    function publicApprove(address _registryOwner, bytes32 _proofHash, uint256 _value) public {
        NoteRegistry storage registry = registries[_registryOwner];
        require(address(registry.behaviour) != address(0x0), "note registry does not exist");
        registry.publicApprovals[msg.sender][_proofHash] = _value;
    }

    /**
     * @dev Returns the registry for a given address.
     *
     * @param _registryOwner - address of the registry owner in question
     *
     * @return linkedTokenAddress - public ERC20 token that is linked to the NoteRegistry. This is used to
     * transfer public value into and out of the system
     * @return scalingFactor - defines how many ERC20 tokens are represented by one AZTEC note
     * @return totalSupply - represents the total current supply of public tokens associated with a particular registry
     * @return confidentialTotalMinted - keccak256 hash of the note representing the total minted supply
     * @return confidentialTotalBurned - keccak256 hash of the note representing the total burned supply
     * @return canConvert - flag set by the owner to decide whether the registry has public to private, and
     * vice versa, conversion privilege
     * @return canAdjustSupply - determines whether the registry has minting and burning privileges
     */
    function getRegistry(address _registryOwner) public view returns (
        address linkedToken,
        uint256 scalingFactor,
        bytes32 confidentialTotalMinted,
        bytes32 confidentialTotalBurned,
        uint256 totalSupply,
        uint256 totalSupplemented,
        bool canConvert,
        bool canAdjustSupply
    ) {
        NoteRegistry memory registry = registries[_registryOwner];
        (
            scalingFactor,
            confidentialTotalMinted,
            confidentialTotalBurned,
            canConvert,
            canAdjustSupply
        ) = registry.behaviour.getRegistry();
        linkedToken = address(registry.linkedToken);
        totalSupply = registry.totalSupply;
        totalSupplemented = registry.totalSupplemented;
    }

    /**
     * @dev Returns the note for a given address and note hash.
     *
     * @param _registryOwner - address of the registry owner
     * @param _noteHash - keccak256 hash of the note coordiantes (gamma and sigma)
     *
     * @return status - status of the note, details whether the note is in a note registry
     * or has been destroyed
     * @return createdOn - time the note was created
     * @return destroyedOn - time the note was destroyed
     * @return noteOwner - address of the note owner
     */
    function getNote(address _registryOwner, bytes32 _noteHash) public view returns (
        uint8 status,
        uint40 createdOn,
        uint40 destroyedOn,
        address noteOwner
    ) {
        NoteRegistry memory registry = registries[_registryOwner];
        return registry.behaviour.getNote(_noteHash);
    }

    /**
    * @dev Internal utility method which converts two booleans into a uint8 where the first boolean
    * represents (1 == true, 0 == false) the bit in position 1, and the second boolean the bit in position 2.
    * The output is 1 for an asset which can convert between public and private, 2 for one with no conversion
    * but with the ability to mint and/or burn, and 3 for a mixed asset which can convert and mint/burn
    *
    */
    function getAssetTypeFromFlags(bool _canConvert, bool _canAdjust) internal pure returns (uint8 assetType) {
        uint8 convert = _canConvert ? 1 : 0;
        uint8 adjust = _canAdjust ? 2 : 0;

        assetType = convert + adjust;
    }

    /**
    * @dev Internal utility method which converts three uint8s into a uint24
    *
    */
    function computeVersionFromComponents(
        uint8 _first,
        uint8 _second,
        uint8 _third
    ) internal pure returns (uint24 version) {
        assembly {
            version := or(mul(_first, 0x10000), or(mul(_second, 0x100), _third))
        }
    }

    /**
    * @dev used for slow release, useless afterwards.
    */
    function makeAssetAvailable(address _registryOwner) public onlyOwner {
        NoteRegistry memory registry = registries[_registryOwner];
        registry.behaviour.makeAvailable();
    }
}

// File: contracts/libs/NoteUtils.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title NoteUtils
 * @author AZTEC
 * @dev NoteUtils is a utility library that extracts user-readable information from AZTEC proof outputs.
 *      Specifically, `bytes proofOutput` objects can be extracted from `bytes proofOutputs`,
 *      `bytes proofOutput` and `bytes note` can be extracted into their constituent components,
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
library NoteUtils {

    /**
    * @dev Get the number of entries in an AZTEC-ABI array (bytes proofOutputs, bytes inputNotes, bytes outputNotes)
    *      All 3 are rolled into a single function to eliminate 'wet' code - the implementations are identical
    * @param _proofOutputsOrNotes `proofOutputs`, `inputNotes` or `outputNotes`
    * @return number of entries in the pseudo dynamic array
    */
    function getLength(bytes memory _proofOutputsOrNotes) internal pure returns (
        uint len
    ) {
        assembly {
            // first word = the raw byte length
            // second word = the actual number of entries (hence the 0x20 offset)
            len := mload(add(_proofOutputsOrNotes, 0x20))
        }
    }

    /**
    * @dev Get a bytes object out of a dynamic AZTEC-ABI array
    * @param _proofOutputsOrNotes `proofOutputs`, `inputNotes` or `outputNotes`
    * @param _i the desired entry
    * @return number of entries in the pseudo dynamic array
    */
    function get(bytes memory _proofOutputsOrNotes, uint _i) internal pure returns (
        bytes memory out
    ) {
        bool valid;
        assembly {
            // check that i < the number of entries
            valid := lt(
                _i,
                mload(add(_proofOutputsOrNotes, 0x20))
            )
            // memory map of the array is as follows:
            // 0x00 - 0x20 : byte length of array
            // 0x20 - 0x40 : n, the number of entries
            // 0x40 - 0x40 + (0x20 * i) : relative memory offset to start of i'th entry (i <= n)

            // Step 1: compute location of relative memory offset: _proofOutputsOrNotes + 0x40 + (0x20 * i) 
            // Step 2: loaded relative offset and add to _proofOutputsOrNotes to get absolute memory location
            out := add(
                mload(
                    add(
                        add(_proofOutputsOrNotes, 0x40),
                        mul(_i, 0x20)
                    )
                ),
                _proofOutputsOrNotes
            )
        }
        require(valid, "AZTEC array index is out of bounds");
    }

    /**
    * @dev Extract constituent elements of a `bytes _proofOutput` object
    * @param _proofOutput an AZTEC proof output
    * @return inputNotes, AZTEC-ABI dynamic array of input AZTEC notes
    * @return outputNotes, AZTEC-ABI dynamic array of output AZTEC notes
    * @return publicOwner, the Ethereum address of the owner of any public tokens involved in the proof
    * @return publicValue, the amount of public tokens involved in the proof
    *         if (publicValue > 0), this represents a transfer of tokens from ACE to publicOwner
    *         if (publicValue < 0), this represents a transfer of tokens from publicOwner to ACE
    */
    function extractProofOutput(bytes memory _proofOutput) internal pure returns (
        bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue
    ) {
        assembly {
            // memory map of a proofOutput:
            // 0x00 - 0x20 : byte length of proofOutput
            // 0x20 - 0x40 : relative offset to inputNotes
            // 0x40 - 0x60 : relative offset to outputNotes
            // 0x60 - 0x80 : publicOwner
            // 0x80 - 0xa0 : publicValue
            // 0xa0 - 0xc0 : challenge
            inputNotes := add(_proofOutput, mload(add(_proofOutput, 0x20)))
            outputNotes := add(_proofOutput, mload(add(_proofOutput, 0x40)))
            publicOwner := and(
                mload(add(_proofOutput, 0x60)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            publicValue := mload(add(_proofOutput, 0x80))
        }
    }

    /**
    * @dev Extract the challenge from a bytes proofOutput variable
    * @param _proofOutput bytes proofOutput, outputted from a proof validation smart contract
    * @return bytes32 challenge - cryptographic variable that is part of the sigma protocol
    */
    function extractChallenge(bytes memory _proofOutput) internal pure returns (
        bytes32 challenge
    ) {
        assembly {
            challenge := mload(add(_proofOutput, 0xa0))
        }
    }

    /**
    * @dev Extract constituent elements of an AZTEC note
    * @param _note an AZTEC note
    * @return owner, Ethereum address of note owner
    * @return noteHash, the hash of the note's public key
    * @return metadata, note-specific metadata (contains public key and any extra data needed by note owner)
    */
    function extractNote(bytes memory _note) internal pure returns (
            address owner,
            bytes32 noteHash,
            bytes memory metadata
    ) {
        assembly {
            // memory map of a note:
            // 0x00 - 0x20 : byte length of note
            // 0x20 - 0x40 : note type
            // 0x40 - 0x60 : owner
            // 0x60 - 0x80 : noteHash
            // 0x80 - 0xa0 : start of metadata byte array
            owner := and(
                mload(add(_note, 0x40)),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            noteHash := mload(add(_note, 0x60))
            metadata := add(_note, 0x80)
        }
    }
    
    /**
    * @dev Get the note type
    * @param _note an AZTEC note
    * @return noteType
    */
    function getNoteType(bytes memory _note) internal pure returns (
        uint256 noteType
    ) {
        assembly {
            noteType := mload(add(_note, 0x20))
        }
    }
}

// File: contracts/libs/ProofUtils.sol

pragma solidity >= 0.5.0 <0.6.0;

/**
 * @title ProofUtils
 * @author AZTEC
 * @dev Library of proof utility functions
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
library ProofUtils {

    /**
     * @dev We compress three uint8 numbers into only one uint24 to save gas.
     * Reverts if the category is not one of [1, 2, 3, 4].
     * @param proof The compressed uint24 number.
     * @return A tuple (uint8, uint8, uint8) representing the epoch, category and proofId.
     */
    function getProofComponents(uint24 proof) internal pure returns (uint8 epoch, uint8 category, uint8 id) {
        assembly {
            id := and(proof, 0xff)
            category := and(div(proof, 0x100), 0xff)
            epoch := and(div(proof, 0x10000), 0xff)
        }
        return (epoch, category, id);
    }
}

// File: contracts/libs/SafeMath8.sol

pragma solidity >=0.5.0 <= 0.6.0;

/**
 * @title SafeMath8
 * @author AZTEC
 * @dev Library of SafeMath arithmetic operations
 *
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

library SafeMath8 {
    
    /**
    * @dev SafeMath multiplication
    * @param a - uint8 multiplier
    * @param b - uint8 multiplicand
    * @return uint8 result of multiplying a and b
    */
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        uint256 c = uint256(a) * uint256(b);
        require(c < 256, "uint8 mul triggered integer overflow");
        return uint8(c);
    }

    /**
    * @dev SafeMath division
    * @param a - uint8 dividend
    * @param b - uint8 divisor
    * @return uint8 result of dividing a by b
    */
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
        return a / b;
    }

    /**
    * @dev SafeMath subtraction
    * @param a - uint8 minuend
    * @param b - uint8 subtrahend
    * @return uint8 result of subtracting b from a
    */
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a, "uint8 sub triggered integer underflow");
        return a - b;
    }

    /**
    * @dev SafeMath addition
    * @param a - uint8 addend
    * @param b - uint8 addend
    * @return uint8 result of adding a and b
    */
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "uint8 add triggered integer overflow");
        return c;
    }
}

// File: contracts/ACE/ACE.sol

pragma solidity >=0.5.0 <0.6.0;





// TODO: v-- harmonize




/**
 * @title The AZTEC Cryptography Engine
 * @author AZTEC
 * @dev ACE validates the AZTEC protocol's family of zero-knowledge proofs, which enables
 *      digital asset builders to construct fungible confidential digital assets according to the AZTEC token standard.
 * 
 * Copyright 2020 Spilsbury Holdings Ltd 
 *
 * Licensed under the GNU Lesser General Public Licence, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
contract ACE is IAZTEC, Ownable, NoteRegistryManager {
    using NoteUtils for bytes;
    using ProofUtils for uint24;
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    event SetCommonReferenceString(bytes32[6] _commonReferenceString);
    event SetProof(
        uint8 indexed epoch,
        uint8 indexed category,
        uint8 indexed id,
        address validatorAddress
    );
    event IncrementLatestEpoch(uint8 newLatestEpoch);

    // The commonReferenceString contains one G1 group element and one G2 group element,
    // that are created via the AZTEC protocol's trusted setup. All zero-knowledge proofs supported
    // by ACE use the same common reference string.
    bytes32[6] private commonReferenceString;

    // `validators`contains the addresses of the contracts that validate specific proof types
    address[0x100][0x100][0x10000] public validators;

    // a list of invalidated proof ids, used to blacklist proofs in the case of a vulnerability being discovered
    bool[0x100][0x100][0x10000] public disabledValidators;

    // latest proof epoch accepted by this contract
    uint8 public latestEpoch = 1;

    /**
    * @dev contract constructor. Sets the owner of ACE
    **/
    constructor() public Ownable() {}

    /**
    * @dev Mint AZTEC notes
    *
    * @param _proof the AZTEC proof object
    * @param _proofData the mint proof construction data
    * @param _proofSender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return two `bytes` objects. The first contains the new confidentialTotalSupply note and the second contains the
    * notes that were created. Returned so that a zkAsset can emit the appropriate events
    */
    function mint(
        uint24 _proof,
        bytes calldata _proofData,
        address _proofSender
    ) external returns (bytes memory) {

        NoteRegistry memory registry = registries[msg.sender];
        require(address(registry.behaviour) != address(0x0), "note registry does not exist for the given address");

        // Check that it's a mintable proof
        (, uint8 category, ) = _proof.getProofComponents();

        require(category == uint8(ProofCategory.MINT), "this is not a mint proof");

        bytes memory _proofOutputs = this.validateProof(_proof, _proofSender, _proofData);
        require(_proofOutputs.getLength() > 0, "call to validateProof failed");

        registry.behaviour.mint(_proofOutputs);
        return(_proofOutputs);
    }

    /**
    * @dev Burn AZTEC notes
    *
    * @param _proof the AZTEC proof object
    * @param _proofData the burn proof construction data
    * @param _proofSender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return two `bytes` objects. The first contains the new confidentialTotalSupply note and the second contains the
    * notes that were created. Returned so that a zkAsset can emit the appropriate events
    */
    function burn(
        uint24 _proof,
        bytes calldata _proofData,
        address _proofSender
    ) external returns (bytes memory) {
        NoteRegistry memory registry = registries[msg.sender];
        require(address(registry.behaviour) != address(0x0), "note registry does not exist for the given address");

        // Check that it's a burnable proof
        (, uint8 category, ) = _proof.getProofComponents();

        require(category == uint8(ProofCategory.BURN), "this is not a burn proof");

        bytes memory _proofOutputs = this.validateProof(_proof, _proofSender, _proofData);
        require(_proofOutputs.getLength() > 0, "call to validateProof failed");

        registry.behaviour.burn(_proofOutputs);
        return _proofOutputs;
    }

    /**
    * @dev Validate an AZTEC zero-knowledge proof. ACE will issue a validation transaction to the smart contract
    *      linked to `_proof`. The validator smart contract will have the following interface:
    *
    *      function validate(
    *          bytes _proofData,
    *          address _sender,
    *          bytes32[6] _commonReferenceString
    *      ) public returns (bytes)
    *
    * @param _proof the AZTEC proof object
    * @param _sender the Ethereum address of the original transaction sender. It is explicitly assumed that
    *        an asset using ACE supplies this field correctly - if they don't their asset is vulnerable to front-running
    * Unnamed param is the AZTEC zero-knowledge proof data
    * @return a `bytes proofOutputs` variable formatted according to the Cryptography Engine standard
    */
    function validateProof(uint24 _proof, address _sender, bytes calldata) external returns (bytes memory) {
        require(_proof != 0, "expected the proof to be valid");
        // validate that the provided _proof object maps to a corresponding validator and also that
        // the validator is not disabled
        address validatorAddress = getValidatorAddress(_proof);
        bytes memory proofOutputs;
        assembly {
            // the first evm word of the 3rd function param is the abi encoded location of proof data
            let proofDataLocation := add(0x04, calldataload(0x44))

            // manually construct validator calldata map
            let memPtr := mload(0x40)
            mstore(add(memPtr, 0x04), 0x100) // location in calldata of the start of `bytes _proofData` (0x100)
            mstore(add(memPtr, 0x24), _sender)
            mstore(add(memPtr, 0x44), sload(commonReferenceString_slot))
            mstore(add(memPtr, 0x64), sload(add(0x01, commonReferenceString_slot)))
            mstore(add(memPtr, 0x84), sload(add(0x02, commonReferenceString_slot)))
            mstore(add(memPtr, 0xa4), sload(add(0x03, commonReferenceString_slot)))
            mstore(add(memPtr, 0xc4), sload(add(0x04, commonReferenceString_slot)))
            mstore(add(memPtr, 0xe4), sload(add(0x05, commonReferenceString_slot)))

            // 0x104 because there's an address, the length 6 and the static array items
            let destination := add(memPtr, 0x104)
            // note that we offset by 0x20 because the first word is the length of the dynamic bytes array
            let proofDataSize := add(calldataload(proofDataLocation), 0x20)
            // copy the calldata into memory so we can call the validator contract
            calldatacopy(destination, proofDataLocation, proofDataSize)
            // call our validator smart contract, and validate the call succeeded
            let callSize := add(proofDataSize, 0x104)
            switch staticcall(gas, validatorAddress, memPtr, callSize, 0x00, 0x00)
            case 0 {
                mstore(0x00, 400) revert(0x00, 0x20) // call failed because proof is invalid
            }

            // copy returndata to memory
            returndatacopy(memPtr, 0x00, returndatasize)
            // store the proof outputs in memory
            mstore(0x40, add(memPtr, returndatasize))
            // the first evm word in the memory pointer is the abi encoded location of the actual returned data
            proofOutputs := add(memPtr, mload(memPtr))
        }

        // if this proof satisfies a balancing relationship, we need to record the proof hash
        if (((_proof >> 8) & 0xff) == uint8(ProofCategory.BALANCED)) {
            uint256 length = proofOutputs.getLength();
            for (uint256 i = 0; i < length; i += 1) {
                bytes32 proofHash = keccak256(proofOutputs.get(i));
                bytes32 validatedProofHash = keccak256(abi.encode(proofHash, _proof, msg.sender));
                validatedProofs[validatedProofHash] = true;
            }
        }
        return proofOutputs;
    }

    /**
    * @dev Clear storage variables set when validating zero-knowledge proofs.
    *      The only address that can clear data from `validatedProofs` is the address that created the proof.
    *      Function is designed to utilize [EIP-1283](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1283.md)
    *      to reduce gas costs. It is highly likely that any storage variables set by `validateProof`
    *      are only required for the duration of a single transaction.
    *      E.g. a decentralized exchange validating a swap proof and sending transfer instructions to
    *      two confidential assets.
    *      This method allows the calling smart contract to recover most of the gas spent by setting `validatedProofs`
    * @param _proof the AZTEC proof object
    * @param _proofHashes dynamic array of proof hashes
    */
    function clearProofByHashes(uint24 _proof, bytes32[] calldata _proofHashes) external {
        uint256 length = _proofHashes.length;
        for (uint256 i = 0; i < length; i += 1) {
            bytes32 proofHash = _proofHashes[i];
            require(proofHash != bytes32(0x0), "expected no empty proof hash");
            bytes32 validatedProofHash = keccak256(abi.encode(proofHash, _proof, msg.sender));
            require(validatedProofs[validatedProofHash] == true, "can only clear previously validated proofs");
            validatedProofs[validatedProofHash] = false;
        }
    }

    /**
    * @dev Set the common reference string.
    *      If the trusted setup is re-run, we will need to be able to change the crs
    * @param _commonReferenceString the new commonReferenceString
    */
    function setCommonReferenceString(bytes32[6] memory _commonReferenceString) public {
        require(isOwner(), "only the owner can set the common reference string");
        commonReferenceString = _commonReferenceString;
        emit SetCommonReferenceString(_commonReferenceString);
    }

    /**
    * @dev Forever invalidate the given proof.
    * @param _proof the AZTEC proof object
    */
    function invalidateProof(uint24 _proof) public {
        require(isOwner(), "only the owner can invalidate a proof");
        (uint8 epoch, uint8 category, uint8 id) = _proof.getProofComponents();
        require(validators[epoch][category][id] != address(0x0), "can only invalidate proofs that exist");
        disabledValidators[epoch][category][id] = true;
    }

    /**
    * @dev Validate a previously validated AZTEC proof via its hash
    *      This enables confidential assets to receive transfer instructions from a dApp that
    *      has already validated an AZTEC proof that satisfies a balancing relationship.
    * @param _proof the AZTEC proof object
    * @param _proofHash the hash of the `proofOutput` received by the asset
    * @param _sender the Ethereum address of the contract issuing the transfer instruction
    * @return a boolean that signifies whether the corresponding AZTEC proof has been validated
    */
    function validateProofByHash(
        uint24 _proof,
        bytes32 _proofHash,
        address _sender
    ) public view returns (bool) {
        // We need create a unique encoding of _proof, _proofHash and _sender,
        // and use as a key to access validatedProofs
        // We do this by computing bytes32 validatedProofHash = keccak256(ABI.encode(_proof, _proofHash, _sender))
        // We also need to access disabledValidators[_proof.epoch][_proof.category][_proof.id]
        // This bit is implemented in Yul, as 3-dimensional array access chews through
        // a lot of gas in Solidity, as does ABI.encode
        bytes32 validatedProofHash;
        bool isValidatorDisabled;
        assembly {
            // inside _proof, we have 3 packed variables : [epoch, category, id]
            // each is a uint8.

            // We need to compute the storage key for `disabledValidators[epoch][category][id]`
            // Type of array is bool[0x100][0x100][0x100]
            // Solidity will only squish 32 boolean variables into a single storage slot, not 256
            // => result of disabledValidators[epoch][category] is stored in 0x08 storage slots
            // => result of disabledValidators[epoch] is stored in 0x08 * 0x100 = 0x800 storage slots

            // To compute the storage slot  disabledValidators[epoch][category][id], we do the following:
            // 1. get the disabledValidators slot
            // 2. add (epoch * 0x800) to the slot (or epoch << 11)
            // 3. add (category * 0x08) to the slot (or category << 3)
            // 4. add (id / 0x20) to the slot (or id >> 5)

            // Once the storage slot has been loaded, we need to isolate the byte that contains our boolean
            // This will be equal to id % 0x20, which is also id & 0x1f

            // Putting this all together. The storage slot offset from '_proof' is...
            // epoch: ((_proof & 0xff0000) >> 16) << 11 = ((_proof & 0xff0000) >> 5)
            // category: ((_proof & 0xff00) >> 8) << 3 = ((_proof & 0xff00) >> 5)
            // id: (_proof & 0xff) >> 5
            // i.e. the storage slot offset = _proof >> 5

            // the byte index of the storage word that we require, is equal to (_proof & 0x1f)
            // to convert to a bit index, we multiply by 8
            // i.e. bit index = shl(3, and(_proof & 0x1f))
            // => result = shr(shl(3, and(_proof & 0x1f), value))
            isValidatorDisabled :=
                shr(
                    shl(
                        0x03,
                        and(_proof, 0x1f)
                    ),
                    sload(add(shr(5, _proof), disabledValidators_slot))
                )

            // Next, compute validatedProofHash = keccak256(abi.encode(_proofHash, _proof, _sender))
            // cache free memory pointer - we will overwrite it when computing hash (cheaper than using free memory)
            let memPtr := mload(0x40)
            mstore(0x00, _proofHash)
            mstore(0x20, _proof)
            mstore(0x40, _sender)
            validatedProofHash := keccak256(0x00, 0x60)
            mstore(0x40, memPtr) // restore the free memory pointer
        }
        require(isValidatorDisabled == false, "proof id has been invalidated");
        return validatedProofs[validatedProofHash];
    }

    /**
    * @dev Adds or modifies a proof into the Cryptography Engine.
    *       This method links a given `_proof` to a smart contract validator.
    * @param _proof the AZTEC proof object
    * @param _validatorAddress the address of the smart contract validator
    */
    function setProof(
        uint24 _proof,
        address _validatorAddress
    ) public {
        require(isOwner(), "only the owner can set a proof");
        require(_validatorAddress != address(0x0), "expected the validator address to exist");
        (uint8 epoch, uint8 category, uint8 id) = _proof.getProofComponents();
        require(epoch <= latestEpoch, "the proof epoch cannot be bigger than the latest epoch");
        require(validators[epoch][category][id] == address(0x0), "existing proofs cannot be modified");
        validators[epoch][category][id] = _validatorAddress;
        emit SetProof(epoch, category, id, _validatorAddress);
    }

    /**
     * @dev Increments the `latestEpoch` storage variable.
     */
    function incrementLatestEpoch() public {
        require(isOwner(), "only the owner can update the latest epoch");
        latestEpoch = latestEpoch.add(1);
        emit IncrementLatestEpoch(latestEpoch);
    }

    /**
    * @dev Returns the common reference string.
    * We use a custom getter for `commonReferenceString` - the default getter created by making the storage
    * variable public indexes individual elements of the array, and we want to return the whole array
    */
    function getCommonReferenceString() public view returns (bytes32[6] memory) {
        return commonReferenceString;
    }

    /**
    * @dev Get the address of the relevant validator contract
    *
    * @param _proof unique identifier of a particular proof
    * @return validatorAddress - the address of the validator contract
    */
    function getValidatorAddress(uint24 _proof) public view returns (address validatorAddress) {
        bool isValidatorDisabled;
        bool queryInvalid;
        assembly {
            // To compute the storage key for validatorAddress[epoch][category][id], we do the following:
            // 1. get the validatorAddress slot
            // 2. add (epoch * 0x10000) to the slot
            // 3. add (category * 0x100) to the slot
            // 4. add (id) to the slot
            // i.e. the range of storage pointers allocated to validatorAddress ranges from
            // validatorAddress_slot to (0xffff * 0x10000 + 0xff * 0x100 + 0xff = validatorAddress_slot 0xffffffff)

            // Conveniently, the multiplications we have to perform on epoch, category and id correspond
            // to their byte positions in _proof.
            // i.e. (epoch * 0x10000) = and(_proof, 0xff0000)
            // and  (category * 0x100) = and(_proof, 0xff00)
            // and  (id) = and(_proof, 0xff)

            // Putting this all together. The storage slot offset from '_proof' is...
            // (_proof & 0xffff0000) + (_proof & 0xff00) + (_proof & 0xff)
            // i.e. the storage slot offset IS the value of _proof
            validatorAddress := sload(add(_proof, validators_slot))

            isValidatorDisabled :=
                shr(
                    shl(0x03, and(_proof, 0x1f)),
                    sload(add(shr(5, _proof), disabledValidators_slot))
                )
            queryInvalid := or(iszero(validatorAddress), isValidatorDisabled)
        }

        // wrap both require checks in a single if test. This means the happy path only has 1 conditional jump
        if (queryInvalid) {
            require(validatorAddress != address(0x0), "expected the validator address to exist");
            require(isValidatorDisabled == false, "expected the validator address to not be disabled");
        }
    }
}
