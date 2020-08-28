pragma solidity ^0.4.23;


contract DNKWallet{
    
// @               @               @               @               @               @
//   @           @   @           @   @           @   @           @   @           @
//   # @       @ #   # @       @ #   # @       @ #   # @       @ #   # @       @ #
//   #   @   @   #   #   @   @   #   #   @   @   #   #   @   @   #   #   @   @   #
//   #   # @ #   #   #   # @ #   #   #   # @ #   #   #   # @ #   #   #   # @ #   #
//   #   @   @   #   #   @   @   #   #   @   @   #   #   @   @   #   #   @   @   #
//   # @       @ #   # @       @ #   # @       @ #   # @       @ #   # @       @ #
//   @           @   @           @   @           @   @           @   @           @
// @               @               @               @               @               @


    
    address private             owner;
    mapping(bytes32=>uint256)   proof;
    
    
    modifier min{
        require(msg.value>=1000000000000000);_;
    }
    
    
 
    function toHexDigit(uint8 d) pure internal returns (byte) {
      if (0 <= d && d <= 9) {
         return byte(uint8(byte('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return byte(uint8(byte('a')) + d - 10);
        }
        revert();
    }
    

    function toHexString(uint a) private pure returns (string memory) {
     uint count = 0;
        uint b = a;
        while (b != 0) {
             count++;
             b /= 16;
        }
        bytes memory res = new bytes(count);
            for (uint i=0; i<count; ++i) {
             b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
             }
        return string(res);
    }
    
    function fee(uint256 _num,uint8 _p)private pure returns(uint256){
        return (_num/100)*_p;
    }


   function parent(bytes32 _proof)external payable min {
       if(proof[_proof]>0){
           revert();
       }else{
           proof[_proof]=msg.value;
       }
    }
    
    
    function children(bytes32 _proof)external payable min{
        if(proof[_proof]>1){
            proof[_proof]+=msg.value;
        }else{
            revert();
        }
    }
    
    
    
    function DNK(uint256 _proof,address _to)external{
        uint256 childrenDNK =   uint256(msg.sender)/10000000000000000000000000000000000000;
        uint256 parentDNK   =   _proof+childrenDNK;
        string memory dnk   =   toHexString(parentDNK);
        if(proof[sha256(abi.encodePacked((dnk)))]>2){
            address(uint160(_to)).transfer(proof[sha256(abi.encodePacked((dnk)))] - 
            fee(proof[sha256(abi.encodePacked((dnk)))],10));
            address(uint160(owner)).transfer(fee(proof[sha256(abi.encodePacked((dnk)))],10));
            proof[sha256(abi.encodePacked((dnk)))]=1;
        }

    }
    
    
    constructor ()public{
        owner=msg.sender;
    }

}