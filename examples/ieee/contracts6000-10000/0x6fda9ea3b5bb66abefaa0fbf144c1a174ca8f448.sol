pragma solidity 0.5.14;


contract ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() public view returns(uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
}

contract CERC20 is ERC20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateStored() public view returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function underlying() external view returns (address);
}

contract DexProxyInterface {
    function name() public view returns(string memory);
    function getSwapQuantity(address src, address dst, uint256 srcQty) public view returns(uint256);
    function getSwapRate(address src, address dst, uint256 srcQty) public view returns(uint256);
    function executeSwap(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool);
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

contract cTokenKyberBridge is AdminRole {
    string public name = "cTokenKyberBridge";
    address public proxy;
    mapping(address => bool) cTokens;

    constructor() public {
        cTokens[0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E] = true;
        cTokens[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = true;
        cTokens[0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5] = true;
        cTokens[0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1] = true;
        cTokens[0xF5DCe57282A584D2746FaF1593d3121Fcac444dC] = true;
        cTokens[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = true;
        cTokens[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = true;
        cTokens[0xC11b1268C1A384e55C48c2391d8d480264A3A7F4] = true;
        cTokens[0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407] = true;
        
        proxy = 0x6c51AaBD10b939C1D607694571Fd6d6CF4DCd1F5;
    }

    function addcToken(address _cToken) external onlyAdmin {
        cTokens[_cToken] = true;
    }

    function delcToken(address _cToken) external onlyAdmin {
        cTokens[_cToken] = false; 
    }

    function setProxy(address _proxy) external onlyAdmin {
        proxy = _proxy;
    }

    function isCToken(address _token) internal view returns(bool) {
        return cTokens[_token];
    }

    function getSwapQuantity(address src, address dst, uint256 srcQty) external view returns(uint256) {
        address srcToken;
        address dstToken;
        uint256 srcQuantity;
        uint256 dstDecimals;
        uint256 dstExchangeRate;
        uint256 dstQuantity;

        if (isCToken(src)) {
            // En este punto el souce es un cToken, hay que traer la direccion de su underlying
            // y ademas calcular de acuerdo a su rate la cantidad a pasarle al proxy
            CERC20 cToken = CERC20(src);
            srcToken = cToken.underlying();
            srcQuantity = (srcQty * cToken.exchangeRateStored()) / 10**18; 
        } else {
            srcToken = src;
            srcQuantity = srcQty;
        }

        if (isCToken(dst)) {
            // En este punto el destino es un cToken, hay que traer la direccion de su underlying
            CERC20 cToken = CERC20(dst);
            dstToken = cToken.underlying();
            dstDecimals = cToken.decimals();
            dstExchangeRate = cToken.exchangeRateStored();
        } else {
            dstToken = dst;
            dstDecimals = ERC20(dst).decimals();
            dstExchangeRate = 1;
        }

        if (srcToken == dstToken) {
            // Un token es el underlying del otro 
            if (isCToken(dst)) {
                return (srcQuantity * 10**(36-dstDecimals)) / dstExchangeRate;
            } else {
                return (srcQuantity * 10**(18-dstDecimals));
            }
        }

        dstQuantity = DexProxyInterface(proxy).getSwapQuantity(srcToken, dstToken, srcQuantity);

        if (isCToken(dst)) {
            dstQuantity = (dstQuantity * 10**(36-dstDecimals)) / dstExchangeRate;
        }
        return dstQuantity;
    }
}