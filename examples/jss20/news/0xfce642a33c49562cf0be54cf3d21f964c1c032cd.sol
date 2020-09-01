pragma solidity 0.5.0;

contract DappHeroTest {
    uint public important = 20;
    bytes32 public hello = "hello";
    uint public fee = 1 ether / 100;
    
    function viewNoArgsMultipleReturn() public view returns(uint _important, bytes32 _hello){
        return (
            important,
            hello
        );
    }
    
    function viewMultipleArgsSingleReturn(address from, uint multiplier) public view returns(uint _balanceMultiplied){
        return address(from).balance * multiplier;
    }
    
    function viewMultipleArgsMultipleReturn(address from, uint multiplier) public view returns(uint _balanceMultiplied, bytes32 _hello){
        return (
            address(from).balance * multiplier,
            hello
        );
    }

    event EventTrigger(address indexed sender, uint value);
    event ValueSent(address indexed sender);
    event ValueSentWithMessage(address indexed sender, bytes32 message);

    function triggerEvent(uint value) public {
        emit EventTrigger (msg.sender, value);
    }

    modifier isCorrectFee() {
        require(msg.value == fee);
        _;
    }

    function sendEthNoArgs() isCorrectFee public payable {
        emit ValueSent(msg.sender);
    }

    function sendEthWithArgs(bytes32 message) isCorrectFee public payable {
        emit ValueSentWithMessage(msg.sender, message);
    }

    function sendVariableEthNoArgs() public payable {
        require(msg.value > fee / 10);
        emit ValueSent(msg.sender);
    }

    function sendVariableEthWithArgs(bytes32 message) public payable {
        require(msg.value > fee / 10);
        emit ValueSentWithMessage(msg.sender, message);
    }
}