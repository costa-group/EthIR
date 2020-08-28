pragma solidity 0.5.14;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract SecretaryRole is Context {
    using Roles for Roles.Role;

    event SecretaryAdded(address indexed account);
    event SecretaryRemoved(address indexed account);

    Roles.Role private _secretaries;

    modifier onlySecretary() {
        require(isSecretary(_msgSender()), "SecretaryRole: caller does not have the Secretary role");
        _;
    }
    
    function isSecretary(address account) public view returns (bool) {
        return _secretaries.has(account);
    }

    function addSecretary(address account) public onlySecretary {
        _addSecretary(account);
    }

    function renounceSecretary() public {
        _removeSecretary(_msgSender());
    }

    function _addSecretary(address account) internal {
        _secretaries.add(account);
        emit SecretaryAdded(account);
    }

    function _removeSecretary(address account) internal {
        _secretaries.remove(account);
        emit SecretaryRemoved(account);
    }
}

interface IToken { // brief ERC-20 interface
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MemberDripDrop is SecretaryRole {
    /***************
    INTERNAL DETAILS
    ***************/
    uint256 public ethDrip;
    uint256 public tokenDrip;
    IToken public dripToken;
    address payable[] members;
    string public message;
    
    mapping(address => Member) public memberList;
    
    struct Member {
        uint256 memberIndex;
        bool exists;
    }

    // ******
    // EVENTS
    // ******
    event DripTokenUpdated(address indexed updatedDripToken);
    event TokenDripUpdated(uint256 indexed updatedTokenDrip);
    event ETHDripUpdated(uint256 indexed updatedETHDrip);
    event MemberAdded(address indexed addedMember);
    event MemberRemoved(address indexed removedMember);
    event MessageUpdated(string indexed updatedMessage);
    event SecretaryUpdated(address indexed updatedSecretary);
    
    function() external payable { } // contract receives ETH

    constructor(
        uint256 _ethDrip, 
        uint256 _tokenDrip,  
        address dripTokenAddress, 
        address payable[] memory _members,
        string memory _message) payable public { // initializes contract
        for (uint256 i = 0; i < _members.length; i++) {
            require(_members[i] != address(0), "member address cannot be 0");
            memberList[_members[i]].memberIndex = members.push(_members[i]) - 1;
            memberList[_members[i]].exists = true;
        }
        
        ethDrip = _ethDrip;
        tokenDrip = _tokenDrip;
        dripToken = IToken(dripTokenAddress);
        message = _message;
        
        _addSecretary(members[0]); // first address in member array is initial secretary  
    }
    
    /************************
    DRIP/DROP TOKEN FUNCTIONS
    ************************/
    function dripTKN() public onlySecretary { // transfer token to members per stored drip amount
        for (uint256 i = 0; i < members.length; i++) {
            dripToken.transfer(members[i], tokenDrip);
        }
    }
    
    function dropTKN(uint256 drop, address dropTokenAddress) public onlySecretary { // transfer token to members per approved drop amount
        for (uint256 i = 0; i < members.length; i++) {
            IToken dropToken = IToken(dropTokenAddress);
            dropToken.transferFrom(msg.sender, members[i], drop);
        }
    }
    
    function customDropTKN(uint256[] memory drop, address dropTokenAddress) public onlySecretary { // transfer token to members per approved index drop amounts
        for (uint256 i = 0; i < members.length; i++) {
            IToken dropToken = IToken(dropTokenAddress);
            dropToken.transferFrom(msg.sender, members[i], drop[i]);
        }
    }
    
    /**********************
    DRIP/DROP ETH FUNCTIONS
    **********************/
    function dripETH() public onlySecretary { // transfer ETH to members per stored drip amount
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(ethDrip);
        }
    }

    function dropETH() payable public onlySecretary { // transfer ETH to members per attached drop amount
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(msg.value);
        }
    }
    
    function customDropETH(uint256[] memory drop) payable public onlySecretary { // transfer ETH to members per index drop amounts
        for (uint256 i = 0; i < members.length; i++) {
            members[i].transfer(drop[i]);
        }
    }
    
    /******************
    SECRETARY FUNCTIONS
    ******************/
    // ******************
    // DRIP/DROP REGISTRY
    // ******************
    function addMember(address payable addedMember) public onlySecretary { 
        require(memberList[addedMember].exists != true, "member already exists");
        memberList[addedMember].memberIndex = members.push(addedMember) - 1;
        memberList[addedMember].exists = true;
        emit MemberAdded(addedMember);
    }

    function removeMember(address removedMember) public onlySecretary {
        require(memberList[removedMember].exists = true, "no such member to remove");
        uint256 memberToDelete = memberList[removedMember].memberIndex;
        address payable keyToMove = members[members.length-1];
        members[memberToDelete] = keyToMove;
        memberList[keyToMove].memberIndex = memberToDelete;
        memberList[removedMember].exists = false;
        members.length--;
        emit MemberRemoved(removedMember);
    }
    
    function updateMessage(string memory updatedMessage) public onlySecretary {
        message = updatedMessage;
        emit MessageUpdated(updatedMessage);
    }

    // ************
    // DRIP DETAILS
    // ************
    function updateETHDrip(uint256 updatedETHDrip) public onlySecretary {
        ethDrip = updatedETHDrip;
        emit ETHDripUpdated(updatedETHDrip);
    }
    
    function updateDripToken(address updatedDripToken) public onlySecretary {
        dripToken = IToken(updatedDripToken);
        emit DripTokenUpdated(updatedDripToken);
    }
    
    function updateTokenDrip(uint256 updatedTokenDrip) public onlySecretary {
        tokenDrip = updatedTokenDrip;
        emit TokenDripUpdated(updatedTokenDrip);
    }
    
    /***************
    GETTER FUNCTIONS
    ***************/
    // ****
    // DRIP
    // ****
    function ETHBalance() public view returns (uint256) { // get balance of ETH in contract
        return address(this).balance;
    }
    
    function TokenBalance() public view returns (uint256) { // get balance of drip token in contract
        return dripToken.balanceOf(address(this));
    }

    // ******
    // MEMBER
    // ******
    function Membership() public view returns (address payable[] memory) {
        return members;
    }

    function MemberCount() public view returns(uint256 memberCount) {
        return members.length;
    }

    function isMember(address memberAddress) public view returns (bool memberExists) {
        if(members.length == 0) return false;
        return (members[memberList[memberAddress].memberIndex] == memberAddress);
    }
}

contract MemberDripDropFactory {
    MemberDripDrop private DripDrop;
    address[] public dripdrops;

    event newDripDrop(address indexed secretary, address indexed dripdrop);

    function newMemberDripDrop(
        uint256 _ethDrip, 
        uint256 _tokenDrip,  
        address dripTokenAddress, 
        address payable[] memory _members,
        string memory _message) payable public {
            
        DripDrop = (new MemberDripDrop).value(msg.value)(
            _ethDrip,
            _tokenDrip,
            dripTokenAddress,
            _members,
            _message);
            
        dripdrops.push(address(DripDrop));
        emit newDripDrop(_members[0], address(DripDrop));
    }
}