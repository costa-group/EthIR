pragma solidity ^0.4.26;

// This is the smart contract for Simple FOMO
// A game theory based lottery that rewards the last entry with the 50% of the pot.
// Round 2 now also rewards the address/person that has the most entries with the other 50% of the pot
// This encourages players to enter early so they can take advantage of the lower entry cost.

// Modeled on the infamous Fomo3D but without its complexities, Simple FOMO has safeguards to reduce the chance
// a person will clog the blockchain to make them become the last entry and the winner.

contract Simple_FOMO_Round_2 {

  // Administrator information
  address public feeAddress; // This is the address of the person that collects the fees, nothing more, nothing less. It can be changed.
  uint256 public feePercent = 2500; // This is the percent of the fee (2500 = 2.5%, 1 = 0.001%)

  // Lotto information
  uint256 public potSize = 0; // This is the size of the lottery pool in Wei
  uint256 public entryCost = 1000000000000000; // This is the initial cost to enter the lottery pool (0.001 ETH)
  uint256 constant entryCostStep = 5000000000000000; // This is the increase in the entry cost per 10 entries (0.005 ETH)
  address public lastEntryAddress; // This is the address of the person who has entered the pool last
  address public mostEntryAddress; // The address that has the most entries
  uint256 public mostEntryCount = 0; // Represents the number of entries from the top entry address
  uint256 public deadline; // This represents the initial deadline for the pool
  uint256 constant gameDuration = 7; // This is the default amount of days the lottery will last for, can be extended with entries
  uint256 public extensionTime = 600; // The default extension time per entry (600 seconds = 10 minutes)
                                      // Extension time is increased by 0.5 seconds for each entry

  // Player information                                    
  uint256 public totalEntries = 0; // The total amount of entries in the pool
  mapping (address => uint256) private entryAmountList; // A list of entry amounts, mapped by each address (key)

  constructor() public payable {
    feeAddress = msg.sender; // Set the contract creator to the first feeAddress
    lastEntryAddress = msg.sender;
    mostEntryAddress = msg.sender;
    potSize = msg.value;
    deadline = now + gameDuration * 86400; // Set the game to end 7 days after lottery start
  }

  event ClaimedLotto(address _user, uint256 _amount); // Auxillary events
  event MostEntries(address _user, uint256 _amount, uint256 _entries);
  event AddedEntry(address _user, uint256 _amount, uint256 _entrycount);
  event AddedNewParticipant(address _user);
  event ChangedFeeAddress(address _newFeeAddress);
  event FailedFeeSend(address _user, uint256 _amount);

  // View function
  function viewLottoDetails() public view returns (
    uint256 _entryCost,
    uint256 _potSize,
    address _lastEntryAddress,
    address _mostEntryAddress,
    uint256 _mostEntryCount, 
    uint256 _deadline
  ) {
    return (entryCost, potSize, lastEntryAddress, mostEntryAddress, mostEntryCount, deadline);
  }

  // Action functions
  // Change contract fee address
  function changeContractFeeAddress(address _newFeeAddress) public {
    require (msg.sender == feeAddress); // Only the current feeAddress can change the feeAddress of the contract
    
    feeAddress = _newFeeAddress; // Update the fee address

     // Trigger event.
    emit ChangedFeeAddress(_newFeeAddress);
  }

  // Withdraw from pool when time has expired
  function claimLottery() public {
    require (msg.sender == lastEntryAddress || msg.sender == mostEntryAddress); // Only the last person to enter or most entries can claim the lottery
    uint256 currentTime = now; // Get the current time in seconds
    uint256 claimTime = deadline + 300; // Add 5 minutes to the deadline, only after then can the lotto be claimed
    require (currentTime > claimTime);
    // Congrats, this person has won the lottery
    require (potSize > 0); // Cannot claim an empty pot
    uint256 totalTransferAmount = potSize; // The amount that is going to the winners
    potSize = 0; // Set the potSize to zero before contacting the external address

    uint256 transferAmountLastEntry = totalTransferAmount / 2; // This is the amount going to the last entry
    uint256 transferAmountMostEntries = totalTransferAmount - transferAmountLastEntry; // The rest goes to the player with most entries

    // Send to external accounts
    // This method will only be used once, so make sure the receiving address is not a contract
    bool sendok_most = mostEntryAddress.send(transferAmountMostEntries);
    bool sendok_last = lastEntryAddress.send(transferAmountLastEntry);

     // Trigger event.
    if(sendok_last == true){
      emit ClaimedLotto(lastEntryAddress, transferAmountLastEntry);
    }
    if(sendok_most == true){
      emit MostEntries(mostEntryAddress, transferAmountMostEntries, mostEntryCount);
    } 
  }

  // Add entry to the pool
  function addEntry() public payable {
    require (msg.value == entryCost); // Entry must be equal to entry cost, not more or less
    uint256 currentTime = now; // Get the current time in seconds
    require (currentTime <= deadline); // Cannot submit an entry if the deadline has passed

    // Add this player to the entry list if not already on it (new in Round 2)
    uint256 entryAmount = entryAmountList[msg.sender];
    if(entryAmount == 0){
      // This is a new participant
      emit AddedNewParticipant(msg.sender);
    }
    entryAmount++;
    entryAmountList[msg.sender] = entryAmount; // Increase the entry count for this participant

    //Now compare this entry to the most entries
    if(entryAmount > mostEntryCount){
      // This entry makes this user have the most entries
      mostEntryCount = entryAmount;
      mostEntryAddress = msg.sender;
    }

    // Entry is valid, now modify the pool based on it
    uint256 feeAmount = (entryCost * feePercent) / 100000; // Calculate the usage fee
    uint256 potAddition = entryCost - feeAmount; // This is the amount actually going into the pot

    potSize = potSize + potAddition; // Add this amount to the pot
    extensionTime = 600 + (totalEntries / 2); // The extension time increases as more entries are submitted
    totalEntries = totalEntries + 1; // Increased the amount of entries
    if(totalEntries % 10 == 0){
      entryCost = entryCost + entryCostStep; // Increase the cost to enter every 10 entries
    }

    if(currentTime + extensionTime > deadline){ // Move the deadline if the extension time brings it beyond
      deadline = currentTime + extensionTime;
    }

    lastEntryAddress = msg.sender; // Now this entry is the last address for now

    //Pay a fee to the feeAddress
    bool sentfee = feeAddress.send(feeAmount);
    if(sentfee == false){
      emit FailedFeeSend(feeAddress, feeAmount); // Create an event in case of fee sending failed, but don't stop registering the entry
    }

    // Trigger event.
    emit AddedEntry(msg.sender, msg.value, entryAmountList[msg.sender]);
  }
}