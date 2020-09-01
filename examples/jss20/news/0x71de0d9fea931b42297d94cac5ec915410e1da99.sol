pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

interface EtherShare {
    function count() external view returns (uint);
    function allShare(uint ShareID, uint ReplyID) external view returns (address,string memory,uint,bool,string memory);
}

interface EtherShareLike {
    function allLike(uint ShareID, uint ReplyID) external view returns (uint);
}

interface EtherShareReward {
    function getSum(uint ShareID, uint ReplyID) external view returns (uint);
}



contract EtherShareQuery {
    EtherShare ES = EtherShare(0xc86bDf9661c62646194ef29b1b8f5Fe226E8C97E);
    EtherShareLike ESL = EtherShareLike(0x43820f75F021C34Ce13DeD1595633ed39b79ab47);
    EtherShareReward ESR = EtherShareReward(0x28daa51dC3D80A951af9C451D174F0c7156c6876);
    
    struct oneQuery {
        address sender;
        string nickname;
        uint timestamp;
        bool AllowUpdated;
        string content;
        uint like;
        uint reward;
    }
    
    function get(uint ShareID, uint ReplyID) view public returns (oneQuery memory) {
        uint timestamp;
        address sender; 
        string memory nickname;
        string memory content;
        bool AllowUpdated;
        uint like;
        uint reward;
        
        (sender, nickname, timestamp, AllowUpdated, content) = ES.allShare(ShareID, ReplyID);
        like = ESL.allLike(ShareID, ReplyID);
        reward = ESR.getSum(ShareID, ReplyID);
        
        oneQuery memory answer = oneQuery(sender, nickname, timestamp, AllowUpdated, content, like, reward);
        
        return answer;
    }
}