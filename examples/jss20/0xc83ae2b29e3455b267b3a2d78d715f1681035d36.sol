/**
 *Submitted for verification at Etherscan.io on 2019-02-26
*/

pragma solidity ^0.4.23;

contract Maxidice {
    uint public minNumber = 1;
    uint public maxNumber = 6;
    uint public maxRoomPlayers = 6;
    uint256 public totalPotWin = 0;
    uint256 public largestAmountWin = 0;
    uint256 public profit = 0;
    address constant public adminAddress = 0x0A8a8c178E97f8D50262838c6A5E3069C2143425;
    

    struct Player {
        uint256 profit;
        uint numberSelected;
        uint256 amountBet;
    }

    struct Room {
        uint roomState;
        string roomId;
        uint currentPlayers;
        uint256 totalAmountBetting;
        uint256 minBet;
        uint lostNumber;
        address[] players;
        address roomMaster;
        mapping (address => Player) playersInfo;
    }

    mapping (string => Room) rooms;
    string[] roomIds;
    
    event PlayerBet(string roomId);
    event GameFinished(string roomId, uint loseNumber);
    event RoomOpened(string roomId);
    event StartOver(string roomId, string nRoomId);
    
    function createRoom(string roomId) public returns(bool) {
        Room memory nRoom;
        Player memory p;
        nRoom.roomState = 1;
        nRoom.roomId = roomId;
        nRoom.totalAmountBetting = 0;
        nRoom.currentPlayers = 1;
        nRoom.roomMaster = msg.sender;
        rooms[roomId] = nRoom;
        p.profit = 0;
        p.numberSelected = 1;
        rooms[roomId].playersInfo[msg.sender] = p;
        rooms[roomId].players.push(msg.sender);
        roomIds.push(roomId);
        emit RoomOpened(roomId);
        return true;
    }

    function getRooms() public view returns(string) {
        string memory rIds;
        if (roomIds.length < 1) {
            return rIds;
        }
        for (uint256 i = 0; i < roomIds.length; i++) {
            string memory roomId = roomIds[i];
            Room memory room = rooms[roomId];
            string memory roomLabel = string(abi.encodePacked(roomId, ":", uint2str(room.currentPlayers)));
            if (i > 0) {
                rIds = string(abi.encodePacked(rIds, ","));
            }
            rIds = string(abi.encodePacked(rIds, roomLabel));
        }
        return rIds;
    }

    function getRoomBasicInfo(string roomId) public view returns(string, string, uint, uint256, uint256, uint) {
        if (checkRoomExists(roomId) == false) {
            return ("", "", 0, 0, 0, 0);
        }
        Room memory r = rooms[roomId];
        return (r.roomId, add2str(r.roomMaster), r.currentPlayers, r.totalAmountBetting, r.minBet, r.lostNumber);
    }

    function getRoomPlayers(string roomId) public view returns(string) {
        string memory result = "";
        if (checkRoomExists(roomId) == false) {
            return result;
        }
        for (uint i = 0; i < rooms[roomId].players.length; i++) {
            string memory playerStr = add2str(rooms[roomId].players[i]);
            Player memory p = rooms[roomId].playersInfo[rooms[roomId].players[i]];
            playerStr = string(abi.encodePacked(playerStr, ":", uint2str(p.numberSelected), ":", uint2str(p.amountBet)));
            if (i > 0) {
                result = string(abi.encodePacked(result, ","));
            }
            result = string(abi.encodePacked(result, playerStr));
        }
        return result;
    }

    function checkRoomExists(string roomId) internal view returns(bool) {
        if (rooms[roomId].roomState > 0) {
            return true;
        }
        return false;
    }

    function bet(string roomId) public payable returns(bool){
        require(checkRoomExists(roomId), "room is not exist");
        Player memory p = rooms[roomId].playersInfo[msg.sender];
        if (p.numberSelected == 0 && p.amountBet == 0) {
            rooms[roomId].currentPlayers += 1;
            rooms[roomId].players.push(msg.sender);
        }
        if (rooms[roomId].minBet == 0) {
            rooms[roomId].minBet = msg.value;
        }
        if (p.numberSelected == 0) {
            p.numberSelected = rooms[roomId].currentPlayers;
        }
        if (p.amountBet == 0) {
            p.amountBet = msg.value;
            rooms[roomId].totalAmountBetting += msg.value;
        }
        
        rooms[roomId].playersInfo[msg.sender] = p;
        emit PlayerBet(roomId);
        return true;
    }

    function startGame(string memory roomId) public returns(uint256){
        uint256 numberGenerated = block.number % 6 + 1;
        rooms[roomId].lostNumber = numberGenerated;
        distributePrizes(roomId, numberGenerated);
        emit GameFinished(roomId, numberGenerated);
        return numberGenerated;
    }

    function distributePrizes(string roomId, uint256 loseNumber) public {
        address[100] memory winners;
        Room storage room = rooms[roomId];
        uint256 totalBetWon = (room.totalAmountBetting * 98) / 100;
        profit += totalBetWon;
        totalPotWin += totalBetWon;
        if (largestAmountWin < totalBetWon) {
            largestAmountWin = totalBetWon;
        }
        uint count = 0;
        for (uint256 i = 0; i < room.players.length; i++) {
            address playerAddr = room.players[i];
            if (room.playersInfo[playerAddr].numberSelected != loseNumber) {
                winners[count] = playerAddr;
                count++;
            }
        }
        for (uint j = 0; j < count; j++) {
            if (winners[j] != address(0)) {
                winners[j].transfer(totalBetWon / count);
            }
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function add2str(address x) internal pure returns(string) {
        bytes32 value = bytes32(uint256(x));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function StartGameOver(string roomId, string nRoomId) public returns(bool) {
        Room memory nRoom;
        Player memory p;
        nRoom.roomState = 1;
        nRoom.roomId = nRoomId;
        nRoom.totalAmountBetting = 0;
        nRoom.currentPlayers = 1;
        nRoom.minBet = rooms[roomId].minBet;
        nRoom.roomMaster = msg.sender;
        rooms[nRoomId] = nRoom;
        p.profit = 0;
        p.numberSelected = 1;
        rooms[nRoomId].playersInfo[msg.sender] = p;
        rooms[nRoomId].players.push(msg.sender);
        roomIds.push(nRoomId);
        emit StartOver(roomId, nRoomId);
        return true;
    }
    event EtherWithdraw(uint amount, address sendTo);

    function withdrawAll(uint amount, address sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        // emit EtherWithdraw(amount, sendTo);
    }
    modifier onlyAdmin() {
        assert(msg.sender == adminAddress);
        _;
    }
}