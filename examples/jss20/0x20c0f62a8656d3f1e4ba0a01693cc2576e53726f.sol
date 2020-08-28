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

contract AdminRole {

    mapping (address => bool) adminGroup;
    address payable owner;

    constructor () public {
        adminGroup[msg.sender] = true;
        owner = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(
            isAdmin(msg.sender),
            "The caller is not Admin"
        );
        _;
    }

    modifier onlyOwner {
        require(
            owner == msg.sender,
            "The caller is not Owner"
        );
        _;
    }

    function addAdmin(address addr) external onlyAdmin {
        adminGroup[addr] = true;
    }
    function delAdmin(address addr) external onlyAdmin {
        adminGroup[addr] = false;
    }

    function isAdmin(address addr) public view returns(bool) {
        return adminGroup[addr];
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }
}

contract Withdrawable is AdminRole {
    /*
     * External Function to withdraw founds -> Gas or Tokens
     */
    function withdrawTo (address payable dst, uint founds, address token) external onlyAdmin {
        if (token == address(0))
            require (address(this).balance >= founds);
        else {
            ERC20 erc20 = ERC20(token);
            require (erc20.balanceOf(address(this)) >= founds);
        }
        sendFounds(dst,founds, token);
    }

    /*
     * Function to send founds -> Gas or Tokens
     */
    function sendFounds(address payable dst, uint amount, address token) internal returns(bool) {
        ERC20 erc20;
        if (token == address(0))
            require(address(dst).send(amount), "Impossible send founds");
        else {
            erc20 = ERC20(token);
            require(erc20.transfer(dst, amount), "Impossible send founds");
        }
    }
}

contract KyberProxy is Withdrawable {
    string public name = "Kyber";
    Kyber proxy;

    constructor () public {
        /**
         * Mainnnet
         */
        proxy = Kyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    }


    function getSwapQuantity(address src, address dst, uint256 srcQty) public view returns(uint256) {
        uint256 rate = getSwapRate(src,dst,srcQty);
        ERC20 srcToken = ERC20(src);
        uint256 ret;

        ret = (srcQty * (10**(18-srcToken.decimals())) * rate) / (10 ** 18);
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
            0x8000000000000000000000000000000000000000000000000000000000000000,
            rate,
            address(0)
        );

        require(bought != 0, "Unable to exchange tokens");

        return true;
    }
}