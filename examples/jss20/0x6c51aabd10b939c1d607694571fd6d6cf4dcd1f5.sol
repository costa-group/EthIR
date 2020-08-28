pragma solidity 0.5.14;


contract ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() public view returns(uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}


contract Kyber {
    function getExpectedRate(address src, address dest, uint srcQty)
        public view returns (uint expectedRate, uint slippageRate);

    function trade(address src, uint srcAmount, address dst, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId)
        public payable returns(uint);
}


contract KyberProxy {
    Kyber proxy;

    constructor () public {
        proxy = Kyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    }


    function getSwapQuantity(address src, address dst, uint256 srcQty) public view returns(uint256) {
        uint256 rate = getSwapRate(src,dst,srcQty);
        ERC20 srcToken = ERC20(src);
        uint256 ret;

        ret = (srcQty * (10 **(18-srcToken.decimals())) * rate) / (10 ** 18); 
        return ret;
    }

    function getSwapRate(address src, address dst, uint256 srcQty) public view returns(uint256) {
        uint256 rate;

        (rate,) = proxy.getExpectedRate(src,dst,srcQty);
        return rate;
    }

    function executeSwap(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool) {
        uint256 rate;
        uint256 bought;
        ERC20 token = ERC20(srcToken);

        rate = getSwapRate(srcToken,dstToken,srcQty);

        require(token.transferFrom(msg.sender, address(this), srcQty), "Unable to transferFrom()");

        // Set the spender's token allowance to tokenQty
        require(token.approve(address(proxy), srcQty), "Unable to appove()");

        bought = proxy.trade(
            srcToken,
            srcQty,
            dstToken,
            dstAddress,
            2 * (rate * srcQty) / (10 ** 18),
            rate,
            address(0)
        );

        require(bought != 0, "Unable to exchange tokens");

        return true;
    }
}