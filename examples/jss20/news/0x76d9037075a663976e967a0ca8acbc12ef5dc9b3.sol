pragma solidity ^0.4.26;


/* TEMPLATE TERMS



Establishing a retainer and acknowledging the mutual consideration and agreement hereby, Client, indentified as ethereum address '0x[[Client Ethereum Address]]',



commits a digital payment transactional script capped at '$[[Payment Cap in Dollars]]' for the benefit of Provider, identified as ethereum address '0x[[Provider Ethereum Address]]',



in exchange for the prompt satisfaction of the following deliverables to Client by Provider, '[[Deliverable]]', upon scripted payments set at the rate of '$[[Deliverable Rate]]' per deliverable,



with such retainer relationship not to exceed '[[Retainer Duration in Days]]' days and to be governed by the choice of [[Choice of Law and Arbitration Forum]] law and 'either/or' arbitration rules in [[Choice of Law and Arbitration Forum]]. 

*/



/* OPENLAW TEMPLATE



https://app.openlaw.io/template/OpenLEX%20-%20Digital%20Dollar%20Retainer%20(DDR)



*/



/***************

DDR CONTRACT

***************/



contract DigitalDollarRetainer {



string public terms; // **terms governing DDR**



// **ERC-20 Token References**

uint256 private decimalFactor = 10**uint256(18); // **adjusts token payments to wei amount for UX**

address public daiToken = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359; // **designated ERC-20 token for payments - DAI 'digital dollar'**

address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // **designated ERC-20 token for payments - USDC 'digital dollar'**



// **Service Retainer References**

address public client; // **client ethereum address**

address public provider; // **ethereum address that receives payments in exchange for goods or services**

string public deliverable; // **goods or services (deliverable) retained for benefit of ethereum payments**

string public governingLawandForum; // **choice of law and forum for retainer relationship**

uint8 public retainerDurationinDays; // **duration of retainer in days**

uint8 public deliverableRate; // **rate for retained deliverables in digital dollars**

uint8 public paid; // **amount paid thus far under retainer in digital dollars**

uint8 public payCap; // **retainer payment cap in digital dollars**



event Paid(uint256 amount, address indexed); // **triggered on successful payments**



constructor(string _terms, address _client, address _provider, string _deliverable, string _governingLawandForum, uint8 _retainerDurationinDays, uint8 _deliverableRate, uint8 _payCap) public {

terms = _terms;

client = _client;

provider = _provider;

deliverable = _deliverable;

governingLawandForum = _governingLawandForum;

retainerDurationinDays = _retainerDurationinDays;

deliverableRate = _deliverableRate;

payCap = _payCap;

}



function getTerms() // **getter function to facilitate factory calls**

public

view

returns (string)

{

return terms;

}



function payDAI() public { // **forwards approved DAI token amount to provider ethereum address**

require(msg.sender == client);

require(paid <= payCap, "payDAI: payCap exceeded");

require(paid + deliverableRate <= payCap, "payDAI: payCap exceeded");

uint256 weiAmount = deliverableRate * decimalFactor;

ERC20 dai = ERC20(daiToken);

dai.transferFrom(msg.sender, provider, weiAmount);

emit Paid(weiAmount, msg.sender);

paid = paid + deliverableRate;

}



function payUSDC() public { // **forwards approved USDC token amount to provider ethereum address**

require(msg.sender == client);

require(paid <= payCap, "payUSDC: payCap exceeded");

require(paid + deliverableRate <= payCap, "payUSDC: payCap exceeded");

uint256 weiAmount = deliverableRate * decimalFactor;

ERC20 usdc = ERC20(usdcToken);

usdc.transferFrom(msg.sender, provider, weiAmount);

emit Paid(weiAmount, msg.sender);

paid = paid + deliverableRate;

}

}



/***************

ERC20 CONTRACT

***************/



/**

* @title ERC20

* @dev see https://github.com/ethereum/EIPs/issues/20

*/

contract ERC20 {

uint256 public totalSupply;



function balanceOf(address who) public view returns (uint256);

function transfer(address to, uint256 value) public returns (bool);

function allowance(address owner, address spender) public view returns (uint256);

function transferFrom(address from, address to, uint256 value) public returns (bool);

function approve(address spender, uint256 value) public returns (bool);



event Approval(address indexed owner, address indexed spender, uint256 value);

event Transfer(address indexed from, address indexed to, uint256 value);

}



/***************

FACTORY CONTRACT

***************/



contract DigitalDollarRetainerFactory {



// **index of created contracts**

mapping (address => bool) public validContracts;

address[] public contracts;



// **useful to know the row count in contracts index**

function getContractCount()

public

view

returns(uint contractCount)

{

return contracts.length;

}



// **get all contracts**

function getDeployedContracts() public view returns (address[])

{

return contracts;

}



// **deploy a new contract**

function newDigitalRetainer(string _terms, address _client, address _provider, string _deliverable, string _governingLawandForum, uint8 _retainerDurationinDays, uint8 _deliverableRate, uint8 _payCap)

public

returns(address)

{

DigitalDollarRetainer c = new DigitalDollarRetainer(_terms, _client, _provider, _deliverable, _governingLawandForum, _retainerDurationinDays, _deliverableRate, _payCap);

validContracts[c] = true;

contracts.push(c);

return c;

}



// **retrieve stored terms from deployed DDR**

function getTerms(address ddRetainer)

public

view

returns(string)

{



// **ensure valid address for DDR**

require(validContracts[ddRetainer],"Contract Not Found!");



return (DigitalDollarRetainer(ddRetainer).getTerms());

}

}