
// </ORACLIZE_API>
contract EthereumPot {

    address owner;
    address[] addresses;
    address winnerAddress;

    uint[] slots;
    uint minBetSize = 0.01 ether;
    uint potSize = 0;
    uint  amountWon;
    uint potTime = 300;
    uint endTime = now + potTime;
    uint totalBet = 0;
    uint random_number;

    bool public locked = false;

 
    event potSizeChanged(
    );
    event winnerAnnounced(
        address winner,
        uint amount
    );
    event timeLeft(uint left);

    function EthereumPot() public {
        //oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        owner = msg.sender;
    }

    function Kill() public {
        if(owner == msg.sender)
          int a = 5;//selfdestruct(owner);
    }

    function /* actual callback */__callback(bytes32 _queryId, string _result, bytes _proof)
    {
        // if we reach this point successfully, it means that the attached authenticity proof has passed!
        if(msg.sender != 0) throw;

         // generate a random number between potSize(number of tickets sold) and 1
        random_number = uint(sha3(_result))%potSize + 1;

          // find that winner based on the random number generated
        winnerAddress = findWinner(random_number);

        // winner wins 98% of the remaining balance after oraclize fees
        amountWon = this.balance * 98 / 100 ;


        // announce winner
        winnerAnnounced(winnerAddress, amountWon);
        if(winnerAddress.send(amountWon)) {

            if(owner.send(this.balance)) {
                openPot();
            }


        }



    }

    function update() internal{
        uint delay = 0; // number of seconds to wait before the execution takes place
        bytes32 queryId = 0;//oraclize_newRandomDSQuery(delay, 10, 400000);
        queryId = queryId;// this function internally generates the correct oraclize_query and returns its queryId
    }

    function findWinner(uint random) returns (address winner) {

        for(uint i = 0; i < slots.length; i++) {

           if(random <= slots[i]) {
               return addresses[i];
           }

        }

    }

    function joinPot() public payable {

        if(now > endTime) throw;
        if(locked) throw;

        uint tickets = 0;

        for(uint i = msg.value; i >= minBetSize; i-= minBetSize) {
            tickets++;
        }
        if(tickets > 0) {
            addresses.push(msg.sender);
            slots.push(potSize += tickets);
            totalBet+= tickets;
            potSizeChanged();
            timeLeft(endTime - now);
        }
    }

    function getPlayers() constant public returns(address[]) {
        return addresses;
    }

    function getSlots() constant public returns(uint[]) {
        return slots;
    }

    function getEndTime() constant public returns (uint) {
        return endTime;
    }

    function openPot() internal {
        potSize = 0;
        endTime = now + potTime;
        timeLeft(endTime - now);
        delete slots;
        delete addresses;

        locked = false;
    }

    function rewardWinner() public payable {

        //assert time & locked state
        if(now < endTime) throw;
        if(locked) throw;
        locked = true;

        if(potSize > 0) {
            //if only 1 person bet, wait until they've been challenged
            if(addresses.length == 1) {
                endTime = now + potTime;
                timeLeft(endTime - now);
                locked = false;
            }

            else {
             update();
            }

        }
        else {
            winnerAnnounced(0x0000000000000000000000000000000000000000, 0);
            openPot();
        }

    }




}
