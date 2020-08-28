pragma solidity 0.5.9;

/* SOLIDITY RETAINER LETTER FOR LEGAL ENGINEERING

DEAR MSG.SENDER(S):

Upon calling the "payRetainerFee" function in the ascribed *uint256* public fee amount (Ξ) ("Retainer Fee")
and providing an e-mail or similar communication address for your contact as the *string* value therein, 
a member of Open, ESQ LLC ("OE"), shall contact you thereby within three (3) business days
and arrange a consultation to upload one (1) legal agreement in OpenLaw.io markup,
not to exceed twenty (20) pages, and deploy up to three (3) related Solidity scripts on Ethereum, 
with such retained OE services to be completed within five (5) business days,
or a full refund (Ξ) shall be promptly returned to msg.sender(s). 

OE may transfer the benefit of Retainer Fees by calling the "assignBeneficiary" function.

OE may revise the Retainer Fee amount by calling the "updateFee" function; 
for the avoidance of doubt, such state changes shall not affect OE services already retained hereby.

This Solidity Retainer Letter is governed by New York law; 
related disputes shall be resolved by arbitration in Kings County, New York.

OE, info@openesq.tech
*/

contract Retainer {
    
    address payable public beneficiary; // address to receive retainer fees
    uint256 public fee; // wei amount of retainer fee
    
    address private admin;
    
    event Retained(address indexed, string request); // triggered on payRetainerFee success
    
    modifier onlyAdmin() // restrict functions to beneficiary address
    {
        require(
            msg.sender == admin,
            "Sender not authorized."
        );
        _;
    }
    
    constructor(uint256 _fee) public { // initializes contract with retainer fee amount
        beneficiary = msg.sender;
        admin = msg.sender;
        fee = _fee;
    }

    function payRetainerFee(string memory request) public payable { // allows public to pay retainer fee
        require(msg.value == fee);
        beneficiary.transfer(msg.value);
        emit Retained(msg.sender, request);
    }
    
    // Beneficiary can manage retainer structure 
    
    function updateFee(uint256 newFee) public onlyAdmin { // changes fee amount for retainers
        fee = newFee;
    }
    
    function assignBeneficiary(address payable newBeneficiary) public onlyAdmin { // changes beneficiary address
        beneficiary = newBeneficiary;
    }
}