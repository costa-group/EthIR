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



pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;





interface ERC20 {

    function name() external view returns (string memory);

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

    *     address token; // Address of token contract

    *     string tokenType;     // Token type ("ERC20" by default)

    *     uint256 rate;        // Price per share (1e18)

    * }

    */

    function getComponents(address token) external view returns (Component[] memory);

}





/**

 * @dev IdleToken contract interface.

 * Only the functions required for IdleTokenAdapter contract are added.

 * The IdleToken contracts are available here

 * https://github.com/bugduino/idle-contracts/blob/master/contracts/IdleToken.sol

 * @author William Bergamo <william@idle.finance>

 */

interface IdleToken {

    function token() external view returns (address);

    function tokenPrice() external view returns (uint256);

}





/**

 * @title Token adapter for IdleTokens.

 * @dev Implementation of TokenAdapter interface.

 */

contract IdleTokenAdapter is TokenAdapter {



    /**

     * @return TokenMetadata struct with ERC20-style token info.

     * @dev Implementation of TokenAdapter interface function.

     */

    function getMetadata(address token) external view override returns (TokenMetadata memory) {

        return TokenMetadata({

            token: token,

            name: ERC20(token).name(),

            symbol: ERC20(token).symbol(),

            decimals: ERC20(token).decimals()

        });

    }



    /**

     * @return Array of Component structs with underlying tokens rates for the given asset.

     * @dev Implementation of TokenAdapter interface function.

     */

    function getComponents(address token) external view override returns (Component[] memory) {

        Component[] memory underlyingTokens = new Component[](1);



        underlyingTokens[0] = Component({

            token: IdleToken(token).token(),

            tokenType: "ERC20",

            rate: IdleToken(token).tokenPrice()

        });



        return underlyingTokens;

    }

}