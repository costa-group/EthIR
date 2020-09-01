pragma solidity ^0.5.0;

interface ENS {
  function owner( bytes32 _node ) external view returns (address);
  function owners( bytes32 _node ) external view returns (address);
}

interface ReverseRegistrar {
  function claim( address _owner ) external returns (bytes32 node);
}

interface ERC20 {
  function balanceOf( address owner ) external view returns (uint);
  function transfer( address _to, uint256 _value ) external returns (bool);
}

contract Resolver {

  event AddrChanged( bytes32 indexed node, address a );
  event PubkeyChanged( bytes32 indexed node, bytes32 x, bytes32 y );

  struct PubKey {
    bytes32 x;
    bytes32 y;
  }

  mapping( bytes32 => address ) public addr;
  mapping( bytes32 => PubKey ) public keys;
  ENS public theENS;
  address payable public beneficiary;

  modifier owns( bytes32 _node ) {
    require( msg.sender == theENS.owners(_node) );
    _;
  }

  // namehash('addr.reverse')
  bytes32 constant REV_ADDR_NODE =
    0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

  function supportsInterface( bytes4 _id ) external pure returns (bool) {
    return    _id == 0x3b3b57de   // addr, EIP137
           || _id == 0xc8690233;  // pubkey, EIP619
  }

  function setAddr( bytes32 _node, address _newAddr ) external owns(_node) {
    addr[_node] = _newAddr;
    emit AddrChanged( _node, _newAddr );
  }

  function pubkey( bytes32 _node ) external view
  returns (bytes32 _x, bytes32 _y) {
    return ( keys[_node].x, keys[_node].y );
  }

  function setPubkey( bytes32 _node, bytes32 _x, bytes32 _y )
  external owns(_node) {
    keys[_node] = PubKey( _x, _y );
    emit PubkeyChanged( _node, _x, _y );
  }

  constructor( address _ens ) public {
    theENS = ENS(_ens);
    beneficiary = msg.sender;
    ReverseRegistrar rr = ReverseRegistrar( theENS.owner(REV_ADDR_NODE) );
    rr.claim( msg.sender ); // give <thissca>.addr.reverse to our deployer
  }

  function () payable external {}

  function sweepEther() external {
    beneficiary.transfer( address(this).balance );
  }

  function sweepToken( address _erc20 ) external {
    ERC20 token = ERC20( _erc20 );
    token.transfer( beneficiary, token.balanceOf(address(this)) );
  }

  function changeBeneficiary( address payable _to ) external {
    require( msg.sender == beneficiary );
    beneficiary = _to;
  }

}