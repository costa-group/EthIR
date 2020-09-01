pragma solidity 0.5.16;

contract Contract {
    uint256 public a;
    constructor () public {
        a = 1;
    }
}

contract Factory {
    function deploy() public {
        new Contract();
        require(1==2, 'Expected failure');
    }
}