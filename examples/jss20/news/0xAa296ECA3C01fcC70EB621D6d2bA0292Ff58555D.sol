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

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}





struct TokenMetadata {

    address token;

    string name;

    string symbol;

    uint8 decimals;

}





struct Component {

    address token;

    string tokenType;

    uint256 rate;

}





/**

 * @title Token adapter interface.

 * @dev getMetadata() and getComponents() functions MUST be implemented.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

interface TokenAdapter {



    /**

     * @dev MUST return TokenMetadata struct with ERC20-style token info.

     * struct TokenMetadata {

     *     address token;

     *     string name;

     *     string symbol;

     *     uint8 decimals;

     * }

     */

    function getMetadata(address token) external view returns (TokenMetadata memory);



    /**

    * @dev MUST return array of Component structs with underlying tokens rates for the given token.

    * struct Component {

    *     address token;    // Address of token contract

    *     string tokenType; // Token type ("ERC20" by default)

    *     uint256 rate;     // Price per share (1e18)

    * }

    */

    function getComponents(address token) external view returns (Component[] memory);

}



/**

 * @dev BasePool contract interface.

 * Only the functions required for PoolTogetherTokenAdapter contract are added.

 * The BasePool contract is available here

 * github.com/pooltogether/pooltogether-contracts/blob/master/contracts/BasePool.sol.

 */

interface BasePool {

    function token() external view returns (address);

}





/**

 * @title Token adapter for PoolTogether pools.

 * @dev Implementation of TokenAdapter interface.

 * @author Igor Sobolev <sobolev@zerion.io>

 */

contract PoolTogetherTokenAdapter is TokenAdapter {



    address internal constant SAI_POOL = 0xb7896fce748396EcFC240F5a0d3Cc92ca42D7d84;



    /**

     * @return TokenMetadata struct with ERC20-style token info.

     * @dev Implementation of TokenAdapter interface function.

     */

    function getMetadata(address token) external view override returns (TokenMetadata memory) {

        return TokenMetadata({

            token: token,

            name: getPoolName(token),

            symbol: "PLT",

            decimals: ERC20(BasePool(token).token()).decimals()

        });

    }



    /**

     * @return Array of Component structs with underlying tokens rates for the given asset.

     * @dev Implementation of TokenAdapter interface function.

     */

    function getComponents(address token) external view override returns (Component[] memory) {

        Component[] memory underlyingTokens = new Component[](1);



        underlyingTokens[0] = Component({

            token: BasePool(token).token(),

            tokenType: "ERC20",

            rate: 1e18

        });



        return underlyingTokens;

    }



    function getPoolName(address token) internal view returns (string memory) {

        if (token == SAI_POOL) {

            return "SAI pool";

        } else {

            address underlying = BasePool(token).token();

            return string(abi.encodePacked(ERC20(underlying).symbol(), " pool"));

        }

    }

}