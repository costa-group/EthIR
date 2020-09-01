pragma solidity ^0.5.12;

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender == owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "address(0) != _newOwner");
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "msg.sender == newOwner");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }
}

contract Adminable is Ownable {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "admins[msg.sender]");
        _;
    }

    function setAdmin(address _admin, bool _authorization) public onlyOwner {
        admins[_admin] = _authorization;
    }
 
}

contract tokenInterface {
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract Deposit_Swap is Ownable, Adminable {
    tokenInterface public tkn;
    
    function setTkn(address _tkn) onlyOwner public {
	     tkn = tokenInterface(_tkn);
    }

	function () external onlyAdmin {
	    uint256 amount = tkn.balanceOf(address(this));
        tkn.transfer(msg.sender, amount);
	}
}