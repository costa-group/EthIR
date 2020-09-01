pragma solidity ^0.6.0;

interface OasisInterface {
    function getMinSell(TokenInterface pay_gem) external view returns (uint);
    function getBuyAmount(address dest, address src, uint srcAmt) external view returns(uint);
	function getPayAmount(address src, address dest, uint destAmt) external view returns (uint);
	function sellAllAmount(
        address src,
        uint srcAmt,
        address dest,
        uint minDest
    ) external returns (uint destAmt);
	function buyAllAmount(
        address dest,
        uint destAmt,
        address src,
        uint maxSrc
    ) external returns (uint srcAmt);

    function offer(
        uint pay_amt,
        TokenInterface pay_gem,
        uint buy_amt,
        TokenInterface buy_gem,
        uint pos
    ) external returns (uint);
    function cancel(uint id) external returns (bool success);
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface AccountInterface {
    function isAuth(address _user) external view returns (bool);
}


contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }
}


contract OasisHelpers is Helpers {
    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    }

    /**
     * @dev Return Oasis Address
     */
    function getOasisAddr() internal pure returns (address) {
        return 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
        _sell = sell == getAddressETH() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    }

    function convertEthToWeth(TokenInterface token, uint amount) internal {
        if(address(token) == getAddressWETH()) token.deposit.value(amount)();
    }

    function convertWethToEth(TokenInterface token, uint amount) internal {
       if(address(token) == getAddressWETH()) {
            token.approve(getAddressWETH(), amount);
            token.withdraw(amount);
        }
    }
}


contract OasisResolver is OasisHelpers {
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function buy(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint sellAmt,
        uint slippage,
        uint getId,
        uint setId
    ) external payable {
        uint _buyAmt = buyAmt;

        uint _sellAmt = _buyAmt == buyAmt ? sellAmt : wmul(sellAmt, wdiv(_buyAmt, buyAmt));

        OasisInterface oasisContract = OasisInterface(getOasisAddr());

        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        require(oasisContract.getMinSell(_sellAddr) <= _sellAmt, "less-than-min-pay-amt");

        uint _slippageAmt = wmul(_sellAmt, add(WAD, slippage));
        uint _expectedAmt = oasisContract.getPayAmount(address(_sellAddr), address(_buyAddr), _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, _expectedAmt);
        _sellAddr.approve(getOasisAddr(), _expectedAmt);

        _sellAmt = oasisContract.buyAllAmount(
            address(_buyAddr),
            buyAmt,
            address(_sellAddr),
            _slippageAmt
        );

        convertWethToEth(_buyAddr, buyAmt);

        emit LogBuy(address(_buyAddr), address(_sellAddr), buyAmt, sellAmt, getId, setId);
    }

    function sell(
        address buyAddr,
        address sellAddr,
        uint buyAmt,
        uint sellAmt,
        uint slippage,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = sellAmt;

        uint _buyAmt = _sellAmt == sellAmt ? buyAmt : wmul(buyAmt, wdiv(_sellAmt, sellAmt));

        OasisInterface oasisContract = OasisInterface(getOasisAddr());

        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        require(oasisContract.getMinSell(_sellAddr) <= _sellAmt, "less-than-min-pay-amt");

        uint _slippageAmt = wdiv(_buyAmt, add(WAD, slippage));
        uint _expectedAmt = oasisContract.getBuyAmount(address(_buyAddr), address(_sellAddr), sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        convertEthToWeth(_sellAddr, sellAmt);
        _sellAddr.approve(getOasisAddr(), _sellAmt);

        _buyAmt = oasisContract.sellAllAmount(
            address(_sellAddr),
            _sellAmt,
            address(_buyAddr),
           _slippageAmt
        );

        convertWethToEth(_buyAddr, _buyAmt);

        emit LogSell(address(_buyAddr), address(_sellAddr), buyAmt, sellAmt, getId, setId);
    }
}


contract ConnectOasis is OasisResolver {
    string public name = "Oasis-v1";
}