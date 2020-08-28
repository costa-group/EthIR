pragma solidity 0.5.14;

contract ETHDrop {
    uint256 public drip;
    address payable[] members;
    address payable private secretary;
    
    function() external payable { }
    
    constructor(uint256 _drip, address payable[] memory _members) payable public {
        drip = _drip;
        members = _members;
        secretary = members[0];
    }
    
    function dripETH() public {
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(drip);
        }
    }
    
    function dropETH(uint256 drop) payable public {
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
    modifier onlySecretary() {
        require(msg.sender == secretary);
        _;
    }
    
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