pragma solidity 0.5.14;

contract ETHDrop {
    uint256 public drip;
    address payable[] members;
    address payable private secretary;
    
    modifier onlySecretary() {
        require(msg.sender == secretary);
        _;
    }
    
    function() external payable { }
    
    constructor(uint256 _drip, address payable[] memory _members) payable public {
        drip = _drip;
        members = _members;
        secretary = members[0];
    }
    
    function dripETH() public onlySecretary {
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(drip);
        }
    }
    
    function dropETH(uint256 drop) payable public onlySecretary {
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(drop);
        }
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /***************
    MEMBER FUNCTIONS
    ***************/
    function addMember(address payable newMember) public onlySecretary {
        members.push(newMember);
    }
    
    function getMembership() public view returns (address payable[] memory) {
        return members;
    }
    
    function getMemberCount() public view returns(uint256 memberCount) {
        return members.length;
    }
    
    function transferSecretary(address payable newSecretary) public onlySecretary {
        secretary = newSecretary;
    }
    
    function updateDrip(uint256 newDrip) public onlySecretary {
        drip = newDrip;
    }
}

contract ETHDropFactory {
    ETHDrop private Drop;
    address[] public drops;
    
    event newDrop(address indexed secretary, address indexed drop);
    
    function newETHDrop(uint256 _drip, address payable[] memory _members) payable public {
        Drop = (new ETHDrop).value(msg.value)(_drip, _members);
        drops.push(address(Drop));
        emit newDrop(_members[0], address(Drop));
    }
}