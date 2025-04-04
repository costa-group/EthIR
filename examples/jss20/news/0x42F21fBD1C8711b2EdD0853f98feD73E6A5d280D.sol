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

 * @dev Staking contract interface.

 * Only the functions required for ZrxAdapter contract are added.

 * The Staking contract is available here

 * github.com/0xProject/0x-monorepo/blob/development/contracts/staking/contracts/src/Staking.sol.

 */

interface Staking {

    function getTotalStake(address) external view returns (uint256);

}





/**

 * @title Adapter for 0x protocol.

 * @dev Implementation of ProtocolAdapter interface.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

contract ZrxAdapter is ProtocolAdapter {



    string public constant override adapterType = "Asset";



    string public constant override tokenType = "ERC20";



    address internal constant STAKING = 0xa26e80e7Dea86279c6d778D702Cc413E6CFfA777;



    /**

     * @return Amount of ZRX locked on the protocol by the given account.

     * @dev Implementation of ProtocolAdapter interface function.

     */

    function getBalance(address, address account) public view override returns (uint256) {

        return Staking(STAKING).getTotalStake(account);

    }

}