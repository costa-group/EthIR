contract UniversalDeployer {
    event Created(address _contract) anonymous;

    function create2(bytes memory _code, uint256 _salt) public payable returns (address _addr) {
        assembly { _addr := create2(callvalue(), add(_code, 32), mload(_code), _salt) }
        emit Created(_addr);
    }
}