pragma solidity >=0.4.18;

contract aNonEventManagement {

    address owner;

    constructor() public {
                owner = msg.sender;
    }

    struct Event {
        string eventDescription;
        bytes32[] eventRegistrations;
    }

    mapping (uint => Event) events;
    uint[] public EventsList;

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

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function quotesCover(string memory text) internal pure returns (string memory) {
        return append("\"", text, "\"" );
    }

    function appendJSONItem(string memory text, string memory key, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(text,"{",quotesCover("id"),":", quotesCover(key), ",",
        quotesCover("desc"),":", quotesCover(value),"}"));
    }

    function setEvent(string memory _eventDescription) public {
        uint _id  = EventsList.length+1;
        events[_id].eventDescription = _eventDescription;
        EventsList.push(_id) -1;
    }

    function getInfoAboutEvents() view public returns (string memory){
        string memory result = "[";
        for (uint i=0; i<EventsList.length; i++) {
            string memory _identifier = uint2str(i+1);
            string memory _description = events[i+1].eventDescription;
            result = appendJSONItem(result, _identifier, _description);
            if (i+1<EventsList.length) {
                result = append(result,",","");
            }
        }
        result = append(result, "]", "");
        return (result);
    }


    event registrationStatus(string message);

    function eventRegistration(uint _id, string memory _phone) public {
        bool _alreadyRegistered = false;
        string memory _message = "";
        bytes32 _encodedphone = keccak256(abi.encode(_phone));
        for(uint i=0; i<events[_id].eventRegistrations.length; i++) {
            if ((events[_id].eventRegistrations[i]) == _encodedphone) {
                _alreadyRegistered = true;
                break;
            }
        }
        if (_alreadyRegistered == true) {
            _message = "member is already registered on this event";
        } else {
            events[_id].eventRegistrations.push(_encodedphone);
            _message = "successfully registered on event";
        }
        emit registrationStatus(_message);
    }


    event IsRegistered(bool status);

    function checkMember(uint _id, string memory _phone) public returns (bool) {
        bool result = false;
        for(uint i=0; i<events[_id].eventRegistrations.length; i++) {
            if ((events[_id].eventRegistrations[i]) == keccak256(abi.encode(_phone))) {
                result = true;
                break;
            }
        }
        emit IsRegistered(result);
        return (result);
    }

}