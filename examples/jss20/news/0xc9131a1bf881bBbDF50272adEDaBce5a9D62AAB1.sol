// Copyright (C) 2020 Zerion Inc. <https://zerion.io>

//

// This program is free software: you can redistribute it and/or modify

// it under the terms of the GNU General Public License as published by

// the Free Software Foundation, either version 3 of the License, or

// (at your option) any later version.

//

// This program is distributed in the hope that it will be useful,

// but WITHOUT ANY WARRANTY; without even the implied warranty of

// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the

// GNU General Public License for more details.

//

// You should have received a copy of the GNU General Public License

// along with this program. If not, see <https://www.gnu.org/licenses/>.



pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;





interface ERC20 {

    function balanceOf(address) external view returns (uint256);

}





/**

 * @title Protocol adapter interface.

 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

abstract contract ProtocolAdapter {



    /**

     * @dev MUST return "Asset" or "Debt".

     * SHOULD be implemented by the public constant state variable.

     */

    function adapterType() external pure virtual returns (string memory);



    /**

     * @dev MUST return token type (default is "ERC20").

     * SHOULD be implemented by the public constant state variable.

     */

    function tokenType() external pure virtual returns (string memory);



    /**

     * @dev MUST return amount of the given token locked on the protocol by the given account.

     */

    function getBalance(address token, address account) public view virtual returns (uint256);

}





/**

 * @title Adapter for iearn.finance protocol.

 * @dev Implementation of ProtocolAdapter interface.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

contract IearnAdapter is ProtocolAdapter {



    string public constant override adapterType = "Asset";



    string public constant override tokenType = "YToken";



    /**

     * @return Amount of YTokens held by the given account.

     * @dev Implementation of ProtocolAdapter interface function.

     */

    function getBalance(address token, address account) public view override returns (uint256) {

        return ERC20(token).balanceOf(account);

    }

}