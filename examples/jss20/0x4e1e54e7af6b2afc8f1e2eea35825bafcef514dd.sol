pragma solidity >=0.6.4;

contract managed
{
    /*
        1) Allows the manager to pause the contract
        2) change fee in the future
    */
    address payable public manager;
    
    constructor() public 
	{
	    manager = msg.sender;
	}

    //Function Modifier
    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }
    

    function setManager(address payable newmanager) external onlyManager
    {
        require(newmanager.balance > 0);
        manager = newmanager;
    }
    
}

contract digitalNotary is managed
{
    
    bool public contractactive;
    
    uint public registrationfee;
    
    uint public changeownerfee;
    
    //A mapping of File Hash with current owner
    mapping(bytes32 => address) FileHashCurrentOwnerMap;
    
    event OwnershipEvent(bytes32 indexed filehash, address indexed filehashowner, uint eventtime);
    

    constructor() public
    {

        contractactive = true;
        
        registrationfee = 5000000000000000; //0.005 ETH
        
        changeownerfee = 25000000000000000; //0.025 ETH
        
    }//end of constructor
    
    function setContractSwitch() external onlyManager
    {
        contractactive = contractactive == true ? false : true;
    }
    
    function setRegistrationFee(uint newfee) external onlyManager
    {
        require(newfee > 0, "Registration Fee should be > 0");
        
        registrationfee = newfee;
    }
    
    function setChangeOwnerFee(uint newfee) external onlyManager
    {
        require(newfee > 0, "Change Ownership fee > 0");
        
        changeownerfee = newfee;
    }
    

    function getFileHashExists(bytes32 filehash) public view returns(bool)
    {
        return FileHashCurrentOwnerMap[filehash] != address(0);
    }
    
    function getFileHashCurrentOwner(bytes32 filehash) public view returns(address)
    {
        require(getFileHashExists(filehash) == true, "File hash not registered");
        
        return FileHashCurrentOwnerMap[filehash];
    }
    
 
    function RegisterFileHash(bytes32 filehash) external payable
    {
        /*
        This method will register the Hash
        */
    
        require(contractactive == true, "Contract not active");
        require(getFileHashExists(filehash) == false, "File Hash already registered");
        require(msg.value == registrationfee, "Registration Fee incorrect");

        //Add Filehash to Map
        FileHashCurrentOwnerMap[filehash] = msg.sender;
        
        //The registrationfee gets paid to manager
        manager.transfer(msg.value);
        
        emit OwnershipEvent(filehash, msg.sender, now);
        
    }//end of registerHash
    
     function transferOwnership(bytes32 filehash, address newowner) external payable
    {
        /*
            This method will change ownership of the hash from the most recent owner to the new owner
        */
        
        require(contractactive == true, "Contract not active");
        require(newowner != address(0), "Owner can not be address(0)");
        require(getFileHashCurrentOwner(filehash) == msg.sender,"Msg Sender Not current owner");
        require(msg.value == changeownerfee, "Change Owner Fee incorrect");
        
        
        //Ownership transferred
        FileHashCurrentOwnerMap[filehash] = newowner;
        
        //The changeownerfee gets paid to manager
        manager.transfer(msg.value);
        
        emit OwnershipEvent(filehash, newowner, now);
        
    }
    
    fallback() external
    {
        
    }
 
}