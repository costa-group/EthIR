pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface AaveInterface {
    function getUserReserveData(address _reserve, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentBorrowBalance,
        uint256 principalBorrowBalance,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint256 liquidityRate,
        uint256 originationFee,
        uint256 variableBorrowIndex,
        uint256 lastUpdateTimestamp,
        bool usageAsCollateralEnabled
    );
    function getUserAccountData(address _user) external view returns (
        uint256 totalLiquidityETH,
        uint256 totalCollateralETH,
        uint256 totalBorrowsETH,
        uint256 totalFeesETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveProviderInterface {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface AavePriceInterface {
    function getAssetPrice(address _asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external view returns(address);
    function getFallbackOracle() external view returns(address);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}

contract AaveHelpers is DSMath {
    /**
     * @dev get Aave Provider Address
    */
    function getAaveProviderAddress() internal pure returns (address) {
        return 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8; //mainnet
    }

    struct AaveTokenData {
        uint tokenPrice;
        uint supplyBalance;
        uint borrowBalance;
        uint borrowFee;
        uint supplyRate;
        uint borrowRate;
    }

    struct AaveUserData {
        uint totalSupplyETH;
        uint totalCollateralETH;
        uint totalBorrowsETH;
        uint totalFeesETH;
        uint availableBorrowsETH;
        uint currentLiquidationThreshold;
        uint healthFactor;
    }

    function getTokenData(AaveInterface aave, address user, address token, uint price)
    internal view returns(AaveTokenData memory tokenData) {
        (
            uint supplyBal,
            uint borrowBal,
            ,
            ,
            uint borrowRate,
            uint supplyRate,
            uint fee,
            ,,
        ) = aave.getUserReserveData(token, user);
        tokenData = AaveTokenData(
            price,
            supplyBal,
            borrowBal,
            fee,
            supplyRate,
            borrowRate
        );
    }

    function getUserData(AaveInterface aave, address user)
    internal view returns (AaveUserData memory userData) {
        (
            uint totalSupplyETH,
            uint totalCollateralETH,
            uint totalBorrowsETH,
            uint totalFeesETH,
            uint availableBorrowsETH,
            uint currentLiquidationThreshold,
            ,
            uint healthFactor
        ) = aave.getUserAccountData(user);

        userData = AaveUserData(
            totalSupplyETH,
            totalCollateralETH,
            totalBorrowsETH,
            totalFeesETH,
            availableBorrowsETH,
            currentLiquidationThreshold,
            healthFactor
        );
    }
}

contract Resolver is AaveHelpers {
    function getPosition(address user, address[] memory tokens) public view returns(AaveTokenData[] memory, AaveUserData memory) {
        AaveProviderInterface AaveProvider = AaveProviderInterface(getAaveProviderAddress());
        AaveInterface aave = AaveInterface(AaveProvider.getLendingPool());
        AaveTokenData[] memory tokensData = new AaveTokenData[](tokens.length);
        uint[] memory tokenPrices = AavePriceInterface(AaveProvider.getPriceOracle()).getAssetsPrices(tokens);
        for (uint i = 0; i < tokens.length; i++) {
            tokensData[i] = getTokenData(aave, user, tokens[i], tokenPrices[i]);
        }
        return (tokensData, getUserData(aave, user));
    }
}

contract InstaAaveResolver is Resolver {
    string public constant name = "Aave-Resolver-v1";
}