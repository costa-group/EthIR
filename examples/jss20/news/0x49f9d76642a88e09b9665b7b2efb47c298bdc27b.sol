pragma solidity ^0.5.16;

contract KyberNetworkProxy {
    function getExpectedRate(address src, address dest, uint srcQty) public view returns (uint expectedRate, uint slippageRate);
}

contract UniswapExchange {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
}

contract PriceChecker {
    KyberNetworkProxy constant private kyberNetworkProxy = KyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    address constant private ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function check(
        address token,
        address uniswap_addr,
        uint256 amount_eth,
        uint256 amount_token
    )
    public
    view
    returns (
        uint256 kyber_buy,
        uint256 kyber_sell,
        uint256 uniswap_buy,
        uint256 uniswap_sell,
        int256 buy_diff,
        int256 sell_diff
    )
    {
        UniswapExchange uniswap_exchange = UniswapExchange(uniswap_addr);
        uint256 expectedRate;
        uint256 slippageRate;
        (expectedRate, slippageRate) = kyberNetworkProxy.getExpectedRate(ETH, token, amount_eth);
        kyber_buy = expectedRate * amount_eth / 10 ** 18;
        (expectedRate, slippageRate) = kyberNetworkProxy.getExpectedRate(token, ETH, amount_token);
        kyber_sell = expectedRate * amount_token / 10 ** 18;
        uniswap_buy = uniswap_exchange.getEthToTokenInputPrice(amount_eth);
        uniswap_sell = uniswap_exchange.getTokenToEthInputPrice(amount_token);
        buy_diff = int(uniswap_buy) - int(kyber_buy);
        sell_diff = int(uniswap_sell) - int(kyber_sell);
    }
}