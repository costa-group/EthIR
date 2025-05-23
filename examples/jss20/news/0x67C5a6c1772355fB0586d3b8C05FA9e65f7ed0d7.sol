// Dependency file: @openzeppelin/contracts/utils/Address.sol







// pragma solidity ^0.6.2;



/**

 * @dev Collection of functions related to the address type

 */

library Address {

    /**

     * @dev Returns true if `account` is a contract.

     *

     * [// importANT]

     * ====

     * It is unsafe to assume that an address for which this function returns

     * false is an externally-owned account (EOA) and not a contract.

     *

     * Among others, `isContract` will return false for the following

     * types of addresses:

     *

     *  - an externally-owned account

     *  - a contract in construction

     *  - an address where a contract will be created

     *  - an address where a contract lived, but was destroyed

     * ====

     */

    function isContract(address account) internal view returns (bool) {

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts

        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned

        // for accounts without code, i.e. `keccak256('')`

        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // solhint-disable-next-line no-inline-assembly

        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);

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

     * // importANT: because control is transferred to `recipient`, care must be

     * taken to not create reentrancy vulnerabilities. Consider using

     * {ReentrancyGuard} or the

     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].

     */

    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value

        (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }



    /**

     * @dev Performs a Solidity function call using a low level `call`. A

     * plain`call` is an unsafe replacement for a function call: use this

     * function instead.

     *

     * If `target` reverts with a revert reason, it is bubbled up by this

     * function (like regular Solidity function calls).

     *

     * Returns the raw returned data. To convert to the expected return value,

     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

     *

     * Requirements:

     *

     * - `target` must be a contract.

     * - calling `target` with `data` must not revert.

     *

     * _Available since v3.1._

     */

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {

      return functionCall(target, data, "Address: low-level call failed");

    }



    /**

     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with

     * `errorMessage` as a fallback revert reason when `target` reverts.

     *

     * _Available since v3.1._

     */

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }



    /**

     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],

     * but also transferring `value` wei to `target`.

     *

     * Requirements:

     *

     * - the calling contract must have an ETH balance of at least `value`.

     * - the called Solidity function must be `payable`.

     *

     * _Available since v3.1._

     */

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {

        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }



    /**

     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but

     * with `errorMessage` as a fallback revert reason when `target` reverts.

     *

     * _Available since v3.1._

     */

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {

        require(address(this).balance >= value, "Address: insufficient balance for call");

        return _functionCallWithValue(target, data, value, errorMessage);

    }



    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {

        require(isContract(target), "Address: call to non-contract");



        // solhint-disable-next-line avoid-low-level-calls

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);

        if (success) {

            return returndata;

        } else {

            // Look for revert reason and bubble it up if present

            if (returndata.length > 0) {

                // The easiest way to bubble the revert reason is using memory via assembly



                // solhint-disable-next-line no-inline-assembly

                assembly {

                    let returndata_size := mload(returndata)

                    revert(add(32, returndata), returndata_size)

                }

            } else {

                revert(errorMessage);

            }

        }

    }

}



// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol







// pragma solidity ^0.6.0;



// import "./IERC20.sol";

// import "../../math/SafeMath.sol";

// import "../../utils/Address.sol";



/**

 * @title SafeERC20

 * @dev Wrappers around ERC20 operations that throw on failure (when the token

 * contract returns false). Tokens that return no value (and instead revert or

 * throw on failure) are also supported, non-reverting calls are assumed to be

 * successful.

 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,

 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.

 */

library SafeERC20 {

    using SafeMath for uint256;

    using Address for address;



    function safeTransfer(IERC20 token, address to, uint256 value) internal {

        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));

    }



    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {

        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));

    }



    /**

     * @dev Deprecated. This function has issues similar to the ones found in

     * {IERC20-approve}, and its usage is discouraged.

     *

     * Whenever possible, use {safeIncreaseAllowance} and

     * {safeDecreaseAllowance} instead.

     */

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        // safeApprove should only be called when setting an initial allowance,

        // or when resetting it to zero. To increase and decrease it, use

        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'

        // solhint-disable-next-line max-line-length

        require((value == 0) || (token.allowance(address(this), spender) == 0),

            "SafeERC20: approve from non-zero to non-zero allowance"

        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));

    }



    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).add(value);

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {

        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));

    }



    /**

     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement

     * on the return value: the return value is optional (but if data is returned, it must not be false).

     * @param token The token targeted by the call.

     * @param data The call data (encoded using abi.encode or one of its variants).

     */

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since

        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that

        // the target address contains contract code and also asserts for success in the low-level call.



        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional

            // solhint-disable-next-line max-line-length

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");

        }

    }

}



// Dependency file: @openzeppelin/contracts/GSN/Context.sol







// pragma solidity ^0.6.0;



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

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal view virtual returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;

    }

}



// Dependency file: contracts/lib/ExplicitERC20.sol



/*

    Copyright 2020 Set Labs Inc.



    Licensed under the Apache License, Version 2.0 (the "License");

    you may not use this file except in compliance with the License.

    You may obtain a copy of the License at



    http://www.apache.org/licenses/LICENSE-2.0



    Unless required by applicable law or agreed to in writing, software

    distributed under the License is distributed on an "AS IS" BASIS,

    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

    See the License for the specific language governing permissions and

    limitations under the License.



    

*/



pragma solidity ^0.6.10;


// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";



/**

 * @title ExplicitERC20

 * @author Set Protocol

 *

 * Utility functions for ERC20 transfers that require the explicit amount to be transfered.

 */

library ExplicitERC20 {

    using SafeMath for uint256;



    /**

     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".

     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)

     *

     * @param _token           ERC20 token to approve

     * @param _from            The account to transfer tokens from

     * @param _to              The account to transfer tokens to

     * @param _quantity        The quantity to transfer

     */

    function transferFrom(

        IERC20 _token,

        address _from,

        address _to,

        uint256 _quantity

    )

        internal

    {

        // Call specified ERC20 contract to transfer tokens (via proxy).

        if (_quantity > 0) {

            uint256 existingBalance = _token.balanceOf(_to);



            SafeERC20.safeTransferFrom(

                _token,

                _from,

                _to,

                _quantity

            );



            uint256 newBalance = _token.balanceOf(_to);



            // Verify transfer quantity is reflected in balance

            require(

                newBalance == existingBalance.add(_quantity),

                "Invalid post transfer balance"

            );

        }

    }

}



// Dependency file: contracts/lib/AddressArrayUtils.sol



/*

    Copyright 2020 Set Labs Inc.



    Licensed under the Apache License, Version 2.0 (the "License");

    you may not use this file except in compliance with the License.

    You may obtain a copy of the License at



    http://www.apache.org/licenses/LICENSE-2.0



    Unless required by applicable law or agreed to in writing, software

    distributed under the License is distributed on an "AS IS" BASIS,

    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

    See the License for the specific language governing permissions and

    limitations under the License.



    

*/



pragma solidity ^0.6.10;


/**

 * @title AddressArrayUtils

 * @author Set Protocol

 *

 * Utility functions to handle Address Arrays

 */

library AddressArrayUtils {



    /**

     * Finds the index of the first occurrence of the given element.

     * @param A The input array to search

     * @param a The value to find

     * @return Returns (index and isIn) for the first occurrence starting from index 0

     */

    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {

        uint256 length = A.length;

        for (uint256 i = 0; i < length; i++) {

            if (A[i] == a) {

                return (i, true);

            }

        }

        return (0, false);

    }



    /**

    * Returns true if the value is present in the list. Uses indexOf internally.

    * @param A The input array to search

    * @param a The value to find

    * @return Returns isIn for the first occurrence starting from index 0

    */

    function contains(address[] memory A, address a) internal pure returns (bool) {

        bool isIn;

        (, isIn) = indexOf(A, a);

        return isIn;

    }



    /**

    * Returns true if there are 2 elements that are the same in an array

    * @param A The input array to search

    * @return Returns boolean for the first occurence of a duplicate

    */

    function hasDuplicate(address[] memory A) internal pure returns(bool) {

        for (uint256 i = 0; i < A.length - 1; i++) {

            address current = A[i];

            for (uint256 j = i + 1; j < A.length; j++) {

                if (current == A[j]) {

                    return true;

                }

            }

        }

        return false;

    }



    /**

     * Returns the array with a appended to A.

     * @param A The first array

     * @param a The value to append

     * @return Returns A appended by a

     */

    function append(address[] memory A, address a) internal pure returns (address[] memory) {

        address[] memory newAddresses = new address[](A.length + 1);

        for (uint256 i = 0; i < A.length; i++) {

            newAddresses[i] = A[i];

        }

        newAddresses[A.length] = a;

        return newAddresses;

    }



    /**

     * @return Returns the new array

     */

    function remove(address[] memory A, address a)

        internal

        pure

        returns (address[] memory)

    {

        (uint256 index, bool isIn) = indexOf(A, a);

        if (!isIn) {

            revert("Address not in array.");

        } else {

            (address[] memory _A,) = pop(A, index);

            return _A;

        }

    }



    /**

    * Removes specified index from array

    * Resulting ordering is not guaranteed

    * @return Returns the new array and the removed entry

    */

    function pop(address[] memory A, uint256 index)

        internal

        pure

        returns (address[] memory, address)

    {

        uint256 length = A.length;

        address[] memory newAddresses = new address[](length - 1);

        for (uint256 i = 0; i < index; i++) {

            newAddresses[i] = A[i];

        }

        for (uint256 j = index + 1; j < length; j++) {

            newAddresses[j - 1] = A[j];

        }

        return (newAddresses, A[index]);

    }

}

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol







// pragma solidity ^0.6.0;



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

     *

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

     *

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

     *

     * - Subtraction cannot overflow.

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

     *

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

     *

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

     *

     * - The divisor cannot be zero.

     */

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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

     *

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

     *

     * - The divisor cannot be zero.

     */

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}



// Dependency file: @openzeppelin/contracts/access/Ownable.sol







// pragma solidity ^0.6.0;



// import "../GSN/Context.sol";

/**

 * @dev Contract module which provides a basic access control mechanism, where

 * there is an account (an owner) that can be granted exclusive access to

 * specific functions.

 *

 * By default, the owner account will be the one that deploys the contract. This

 * can later be changed with {transferOwnership}.

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

        address msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);

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

        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;

    }



    /**

     * @dev Leaves the contract without owner. It will not be possible to call

     * `onlyOwner` functions anymore. Can only be called by the current owner.

     *

     * NOTE: Renouncing ownership will leave the contract without an owner,

     * thereby removing any functionality that is only available to the owner.

     */

    function renounceOwnership() public virtual onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}



// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol







// pragma solidity ^0.6.0;



/**

 * @dev Interface of the ERC20 standard as defined in the EIP.

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

     * // importANT: Beware that changing an allowance with this method brings the risk

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



/*

    Copyright 2020 Set Labs Inc.



    Licensed under the Apache License, Version 2.0 (the "License");

    you may not use this file except in compliance with the License.

    You may obtain a copy of the License at



    http://www.apache.org/licenses/LICENSE-2.0



    Unless required by applicable law or agreed to in writing, software

    distributed under the License is distributed on an "AS IS" BASIS,

    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

    See the License for the specific language governing permissions and

    limitations under the License.



    

*/



pragma solidity ^0.6.10;


// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

// import { AddressArrayUtils } from "../lib/AddressArrayUtils.sol";

// import { ExplicitERC20 } from "../lib/ExplicitERC20.sol";



/**

 * @title Controller

 * @author Set Protocol

 *

 * Contract that houses state for approvals and system contracts such as added Sets,

 * modules, factories, resources (like price oracles), and protocol fee configurations.

 */

contract Controller is Ownable {



    using SafeMath for uint256;

    using AddressArrayUtils for address[];



    /* ============ Events ============ */



    event FactoryAdded(address _factory);

    event FactoryRemoved(address _factory);

    event FeeEdited(address indexed _module, uint256 indexed _feeType, uint256 _feePercentage);

    event FeeRecipientChanged(address _newFeeRecipient);

    event ModuleAdded(address _module);

    event ModuleRemoved(address _module);

    event ResourceAdded(address _resource, uint256 _id);

    event ResourceRemoved(address _resource, uint256 _id);

    event SetAdded(address _setToken, address _factory);

    event SetRemoved(address _setToken);



    /* ============ Modifiers ============ */



    /**

     * Throws if function is called by any address other than a valid factory.

     */

    modifier onlyFactory() {

        require(isFactory[msg.sender], "Only valid factories can call");

        _;

    }



    /**

     * Throws if function is called by any address other than a module or a resource.

     */

    modifier onlyModuleOrResource() {

        require(

            isResource[msg.sender] || isModule[msg.sender],

            "Only valid resources or modules can call"

        );

        _;

    }



    modifier onlyIfInitialized() {

        require(isInitialized, "Contract must be initialized.");

        _;

    }



    /* ============ State Variables ============ */



    // List of enabled Sets

    address[] public sets;

    // List of enabled factories of SetTokens

    address[] public factories;

    // List of enabled Modules; Modules extend the functionality of SetTokens

    address[] public modules;

    // List of enabled Resources; Resources provide data, functionality, or

    // permissions that can be drawn upon from Module, SetTokens or factories

    address[] public resources;



    // Mappings to check whether address is valid Set, Factory, Module or Resource

    mapping(address => bool) public isSet;

    mapping(address => bool) public isFactory;

    mapping(address => bool) public isModule;

    mapping(address => bool) public isResource;



    // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes

    // Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)

    mapping(address => mapping(uint256 => uint256)) public fees;



    // Mapping of resource ID to resource address, which allows contracts to fetch the correct

    // resource while providing an ID

    mapping(uint256 => address) public resourceId;



    // Recipient of protocol fees

    address public feeRecipient;



    // Return true if the controller is initialized

    bool public isInitialized;



    /* ============ Constructor ============ */



    /**

     * Initializes the initial fee recipient on deployment.

     *

     * @param _feeRecipient          Address of the initial protocol fee recipient

     */

    constructor(address _feeRecipient) public {

        feeRecipient = _feeRecipient;

    }



    /* ============ External Functions ============ */



    /**

     * Initializes any predeployed factories, modules, and resources post deployment. Note: This function can

     * only be called by the owner once to batch initialize the initial system contracts.

     *

     * @param _factories             List of factories to add

     * @param _modules               List of modules to add

     * @param _resources             List of resources to add

     * @param _resourceIds           List of resource IDs associated with the resources

     */

    function initialize(

        address[] memory _factories,

        address[] memory _modules,

        address[] memory _resources,

        uint256[] memory _resourceIds

    )

        external

        onlyOwner

    {

        // Requires Controller has not been initialized yet

        require(

            !isInitialized,

            "Controller is already initialized"

        );



        factories = _factories;

        modules = _modules;

        resources = _resources;



        // Loop through and initialize isModule, isFactory, and isResource mapping

        for (uint256 i = 0; i < _factories.length; i++) {

            require(_factories[i] != address(0), "Zero address submitted.");

            isFactory[_factories[i]] = true;

        }

        for (uint256 i = 0; i < _modules.length; i++) {

            require(_modules[i] != address(0), "Zero address submitted.");

            isModule[_modules[i]] = true;

        }

        for (uint256 i = 0; i < _resources.length; i++) {

            require(_resources[i] != address(0), "Zero address submitted.");

            require(_resources.length == _resourceIds.length, "Array lengths do not match.");

            isResource[_resources[i]] = true;

            resourceId[_resourceIds[i]] = _resources[i];

        }



        // Set to true to only allow initialization once

        isInitialized = true;

    }



    /**

     * PRIVILEGED MODULE OR RESOURCE FUNCTION. Allows a module or resource to transfer tokens

     * from an address (that has set allowance on the controller).

     *

     * @param  _token          The address of the ERC20 token

     * @param  _from           The address to transfer from

     * @param  _to             The address to transfer to

     * @param  _quantity       The number of tokens to transfer

     */

    function transferFrom(

        address _token,

        address _from,

        address _to,

        uint256 _quantity

    )

        external

        onlyIfInitialized

        onlyModuleOrResource

    {

        if (_quantity > 0) {

            ExplicitERC20.transferFrom(

                IERC20(_token),

                _from,

                _to,

                _quantity

            );

        }

    }



    /**

     * PRIVILEGED MODULE OR RESOURCE FUNCTION. Allows a module or resource to batch transfer tokens

     * from an address (that has set allowance on the proxy).

     *

     * @param  _tokens          The addresses of the ERC20 token

     * @param  _from            The addresses to transfer from

     * @param  _to              The addresses to transfer to

     * @param  _quantities      The numbers of tokens to transfer

     */

    function batchTransferFrom(

        address[] calldata _tokens,

        address _from,

        address _to,

        uint256[] calldata _quantities

    )

        external

        onlyIfInitialized

        onlyModuleOrResource

    {

        // Storing token count to local variable to save on invocation

        uint256 tokenCount = _tokens.length;



        // Confirm and empty _tokens array is not passed

        require(

            tokenCount > 0,

            "Tokens must not be empty"

        );



        // Confirm there is one quantity for every token address

        require(

            tokenCount == _quantities.length,

            "Tokens and quantities lengths mismatch"

        );



        for (uint256 i = 0; i < tokenCount; i++) {

            if (_quantities[i] > 0) {

                ExplicitERC20.transferFrom(

                    IERC20(_tokens[i]),

                    _from,

                    _to,

                    _quantities[i]

                );

            }

        }

    }



    /**

     * PRIVILEGED FACTORY FUNCTION. Adds a newly deployed SetToken as an enabled SetToken.

     *

     * @param _setToken               Address of the SetToken contract to add

     */

    function addSet(address _setToken) external onlyIfInitialized onlyFactory {

        require(!isSet[_setToken], "Set already exists");



        isSet[_setToken] = true;



        sets.push(_setToken);



        emit SetAdded(_setToken, msg.sender);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Set

     *

     * @param _setToken               Address of the SetToken contract to remove

     */

    function removeSet(address _setToken) external onlyIfInitialized onlyOwner {

        require(isSet[_setToken], "Set does not exist");



        sets = sets.remove(_setToken);



        isSet[_setToken] = false;



        emit SetRemoved(_setToken);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory

     *

     * @param _factory               Address of the factory contract to add

     */

    function addFactory(address _factory) external onlyIfInitialized onlyOwner {

        require(!isFactory[_factory], "Factory already exists");



        isFactory[_factory] = true;



        factories.push(_factory);



        emit FactoryAdded(_factory);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory

     *

     * @param _factory               Address of the factory contract to remove

     */

    function removeFactory(address _factory) external onlyIfInitialized onlyOwner {

        require(isFactory[_factory], "Factory does not exist");



        factories = factories.remove(_factory);



        isFactory[_factory] = false;



        emit FactoryRemoved(_factory);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module

     *

     * @param _module               Address of the module contract to add

     */

    function addModule(address _module) external onlyIfInitialized onlyOwner {

        require(!isModule[_module], "Module already exists");



        isModule[_module] = true;



        modules.push(_module);



        emit ModuleAdded(_module);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module

     *

     * @param _module               Address of the module contract to remove

     */

    function removeModule(address _module) external onlyIfInitialized onlyOwner {

        require(isModule[_module], "Module does not exist");



        modules = modules.remove(_module);



        isModule[_module] = false;



        emit ModuleRemoved(_module);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource

     *

     * @param _resource               Address of the resource contract to add

     * @param _id                     New ID of the resource contract

     */

    function addResource(address _resource, uint256 _id) external onlyIfInitialized onlyOwner {

        require(!isResource[_resource], "Resource already exists");



        require(resourceId[_id] == address(0), "Resource ID already exists");



        isResource[_resource] = true;



        resourceId[_id] = _resource;



        resources.push(_resource);



        emit ResourceAdded(_resource, _id);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource

     *

     * @param _id               ID of the resource contract to remove

     */

    function removeResource(uint256 _id) external onlyIfInitialized onlyOwner {

        address resourceToRemove = resourceId[_id];



        require(resourceToRemove != address(0), "Resource does not exist");



        resources = resources.remove(resourceToRemove);



        resourceId[_id] = address(0);



        isResource[resourceToRemove] = false;



        emit ResourceRemoved(resourceToRemove, _id);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module

     *

     * @param _module               Address of the module contract to add fee to

     * @param _feeType              Type of the fee to add in the module

     * @param _newFeePercentage     Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)

     */

    function addFee(address _module, uint256 _feeType, uint256 _newFeePercentage) external onlyIfInitialized onlyOwner {

        require(isModule[_module], "Module does not exist");



        require(fees[_module][_feeType] == 0, "Fee type already exists on module");



        fees[_module][_feeType] = _newFeePercentage;



        emit FeeEdited(_module, _feeType, _newFeePercentage);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module

     *

     * @param _module               Address of the module contract to edit fee

     * @param _feeType              Type of the fee to edit in the module

     * @param _newFeePercentage     Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)

     */

    function editFee(address _module, uint256 _feeType, uint256 _newFeePercentage) external onlyIfInitialized onlyOwner {

        require(isModule[_module], "Module does not exist");



        require(fees[_module][_feeType] != 0, "Fee type does not exist on module");



        fees[_module][_feeType] = _newFeePercentage;



        emit FeeEdited(_module, _feeType, _newFeePercentage);

    }



    /**

     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient

     *

     * @param _newFeeRecipient      Address of the new protocol fee recipient

     */

    function editFeeRecipient(address _newFeeRecipient) external onlyIfInitialized onlyOwner {

        feeRecipient = _newFeeRecipient;



        emit FeeRecipientChanged(_newFeeRecipient);

    }



    /* ============ External Getter Functions ============ */



    function getModuleFee(

        address _moduleAddress,

        uint256 _feeType

    )

        external

        view

        returns (uint256)

    {

        return fees[_moduleAddress][_feeType];

    }



    function getFactories() external view returns (address[] memory) {

        return factories;

    }



    function getModules() external view returns (address[] memory) {

        return modules;

    }



    function getResources() external view returns (address[] memory) {

        return resources;

    }



    function getSets() external view returns (address[] memory) {

        return sets;

    }



    /**

     * Check if a contract address is a module, Set, resource, factory or controller

     *

     * @param  _contractAddress           The contract address to check

     */

    function isSystemContract(address _contractAddress) external view returns (bool) {

        return (

            isSet[_contractAddress] ||

            isModule[_contractAddress] ||

            isResource[_contractAddress] ||

            isFactory[_contractAddress] ||

            _contractAddress == address(this)

        );

    }

}