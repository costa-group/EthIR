/*
 Hashed time lock Contract ERC20 Token        
*/
pragma solidity ^0.4.18;

     //here we declare the function that we need for the token swap as an interface 

      contract ERC20 {
      
     function balanceOf(address _who )public view returns (uint256 balance);
      function transfer(address _to, uint256 _value) public;
         
    
    
}

contract HTLC_ERC20_Token {
          
  uint public timeLock = now + 200;     //here we set the time lock (using Unix timestamp)
  address owner = msg.sender;           //owner of the contract                  
  bytes32 public sha256_hashed_secret =0x863BBA74EA78B2B913311420656DEDF7603A07FF65EBF0AEB9F15BF27A698838; //hashed secret

  ERC20 Your_token= ERC20(0x22a39C2DD54b71aC884657bb3e37308ABe2D02E1);  /* here we create an instance 
                                                            of the token using its adress to be able 
                                                            to interact with the contract and call its functions
                                                         */
                                                        

  //here we make sure that only the owner can refund his tokens
  modifier onlyOwner{require(msg.sender == owner); _; }


  //here you claim the tokens
    function claim(string _secret) public returns(bool result) {

       require(sha256_hashed_secret == sha256(_secret)); //secret verification
       require(msg.sender!=owner);                //verify that the claimer isn't the owner                 
       uint256 allbalance=Your_token.balanceOf(address(this));// get the tokens that are locked in this HTLC
       Your_token.transfer(msg.sender,allbalance);//transfer the tokens to the claimer 
       selfdestruct(owner);
       return true;
      
       }
    
    
    
       //here the owner can refound the token when the timeout is expired 
        function refund() onlyOwner public returns(bool result) {
        require(now >= timeLock);
        uint256 allbalance=Your_token.balanceOf(address(this)); 
        Your_token.transfer(owner,allbalance);
        selfdestruct(owner);
     
        return true;
      
        }
     
    
}