pragma solidity >=0.4.0 <0.6.0;
 
 interface tokenToTransfer {
        function transfer(address to, uint256 value) external;
        function transferFrom(address from, address to, uint256 value) external;
        function balanceOf(address owner) external returns (uint256);
    }
    
    contract Ownable {
        address private _owner;
        
        constructor() public {
            _owner = msg.sender;
        }
        
        modifier onlyOwner() {
            require(isOwner());
            _;
         }
          
        function isOwner() public view returns(bool) {
            return msg.sender == _owner;
         }
          
        function transferOwnership(address newOwner) public onlyOwner {
            _transferOwnership(newOwner);
        }
        
        function _transferOwnership(address newOwner) internal {
            require(newOwner != address(0));
            _owner = newOwner;
        }
    }
    
    contract StakeImperial is Ownable {
    //Setup of public variables for maintaing between contract transactions
    address ImperialAddress = address(0xA20DF70f6f5935ecde3ED789bc6f7c19fef14087);
    tokenToTransfer public sendtTransaction;
    
    //Setup of staking variables for contract maintenance 
    mapping (address => uint256) private stake;
    mapping (address => uint256) private timeinStake;
    uint256 private time = now;
    uint256 private reward;
    uint256 private timeVariable = 86400;
    uint256 private allStakes;
    bool private higherReward = true;
    
    function View_Balance() public view returns (uint256) {
        sendtTransaction = tokenToTransfer(ImperialAddress);
        return sendtTransaction.balanceOf(msg.sender);
    }
    
    function initateStake() public {
        //uint256 stakedAmount = stake * 1000000;
        sendtTransaction = tokenToTransfer(ImperialAddress);
        uint256 stakedAmount = View_Balance();
        sendtTransaction.transferFrom(msg.sender, address(this), stakedAmount);
        stake[msg.sender] = stakedAmount;
        allStakes += stakedAmount;
        timeinStake[msg.sender] = now;
    }
    
    function displayStake() public view returns (uint256) {
        return stake[msg.sender];
    }
    
    function displayBalance() public view returns (uint256) {
        uint256 balanceTime = (now - timeinStake[msg.sender]) / timeVariable;
        if (higherReward == true) {
        return balanceTime * reward * stake[msg.sender];
        } else {
        balanceTime = balanceTime * (stake[msg.sender] / reward) + stake[msg.sender];
        return balanceTime;
        }
    }
    
    function displayAllStakes() public view returns (uint256) {
        return allStakes;
    }
    
    function displayTimeVariable() public view returns (uint256) {
        return timeVariable;
    }
    
    function displayTimeWhenUserStaked() public view returns (uint256) {
        return timeinStake[msg.sender];
    }
    
    //Admin change address to updated address function
    function changeImperialAddresstoNew(address change) public onlyOwner {
        ImperialAddress = change;
    }
    
    //Admin change reward function
    function changeReward(uint256 change) public onlyOwner {
        reward = change;
    }
    
    //Admin change reward function
    function changeTimeVariable(uint256 change) public onlyOwner {
        timeVariable = change;
    }
    
    //Admin reward function for lower than 100%
    function changeRewardtoLower(bool value) public onlyOwner {
        higherReward = value;
    }
    
    //Admin reset time balance to reset stake to new level
    function resetTime() public onlyOwner {
        time = now;
    }
    
    function withdrawBalance() public {
            if (timeinStake[msg.sender] == 0) {
                revert();
            }
        if (higherReward = true) {
        sendtTransaction = tokenToTransfer(ImperialAddress);
        uint256 getUserBalance = displayBalance();
        sendtTransaction.transfer(msg.sender, getUserBalance);
        stake[msg.sender] = 0;
        allStakes -= getUserBalance;
        timeinStake[msg.sender] = 0;
        }
    }
    
    
 }