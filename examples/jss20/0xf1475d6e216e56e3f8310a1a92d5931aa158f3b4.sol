pragma solidity ^0.4.25;


contract Proxy {
    function execute(
        address target, uint256 weiValue, bytes payload
    ) public {
        target.call.value(weiValue)(payload);
    }

    function () public payable {}

    function tokenFallback(address, uint256, bytes) public pure {}
}