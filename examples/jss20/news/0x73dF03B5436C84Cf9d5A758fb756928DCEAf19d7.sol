/**

 *Submitted for verification at Etherscan.io on 2020-04-13

*/



// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.5.2;

pragma experimental "ABIEncoderV2";



/**

 * @title Helps contracts guard against reentrancy attacks.

 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>

 * @dev If you mark a function `nonReentrant`, you should also

 * mark it `external`.

 */

contract ReentrancyGuard {

    /// @dev counter to allow mutex lock with only one SSTORE operation

    uint256 private _guardCounter;



    constructor () internal {

        // The counter starts at one to prevent changing it from zero to a non-zero

        // value, which is a more expensive operation.

        _guardCounter = 1;

    }



    /**

     * @dev Prevents a contract from calling itself, directly or indirectly.

     * Calling a `nonReentrant` function from another `nonReentrant`

     * function is not supported. It is possible to prevent this from happening

     * by making the `nonReentrant` function external, and make it call a

     * `private` function that does the actual work.

     */

    modifier nonReentrant() {

        _guardCounter += 1;

        uint256 localCounter = _guardCounter;

        _;

        require(localCounter == _guardCounter);

    }

}



// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity ^0.5.2;



/**

 * @title SafeMath

 * @dev Unsigned math operations with safety checks that revert on error

 */

library SafeMath {

    /**

     * @dev Multiplies two unsigned integers, reverts on overflow.

     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {

            return 0;

        }



        uint256 c = a * b;

        require(c / a == b);



        return c;

    }



    /**

     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

     */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }



    /**

     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

     */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b <= a);

        uint256 c = a - b;



        return c;

    }



    /**

     * @dev Adds two unsigned integers, reverts on overflow.

     */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;

        require(c >= a);



        return c;

    }



    /**

     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

     * reverts when dividing by zero.

     */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b != 0);

        return a % b;

    }

}



// File: contracts/lib/CommonMath.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;






library CommonMath {

    using SafeMath for uint256;



    uint256 public constant SCALE_FACTOR = 10 ** 18;

    uint256 public constant MAX_UINT_256 = 2 ** 256 - 1;



    /**

     * Returns scale factor equal to 10 ** 18

     *

     * @return  10 ** 18

     */

    function scaleFactor()

        internal

        pure

        returns (uint256)

    {

        return SCALE_FACTOR;

    }



    /**

     * Calculates and returns the maximum value for a uint256

     *

     * @return  The maximum value for uint256

     */

    function maxUInt256()

        internal

        pure

        returns (uint256)

    {

        return MAX_UINT_256;

    }



    /**

     * Increases a value by the scale factor to allow for additional precision

     * during mathematical operations

     */

    function scale(

        uint256 a

    )

        internal

        pure

        returns (uint256)

    {

        return a.mul(SCALE_FACTOR);

    }



    /**

     * Divides a value by the scale factor to allow for additional precision

     * during mathematical operations

    */

    function deScale(

        uint256 a

    )

        internal

        pure

        returns (uint256)

    {

        return a.div(SCALE_FACTOR);

    }



    /**

    * @dev Performs the power on a specified value, reverts on overflow.

    */

    function safePower(

        uint256 a,

        uint256 pow

    )

        internal

        pure

        returns (uint256)

    {

        require(a > 0);



        uint256 result = 1;

        for (uint256 i = 0; i < pow; i++){

            uint256 previousResult = result;



            // Using safemath multiplication prevents overflows

            result = previousResult.mul(a);

        }



        return result;

    }



    /**

    * @dev Performs division where if there is a modulo, the value is rounded up

    */

    function divCeil(uint256 a, uint256 b)

        internal

        pure

        returns(uint256)

    {

        return a.mod(b) > 0 ? a.div(b).add(1) : a.div(b);

    }



    /**

     * Checks for rounding errors and returns value of potential partial amounts of a principal

     *

     * @param  _principal       Number fractional amount is derived from

     * @param  _numerator       Numerator of fraction

     * @param  _denominator     Denominator of fraction

     * @return uint256          Fractional amount of principal calculated

     */

    function getPartialAmount(

        uint256 _principal,

        uint256 _numerator,

        uint256 _denominator

    )

        internal

        pure

        returns (uint256)

    {

        // Get remainder of partial amount (if 0 not a partial amount)

        uint256 remainder = mulmod(_principal, _numerator, _denominator);



        // Return if not a partial amount

        if (remainder == 0) {

            return _principal.mul(_numerator).div(_denominator);

        }



        // Calculate error percentage

        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(_numerator.mul(_principal));



        // Require error percentage is less than 0.1%.

        require(

            errPercentageTimes1000000 < 1000,

            "CommonMath.getPartialAmount: Rounding error exceeds bounds"

        );



        return _principal.mul(_numerator).div(_denominator);

    }



    /*

     * Gets the rounded up log10 of passed value

     *

     * @param  _value         Value to calculate ceil(log()) on

     * @return uint256        Output value

     */

    function ceilLog10(

        uint256 _value

    )

        internal

        pure

        returns (uint256)

    {

        // Make sure passed value is greater than 0

        require (

            _value > 0,

            "CommonMath.ceilLog10: Value must be greater than zero."

        );



        // Since log10(1) = 0, if _value = 1 return 0

        if (_value == 1) return 0;



        // Calcualte ceil(log10())

        uint256 x = _value - 1;



        uint256 result = 0;



        if (x >= 10 ** 64) {

            x /= 10 ** 64;

            result += 64;

        }

        if (x >= 10 ** 32) {

            x /= 10 ** 32;

            result += 32;

        }

        if (x >= 10 ** 16) {

            x /= 10 ** 16;

            result += 16;

        }

        if (x >= 10 ** 8) {

            x /= 10 ** 8;

            result += 8;

        }

        if (x >= 10 ** 4) {

            x /= 10 ** 4;

            result += 4;

        }

        if (x >= 100) {

            x /= 100;

            result += 2;

        }

        if (x >= 10) {

            result += 1;

        }



        return result + 1;

    }

}



// File: contracts/external/0x/LibBytes.sol



/*

  Copyright 2018 ZeroEx Intl.

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



pragma solidity ^0.5.7;


library LibBytes {



    using LibBytes for bytes;



    /// @dev Gets the memory address for the contents of a byte array.

    /// @param input Byte array to lookup.

    /// @return memoryAddress Memory address of the contents of the byte array.

    function contentAddress(bytes memory input)

        internal

        pure

        returns (uint256 memoryAddress)

    {

        assembly {

            memoryAddress := add(input, 32)

        }

        return memoryAddress;

    }



    /// @dev Reads an unpadded bytes4 value from a position in a byte array.

    /// @param b Byte array containing a bytes4 value.

    /// @param index Index in byte array of bytes4 value.

    /// @return bytes4 value from byte array.

    function readBytes4(

        bytes memory b,

        uint256 index)

        internal

        pure

        returns (bytes4 result)

    {

        require(

            b.length >= index + 4,

            "GREATER_OR_EQUAL_TO_4_LENGTH_REQUIRED"

        );

        assembly {

            result := mload(add(b, 32))

            // Solidity does not require us to clean the trailing bytes.

            // We do it anyway

            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)

        }

        return result;

    }





    /// @dev Reads a bytes32 value from a position in a byte array.

    /// @param b Byte array containing a bytes32 value.

    /// @param index Index in byte array of bytes32 value.

    /// @return bytes32 value from byte array.

    function readBytes32(

        bytes memory b,

        uint256 index

    )

        internal

        pure

        returns (bytes32 result)

    {

        require(

            b.length >= index + 32,

            "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"

        );



        // Arrays are prefixed by a 256 bit length parameter

        index += 32;



        // Read the bytes32 from array memory

        assembly {

            result := mload(add(b, index))

        }

        return result;

    }



    /// @dev Copies `length` bytes from memory location `source` to `dest`.

    /// @param dest memory address to copy bytes to.

    /// @param source memory address to copy bytes from.

    /// @param length number of bytes to copy.

    function memCopy(

        uint256 dest,

        uint256 source,

        uint256 length

    )

        internal

        pure

    {

        if (length < 32) {

            // Handle a partial word by reading destination and masking

            // off the bits we are interested in.

            // This correctly handles overlap, zero lengths and source == dest

            assembly {

                let mask := sub(exp(256, sub(32, length)), 1)

                let s := and(mload(source), not(mask))

                let d := and(mload(dest), mask)

                mstore(dest, or(s, d))

            }

        } else {

            // Skip the O(length) loop when source == dest.

            if (source == dest) {

                return;

            }



            // For large copies we copy whole words at a time. The final

            // word is aligned to the end of the range (instead of after the

            // previous) to handle partial words. So a copy will look like this:

            //

            //  ####

            //      ####

            //          ####

            //            ####

            //

            // We handle overlap in the source and destination range by

            // changing the copying direction. This prevents us from

            // overwriting parts of source that we still need to copy.

            //

            // This correctly handles source == dest

            //

            if (source > dest) {

                assembly {

                    // We subtract 32 from `sEnd` and `dEnd` because it

                    // is easier to compare with in the loop, and these

                    // are also the addresses we need for copying the

                    // last bytes.

                    length := sub(length, 32)

                    let sEnd := add(source, length)

                    let dEnd := add(dest, length)



                    // Remember the last 32 bytes of source

                    // This needs to be done here and not after the loop

                    // because we may have overwritten the last bytes in

                    // source already due to overlap.

                    let last := mload(sEnd)



                    // Copy whole words front to back

                    // Note: the first check is always true,

                    // this could have been a do-while loop.

                    for {} lt(source, sEnd) {} {

                        mstore(dest, mload(source))

                        source := add(source, 32)

                        dest := add(dest, 32)

                    }



                    // Write the last 32 bytes

                    mstore(dEnd, last)

                }

            } else {

                assembly {

                    // We subtract 32 from `sEnd` and `dEnd` because those

                    // are the starting points when copying a word at the end.

                    length := sub(length, 32)

                    let sEnd := add(source, length)

                    let dEnd := add(dest, length)



                    // Remember the first 32 bytes of source

                    // This needs to be done here and not after the loop

                    // because we may have overwritten the first bytes in

                    // source already due to overlap.

                    let first := mload(source)



                    // Copy whole words back to front

                    // We use a signed comparisson here to allow dEnd to become

                    // negative (happens when source and dest < 32). Valid

                    // addresses in local memory will never be larger than

                    // 2**255, so they can be safely re-interpreted as signed.

                    // Note: the first check is always true,

                    // this could have been a do-while loop.

                    for {} slt(dest, dEnd) {} {

                        mstore(dEnd, mload(sEnd))

                        sEnd := sub(sEnd, 32)

                        dEnd := sub(dEnd, 32)

                    }



                    // Write the first 32 bytes

                    mstore(dest, first)

                }

            }

        }

    }



    /// @dev Returns a slices from a byte array.

    /// @param b The byte array to take a slice from.

    /// @param from The starting index for the slice (inclusive).

    /// @param to The final index for the slice (exclusive).

    /// @return result The slice containing bytes at indices [from, to)

    function slice(bytes memory b, uint256 from, uint256 to)

        internal

        pure

        returns (bytes memory result)

    {

        require(

            from <= to,

            "FROM_LESS_THAN_TO_REQUIRED"

        );

        require(

            // NOTE: Set Protocol changed from `to < b.length` so that the last byte can be sliced off

            to <= b.length,

            "TO_LESS_THAN_LENGTH_REQUIRED"

        );



        // Create a new bytes structure and copy contents

        result = new bytes(to - from);

        memCopy(

            result.contentAddress(),

            b.contentAddress() + from,

            result.length);

        return result;

    }

}



// File: contracts/core/lib/ExchangeHeaderLibrary.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;








/**

 * @title ExchangeHeaderLibrary

 * @author Set Protocol

 *

 * This library contains functions and structs to assist with parsing exchange orders data

 */

library ExchangeHeaderLibrary {

    using LibBytes for bytes;

    using SafeMath for uint256;



    // ============ Structs ============



    struct ExchangeHeader {

        uint8 exchange;

        uint8 orderCount;

        uint256 orderDataBytesLength;

    }



    function EXCHANGE_HEADER_LENGTH()

        internal

        pure

        returns (uint256)

    {

        return uint256(96);

    }



    // ============ Internal Functions ============



    /**

     * Function to convert bytes into ExchangeHeader

     *

     * @param _orderData        Bytes representing the order body information

     * @param _offset           Bytes to offset orderData by

     * @return ExchangeHeader   Struct containing data for a batch of exchange orders

     */

    function parseExchangeHeader(

        bytes memory _orderData,

        uint256 _offset

    )

        internal

        pure

        returns (ExchangeHeader memory)

    {

        ExchangeHeader memory header;



        uint256 headerDataStart = _orderData.contentAddress().add(_offset);



        assembly {

            mstore(header,          mload(headerDataStart))            // exchange

            mstore(add(header, 32), mload(add(headerDataStart, 32)))   // orderCount

            mstore(add(header, 64), mload(add(headerDataStart, 64)))   // orderDataBytesLength

        }



        return header;

    }



    /**

     * Function to extract the exchange body from the order data

     *

     * @param _orderData                Bytes representing the exchange order information

     * @param _scannedBytes             Number representing the number of bytes already processed

     * @param _exchangeDataLength       Length of the exchange data from the exchange data header

     * @return ExchangeBody  Bytes representing the exchange body

     */

    function sliceBodyData(

        bytes memory _orderData,

        uint256 _scannedBytes,

        uint256 _exchangeDataLength

    )

        internal

        pure

        returns (bytes memory)

    {

        bytes memory bodyData = LibBytes.slice(

            _orderData,

            _scannedBytes.add(EXCHANGE_HEADER_LENGTH()),

            _scannedBytes.add(_exchangeDataLength)

        );



        return bodyData;

    }

}



// File: contracts/lib/AddressArrayUtils.sol



// Pulled in from Cryptofin Solidity package in order to control Solidity compiler version

// https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol



pragma solidity ^0.5.7;




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

     * Returns the combination of the two arrays

     * @param A The first array

     * @param B The second array

     * @return Returns A extended by B

     */

    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {

        uint256 aLength = A.length;

        uint256 bLength = B.length;

        address[] memory newAddresses = new address[](aLength + bLength);

        for (uint256 i = 0; i < aLength; i++) {

            newAddresses[i] = A[i];

        }

        for (uint256 j = 0; j < bLength; j++) {

            newAddresses[aLength + j] = B[j];

        }

        return newAddresses;

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

     * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.

     * @param A The first array

     * @param B The second array

     * @return The intersection of the two arrays

     */

    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {

        uint256 length = A.length;

        bool[] memory includeMap = new bool[](length);

        uint256 newLength = 0;

        for (uint256 i = 0; i < length; i++) {

            if (contains(B, A[i])) {

                includeMap[i] = true;

                newLength++;

            }

        }

        address[] memory newAddresses = new address[](newLength);

        uint256 j = 0;

        for (uint256 k = 0; k < length; k++) {

            if (includeMap[k]) {

                newAddresses[j] = A[k];

                j++;

            }

        }

        return newAddresses;

    }



    /**

     * Returns the union of the two arrays. Order is not guaranteed.

     * @param A The first array

     * @param B The second array

     * @return The union of the two arrays

     */

    function union(address[] memory A, address[] memory B) internal pure returns (address[] memory) {

        address[] memory leftDifference = difference(A, B);

        address[] memory rightDifference = difference(B, A);

        address[] memory intersection = intersect(A, B);

        return extend(leftDifference, extend(intersection, rightDifference));

    }



    /**

     * Computes the difference of two arrays. Assumes there are no duplicates.

     * @param A The first array

     * @param B The second array

     * @return The difference of the two arrays

     */

    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {

        uint256 length = A.length;

        bool[] memory includeMap = new bool[](length);

        uint256 count = 0;

        // First count the new length because can't push for in-memory arrays

        for (uint256 i = 0; i < length; i++) {

            address e = A[i];

            if (!contains(B, e)) {

                includeMap[i] = true;

                count++;

            }

        }

        address[] memory newAddresses = new address[](count);

        uint256 j = 0;

        for (uint256 k = 0; k < length; k++) {

            if (includeMap[k]) {

                newAddresses[j] = A[k];

                j++;

            }

        }

        return newAddresses;

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

            revert();

        } else {

            (address[] memory _A,) = pop(A, index);

            return _A;

        }

    }



    /**

     * Returns whether or not there's a duplicate. Runs in O(n^2).

     * @param A Array to search

     * @return Returns true if duplicate, false otherwise

     */

    function hasDuplicate(address[] memory A) internal pure returns (bool) {

        if (A.length == 0) {

            return false;

        }

        for (uint256 i = 0; i < A.length - 1; i++) {

            for (uint256 j = i + 1; j < A.length; j++) {

                if (A[i] == A[j]) {

                    return true;

                }

            }

        }

        return false;

    }



    /**

     * Returns whether the two arrays are equal.

     * @param A The first array

     * @param B The second array

     * @return True is the arrays are equal, false if not.

     */

    function isEqual(address[] memory A, address[] memory B) internal pure returns (bool) {

        if (A.length != B.length) {

            return false;

        }

        for (uint256 i = 0; i < A.length; i++) {

            if (A[i] != B[i]) {

                return false;

            }

        }

        return true;

    }

}



// File: contracts/core/interfaces/ICore.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;




/**

 * @title ICore

 * @author Set Protocol

 *

 * The ICore Contract defines all the functions exposed in the Core through its

 * various extensions and is a light weight way to interact with the contract.

 */

interface ICore {

    /**

     * Return transferProxy address.

     *

     * @return address       transferProxy address

     */

    function transferProxy()

        external

        view

        returns (address);



    /**

     * Return vault address.

     *

     * @return address       vault address

     */

    function vault()

        external

        view

        returns (address);



    /**

     * Return address belonging to given exchangeId.

     *

     * @param  _exchangeId       ExchangeId number

     * @return address           Address belonging to given exchangeId

     */

    function exchangeIds(

        uint8 _exchangeId

    )

        external

        view

        returns (address);



    /*

     * Returns if valid set

     *

     * @return  bool      Returns true if Set created through Core and isn't disabled

     */

    function validSets(address)

        external

        view

        returns (bool);



    /*

     * Returns if valid module

     *

     * @return  bool      Returns true if valid module

     */

    function validModules(address)

        external

        view

        returns (bool);



    /**

     * Return boolean indicating if address is a valid Rebalancing Price Library.

     *

     * @param  _priceLibrary    Price library address

     * @return bool             Boolean indicating if valid Price Library

     */

    function validPriceLibraries(

        address _priceLibrary

    )

        external

        view

        returns (bool);



    /**

     * Exchanges components for Set Tokens

     *

     * @param  _set          Address of set to issue

     * @param  _quantity     Quantity of set to issue

     */

    function issue(

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Issues a specified Set for a specified quantity to the recipient

     * using the caller's components from the wallet and vault.

     *

     * @param  _recipient    Address to issue to

     * @param  _set          Address of the Set to issue

     * @param  _quantity     Number of tokens to issue

     */

    function issueTo(

        address _recipient,

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Converts user's components into Set Tokens held directly in Vault instead of user's account

     *

     * @param _set          Address of the Set

     * @param _quantity     Number of tokens to redeem

     */

    function issueInVault(

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Function to convert Set Tokens into underlying components

     *

     * @param _set          The address of the Set token

     * @param _quantity     The number of tokens to redeem. Should be multiple of natural unit.

     */

    function redeem(

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Redeem Set token and return components to specified recipient. The components

     * are left in the vault

     *

     * @param _recipient    Recipient of Set being issued

     * @param _set          Address of the Set

     * @param _quantity     Number of tokens to redeem

     */

    function redeemTo(

        address _recipient,

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Function to convert Set Tokens held in vault into underlying components

     *

     * @param _set          The address of the Set token

     * @param _quantity     The number of tokens to redeem. Should be multiple of natural unit.

     */

    function redeemInVault(

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Composite method to redeem and withdraw with a single transaction

     *

     * Normally, you should expect to be able to withdraw all of the tokens.

     * However, some have central abilities to freeze transfers (e.g. EOS). _toExclude

     * allows you to optionally specify which component tokens to exclude when

     * redeeming. They will remain in the vault under the users' addresses.

     *

     * @param _set          Address of the Set

     * @param _to           Address to withdraw or attribute tokens to

     * @param _quantity     Number of tokens to redeem

     * @param _toExclude    Mask of indexes of tokens to exclude from withdrawing

     */

    function redeemAndWithdrawTo(

        address _set,

        address _to,

        uint256 _quantity,

        uint256 _toExclude

    )

        external;



    /**

     * Deposit multiple tokens to the vault. Quantities should be in the

     * order of the addresses of the tokens being deposited.

     *

     * @param  _tokens           Array of the addresses of the ERC20 tokens

     * @param  _quantities       Array of the number of tokens to deposit

     */

    function batchDeposit(

        address[] calldata _tokens,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Withdraw multiple tokens from the vault. Quantities should be in the

     * order of the addresses of the tokens being withdrawn.

     *

     * @param  _tokens            Array of the addresses of the ERC20 tokens

     * @param  _quantities        Array of the number of tokens to withdraw

     */

    function batchWithdraw(

        address[] calldata _tokens,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Deposit any quantity of tokens into the vault.

     *

     * @param  _token           The address of the ERC20 token

     * @param  _quantity        The number of tokens to deposit

     */

    function deposit(

        address _token,

        uint256 _quantity

    )

        external;



    /**

     * Withdraw a quantity of tokens from the vault.

     *

     * @param  _token           The address of the ERC20 token

     * @param  _quantity        The number of tokens to withdraw

     */

    function withdraw(

        address _token,

        uint256 _quantity

    )

        external;



    /**

     * Transfer tokens associated with the sender's account in vault to another user's

     * account in vault.

     *

     * @param  _token           Address of token being transferred

     * @param  _to              Address of user receiving tokens

     * @param  _quantity        Amount of tokens being transferred

     */

    function internalTransfer(

        address _token,

        address _to,

        uint256 _quantity

    )

        external;



    /**

     * Deploys a new Set Token and adds it to the valid list of SetTokens

     *

     * @param  _factory              The address of the Factory to create from

     * @param  _components           The address of component tokens

     * @param  _units                The units of each component token

     * @param  _naturalUnit          The minimum unit to be issued or redeemed

     * @param  _name                 The bytes32 encoded name of the new Set

     * @param  _symbol               The bytes32 encoded symbol of the new Set

     * @param  _callData             Byte string containing additional call parameters

     * @return setTokenAddress       The address of the new Set

     */

    function createSet(

        address _factory,

        address[] calldata _components,

        uint256[] calldata _units,

        uint256 _naturalUnit,

        bytes32 _name,

        bytes32 _symbol,

        bytes calldata _callData

    )

        external

        returns (address);



    /**

     * Exposes internal function that deposits a quantity of tokens to the vault and attributes

     * the tokens respectively, to system modules.

     *

     * @param  _from            Address to transfer tokens from

     * @param  _to              Address to credit for deposit

     * @param  _token           Address of token being deposited

     * @param  _quantity        Amount of tokens to deposit

     */

    function depositModule(

        address _from,

        address _to,

        address _token,

        uint256 _quantity

    )

        external;



    /**

     * Exposes internal function that withdraws a quantity of tokens from the vault and

     * deattributes the tokens respectively, to system modules.

     *

     * @param  _from            Address to decredit for withdraw

     * @param  _to              Address to transfer tokens to

     * @param  _token           Address of token being withdrawn

     * @param  _quantity        Amount of tokens to withdraw

     */

    function withdrawModule(

        address _from,

        address _to,

        address _token,

        uint256 _quantity

    )

        external;



    /**

     * Exposes internal function that deposits multiple tokens to the vault, to system

     * modules. Quantities should be in the order of the addresses of the tokens being

     * deposited.

     *

     * @param  _from              Address to transfer tokens from

     * @param  _to                Address to credit for deposits

     * @param  _tokens            Array of the addresses of the tokens being deposited

     * @param  _quantities        Array of the amounts of tokens to deposit

     */

    function batchDepositModule(

        address _from,

        address _to,

        address[] calldata _tokens,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Exposes internal function that withdraws multiple tokens from the vault, to system

     * modules. Quantities should be in the order of the addresses of the tokens being withdrawn.

     *

     * @param  _from              Address to decredit for withdrawals

     * @param  _to                Address to transfer tokens to

     * @param  _tokens            Array of the addresses of the tokens being withdrawn

     * @param  _quantities        Array of the amounts of tokens to withdraw

     */

    function batchWithdrawModule(

        address _from,

        address _to,

        address[] calldata _tokens,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Expose internal function that exchanges components for Set tokens,

     * accepting any owner, to system modules

     *

     * @param  _owner        Address to use tokens from

     * @param  _recipient    Address to issue Set to

     * @param  _set          Address of the Set to issue

     * @param  _quantity     Number of tokens to issue

     */

    function issueModule(

        address _owner,

        address _recipient,

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Expose internal function that exchanges Set tokens for components,

     * accepting any owner, to system modules

     *

     * @param  _burnAddress         Address to burn token from

     * @param  _incrementAddress    Address to increment component tokens to

     * @param  _set                 Address of the Set to redeem

     * @param  _quantity            Number of tokens to redeem

     */

    function redeemModule(

        address _burnAddress,

        address _incrementAddress,

        address _set,

        uint256 _quantity

    )

        external;



    /**

     * Expose vault function that increments user's balance in the vault.

     * Available to system modules

     *

     * @param  _tokens          The addresses of the ERC20 tokens

     * @param  _owner           The address of the token owner

     * @param  _quantities      The numbers of tokens to attribute to owner

     */

    function batchIncrementTokenOwnerModule(

        address[] calldata _tokens,

        address _owner,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Expose vault function that decrement user's balance in the vault

     * Only available to system modules.

     *

     * @param  _tokens          The addresses of the ERC20 tokens

     * @param  _owner           The address of the token owner

     * @param  _quantities      The numbers of tokens to attribute to owner

     */

    function batchDecrementTokenOwnerModule(

        address[] calldata _tokens,

        address _owner,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Expose vault function that transfer vault balances between users

     * Only available to system modules.

     *

     * @param  _tokens           Addresses of tokens being transferred

     * @param  _from             Address tokens being transferred from

     * @param  _to               Address tokens being transferred to

     * @param  _quantities       Amounts of tokens being transferred

     */

    function batchTransferBalanceModule(

        address[] calldata _tokens,

        address _from,

        address _to,

        uint256[] calldata _quantities

    )

        external;



    /**

     * Transfers token from one address to another using the transfer proxy.

     * Only available to system modules.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _quantity       The number of tokens to transfer

     * @param  _from           The address to transfer from

     * @param  _to             The address to transfer to

     */

    function transferModule(

        address _token,

        uint256 _quantity,

        address _from,

        address _to

    )

        external;



    /**

     * Expose transfer proxy function to transfer tokens from one address to another

     * Only available to system modules.

     *

     * @param  _tokens         The addresses of the ERC20 token

     * @param  _quantities     The numbers of tokens to transfer

     * @param  _from           The address to transfer from

     * @param  _to             The address to transfer to

     */

    function batchTransferModule(

        address[] calldata _tokens,

        uint256[] calldata _quantities,

        address _from,

        address _to

    )

        external;

}



// File: contracts/core/interfaces/ISetToken.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;


/**

 * @title ISetToken

 * @author Set Protocol

 *

 * The ISetToken interface provides a light-weight, structured way to interact with the

 * SetToken contract from another contract.

 */

interface ISetToken {



    /* ============ External Functions ============ */



    /*

     * Get natural unit of Set

     *

     * @return  uint256       Natural unit of Set

     */

    function naturalUnit()

        external

        view

        returns (uint256);



    /*

     * Get addresses of all components in the Set

     *

     * @return  componentAddresses       Array of component tokens

     */

    function getComponents()

        external

        view

        returns (address[] memory);



    /*

     * Get units of all tokens in Set

     *

     * @return  units       Array of component units

     */

    function getUnits()

        external

        view

        returns (uint256[] memory);



    /*

     * Checks to make sure token is component of Set

     *

     * @param  _tokenAddress     Address of token being checked

     * @return  bool             True if token is component of Set

     */

    function tokenIsComponent(

        address _tokenAddress

    )

        external

        view

        returns (bool);



    /*

     * Mint set token for given address.

     * Can only be called by authorized contracts.

     *

     * @param  _issuer      The address of the issuing account

     * @param  _quantity    The number of sets to attribute to issuer

     */

    function mint(

        address _issuer,

        uint256 _quantity

    )

        external;



    /*

     * Burn set token for given address

     * Can only be called by authorized contracts

     *

     * @param  _from        The address of the redeeming account

     * @param  _quantity    The number of sets to burn from redeemer

     */

    function burn(

        address _from,

        uint256 _quantity

    )

        external;



    /**

    * Transfer token for a specified address

    *

    * @param to The address to transfer to.

    * @param value The amount to be transferred.

    */

    function transfer(

        address to,

        uint256 value

    )

        external;

}



// File: contracts/core/interfaces/IVault.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;


/**

 * @title IVault

 * @author Set Protocol

 *

 * The IVault interface provides a light-weight, structured way to interact with the Vault

 * contract from another contract.

 */

interface IVault {



    /*

     * Withdraws user's unassociated tokens to user account. Can only be

     * called by authorized core contracts.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _to             The address to transfer token to

     * @param  _quantity       The number of tokens to transfer

     */

    function withdrawTo(

        address _token,

        address _to,

        uint256 _quantity

    )

        external;



    /*

     * Increment quantity owned of a token for a given address. Can

     * only be called by authorized core contracts.

     *

     * @param  _token           The address of the ERC20 token

     * @param  _owner           The address of the token owner

     * @param  _quantity        The number of tokens to attribute to owner

     */

    function incrementTokenOwner(

        address _token,

        address _owner,

        uint256 _quantity

    )

        external;



    /*

     * Decrement quantity owned of a token for a given address. Can only

     * be called by authorized core contracts.

     *

     * @param  _token           The address of the ERC20 token

     * @param  _owner           The address of the token owner

     * @param  _quantity        The number of tokens to deattribute to owner

     */

    function decrementTokenOwner(

        address _token,

        address _owner,

        uint256 _quantity

    )

        external;



    /**

     * Transfers tokens associated with one account to another account in the vault

     *

     * @param  _token          Address of token being transferred

     * @param  _from           Address token being transferred from

     * @param  _to             Address token being transferred to

     * @param  _quantity       Amount of tokens being transferred

     */



    function transferBalance(

        address _token,

        address _from,

        address _to,

        uint256 _quantity

    )

        external;





    /*

     * Withdraws user's unassociated tokens to user account. Can only be

     * called by authorized core contracts.

     *

     * @param  _tokens          The addresses of the ERC20 tokens

     * @param  _owner           The address of the token owner

     * @param  _quantities      The numbers of tokens to attribute to owner

     */

    function batchWithdrawTo(

        address[] calldata _tokens,

        address _to,

        uint256[] calldata _quantities

    )

        external;



    /*

     * Increment quantites owned of a collection of tokens for a given address. Can

     * only be called by authorized core contracts.

     *

     * @param  _tokens          The addresses of the ERC20 tokens

     * @param  _owner           The address of the token owner

     * @param  _quantities      The numbers of tokens to attribute to owner

     */

    function batchIncrementTokenOwner(

        address[] calldata _tokens,

        address _owner,

        uint256[] calldata _quantities

    )

        external;



    /*

     * Decrements quantites owned of a collection of tokens for a given address. Can

     * only be called by authorized core contracts.

     *

     * @param  _tokens          The addresses of the ERC20 tokens

     * @param  _owner           The address of the token owner

     * @param  _quantities      The numbers of tokens to attribute to owner

     */

    function batchDecrementTokenOwner(

        address[] calldata _tokens,

        address _owner,

        uint256[] calldata _quantities

    )

        external;



   /**

     * Transfers tokens associated with one account to another account in the vault

     *

     * @param  _tokens           Addresses of tokens being transferred

     * @param  _from             Address tokens being transferred from

     * @param  _to               Address tokens being transferred to

     * @param  _quantities       Amounts of tokens being transferred

     */

    function batchTransferBalance(

        address[] calldata _tokens,

        address _from,

        address _to,

        uint256[] calldata _quantities

    )

        external;



    /*

     * Get balance of particular contract for owner.

     *

     * @param  _token    The address of the ERC20 token

     * @param  _owner    The address of the token owner

     */

    function getOwnerBalance(

        address _token,

        address _owner

    )

        external

        view

        returns (uint256);

}



// File: contracts/core/modules/lib/ExchangeIssuanceLibrary.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;














/**

 * @title ExchangeIssuanceLibrary

 * @author Set Protocol

 *

 * The ExchangeIssuanceLibrary contains functions for validating exchange order data

 */

library ExchangeIssuanceLibrary {

    using SafeMath for uint256;

    using AddressArrayUtils for address[];



    // ============ Structs ============



    struct ExchangeIssuanceParams {

        address setAddress;

        uint256 quantity;

        uint8[] sendTokenExchangeIds;

        address[] sendTokens;

        uint256[] sendTokenAmounts;

        address[] receiveTokens;

        uint256[] receiveTokenAmounts;

    }



    /**

     * Validates that the quantity to issue is positive and a multiple of the Set natural unit.

     *

     * @param _set                The address of the Set

     * @param _quantity           The quantity of Sets to issue or redeem

     */

    function validateQuantity(

        address _set,

        uint256 _quantity

    )

        internal

        view

    {

        // Make sure quantity to issue is greater than 0

        require(

            _quantity > 0,

            "ExchangeIssuanceLibrary.validateQuantity: Quantity must be positive"

        );



        // Make sure Issue quantity is multiple of the Set natural unit

        require(

            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,

            "ExchangeIssuanceLibrary.validateQuantity: Quantity must be multiple of natural unit"

        );

    }



    /**

     * Validates that the required Components and amounts are valid components and positive.

     * Duplicate receive token values are not allowed

     *

     * @param _receiveTokens           The addresses of components required for issuance

     * @param _receiveTokenAmounts     The quantities of components required for issuance

     */

    function validateReceiveTokens(

        address[] memory _receiveTokens,

        uint256[] memory _receiveTokenAmounts

    )

        internal

        view

    {

        uint256 receiveTokensCount = _receiveTokens.length;



        // Make sure required components array is non-empty

        require(

            receiveTokensCount > 0,

            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens must not be empty"

        );



        // Ensure the receive tokens has no duplicates

        require(

            !_receiveTokens.hasDuplicate(),

            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens must not have duplicates"

        );



        // Make sure required components and required component amounts are equal length

        require(

            receiveTokensCount == _receiveTokenAmounts.length,

            "ExchangeIssuanceLibrary.validateReceiveTokens: Receive tokens and amounts must be equal length"

        );



        for (uint256 i = 0; i < receiveTokensCount; i++) {

            // Make sure all required component amounts are non-zero

            require(

                _receiveTokenAmounts[i] > 0,

                "ExchangeIssuanceLibrary.validateReceiveTokens: Component amounts must be positive"

            );

        }

    }



    /**

     * Validates that the tokens received exceeds what we expect

     *

     * @param _vault                        The address of the Vault

     * @param _receiveTokens                The addresses of components required for issuance

     * @param _requiredBalances             The quantities of components required for issuance

     * @param _userToCheck                  The address of the user

     */

    function validatePostExchangeReceiveTokenBalances(

        address _vault,

        address[] memory _receiveTokens,

        uint256[] memory _requiredBalances,

        address _userToCheck

    )

        internal

        view

    {

        // Get vault instance

        IVault vault = IVault(_vault);



        // Check that caller's receive tokens in Vault have been incremented correctly

        for (uint256 i = 0; i < _receiveTokens.length; i++) {

            uint256 currentBal = vault.getOwnerBalance(

                _receiveTokens[i],

                _userToCheck

            );



            require(

                currentBal >= _requiredBalances[i],

                "ExchangeIssuanceLibrary.validatePostExchangeReceiveTokenBalances: Insufficient receive token acquired"

            );

        }

    }



    /**

     * Validates that the send tokens inputs are valid. Since tokens are sent to various exchanges,

     * duplicate send tokens are valid

     *

     * @param _core                         The address of Core

     * @param _sendTokenExchangeIds         List of exchange wrapper enumerations corresponding to

     *                                          the wrapper that will handle the component

     * @param _sendTokens                   The address of the send tokens

     * @param _sendTokenAmounts             The quantities of send tokens

     */

    function validateSendTokenParams(

        address _core,

        uint8[] memory _sendTokenExchangeIds,

        address[] memory _sendTokens,

        uint256[] memory _sendTokenAmounts

    )

        internal

        view

    {

        require(

            _sendTokens.length > 0,

            "ExchangeIssuanceLibrary.validateSendTokenParams: Send token inputs must not be empty"

        );



        require(

            _sendTokenExchangeIds.length == _sendTokens.length &&

            _sendTokens.length == _sendTokenAmounts.length,

            "ExchangeIssuanceLibrary.validateSendTokenParams: Send token inputs must be of the same length"

        );



        ICore core = ICore(_core);



        for (uint256 i = 0; i < _sendTokenExchangeIds.length; i++) {

            // Make sure all exchanges are valid

            require(

                core.exchangeIds(_sendTokenExchangeIds[i]) != address(0),

                "ExchangeIssuanceLibrary.validateSendTokenParams: Must be valid exchange"

            );



            // Make sure all send token amounts are non-zero

            require(

                _sendTokenAmounts[i] > 0,

                "ExchangeIssuanceLibrary.validateSendTokenParams: Send amounts must be positive"

            );

        }

    }

}



// File: contracts/lib/IERC20.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;




/**

 * @title IERC20

 * @author Set Protocol

 *

 * Interface for using ERC20 Tokens. This interface is needed to interact with tokens that are not

 * fully ERC20 compliant and return something other than true on successful transfers.

 */

interface IERC20 {

    function balanceOf(

        address _owner

    )

        external

        view

        returns (uint256);



    function allowance(

        address _owner,

        address _spender

    )

        external

        view

        returns (uint256);



    function transfer(

        address _to,

        uint256 _quantity

    )

        external;



    function transferFrom(

        address _from,

        address _to,

        uint256 _quantity

    )

        external;



    function approve(

        address _spender,

        uint256 _quantity

    )

        external

        returns (bool);



    function totalSupply()

        external

        returns (uint256);

}



// File: contracts/lib/ERC20Wrapper.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;








/**

 * @title ERC20Wrapper

 * @author Set Protocol

 *

 * This library contains functions for interacting wtih ERC20 tokens, even those not fully compliant.

 * For all functions we will only accept tokens that return a null or true value, any other values will

 * cause the operation to revert.

 */

library ERC20Wrapper {



    // ============ Internal Functions ============



    /**

     * Check balance owner's balance of ERC20 token

     *

     * @param  _token          The address of the ERC20 token

     * @param  _owner          The owner who's balance is being checked

     * @return  uint256        The _owner's amount of tokens

     */

    function balanceOf(

        address _token,

        address _owner

    )

        external

        view

        returns (uint256)

    {

        return IERC20(_token).balanceOf(_owner);

    }



    /**

     * Checks spender's allowance to use token's on owner's behalf.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _owner          The token owner address

     * @param  _spender        The address the allowance is being checked on

     * @return  uint256        The spender's allowance on behalf of owner

     */

    function allowance(

        address _token,

        address _owner,

        address _spender

    )

        internal

        view

        returns (uint256)

    {

        return IERC20(_token).allowance(_owner, _spender);

    }



    /**

     * Transfers tokens from an address. Handle's tokens that return true or null.

     * If other value returned, reverts.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _to             The address to transfer to

     * @param  _quantity       The amount of tokens to transfer

     */

    function transfer(

        address _token,

        address _to,

        uint256 _quantity

    )

        external

    {

        IERC20(_token).transfer(_to, _quantity);



        // Check that transfer returns true or null

        require(

            checkSuccess(),

            "ERC20Wrapper.transfer: Bad return value"

        );

    }



    /**

     * Transfers tokens from an address (that has set allowance on the proxy).

     * Handle's tokens that return true or null. If other value returned, reverts.

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

    {

        IERC20(_token).transferFrom(_from, _to, _quantity);



        // Check that transferFrom returns true or null

        require(

            checkSuccess(),

            "ERC20Wrapper.transferFrom: Bad return value"

        );

    }



    /**

     * Grants spender ability to spend on owner's behalf.

     * Handle's tokens that return true or null. If other value returned, reverts.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _spender        The address to approve for transfer

     * @param  _quantity       The amount of tokens to approve spender for

     */

    function approve(

        address _token,

        address _spender,

        uint256 _quantity

    )

        internal

    {

        IERC20(_token).approve(_spender, _quantity);



        // Check that approve returns true or null

        require(

            checkSuccess(),

            "ERC20Wrapper.approve: Bad return value"

        );

    }



    /**

     * Ensure's the owner has granted enough allowance for system to

     * transfer tokens.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _owner          The address of the token owner

     * @param  _spender        The address to grant/check allowance for

     * @param  _quantity       The amount to see if allowed for

     */

    function ensureAllowance(

        address _token,

        address _owner,

        address _spender,

        uint256 _quantity

    )

        internal

    {

        uint256 currentAllowance = allowance(_token, _owner, _spender);

        if (currentAllowance < _quantity) {

            approve(

                _token,

                _spender,

                CommonMath.maxUInt256()

            );

        }

    }



    // ============ Private Functions ============



    /**

     * Checks the return value of the previous function up to 32 bytes. Returns true if the previous

     * function returned 0 bytes or 1.

     */

    function checkSuccess(

    )

        private

        pure

        returns (bool)

    {

        // default to failure

        uint256 returnValue = 0;



        assembly {

            // check number of bytes returned from last function call

            switch returndatasize



            // no bytes returned: assume success

            case 0x0 {

                returnValue := 1

            }



            // 32 bytes returned

            case 0x20 {

                // copy 32 bytes into scratch space

                returndatacopy(0x0, 0x0, 0x20)



                // load those bytes into returnValue

                returnValue := mload(0x0)

            }



            // not sure what was returned: dont mark as success

            default { }

        }



        // check if returned value is one or nothing

        return returnValue == 1;

    }

}



// File: contracts/core/lib/ExchangeWrapperLibraryV2.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;




/**

 * @title ExchangeWrapperLibrary

 * @author Set Protocol

 *

 * This library contains structs and functions to assist executing orders on third party exchanges

 *

 * CHANGELOG

 * - Removes functions that result in circular dependencies when trying to flatten.

 * - Functions using this library mainly use it for the structs

 */

library ExchangeWrapperLibraryV2 {



    // ============ Structs ============



    /**

     * caller                           Original user initiating transaction

     * orderCount                       Expected number of orders to execute

     */

    struct ExchangeData {

        address caller;

        uint256 orderCount;

    }



    /**

     * components                       A list of the acquired components from exchange wrapper

     * componentQuantities              A list of the component quantities acquired

     */

    struct ExchangeResults {

        address[] receiveTokens;

        uint256[] receiveTokenAmounts;

    }

}



// File: contracts/core/interfaces/IExchangeWrapper.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;




/**

 * @title IExchangeWrapper

 * @author Set Protocol

 *

 * Interface for executing an order with an exchange wrapper

 */

interface IExchangeWrapper {



    /* ============ External Functions ============ */



    /**

     * Exchange some amount of makerToken for takerToken.

     *

     * maker                            Issuance order maker

     * taker                            Issuance order taker

     * makerToken                       Address of maker token used in exchange orders

     * makerAssetAmount                 Amount of issuance order maker token to use on this exchange

     * orderCount                       Expected number of orders to execute

     * fillQuantity                     Quantity of Set to be filled

     * attemptedFillQuantity            Quantity of Set taker attempted to fill

     *

     * @param  _orderData               Arbitrary bytes data for any information to pass to the exchange

     */

    function exchange(

        ExchangeWrapperLibraryV2.ExchangeData calldata _exchangeData,

        bytes calldata _orderData

    )

        external

        returns (ExchangeWrapperLibraryV2.ExchangeResults memory);

}



// File: contracts/core/lib/ExchangeWrapperLibrary.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;
















/**

 * @title ExchangeWrapperLibrary

 * @author Set Protocol

 *

 * This library contains structs and functions to assist executing orders on third party exchanges

 */

library ExchangeWrapperLibrary {



    // ============ Structs ============



    /**

     * caller                           Original user initiating transaction

     * orderCount                       Expected number of orders to execute

     */

    struct ExchangeData {

        address caller;

        uint256 orderCount;

    }



    /**

     * receiveTokens                    A list of the acquired components from exchange wrapper

     * receiveTokenAmounts              A list of the component quantities acquired

     */

    struct ExchangeResults {

        address[] receiveTokens;

        uint256[] receiveTokenAmounts;

    }



    /**

     * Checks if any send tokens leftover and transfers to caller

     * @param  _sendTokens    The addresses of send tokens

     * @param  _caller        The address of the original transaction caller

     */

    function returnLeftoverSendTokens(

        address[] memory _sendTokens,

        address _caller

    )

        internal

    {

        for (uint256 i = 0; i < _sendTokens.length; i++) {

            // Transfer any unused or remainder send token back to the caller

            uint256 remainderSendToken = ERC20Wrapper.balanceOf(_sendTokens[i], address(this));

            if (remainderSendToken > 0) {

                ERC20Wrapper.transfer(

                    _sendTokens[i],

                    _caller,

                    remainderSendToken

                );

            }

        }

    }



    /**

     * Calls exchange to execute trades and deposits fills into Vault for issuanceOrder maker.

     *

     *

     * @param  _core                    Address of Core

     * @param  _exchangeData            Standard exchange wrapper interface object containing exchange metadata

     * @param  _exchangeWrapper         Address of exchange wrapper being called

     * @param  _bodyData                Arbitrary bytes data for orders to be executed on exchange

     */

    function callExchange(

        address _core,

        ExchangeWrapperLibraryV2.ExchangeData memory _exchangeData,

        address _exchangeWrapper,

        bytes memory _bodyData

    )

        internal

    {

        // Call Exchange

        ExchangeWrapperLibraryV2.ExchangeResults memory exchangeResults = IExchangeWrapper(_exchangeWrapper).exchange(

            _exchangeData,

            _bodyData

        );



        // Transfer receiveToken tokens from wrapper to vault

        ICore(_core).batchDepositModule(

            _exchangeWrapper,

            _exchangeData.caller,

            exchangeResults.receiveTokens,

            exchangeResults.receiveTokenAmounts

        );

    }

}



// File: contracts/core/interfaces/ITransferProxy.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;


/**

 * @title ITransferProxy

 * @author Set Protocol

 *

 * The ITransferProxy interface provides a light-weight, structured way to interact with the

 * TransferProxy contract from another contract.

 */

interface ITransferProxy {



    /* ============ External Functions ============ */



    /**

     * Transfers tokens from an address (that has set allowance on the proxy).

     * Can only be called by authorized core contracts.

     *

     * @param  _token          The address of the ERC20 token

     * @param  _quantity       The number of tokens to transfer

     * @param  _from           The address to transfer from

     * @param  _to             The address to transfer to

     */

    function transfer(

        address _token,

        uint256 _quantity,

        address _from,

        address _to

    )

        external;



    /**

     * Transfers tokens from an address (that has set allowance on the proxy).

     * Can only be called by authorized core contracts.

     *

     * @param  _tokens         The addresses of the ERC20 token

     * @param  _quantities     The numbers of tokens to transfer

     * @param  _from           The address to transfer from

     * @param  _to             The address to transfer to

     */

    function batchTransfer(

        address[] calldata _tokens,

        uint256[] calldata _quantities,

        address _from,

        address _to

    )

        external;

}



// File: contracts/core/modules/lib/ModuleCoreState.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;










/**

 * @title ModuleCoreState

 * @author Set Protocol

 *

 * The ModuleCoreState library maintains Core-related state for modules

 */

contract ModuleCoreState {



    /* ============ State Variables ============ */



    // Address of core contract

    address public core;



    // Address of vault contract

    address public vault;



    // Instance of core contract

    ICore public coreInstance;



    // Instance of vault contract

    IVault public vaultInstance;



    /* ============ Public Getters ============ */



    /**

     * Constructor function for ModuleCoreState

     *

     * @param _core                The address of Core

     * @param _vault               The address of Vault

     */

    constructor(

        address _core,

        address _vault

    )

        public

    {

        // Commit passed address to core state variable

        core = _core;



        // Commit passed address to coreInstance state variable

        coreInstance = ICore(_core);



        // Commit passed address to vault state variable

        vault = _vault;



        // Commit passed address to vaultInstance state variable

        vaultInstance = IVault(_vault);

    }

}



// File: contracts/core/modules/lib/ExchangeExecution.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;




















/**

 * @title ExchangeExecution

 * @author Set Protocol

 *

 * The ExchangeExecution contract exposes functions that allow validation and execution of exchange orders.

 */

contract ExchangeExecution is

    ModuleCoreState

{

    using SafeMath for uint256;



     /* ============ Private Functions ============ */



    /**

     * Execute the exchange orders by parsing the order data and facilitating the transfers. Each

     * header represents a batch of orders for a particular exchange (0x, Kyber)

     *

     * @param _orderData               Bytes array containing the exchange orders to execute

     */

    function executeExchangeOrders(

        bytes memory _orderData

    )

        internal

    {

        // Bitmask integer of called exchanges. Acts as a lock so that duplicate exchange headers are not passed in.

        uint256 calledExchanges = 0;



        uint256 scannedBytes = 0;

        while (scannedBytes < _orderData.length) {

            // Parse exchange header based on scannedBytes

            ExchangeHeaderLibrary.ExchangeHeader memory header = ExchangeHeaderLibrary.parseExchangeHeader(

                _orderData,

                scannedBytes

            );



            // Get exchange address from state mapping based on header exchange info

            address exchangeWrapper = coreInstance.exchangeIds(header.exchange);



            // Verify exchange address is registered

            require(

                exchangeWrapper != address(0),

                "ExchangeExecution.executeExchangeOrders: Invalid or disabled Exchange address"

            );



            // Verify exchange has not already been called

            uint256 exchangeBitIndex = CommonMath.safePower(2, header.exchange);

            require(

                (calledExchanges & exchangeBitIndex) == 0,

                "ExchangeExecution.executeExchangeOrders: Exchange already called"

            );



            // Calculate the exchange data length

            uint256 exchangeDataLength = header.orderDataBytesLength.add(

                ExchangeHeaderLibrary.EXCHANGE_HEADER_LENGTH()

            );



            // Read the order body based on order data length info in header plus the length of the header

            bytes memory bodyData = ExchangeHeaderLibrary.sliceBodyData(

                _orderData,

                scannedBytes,

                exchangeDataLength

            );



            // Construct the Exchange Data struct for callExchange interface

            ExchangeWrapperLibraryV2.ExchangeData memory exchangeData = ExchangeWrapperLibraryV2.ExchangeData({

                caller: msg.sender,

                orderCount: header.orderCount

            });



            // Execute orders using the appropriate exchange wrappers

            ExchangeWrapperLibrary.callExchange(

                core,

                exchangeData,

                exchangeWrapper,

                bodyData

            );



            // Update scanned bytes with header and body lengths

            scannedBytes = scannedBytes.add(exchangeDataLength);



            // Increment bit of current exchange to ensure non-duplicate entries

            calledExchanges = calledExchanges.add(exchangeBitIndex);

        }

    }



    /**

     * Calculates the user's balance of tokens required after exchange orders have been executed

     *

     * @param  _exchangeIssuanceParams       A Struct containing exchange issuance metadata

     * @return uint256[]                     Expected token balances after order execution

     */

    function calculateReceiveTokenBalances(

        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams

    )

        internal

        view

        returns (uint256[] memory)

    {

        // Calculate amount of receive tokens required

        uint256[] memory requiredBalances = new uint256[](_exchangeIssuanceParams.receiveTokens.length);

        for (uint256 i = 0; i < _exchangeIssuanceParams.receiveTokens.length; i++) {

            // Get the user's current vault balances

            uint256 tokenBalance = vaultInstance.getOwnerBalance(

                _exchangeIssuanceParams.receiveTokens[i],

                msg.sender

            );



            // Amount of receive tokens to be added to Vault

            uint256 requiredAddition = _exchangeIssuanceParams.receiveTokenAmounts[i];



            // Required vault balances after exchange order execution

            requiredBalances[i] = tokenBalance.add(requiredAddition);

        }



        return requiredBalances;

    }



    /**

     * Validates exchangeIssueParam inputs

     *

     * @param  _exchangeIssuanceParams       A Struct containing exchange issuance metadata

     */

    function validateExchangeIssuanceParams(

        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams

    )

        internal

        view

    {

        // Verify Set was created by Core and is enabled

        require(

            coreInstance.validSets(_exchangeIssuanceParams.setAddress),

            "ExchangeExecution.validateExchangeIssuanceParams: Invalid or disabled SetToken address"

        );



        // Validate the issuance quantity

        ExchangeIssuanceLibrary.validateQuantity(

            _exchangeIssuanceParams.setAddress,

            _exchangeIssuanceParams.quantity

        );



        // Validate send token data

        ExchangeIssuanceLibrary.validateSendTokenParams(

            core,

            _exchangeIssuanceParams.sendTokenExchangeIds,

            _exchangeIssuanceParams.sendTokens,

            _exchangeIssuanceParams.sendTokenAmounts

        );



        // Validate receive token inputs

        ExchangeIssuanceLibrary.validateReceiveTokens(

            _exchangeIssuanceParams.receiveTokens,

            _exchangeIssuanceParams.receiveTokenAmounts

        );

    }

}



// File: contracts/core/lib/SetTokenLibrary.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;










library SetTokenLibrary {

    using SafeMath for uint256;



    struct SetDetails {

        uint256 naturalUnit;

        address[] components;

        uint256[] units;

    }



    /**

     * Validates that passed in tokens are all components of the Set

     *

     * @param _set                      Address of the Set

     * @param _tokens                   List of tokens to check

     */

    function validateTokensAreComponents(

        address _set,

        address[] calldata _tokens

    )

        external

        view

    {

        for (uint256 i = 0; i < _tokens.length; i++) {

            // Make sure all tokens are members of the Set

            require(

                ISetToken(_set).tokenIsComponent(_tokens[i]),

                "SetTokenLibrary.validateTokensAreComponents: Component must be a member of Set"

            );



        }

    }



    /**

     * Validates that passed in quantity is a multiple of the natural unit of the Set.

     *

     * @param _set                      Address of the Set

     * @param _quantity                 Quantity to validate

     */

    function isMultipleOfSetNaturalUnit(

        address _set,

        uint256 _quantity

    )

        external

        view

    {

        require(

            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,

            "SetTokenLibrary.isMultipleOfSetNaturalUnit: Quantity is not a multiple of nat unit"

        );

    }



    /**

     * Validates that passed in quantity is a multiple of the natural unit of the Set.

     *

     * @param _core                     Address of Core

     * @param _set                      Address of the Set

     */

    function requireValidSet(

        ICore _core,

        address _set

    )

        internal

        view

    {

        require(

            _core.validSets(_set),

            "SetTokenLibrary: Must be an approved SetToken address"

        );

    }



    /**

     * Retrieves the Set's natural unit, components, and units.

     *

     * @param _set                      Address of the Set

     * @return SetDetails               Struct containing the natural unit, components, and units

     */

    function getSetDetails(

        address _set

    )

        internal

        view

        returns (SetDetails memory)

    {

        // Declare interface variables

        ISetToken setToken = ISetToken(_set);



        // Fetch set token properties

        uint256 naturalUnit = setToken.naturalUnit();

        address[] memory components = setToken.getComponents();

        uint256[] memory units = setToken.getUnits();



        return SetDetails({

            naturalUnit: naturalUnit,

            components: components,

            units: units

        });

    }

}



// File: contracts/core/modules/ExchangeIssuanceModule.sol



/*

    Copyright 2018 Set Labs Inc.



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



pragma solidity ^0.5.7;


















/**

 * @title ExchangeIssuanceModule

 * @author Set Protocol

 *

 * The ExchangeIssuanceModule facilitates the exchangeIssue and exchangeRedeem functions which allows

 * the issuance and redemption Sets using exchange orders

 */

contract ExchangeIssuanceModule is

    ModuleCoreState,

    ExchangeExecution,

    ReentrancyGuard

{

    using SafeMath for uint256;



    /* ============ Events ============ */



    event LogExchangeIssue(

        address setAddress,

        address indexed callerAddress,

        uint256 quantity,

        address[] sendTokens,

        uint256[] sendTokenAmounts

    );



    event LogExchangeRedeem(

        address setAddress,

        address indexed callerAddress,

        uint256 quantity,

        address[] receiveTokens,

        uint256[] receiveTokenAmounts

    );



    /* ============ Constructor ============ */



    /**

     * Constructor function for ExchangeIssuanceModule

     *

     * @param _core                The address of Core

     * @param _vault               The address of Vault

     */

    constructor(

        address _core,

        address _vault

    )

        public

        ModuleCoreState(

            _core,

            _vault

        )

    {}



    /* ============ Public Functions ============ */



    /**

     * Performs trades via exchange wrappers to acquire components and issues a Set to the caller

     *

     * @param _exchangeIssuanceParams              A Struct containing exchange issuance metadata

     * @param _orderData                           Bytes array containing the exchange orders to execute

     */

    function exchangeIssue(

        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,

        bytes memory _orderData

    )

        public

        nonReentrant

    {

        // Ensures validity of exchangeIssuanceParams

        validateExchangeIssuanceParams(_exchangeIssuanceParams);



        // Validate that all receiveTokens are components of the SEt

        SetTokenLibrary.validateTokensAreComponents(

            _exchangeIssuanceParams.setAddress,

            _exchangeIssuanceParams.receiveTokens

        );



        // Transfer the send tokens to the appropriate exchanges

        transferSendTokensToExchangeWrappers(

            _exchangeIssuanceParams.sendTokenExchangeIds,

            _exchangeIssuanceParams.sendTokens,

            _exchangeIssuanceParams.sendTokenAmounts

        );



        // Execute the exchange orders using the encoded order data

        executeOrders(_exchangeIssuanceParams, _orderData);



        // Issue Set to the caller

        coreInstance.issueModule(

            msg.sender,

            msg.sender,

            _exchangeIssuanceParams.setAddress,

            _exchangeIssuanceParams.quantity

        );



        emit LogExchangeIssue(

            _exchangeIssuanceParams.setAddress,

            msg.sender,

            _exchangeIssuanceParams.quantity,

            _exchangeIssuanceParams.sendTokens,

            _exchangeIssuanceParams.sendTokenAmounts

        );

    }



    /**

     * Redeems a Set and performs trades via exchange wrappers for specified receive tokens. The receive

     * tokens are attributed to the caller.

     *

     * @param _exchangeIssuanceParams              A Struct containing exchange issuance metadata

     * @param _orderData                           Bytes array containing the exchange orders to execute

     */

    function exchangeRedeem(

        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,

        bytes memory _orderData

    )

        public

        nonReentrant

    {

        // Validate exchangeIssuanceParams

        validateExchangeIssuanceParams(_exchangeIssuanceParams);



        // Validate that all sendTokens are components of the Set

        SetTokenLibrary.validateTokensAreComponents(

            _exchangeIssuanceParams.setAddress,

            _exchangeIssuanceParams.sendTokens

        );



        // Redeem Set into the vault, attributing components to this contract

        coreInstance.redeemModule(

            msg.sender,

            address(this),

            _exchangeIssuanceParams.setAddress,

            _exchangeIssuanceParams.quantity

        );



        // Transfer the send tokens to the appropriate exchanges

        withdrawSendTokensFromVaultToExchangeWrappers(

            _exchangeIssuanceParams.sendTokenExchangeIds,

            _exchangeIssuanceParams.sendTokens,

            _exchangeIssuanceParams.sendTokenAmounts

        );



        // Executes the orders, depositing tokens into the Vault to the user

        executeOrders(_exchangeIssuanceParams, _orderData);



        // Withdraw receive tokens from the Vault to the user

        coreInstance.batchWithdrawModule(

            msg.sender,

            msg.sender,

            _exchangeIssuanceParams.receiveTokens,

            _exchangeIssuanceParams.receiveTokenAmounts

        );



        // Withdraw any remaining non-exchanged components to the user

        withdrawRemainingComponentsToUser(_exchangeIssuanceParams.setAddress);



        emit LogExchangeRedeem(

            _exchangeIssuanceParams.setAddress,

            msg.sender,

            _exchangeIssuanceParams.quantity,

            _exchangeIssuanceParams.receiveTokens,

            _exchangeIssuanceParams.receiveTokenAmounts

        );

    }



    /* ============ Private Functions ============ */



    /**

     * Calculates required tokens to receive, executes orders, and checks post-exchange receive balances.

     *

     * @param _exchangeIssuanceParams              A Struct containing exchange issuance metadata

     * @param _orderData                           Bytes array containing the exchange orders to execute

     */

    function executeOrders(

        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams,

        bytes memory _orderData

    )

        private

    {

        // Calculate expected receive token balances after exchange orders executed

        uint256[] memory requiredBalances = calculateReceiveTokenBalances(

            _exchangeIssuanceParams

        );



        // Execute exchange orders

        executeExchangeOrders(_orderData);



        // Check that sender's receive tokens in Vault have been incremented correctly

        ExchangeIssuanceLibrary.validatePostExchangeReceiveTokenBalances(

            vault,

            _exchangeIssuanceParams.receiveTokens,

            requiredBalances,

            msg.sender

        );

    }



    /**

     * Transfers send tokens from the user to the appropriate exchange wrapper. Used in exchange

     * issue.

     *

     * @param _sendTokenExchangeIds            List of exchange wrapper enumerations corresponding to

     *                                              the wrapper that will handle the component

     * @param _sendTokens                      Array of addresses of the payment tokens

     * @param _sendTokenAmounts                Array of amounts of payment Tokens

     */

    function transferSendTokensToExchangeWrappers(

        uint8[] memory _sendTokenExchangeIds,

        address[] memory _sendTokens,

        uint256[] memory _sendTokenAmounts

    )

        private

    {

        for (uint256 i = 0; i < _sendTokens.length; i++) {

            // Get exchange wrapper address from state mapping based on enumeration

            address exchangeWrapper = coreInstance.exchangeIds(_sendTokenExchangeIds[i]);



            // Transfer send tokens to the appropriate exchange wrapper

            coreInstance.transferModule(

                _sendTokens[i],

                _sendTokenAmounts[i],

                msg.sender,

                exchangeWrapper

            );

        }

    }



    /**

     * Transfers send tokens from the Vault to the appropriate exchange wrappers. Used in

     * exchange redeem.

     *

     * @param _sendTokenExchangeIds            List of exchange wrapper enumerations corresponding to

     *                                              the wrapper that will handle the component

     * @param _sendTokens                      Array of addresses of the payment tokens

     * @param _sendTokenAmounts                Array of amounts of payment Tokens

     */

    function withdrawSendTokensFromVaultToExchangeWrappers(

        uint8[] memory _sendTokenExchangeIds,

        address[] memory _sendTokens,

        uint256[] memory _sendTokenAmounts

    )

        private

    {

        for (uint256 i = 0; i < _sendTokens.length; i++) {

            // Get exchange address from state mapping based on header exchange info

            address exchangeWrapper = coreInstance.exchangeIds(_sendTokenExchangeIds[i]);



            // Withdraw send tokens from vault (owned by this contract) to the appropriate exchange wrapper

            coreInstance.withdrawModule(

                address(this),

                exchangeWrapper,

                _sendTokens[i],

                _sendTokenAmounts[i]

            );

        }

    }



    /**

     * Withdraws any remaining un-exchanged components from the Vault in the posession of this contract

     * to the caller

     *

     * @param  _setAddress   Address of the Base Set

     */

    function withdrawRemainingComponentsToUser(

        address _setAddress

    )

        private

    {

        address[] memory baseSetComponents = ISetToken(_setAddress).getComponents();

        uint256[] memory baseSetWithdrawQuantities = new uint256[](baseSetComponents.length);

        for (uint256 i = 0; i < baseSetComponents.length; i++) {

            uint256 withdrawQuantity = vaultInstance.getOwnerBalance(baseSetComponents[i], address(this));

            if (withdrawQuantity > 0) {

                baseSetWithdrawQuantities[i] = withdrawQuantity;

            }

        }



        // Return the unexchanged components to the user

        coreInstance.batchWithdrawModule(

            address(this),

            msg.sender,

            baseSetComponents,

            baseSetWithdrawQuantities

        );

    }

}