pragma solidity ^0.5.8;

contract Contract {
    mapping (address=>string) ipfsHashes;
    address[] public accts;

    event hashUpdated(string _ipfshash, address _address);

    function setHash(address _address, string memory _ipfshash) public {
        ipfsHashes[_address] = _ipfshash;
        accts.push(_address);
        emit hashUpdated(_ipfshash, _address);
    }

    function getAcctsLength() public view returns(uint256) {
        return accts.length;
    }

    function getHash(address _address) view public returns (string memory ipfshash) {
        return (ipfsHashes[_address]);
    }
}