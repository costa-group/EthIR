pragma solidity ^0.5.0;


contract ViewCallGasLimit {
    function check() public view returns(uint256) {
        return gasleft();
    }
}