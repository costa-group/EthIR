pragma solidity 0.5.6;

contract Digital_Identity {
  string public name = "Digital Identity Blockchain";
  mapping(address => Identity) public identities;

  struct Identity {
    address did;
    string contentAddress;
  }

  function createIdentity(string memory _contentAddress) public {
    require(bytes(_contentAddress).length > 0, 'Invalid address');
    identities[msg.sender] = Identity(msg.sender, _contentAddress);
  }
}