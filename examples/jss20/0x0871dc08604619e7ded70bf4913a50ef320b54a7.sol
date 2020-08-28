pragma solidity ^0.6.0;

abstract contract Resolver {
    function get(string memory key, uint256 tokenId) public virtual view returns (string memory);
}

contract CryptoToken {
    uint256 private constant _CRYPTO_HASH =
        0x0f4a10a4f46c288cea365fcf45cccf0e9d901b945b9829ccdb54c10dc3cb7a6f;
    address private constant _RESOLVER = 0xA1cAc442Be6673C49f8E74FFC7c4fD746f3cBD0D;
    function root() public pure returns (uint256) {
        return _CRYPTO_HASH;
    }  
    function resolver() public pure returns(address) {
        return _RESOLVER;
    }
    fallback() external{}
    
    function getTokenId(string memory label) public pure returns(uint256) {
        return uint256(keccak256(abi.encodePacked(root(), keccak256(abi.encodePacked(label)))));
    }
    
    function getIpfs(uint256 tokenId) public view returns(string memory) {
        return Resolver(resolver()).get("ipfs.html.value",tokenId);
    }

}