pragma solidity 0.5.16; // optimization runs: 200


interface IDai {
  function permit(
    address holder, address spender, uint256 nonce, uint256 expiry,
    bool allowed, uint8 v, bytes32 r, bytes32 s
  ) external;
  
  function approve(address spender, uint256 amount) external returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  
  function nonces(address account) external view returns (uint256 nonce);
}


interface ISyndicate {
  function enlist(uint256 daiAmount) external;
  
  function transfer(address to, uint256 value) external returns (bool);
}


contract DaiBackstopSyndicateEnlisterV3 {
  bytes32 internal constant _DAI_DOMAIN_SEPARATOR = bytes32(
    0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7
  );

  bytes32 internal constant _DAI_PERMIT_TYPEHASH = bytes32(
    0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb
  );

  IDai internal constant _DAI = IDai(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  ISyndicate internal constant _SYNDICATE = ISyndicate(
    0x00000000357646e36Fe575885Bb3e1A0772E64Cc
  );
  
  constructor() public {
    require(
      _DAI.approve(address(_SYNDICATE), uint256(-1)),
      "DaiBackstopSyndicateEnlisterV1/constructor: Syndicate approval failed."
    );
  }

  function approveAndEnlist(
    uint256 amount, uint256 nonce, uint256 expiry, bytes memory signature
  ) public {
    // Parse the supplied signature.
    bytes32 r; bytes32 s; uint8 v;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Approve this address to transfer Dai on behalf of the caller.
    _DAI.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);

    // Transfer specified Dai amount from the caller to this account.
    require(
      _DAI.transferFrom(msg.sender, address(this), amount),
      "DaiBackstopSyndicateEnlisterV1/approveAndEnlist: Dai transfer in failed."
    );

    // Use the transferred Dai to enlist in the syndicate.
    _SYNDICATE.enlist(amount);

    // Return the newly minted tokens to the caller.
    require(
      _SYNDICATE.transfer(msg.sender, amount),
      "DaiBackstopSyndicateEnlisterV1/approveAndEnlist: Token transfer out failed."
    );
  }

  function getDigest(address enlister) external view returns (
    bytes32 digest, uint256 nonce, uint256 expiry
  ) {
    nonce = _DAI.nonces(enlister); // current nonce
    expiry = block.timestamp + 1800; // 30 minutes
    digest = keccak256(abi.encodePacked(
      "\x19\x01", _DAI_DOMAIN_SEPARATOR, keccak256(abi.encode(
        _DAI_PERMIT_TYPEHASH, enlister, address(this), nonce, expiry, true
      ))
    ));
  }
}