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





/**

 * @title Protocol adapter interface.

 * @dev adapterType(), tokenType(), and getBalance() functions MUST be implemented.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

interface ProtocolAdapter {



    /**

     * @dev MUST return "Asset" or "Debt".

     * SHOULD be implemented by the public constant state variable.

     */

    function adapterType() external pure returns (string memory);



    /**

     * @dev MUST return token type (default is "ERC20").

     * SHOULD be implemented by the public constant state variable.

     */

    function tokenType() external pure returns (string memory);



    /**

     * @dev MUST return amount of the given token locked on the protocol by the given account.

     */

    function getBalance(address token, address account) external view returns (uint256);

}





/**

 * @dev Proxy contract interface.

 * Only the functions required for SynthetixAssetAdapter contract are added.

 * The Proxy contract is available here

 * github.com/Synthetixio/synthetix/blob/master/contracts/Proxy.sol.

 */

interface Proxy {

    function target() external view returns (address);

}





/**

 * @dev Synthetix contract interface.

 * Only the functions required for SynthetixAssetAdapter contract are added.

 * The Synthetix contract is available here

 * github.com/Synthetixio/synthetix/blob/master/contracts/Synthetix.sol.

 */

interface Synthetix {

    function collateral(address) external view returns (uint256);

}





/**

 * @title Asset adapter for Synthetix protocol.

 * @dev Implementation of ProtocolAdapter interface.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

contract SynthetixAssetAdapter is ProtocolAdapter {



    string public constant override adapterType = "Asset";



    string public constant override tokenType = "ERC20";



    /**

     * @return Amount of SNX locked on the protocol by the given account.

     * @dev Implementation of ProtocolAdapter interface function.

     */

    function getBalance(address token, address account) external view override returns (uint256) {

        Synthetix synthetix = Synthetix(Proxy(token).target());



        return synthetix.collateral(account);

    }

}