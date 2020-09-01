/**
*Submitted for verification at Etherscan.io on 2020-01-25
*https://ito.etvr.us is used for investment of broker
*https://www.etvr.us is our official website
*/
pragma solidity ^0.4.16;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
 contract TokenERC20 {
string public name; //name is EthanVR
string public symbol; //symbol is ETVR
uint8 public decimals = 5;  
uint256 public totalSupply;
mapping (address => uint256) public balanceOf;
mapping (address => mapping (address => uint256)) public allowance;
event Transfer(address indexed from, address indexed to, uint256 value);
event Burn(address indexed from, uint256 value);
function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
	totalSupply = initialSupply * 10 ** uint256(decimals); 
	balanceOf[msg.sender] = totalSupply;        
	name = tokenName;                     
	symbol = tokenSymbol;                 
}

/**
*In the world of VR,The perceptual function possessed 
*by all people can be experientially well integrated,
*Users are fully engaged,Forget the difference between 
*virtual and reality,And you can do whatever you want.VR`s
* immersion, interactivity, and perception will revolutionize 
*human activity,The advent of the era of value Internet led
* by blockchain
*/

function _transfer(address _from, address _to, uint _value) internal {
	require(_to != 0x0); // dev Divides two numbers and returns the remainder (unsigned integer modulo)
	require(balanceOf[_from] >= _value);
	require(balanceOf[_to] + _value > balanceOf[_to]); //dev compare two numbers and returns the smaller one
	uint previousBalances = balanceOf[_from] + balanceOf[_to];
	balanceOf[_from] -= _value;
	balanceOf[_to] += _value;
	Transfer(_from, _to, _value);  //dev compare two numbers and returns the smaller Two
	assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
}

  /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *ETVR token issue.
     */

function transfer(address _to, uint256 _value) public {
	_transfer(msg.sender, _to, _value); //dev Divides two numbers and returns the remainder (unsigned integer modulo)
}
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	require(_value <= allowance[_from][msg.sender]);     
	allowance[_from][msg.sender] -= _value;
	_transfer(_from, _to, _value);
	return true;
}

/**
*ETVR is a DAPP developed on the Ethereum smart contract
*developed by EthanVR company,ETVR financial data
*deployment runs on the Ethereum blockchain,
*ETVR contract will not stop after opening.ETVR
* issues tokens through the ITO (Initial Smart Offering ) 
*method of smart contracts.
*/

function approve(address _spender, uint256 _value) public
returns (bool success) {
	allowance[msg.sender][_spender] = _value;
	return true;
}


function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	public
	returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

function burn(uint256 _value) public returns (bool success) {
	require(balanceOf[msg.sender] >= _value);   
	balanceOf[msg.sender] -= _value;           
	totalSupply -= _value;               
	Burn(msg.sender, _value);
	return true;
}

  // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.

function burnFrom(address _from, uint256 _value) public returns (bool success) {
	require(balanceOf[_from] >= _value);        
	require(_value <= allowance[_from][msg.sender]);  
	balanceOf[_from] -= _value;          
	allowance[_from][msg.sender] -= _value;  
	totalSupply -= _value;            
	Burn(_from, _value);
	return true;
}
}

/**
*Brokers who invest ETH in the ETVR contract network 
*through the ITO method will obtain a certain 
*percentage of VR tokens: ETVR. The brokers can also
*use the lock-to-invest method to enlarge (2-5 times) ETH assets.
*/