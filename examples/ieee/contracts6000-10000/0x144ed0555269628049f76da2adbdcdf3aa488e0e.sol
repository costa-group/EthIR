pragma solidity ^0.5.0;

contract DOSAddressBridgeInterface {
    function getProxyAddress() public view returns(address);
}

contract CommitReveal {
    struct Participant {
        uint secret;
        bytes32 commitment;
        bool revealed;
    }

    struct Campaign {
        uint startBlock;
        uint commitDuration;  // in blocks
        uint revealDuration;  // in blocks
        uint revealThreshold;
        uint commitNum;
        uint revealNum;
        uint generatedRandom;
        mapping(address => Participant) participants;
        mapping(bytes32 => bool) commitments;
    }

    Campaign[] public campaigns;
    DOSAddressBridgeInterface public addressBridge;

    modifier checkCommit(uint _cid, bytes32 _commitment) {
        Campaign storage c = campaigns[_cid];
        require(_cid != 0 &&
                block.number >= c.startBlock &&
                block.number < c.startBlock + c.commitDuration,
                "not-in-commit");
        require(_commitment != "", "empty-commitment");
        require(!c.commitments[_commitment], "duplicate-commitment");
        _;
    }
    modifier checkReveal(uint _cid) {
        Campaign storage c = campaigns[_cid];
        require(_cid != 0 &&
                block.number >= c.startBlock + c.commitDuration &&
                block.number < c.startBlock + c.commitDuration + c.revealDuration,
                "not-in-reveal");
        _;
    }
    modifier checkFinish(uint _cid) {
        Campaign storage c = campaigns[_cid];
        require(_cid != 0 &&
                block.number >= c.startBlock + c.commitDuration + c.revealDuration,
                "commit-reveal-not-finished");
        _;
    }
    modifier onlyFromProxy() {
        require(msg.sender == addressBridge.getProxyAddress(), "not-from-dos-proxy");
        _;
    }

    event LogStartCommitReveal(uint cid, uint startBlock, uint commitDuration, uint revealDuration, uint revealThreshold);
    event LogCommit(uint cid, address from, bytes32 commitment);
    event LogReveal(uint cid, address from, uint secret);
    event LogRandom(uint cid, uint random);
    event LogRandomFailure(uint cid, uint commitNum, uint revealNum, uint revealThreshold);

    constructor(address _bridgeAddr) public {
        // campaigns[0] is not used.
        campaigns.length++;
        addressBridge = DOSAddressBridgeInterface(_bridgeAddr);
    }

    // Returns new campaignId.
    function startCommitReveal(
        uint _startBlock,
        uint _commitDuration,
        uint _revealDuration,
        uint _revealThreshold
    )
        public
        onlyFromProxy
        returns(uint)
    {
        uint newCid = campaigns.length;
        campaigns.push(Campaign(_startBlock, _commitDuration, _revealDuration, _revealThreshold, 0, 0, 0));
        emit LogStartCommitReveal(newCid, _startBlock, _commitDuration, _revealDuration, _revealThreshold);
        return newCid;
    }

    function commit(uint _cid, bytes32 _secretHash) public checkCommit(_cid, _secretHash) {
        Campaign storage c = campaigns[_cid];
        c.commitments[_secretHash] = true;
        c.participants[msg.sender] = Participant(0, _secretHash, false);
        c.commitNum++;
        emit LogCommit(_cid, msg.sender, _secretHash);
    }

    function reveal(uint _cid, uint _secret) public checkReveal(_cid) {
        Campaign storage c = campaigns[_cid];
        Participant storage p = c.participants[msg.sender];
        require(!p.revealed && keccak256(abi.encodePacked(_secret)) == p.commitment,
                "revealed-secret-not-match-commitment");
        p.secret = _secret;
        p.revealed = true;
        c.revealNum++;
        c.generatedRandom ^= _secret;
        emit LogReveal(_cid, msg.sender, _secret);
    }

    // Return value of 0 representing invalid random output.
    function getRandom(uint _cid) public checkFinish(_cid) returns (uint) {
        Campaign storage c = campaigns[_cid];
        if (c.revealNum >= c.revealThreshold) {
            emit LogRandom(_cid, c.generatedRandom);
            return c.generatedRandom;
        } else{
            emit LogRandomFailure(_cid, c.commitNum, c.revealNum, c.revealThreshold);
            return 0;
        }
    }
}