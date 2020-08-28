pragma solidity 0.5.14;


contract ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() public view returns(uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
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

contract UniswapFactory {
    function getExchange(address token) external view returns (address exchange);
}

contract UniswapExchange {
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr)
        external returns (uint256 tokens_bought);
}

contract UniswapProxy is Withdrawable {
    string public name = "Uniswap";
    UniswapFactory uniswap;

    constructor () public {
        /**
         * Mainnnet
         */
        uniswap = UniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    }

    function getSwapQuantity(address src, address dst, uint256 srcQty) public view returns(uint256) {
        UniswapExchange srcExchange = UniswapExchange(uniswap.getExchange(src));
        UniswapExchange dstExchange = UniswapExchange(uniswap.getExchange(dst));
        ERC20 dstToken = ERC20(dst);
        uint256 eth;
        uint256 ret;

        eth = srcExchange.getTokenToEthInputPrice(srcQty);
        ret = dstExchange.getEthToTokenInputPrice(eth);
        return ret * 10 ** (18-dstToken.decimals());
    }

    function getSwapRate(address src, address dst, uint256 srcQty) public view returns(uint256) {
        uint256 dstQty = getSwapQuantity(src,dst,srcQty);
        ERC20 srcToken = ERC20(src);
        uint256 ret;

        ret = ( (10**18) * dstQty ) / ( srcQty * 10 ** (18-srcToken.decimals()) );
        return ret;
    }

    function executeSwap(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool) {
        UniswapExchange exchange;
        uint256 dstQty;
        uint256 bought;
        ERC20 token = ERC20(srcToken);

        exchange = UniswapExchange(uniswap.getExchange(srcToken));

        require(address(exchange) != address(0), "Unable to found a valid exchange in Uniswap");

        require(token.transferFrom(msg.sender, address(this), srcQty), "Unable to transferFrom()");

        // Set the spender's token allowance to tokenQty
        require(token.approve(address(exchange), srcQty), "Unable to appove()");

        token = ERC20(dstToken);
        dstQty = getSwapQuantity(srcToken,dstToken,srcQty) / (10**(18-token.decimals()));

        bought = exchange.tokenToTokenSwapInput(
            srcQty,
            dstQty,
            1,
            block.timestamp + 300,
            dstToken
        );

        require(bought != 0, "Unable to exchange tokens");

        require(token.transfer(dstAddress,bought), "Unable to transfer bought tokens");

        return true;
    }
}