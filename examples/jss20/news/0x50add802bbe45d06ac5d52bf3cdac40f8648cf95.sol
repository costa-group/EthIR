pragma solidity ^0.5.0;

library StringHelpers {

    function toString(address _address) public pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
        }
        return string(b);
    }

}