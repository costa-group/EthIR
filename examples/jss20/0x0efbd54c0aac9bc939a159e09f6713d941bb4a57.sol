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

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
}


// ERC20-style token metadata
// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE address is used for ETH
struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;    // Address of token contract
    string tokenType; // Token type ("ERC20" by default)
    uint256 rate;     // Price per share (1e18)
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
 * @dev SmartToken contract interface.
 * Only the functions required for BancorTokenAdapter contract are added.
 * The SmartToken contract is available here
 * github.com/bancorprotocol/contracts/blob/master/solidity/contracts/token/SmartToken.sol.
 */
interface SmartToken {
    function owner() external view returns (address);
    function totalSupply() external view returns (uint256);
}


/**
 * @dev BancorConverter contract interface.
 * Only the functions required for BancorTokenAdapter contract are added.
 * The BancorConverter contract is available here
 * github.com/bancorprotocol/contracts/blob/master/solidity/contracts/converter/BancorConverter.sol.
 */
interface BancorConverter {
    function connectorTokenCount() external view returns (uint256);
    function connectorTokens(uint256) external view returns (address);
}


/**
 * @dev ContractRegistry contract interface.
 * Only the functions required for BancorTokenAdapter contract are added.
 * The ContractRegistry contract is available here
 * github.com/bancorprotocol/contracts/blob/master/solidity/contracts/utility/ContractRegistry.sol.
 */
interface ContractRegistry {
    function addressOf(bytes32) external view returns (address);
}


/**
 * @dev BancorFormula contract interface.
 * Only the functions required for BancorTokenAdapter contract are added.
 * The BancorFormula contract is available here
 * github.com/bancorprotocol/contracts/blob/master/solidity/contracts/converter/BancorFormula.sol.
 */
interface BancorFormula {
    function calculateLiquidateReturn(
        uint256,
        uint256,
        uint32,
        uint256
    )
        external
        view
        returns (uint256);
}


/**
 * @title Token adapter for SmartTokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract BancorTokenAdapter is TokenAdapter {

    address internal constant REGISTRY = 0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4;

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
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address formula = ContractRegistry(REGISTRY).addressOf("BancorFormula");
        uint256 totalSupply = SmartToken(token).totalSupply();
        address converter = SmartToken(token).owner();
        uint256 length = BancorConverter(converter).connectorTokenCount();

        Component[] memory underlyingTokens = new Component[](length);

        address underlyingToken;
        for (uint256 i = 0; i < length; i++) {
            underlyingToken = BancorConverter(converter).connectorTokens(i);

            underlyingTokens[i] = Component({
                token: underlyingToken,
                tokenType: "ERC20",
                rate: BancorFormula(formula).calculateLiquidateReturn(
                    totalSupply,
                    ERC20(underlyingToken).balanceOf(converter),
                    uint32(1000000),
                    uint256(1e18)
                )
            });
        }

        return underlyingTokens;
    }
}