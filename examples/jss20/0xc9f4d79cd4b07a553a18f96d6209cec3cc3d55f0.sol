from vyper.interfaces import ERC721

implements: ERC721

contract ERC721Receiver:
	def onERC721Received(_operator: address, _from: address, _tokenId: uint256, _data: bytes[1024]) -> bytes32: modifying

contract ERC20:
	def transfer(_to: address, _value: uint256) -> bool: modifying
	def burn(_value: uint256): modifying

Transfer: event({_from: indexed(address), _to: indexed(address), _tokenId: indexed(uint256)})
Approval: event({_owner: indexed(address), _approved: indexed(address), _tokenId: indexed(uint256)})
ApprovalForAll: event({_owner: indexed(address), _operator: indexed(address), _approved: bool})
Immutable_IPFS_SHA3_256: event({_from: indexed(address), _hash: bytes[64], _tokenId: indexed(uint256)})
Mutable_IPFS_SHA3_256: event({_from: indexed(address), _hash: bytes[64], _tokenId: indexed(uint256)})

name: public(string[64])
symbol: public(string[32])
tokenURI: public(string[64])
idToOwner: map(uint256, address)
idToApprovals: map(uint256, address)
idToImmutableIPFS_SHA3_256: map(uint256, bytes[64])
idToMutableIPFS_SHA3_256: map(uint256, bytes[64])
idToValuation: map(uint256, uint256)
immutableHashToId: map(bytes[64], uint256)
ownerIdxToTokenId: map(address, map(uint256, uint256))
ownerToNFTokenCount: map(address, uint256)
ownerToOperators: map(address, map(address, bool))
supportedInterfaces: map(bytes32, bool)
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd
ERC20_ADDRESS: constant(address) = 0x64D56f087d87CdaeaC8119C69c48D0d440D560a7
payment_address: address
nonce: uint256
total_supply: uint256

@public
def __init__(_name: string[64], _symbol: string[32], _tokenURI: string[64]):
	self.supportedInterfaces[ERC165_INTERFACE_ID] = True
	self.supportedInterfaces[ERC721_INTERFACE_ID] = True
	self.payment_address = msg.sender
	self.name = _name
	self.symbol = _symbol
	self.tokenURI = _tokenURI

@public
@constant
def totalSupply() -> uint256:
	return self.total_supply

@public
@constant
def supportsInterface(_interfaceID: bytes32) -> bool:
	return self.supportedInterfaces[_interfaceID]

@public
@constant
def balanceOf(_owner: address) -> uint256:
	assert _owner != ZERO_ADDRESS
	return self.ownerToNFTokenCount[_owner]

@public
@constant
def ownerOf(_tokenId: uint256) -> address:
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	return owner

@public
@constant
def tokenByIndex(_index: uint256) -> uint256:
	assert _index < self.total_supply
	return _index

@public
@constant
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
	assert _owner != ZERO_ADDRESS
	assert _index < self.ownerToNFTokenCount[_owner]
	return self.ownerIdxToTokenId[_owner][_index]

@public
@constant
def getApproved(_tokenId: uint256) -> address:
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS
	return self.idToApprovals[_tokenId]

@public
@constant
def getValuation(_tokenId: uint256) -> uint256:
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS
	return self.idToValuation[_tokenId]

@public
@constant
def getImmutableHashOf(_tokenId: uint256) -> bytes[64]:
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	return self.idToImmutableIPFS_SHA3_256[_tokenId]

@public
@constant
def getMutableHashOf(_tokenId: uint256) -> bytes[64]:
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	return self.idToMutableIPFS_SHA3_256[_tokenId]

@public
@constant
def isApprovedForAll(_owner: address, _operator: address) -> bool:
	return (self.ownerToOperators[_owner])[_operator]

@private
@constant
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
	owner: address = self.idToOwner[_tokenId]
	spenderIsOwner: bool = owner == _spender
	spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
	spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
	return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

@private
def _addTokenTo(_to: address, _tokenId: uint256):
	assert self.idToOwner[_tokenId] == ZERO_ADDRESS
	self.idToOwner[_tokenId] = _to
	self.ownerIdxToTokenId[_to][self.ownerToNFTokenCount[_to]] = _tokenId
	self.ownerToNFTokenCount[_to] += 1

@private
def _removeTokenFrom(_from: address, _tokenId: uint256):
	assert self.idToOwner[_tokenId] == _from
	self.idToOwner[_tokenId] = ZERO_ADDRESS
	self.ownerToNFTokenCount[_from] -= 1

@private
def _clearApproval(_owner: address, _tokenId: uint256):
	assert self.idToOwner[_tokenId] == _owner
	if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
		self.idToApprovals[_tokenId] = ZERO_ADDRESS

@private
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
	assert self._isApprovedOrOwner(_sender, _tokenId)
	assert _to != ZERO_ADDRESS
	self._clearApproval(_from, _tokenId)
	self._removeTokenFrom(_from, _tokenId)
	self._addTokenTo(_to, _tokenId)
	log.Transfer(_from, _to, _tokenId)

@public
def transferFrom(_from: address, _to: address, _tokenId: uint256):
	self._transferFrom(_from, _to, _tokenId, msg.sender)

@public
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: bytes[1024]=""):
	self._transferFrom(_from, _to, _tokenId, msg.sender)
	if _to.is_contract:
		returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
		assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", bytes32)

@public
def approve(_approved: address, _tokenId: uint256):
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	assert _approved != owner
	senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
	senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
	assert (senderIsOwner or senderIsApprovedForAll)
	self.idToApprovals[_tokenId] = _approved
	log.Approval(owner, _approved, _tokenId)

@public
def setApprovalForAll(_operator: address, _approved: bool):
	assert _operator != msg.sender
	self.ownerToOperators[msg.sender][_operator] = _approved
	log.ApprovalForAll(msg.sender, _operator, _approved)

@public
def setImmutableHash(_hash: bytes[64], _tokenId: uint256):
	assert self.idToOwner[_tokenId] == msg.sender
	assert _hash != ''
	assert self.idToMutableIPFS_SHA3_256[_tokenId] == ''
	assert self.immutableHashToId[_hash] == 0
	self.idToMutableIPFS_SHA3_256[_tokenId] = _hash
	log.Mutable_IPFS_SHA3_256(msg.sender, _hash, _tokenId)

@public
def setMutableHash(_hash: bytes[64], _tokenId: uint256):
	assert self.idToOwner[_tokenId] == msg.sender
	assert _hash != ''
	self.idToMutableIPFS_SHA3_256[_tokenId] = _hash
	log.Mutable_IPFS_SHA3_256(msg.sender, _hash, _tokenId)

@public
def updateTokenURI(_tokenURI: string[64]):
	assert msg.sender == self.payment_address
	self.tokenURI = _tokenURI

@public
def onERC20Received(_from: address, _value: uint256) -> bytes32:
	assert msg.sender == ERC20_ADDRESS
	assert _value >= 20

	fee: uint256 = _value / 20
	valuation: uint256 = _value - fee
	didPayFee: bool = ERC20(ERC20_ADDRESS).transfer(self.payment_address, fee)
	ERC20(ERC20_ADDRESS).burn(fee)
	assert didPayFee

	self.idToValuation[self.nonce] = valuation
	self._addTokenTo(_from, self.nonce)
	self.nonce += 1
	self.total_supply += 1

	return method_id("onERC20Received(address,uint256)", bytes32)