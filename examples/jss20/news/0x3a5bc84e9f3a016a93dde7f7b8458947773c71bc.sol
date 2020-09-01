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
    function getExpectedRate(address src, address dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);
}

contract KyberProxy {
    Kyber proxy;

    constructor () public {
        proxy = Kyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    }

    function getRate(address src, address dst, uint256 srcQty) public view returns(uint256) {
        uint256 rate;

        (rate,) = proxy.getExpectedRate(src,dst,srcQty);
        return rate;
    }

    function executeSwap(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool) {
        bytes memory ret;
        bytes memory data;
        address sendTo;
        uint256 rate;
        bool success;
        ERC20 token = ERC20(srcToken);

        (rate,) = proxy.getExpectedRate(srcToken,dstToken,srcQty);

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(token.approve(address(proxy), 0));

        // Set the spender's token allowance to tokenQty
        require(token.approve(address(proxy), srcQty));

        if (dstAddress == address(0))
            sendTo = msg.sender;
        else
            sendTo = dstAddress;

        data = abi.encodeWithSelector(
            bytes4(keccak256("trade(address,uint256,address,address,uint256,uint256,address)")),
            srcToken,
            srcQty,
            dstToken,
            sendTo,
            uint(-1),
            rate,
            0
        );
        (success, ret) = address(proxy).delegatecall(data);
        require(success);
        return true;
    }
}