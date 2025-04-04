pragma solidity >=0.4.26;

pragma experimental ABIEncoderV2;

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes  hint) external payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns (uint);
}

contract IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}
interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function totalSupply() external view returns (uint);
  function approve(address guy, uint wad) external returns (bool);
  function transfer(address dst, uint wad) external returns (bool);
  function transferFrom(address src, address dst, uint wad) external returns (bool);
  function () external payable;
}

interface IUniswapFactory {
    function createExchange(address token) external returns (address exchange);
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    function initializeFactory(address template) external;
}






interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract IERC20Token {
    function name() public view returns (string memory) {this;}
    function symbol() public view returns (string memory) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

interface OrFeedInterface {
  function getExchangeRate ( string fromSymbol, string toSymbol, string  venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string  symbol ) external view returns ( address );
  function getSynthBytes32 ( string  symbol ) external view returns ( bytes32 );
  function getForexAddress ( string  symbol ) external view returns ( address );
}


interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

interface IBancorNetwork {
    function getReturnByPath(address[]  _path, uint256 _amount) external view returns (uint256, uint256);
    function convert2(address[] _path, uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvert2(
        address[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);
}
interface IBancorNetworkPathFinder {
    function generatePath(address _sourceToken, address _targetToken) external view returns (address[]);
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal view returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal view returns(uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal view returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal view returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}






contract ArbContract{
OrFeedInterface orfeed = OrFeedInterface(0x8316b082621cfedab95bf4a44a1d4b64a6ffc336);
   address owner;
   bytes  PERM_HINT = "PERM";
   mapping (uint256=>uint256) results;
    mapping(uint256=>uint8[3]) public orders;
    
    
    
    address uniswapFactoryAddress = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    IUniswapFactory uniswapFactory = IUniswapFactory(uniswapFactoryAddress);
    
      modifier onlyOwner() {
            if (msg.sender != owner) {
                throw;
            }
             _;
        }
         address kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
     IKyberNetworkProxy kyberProxy = IKyberNetworkProxy(kyberProxyAddress);
      constructor() public payable {
            owner = msg.sender; 
 
        
        
        
            
          
        }
        
   function kill() onlyOwner{
       selfdestruct(owner);
   }
    
    function() payable{
        
    }
    
    function getTokensBack(address tokenAddress){
        ERC20 token = ERC20(tokenAddress);
        token.transfer(owner, token.balanceOf(this));
    }
    













 
    

    
   
    function bancorPrice(address token1, address token2, uint256 amount) constant returns (uint256){
        // updated with the newest address of the BancorNetwork contract deployed under the circumstances of old versions of `getReturnByPath`
        IContractRegistry contractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        
        //
  // IBancorNetwork bancorNetwork = IBancorNetwork(contractRegistry.addressOf(0x42616e636f724e6574776f726b));
    IBancorNetwork bancorNetwork = IBancorNetwork(0x3Ab6564d5c214bc416EE8421E05219960504eeAD);
   //
       // IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(contractRegistry.addressOf(0x42616e636f724e6574776f726b5061746846696e646572));
         IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
       // address token1ToBancor = token1;
        //address token2ToBancor = token2;
        // in case of Ether (or Weth), we need to provide the address of the EtherToken to the BancorNetwork
        
        if (token1 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token1 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            // the EtherToken addresss for BancorNetwork
            token1 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        if (token2 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token2 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            token2 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        
        address[] memory addressPath;
      
        
            addressPath = bancorNetworkPathFinder.generatePath(token2, token1);
/*
        IERC20Token[] memory tokenPath = new IERC20Token[](addressPath.length);
        
        for(uint256 i = 0; i < addressPath.length; i++) {
            tokenPath[i] = IERC20Token(addressPath[i]);
        }
       */
       (uint256 price, ) = bancorNetwork.getReturnByPath(addressPath, amount);
       return price;
    }
   
      function bancorConvert(address token1, address token2, uint256 amount)  returns (uint256){
        // updated with the newest address of the BancorNetwork contract deployed under the circumstances of old versions of `getReturnByPath`
        IContractRegistry contractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        
        //
  // IBancorNetwork bancorNetwork = IBancorNetwork(contractRegistry.addressOf(0x42616e636f724e6574776f726b));
    IBancorNetwork bancorNetwork = IBancorNetwork(0x3Ab6564d5c214bc416EE8421E05219960504eeAD);
   //
       // IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(contractRegistry.addressOf(0x42616e636f724e6574776f726b5061746846696e646572));
         IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
       // address token1ToBancor = token1;
        //address token2ToBancor = token2;
        // in case of Ether (or Weth), we need to provide the address of the EtherToken to the BancorNetwork
        
        if (token1 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token1 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            // the EtherToken addresss for BancorNetwork
            token1 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        if (token2 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token2 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            token2 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        
        address[] memory addressPath;
      
        
            addressPath = bancorNetworkPathFinder.generatePath(token2, token1);
/*
        IERC20Token[] memory tokenPath = new IERC20Token[](addressPath.length);
        
        for(uint256 i = 0; i < addressPath.length; i++) {
            tokenPath[i] = IERC20Token(addressPath[i]);
        }
       */
       
       uint256 price = bancorNetwork.convert2.value(amount)(addressPath, amount,1 ,0x0,0);
       return price;
    }
    
    
    
 
    function arbIt2(uint[] eOrder, string[] memory tOrder1, uint256 amount, bool back) {
        uint256 final1 = eOrder.length -1;
        uint lastSell = amount;
        address [] tOrder;
       
        
        for(uint j=0; j<tOrder1.length; j++){
            tOrder[j] =orfeed.getTokenAddress(tOrder1[j]);
        }
        for(uint i =0; i<eOrder.length; i++){
            uint256 next = i+1;
            if(i < final1){
               if(eOrder[i] ==1){
                   //kyber buy
                   lastSell = swapTokenOnKyber(tOrder[i], lastSell, tOrder[next]);
               }
               else if(eOrder[i] ==2){
                   lastSell = swapTokenOnUniswap(tOrder[i], lastSell, tOrder[next]);
               }
               else{
                 lastSell = bancorConvert2(tOrder[next], tOrder[i], lastSell);
               }
            }
            else{
                 //sell
                 
                 if(back == true){
               if(eOrder[i] ==1){
                   //kyber buy
                   lastSell = swapTokenOnKyber(tOrder[i], lastSell, tOrder[0]);
               }
               else if(eOrder[i] ==2){
                  lastSell = swapTokenOnUniswap(tOrder[i], lastSell, tOrder[0]);
               }
               else{
                 lastSell = bancorConvert2(tOrder[0], tOrder[i], lastSell);
               }
            }
            }
        }
    }
    
    
      function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] memory tokens,  uint256 amount, string[] exchanges) payable returns(bool){
         arb1(fundsReturnToAddress, liquidityProviderContractAddress, tokens, amount, exchanges);
         return true;
       }
    
     function arb1(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] memory tokens,  uint256 amount, string[] exchanges)  returns(bool){
         
        // uint[] storage eOrder1;
         uint[] memory eOrder1 = new uint[](exchanges.length);
         for(uint i =0; i<exchanges.length; i++){
           if(equal(exchanges[i], "BANCOR")){
               eOrder1[i] =3;
               
           }
          else if(equal(exchanges[i], "KYBER")){
               eOrder1[i] =1;
               
           }
           else{
               eOrder1[i] =2;
           }
           
           
         }
         
         uint lastVar = tokens.length-1;
         bool back = false;


     arbIt3(eOrder1, tokens, amount, back);
      
         uint tLast = tokens.length-1;
         address lastToken = orfeed.getTokenAddress(tokens[tLast]);
         ERC20 lToken = ERC20(lastToken);
         uint256 balanceHere = lToken.balanceOf(this);
         lToken.transfer(fundsReturnToAddress, balanceHere);
    
         return true;

         
         
         
     }
     
     
     function arbIt3(uint[] eOrder, string[] memory tOrder1, uint256 amount, bool back) {
         arbIt2(eOrder, tOrder1, amount, back);
         
     }
 
   
   
         function bancorConvert2(address token1, address token2, uint256 amount)  returns (uint256){
        // updated with the newest address of the BancorNetwork contract deployed under the circumstances of old versions of `getReturnByPath`
        IContractRegistry contractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        
        //
  // IBancorNetwork bancorNetwork = IBancorNetwork(contractRegistry.addressOf(0x42616e636f724e6574776f726b));
    IBancorNetwork bancorNetwork = IBancorNetwork(0x3Ab6564d5c214bc416EE8421E05219960504eeAD);
   //
       // IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(contractRegistry.addressOf(0x42616e636f724e6574776f726b5061746846696e646572));
         IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
       // address token1ToBancor = token1;
        //address token2ToBancor = token2;
        // in case of Ether (or Weth), we need to provide the address of the EtherToken to the BancorNetwork
        
        if (token1 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token1 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            // the EtherToken addresss for BancorNetwork
            token1 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        if (token2 == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE || token2 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2){
            token2 = 0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315;
        }
        
        address[] memory addressPath;
      
        
            addressPath = bancorNetworkPathFinder.generatePath(token2, token1);
/*
        IERC20Token[] memory tokenPath = new IERC20Token[](addressPath.length);
        
        for(uint256 i = 0; i < addressPath.length; i++) {
            tokenPath[i] = IERC20Token(addressPath[i]);
        }
       */
       ERC20 token = ERC20(token1);
       ERC20 tokenT = ERC20(token2);
       
       uint startAmount =token.balanceOf(this);
       token.approve(0x3Ab6564d5c214bc416EE8421E05219960504eeAD, 8000000000000000000000000000000);
       tokenT.approve(0x3Ab6564d5c214bc416EE8421E05219960504eeAD, 8000000000000000000000000000000);
       //"0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359",  10000000000
       uint256 price = bancorNetwork.claimAndConvert2(addressPath, amount,1 ,0x0,0);
        return token.balanceOf(this) - startAmount;
    }
    
     function swapTokenOnKyber(address sellToken1, uint sellTokenAmount, address  buyToken1)  returns (uint) {
    // Approve tokens so network can take them during the swap
    
     ERC20 sellToken = ERC20(sellToken1);
    ERC20 buyToken = ERC20(buyToken1);
    uint startAmount =buyToken.balanceOf(this);
      //uint256 minRate = 0;
      //(, minRate) = kyberProxy.getExpectedRate(buyToken, sellToken, sellTokenAmount);
      sellToken.approve(address(kyberProxy), sellTokenAmount);

      uint buyTokenAmount = kyberProxy.tradeWithHint(sellToken, sellTokenAmount, buyToken, address(this), 8000000000000000000000000000000000000000000000000000000000000000, 0, 0x0000000000000000000000000000000000000004, PERM_HINT);
      return buyToken.balanceOf(this) - startAmount;
  }
  
   
   function swapTokenOnUniswap(address sellToken1, uint sellTokenAmount, address buyToken1)  returns (uint) {
    ERC20 sellToken = ERC20(sellToken1);
    ERC20 buyToken = ERC20(buyToken1);
   uint startAmount =buyToken.balanceOf(this);
    uint256 minTokensBought = 1;
    uint256 minEtherBought = 1;
    address exchangeAddress = uniswapFactory.getExchange(address(sellToken));
    IUniswapExchange exchange = IUniswapExchange(exchangeAddress);
    sellToken.approve(address(exchange), sellTokenAmount);
    uint256 buyTokenAmount = exchange.tokenToTokenSwapInput(sellTokenAmount, minTokensBought, minEtherBought, block.timestamp, address(buyToken));
    return buyToken.balanceOf(this) - startAmount;
  }
    
 
  function compare(string _a, string _b) returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    
    function equal(string _a, string _b) returns (bool) {
        return compare(_a, _b) == 0;
    }
    
    function indexOf(string _haystack, string _needle) returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
            return -1;
        else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;                                  
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
                    {
                        subindex++;
                    }   
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }   
    }

    

    
}