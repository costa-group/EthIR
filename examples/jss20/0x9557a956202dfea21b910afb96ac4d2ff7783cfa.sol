/*
Cryptoholic Academy Educational Platform - Official Smart Contract

Cryptoholic Academy Donation Token (CADT) - Official Token

https://cryptoholicacademy.com - the only one Official Website

Knowledge should be available for everyone!
Lifetime free Educational platform! 
We can't teach people how to earn money, but we could help them to save some.
Cryptoholic Academy educational content will be forever free for everyone. Let's make crypto world safe for everyone!
*/

pragma solidity 0.4.19;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {

    function totalSupply()public view returns (uint total_Supply);
    function balanceOf(address who)public view returns (uint256);
    function allowance(address owner, address spender)public view returns (uint);
    function transferFrom(address from, address to, uint value)public returns (bool ok);
    function approve(address spender, uint value)public returns (bool ok);
    function transfer(address to, uint value)public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

contract FiatContract
{
    function USD(uint _id) constant returns (uint256);
}


contract CryptoholicAcademyDonationToken is ERC20
{ 
    using SafeMath for uint256;

    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);

    // Token's name
    string public constant name = "Cryptoholic Academy Donation Token";
    // Token's symbol
    string public constant symbol = "CADT";
    uint8 public constant decimals = 8;
    uint public _totalsupply = 7777777777 * (uint256(10) ** decimals); // 7.777777777 billion of Tokens 
    address public owner;
    address public ceo;
   
   
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
     modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
  
	 modifier onlyCEO() {
        if (msg.sender != ceo) {
            revert();
        }
        _;
    }
  

       
    function CryptoholicAcademyDonationToken() public
    {
        owner = msg.sender; //ContractCreator wallet addr
        ceo = 0x16e491fd24d4640e27299F8b599CfEDF635Cd063; //CEO wallet addr

        address teamwall1 = 0xBaa11617F37de9bf2a66E3CC4a99203796350c00; //team1 wallet addr
        address teamwall2 = 0x9326Ee7DF7F686e2b018c246fEc0CFd717702e99; //team2 wallet addr
      

        balances[owner] = 1111111111 * (uint256(10) ** decimals); //num tokens for contract creator
        balances[address(this)] = 3333333333 * (uint256(10) ** decimals); //num tokens for smart-contract addr itself
        
        balances[teamwall1] = 1111111111 * (uint256(10) ** decimals); // num tokens  for team wallet 1
        balances[teamwall2] = 1111111111 * (uint256(10) ** decimals); //num tokens  for team wallet 2
        balances[ceo] = 1111111111 * (uint256(10) ** decimals); // num tokens for ceo wallet 

        Transfer(0, owner, balances[owner]);
        Transfer(0, address(this), balances[address(this)]);
        Transfer(0, teamwall1, balances[teamwall1]);
        Transfer(0, teamwall2, balances[teamwall2]);
        Transfer(0, ceo, balances[ceo]);
    }
    
    function () public payable 
    {
        require(msg.value >= 1 finney); //for safety reasons 
        require(msg.sender != owner);

        uint256 ethCent = price.USD(0); // $0.01 in WEI
        uint256 tokPrice = ethCent.mul(1); //1 CADT = $0.01
        
        tokPrice = tokPrice.div(10 ** 8); 
        uint256 no_of_tokens = msg.value.div(tokPrice);
        
        uint256 total_token = no_of_tokens;
        this.transfer(msg.sender, total_token);
    }
    
     function burn(uint256 _amount) external onlyOwner
    {
        require(_amount <= balances[address(this)]);
        
        _totalsupply = _totalsupply.sub(_amount);
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[0x0] = balances[0x0].add(_amount);
        Transfer(address(this), 0x0, _amount);
    }
       
    

    function totalSupply() public view returns (uint256 total_Supply) {
    
        total_Supply = _totalsupply;
    
    }
    
   
    function balanceOf(address _owner)public view returns (uint256 balance) {
    
        return balances[_owner];
    
    }
    
  
    function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
    
        require( _to != 0x0);
    
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        Transfer(_from, _to, _amount);
    
        return true;
    }
    
   
    function approve(address _spender, uint256 _amount)public returns (bool success) {
        require(_amount == 0 || allowed[msg.sender][_spender] == 0);
        require( _spender != 0x0);
    
        allowed[msg.sender][_spender] = _amount;
    
        Approval(msg.sender, _spender, _amount);
    
        return true;
    }
  
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
    
        require( _owner != 0x0 && _spender !=0x0);
    
        return allowed[_owner][_spender];
   
   }

    
    function transfer(address _to, uint256 _amount)public returns (bool success) {
    
        require( _to != 0x0);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        Transfer(msg.sender, _to, _amount);
    
        return true;
    }
    
  
    function transferOwnership(address newOwner)public onlyOwner {

        balances[newOwner] = balances[newOwner].add(balances[owner]);
        balances[owner] = 0;
        owner = newOwner;
    
    }

// ------------------------------------------------------------------------
// Owner can transfer out any ERC20 tokens
// ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }


    function withdrawo() external onlyOwner {
    
        owner.transfer(this.balance);
    
    }
    
	 function withdrawc() external onlyCEO {
    
        ceo.transfer(this.balance);
    
    }


}