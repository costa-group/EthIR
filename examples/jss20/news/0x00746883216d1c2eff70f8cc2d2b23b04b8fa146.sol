pragma solidity 0.6.2;

contract EchoString {
    event Echo(string data);

    function echo(string memory data) public {
        emit Echo(data);
    }
}