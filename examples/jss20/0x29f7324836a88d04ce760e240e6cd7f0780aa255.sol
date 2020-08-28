pragma solidity 0.5.0;

contract DappHeroTest {
    uint public important = 777;
    bytes32 public hello = "Howdy";
    
    address public owner;
    
    event EventTrigger(address indexed sender, uint value);
    event ValueSent(address indexed sender);
    event EmitString(string message);
    event ValueSentWithMessage(address indexed sender, bytes32 message);

    constructor() public {
       owner = msg.sender;
    }

    function viewNoArgsMultipleReturn() public view returns(uint importantNumber, bytes32 sayHello){
        return (
            importantNumber,
            hello
        );
    }
    
    function viewMultipleArgsSingleReturn(address fromAddress, uint amount) public view returns(uint singleInt){
        return 89898989;
    }
    
    function viewMultipleArgsMultipleReturn(address fromAddress, uint amount) public view returns(uint longInteger, bytes32 sayHello){
        return (
            8989898989,
            hello
        );
    }

    function triggerEvent(uint anyInputValue) public {
        emit EventTrigger (msg.sender, 10);
    }

    function sendEthNoArgs() public payable {
        emit ValueSent(msg.sender);
        msg.sender.transfer(msg.value);
    }
    
    function makeTxNoArgs() public {
        emit EventTrigger(msg.sender, important);
    }
    
    function makeTxWithArgs(string memory myString) public {
        emit EmitString(myString);
    }

    function sendEthWithArgs(bytes32 simpleMessage) public payable {
        emit ValueSentWithMessage(msg.sender, "message");
        msg.sender.transfer(msg.value);
    }

    function sendMinimumTwoEthNoArgs() public payable {
        require(msg.value >= 2);
        emit ValueSent(msg.sender);
        msg.sender.transfer(msg.value);
    }

    function sendMinimumTwoEthWithArgs(bytes32 message) public payable {
        require(msg.value >= 2);
        emit ValueSentWithMessage(msg.sender, message);
        msg.sender.transfer(msg.value);
    }
}