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

 * @dev CurveRewards contract interface.

 * Only the functions required for LPCurveSNXAssetAdapter contract are added.

 * The CurveRewards contract is available here

 * github.com/Synthetixio/Unipool/blob/master/contracts/CurveRewards.sol.

 */

interface CurveRewards {

    function earned(address) external view returns (uint256);

}





/**

 * @title Asset adapter for Curve LP rewards.

 * @dev Implementation of ProtocolAdapter interface.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

contract LPCurveSNXAssetAdapter is ProtocolAdapter {



    string public constant override adapterType = "Asset";



    string public constant override tokenType = "ERC20";



    address internal constant LP_REWARD_CURVE = 0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92;



    /**

     * @return Amount of SNX reward available for withdrawal by the given account.

     * @dev Implementation of ProtocolAdapter interface function.

     */

    function getBalance(address, address account) external view override returns (uint256) {

        return CurveRewards(LP_REWARD_CURVE).earned(account);

    }

}