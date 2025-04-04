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



// File: contracts/interfaces/ISwapAndDeposit.sol



pragma solidity ^0.5.12;




interface ISwapAndDeposit {

    event SwapDeposit(address loan, address guy);



    function init(address _depositAddress, address _factoryAddress) external returns (bool);



    function isDestroyed() external view returns (bool);



    function swapAndDeposit(

        address payable depositor,

        address inputTokenAddress,

        uint256 inputTokenAmount

    ) external;

}



// File: contracts/interfaces/ISwapAndDepositFactory.sol



pragma solidity ^0.5.12;


interface ISwapAndDepositFactory {

    event SwapContract(address newSwap);



    function setAuthAddress(address _authAddress) external;



    function setUniswapAddress(address _uniswapAddress) external;



    function setLibraryAddress(address _libraryAddress) external;



    function deploy() external returns (address proxyAddress);

}



// File: contracts/interfaces/IAuthorization.sol



pragma solidity ^0.5.12;


interface IAuthorization {

    function getKycAddress() external view returns (address);



    function getDepositAddress() external view returns (address);



    function hasDeposited(address user) external view returns (bool);



    function isKYCConfirmed(address user) external view returns (bool);



    function setKYCRegistry(address _kycAddress) external returns (bool);



    function setDepositRegistry(address _depositAddress) external returns (bool);

}



// File: contracts/CloneFactory.sol



pragma solidity ^0.5.12;


/*

The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining

a copy of this software and associated documentation files (the

"Software"), to deal in the Software without restriction, including

without limitation the rights to use, copy, modify, merge, publish,

distribute, sublicense, and/or sell copies of the Software, and to

permit persons to whom the Software is furnished to do so, subject to

the following conditions:

The above copyright notice and this permission notice shall be included

in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS

OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF

MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY

CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,

TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE

SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

//solhint-disable max-line-length

//solhint-disable no-inline-assembly



contract CloneFactory {

    function createClone(address target) internal returns (address result) {

        bytes20 targetBytes = bytes20(target);

        assembly {

            let clone := mload(0x40)

            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)

            mstore(add(clone, 0x14), targetBytes)

            mstore(

                add(clone, 0x28),

                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000

            )

            result := create(0, clone, 0x37)

        }

    }



    function isClone(address target, address query) internal view returns (bool result) {

        bytes20 targetBytes = bytes20(target);

        assembly {

            let clone := mload(0x40)

            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)

            mstore(add(clone, 0xa), targetBytes)

            mstore(

                add(clone, 0x1e),

                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000

            )



            let other := add(clone, 0x40)

            extcodecopy(query, other, 0, 0x2d)

            result := and(

                eq(mload(clone), mload(other)),

                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))

            )

        }

    }

}



// File: contracts/SwapAndDepositFactory.sol



pragma solidity ^0.5.12;












contract SwapAndDepositFactory is ISwapAndDepositFactory, CloneFactory, Ownable {

    address public libraryAddress;

    address public authAddress;

    address public uniswapAddress;



    event NewSwapContract(address proxyAddress);



    constructor(

        address _libraryAddress,

        address _authAddress,

        address _uniswapAddress

    ) public {

        libraryAddress = _libraryAddress;

        authAddress = _authAddress;

        uniswapAddress = _uniswapAddress;

    }



    function setAuthAddress(address _authAddress) public onlyOwner {

        authAddress = _authAddress;

    }



    function setUniswapAddress(address _uniswapAddress) public onlyOwner {

        uniswapAddress = _uniswapAddress;

    }



    function setLibraryAddress(address _libraryAddress) public onlyOwner {

        libraryAddress = _libraryAddress;

    }



    function deploy() external returns (address) {

        require(authAddress != address(0), "auth must be set");

        address depositAddress = IAuthorization(authAddress).getDepositAddress();

        require(libraryAddress != address(0), "library must be set");

        require(uniswapAddress != address(0), "uniswap must be set");

        require(depositAddress != address(0), "deposit must be set");

        address proxyAddress = createClone(libraryAddress);

        require(

            ISwapAndDeposit(proxyAddress).init(depositAddress, uniswapAddress),

            "Failed to init"

        );



        emit NewSwapContract(proxyAddress);



        return proxyAddress;

    }



    function isCloned(address target, address query) external view returns (bool result) {

        return isClone(target, query);

    }

}