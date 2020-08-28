pragma solidity ^0.5.13;
library SafeMath {
    function add(uint256 a,uint256 b)internal pure returns(uint256){uint256 c=a+b; require(c>=a); return c;}
	function sub(uint256 a,uint256 b)internal pure returns(uint256){require(b<=a);uint256 c=a-b;return c;}
	function mul(uint256 a,uint256 b)internal pure returns(uint256){if(a==0){return 0;}uint256 c=a*b;require(c/a==b);return c;}
	function div(uint256 a,uint256 b)internal pure returns(uint256){require(b>0);uint256 c=a/b;return c;}}
interface Out{
	function mint(address w,uint256 a)external returns(bool);
    function burn(address w,uint256 a)external returns(bool);
   	function balanceOf(address account)external view returns(uint256);}	
contract ESCROW{    
	using SafeMath for uint256;
	address private rot=0x45F2aB0ca2116b2e1a70BF5e13293947b25d0272;
	mapping(address => uint256) private price;
	mapping(address => uint256) private amount;
	function setEscrow(uint256 p,uint256 a)external returns(bool){
	    require(Out(rot).balanceOf(msg.sender) >= a);
	    require(p>10**14);price[msg.sender]=p;amount[msg.sender]=a;return true;}
	function payEscrow(address payable w)external payable returns(bool){
	    require(msg.value>10**14); uint256 gam=(msg.value.mul(10**18)).div(price[w]);
		require(Out(rot).balanceOf(w) >= amount[w]);require(amount[w] >= gam);
		require(Out(rot).mint(msg.sender,gam));
		require(Out(rot).burn(w,gam));
	    amount[w]=amount[w].sub(gam);
	    w.transfer(msg.value);
	    return true;}
	function geInfo(address n)external view returns(uint256,uint256){return(price[n],amount[n]);}
   	function()external{revert();}}