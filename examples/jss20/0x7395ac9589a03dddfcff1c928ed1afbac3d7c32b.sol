//oracle registry test

interface PriceOracleInterface{
      function getPriceFromOracle (string fromParam, string toParam, string  side, uint256 amount) returns (uint256);
 }
  
    // ERC20 Token Smart Contract
    contract oracleRegistry {
        
      mapping (string=>address) oracleMapping;
      mapping (string=>address) oracleOwners;
      address owner; 
      modifier onlyOwner() {
            if (msg.sender != owner) {
                throw;
            }
             _;
        }
        
      constructor() public payable {
            owner = msg.sender; 
           
        }
        
     
         
     function getPriceFromOracle(string selectedOracle, string fromParam, string toParam, string  side, uint256 amount) public constant returns (uint256){  
          
          address oracleAddress = getOracleAddress(selectedOracle);
          require(oracleAddress != 0x0, "The requested provider is not registered in this oracle registry");
          PriceOracleInterface p = PriceOracleInterface(oracleAddress);
          return p.getPriceFromOracle(fromParam, toParam, side, amount);
          
      }
      
     function withdrawBalance() onlyOwner returns(bool) {
        uint amount = this.balance;
        msg.sender.transfer(amount);
        return true;

    }
    
    
    function registerOracle(string name, address requestedAddress ) payable returns (bool){
        require(msg.value >= 50000000000000000, "Please send .05 ETH to register an oracle. This is to prevent registration spam");
        if(oracleMapping[name] != 0x0 && oracleOwners[name] != msg.sender){
            //you cant update this because you did not register this name
            throw;
            
        }
        
       oracleMapping[name] = requestedAddress;
       oracleOwners[name] = msg.sender;
       return true;
        
    }
    
    function getOracleAddress(string nameReference) constant returns (address){
        
        return oracleMapping[nameReference];
    }
}