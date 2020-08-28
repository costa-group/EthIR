# Burnin (based on the ERC-721 specification)
# https://burni.co

from vyper.interfaces import ERC721

implements: ERC721

# Used to verify a transfer into a NFT-ready smart contract.
contract BurninReceiver:
	def onERC721Received(_operator: address, _from: address, _tokenId: uint256, _data: bytes[1024]) -> bytes32: modifying

# Used to verify a transfer into the Burni smart contract.
contract Burni:
	def transfer(_to: address, _value: uint256) -> bool: modifying
	def burn(_value: uint256): modifying

# Events
Transfer: event({_from: indexed(address), _to: indexed(address), _tokenId: indexed(uint256)})
Approval: event({_owner: indexed(address), _approved: indexed(address), _tokenId: indexed(uint256)})
ApprovalForAll: event({_owner: indexed(address), _operator: indexed(address), _approved: bool})
Immutable_Multihash: event({_from: indexed(address), _hash: string[256], _tokenId: indexed(uint256)})

name: public(string[6])     # Burnin
symbol: public(string[6])   # BURNIN
decimals: public(uint256)   # 0
idToOwner: map(uint256, address)                       # Id -> Owner address
idToApprovals: map(uint256, address)                   # Id -> Spender address
idToImmutableMultihash: map(uint256, string[256])      # Id -> Permanent multihash
idToValuation: map(uint256, uint256)                   # Id -> Burni used to mint token
idToOwnerIdx: map(uint256, uint256)                    # Id -> Index of token (relative to owner)
immutableHashToId: map(string[256], uint256)           # Permanent multihash -> Id
ownerIdxToTokenId: map(address, map(uint256, uint256)) # Index of token (relative to owner) -> Id
ownerToNFTokenCount: map(address, uint256)             # Total supply of tokens for an address
ownerToOperators: map(address, map(address, bool))     # Owner address -> Operator address -> isOperator
supportedInterfaces: map(bytes32, bool)                # Interface -> isSupported

# Supported Interface Ids
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd
ERC721_METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f
ERC721_ENUMERABLE_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000780e9d63

burni_address: address
payment_address: address
total_supply: uint256
base_uri: string[64]

@public
def __init__():
	# Define the token
	self.name = 'Burnin'
	self.symbol = 'BURNIN'
	self.decimals = 0
	self.total_supply = 0
	self.base_uri = 'https://burni.co/nft/'

	self.supportedInterfaces[ERC165_INTERFACE_ID] = True
	self.supportedInterfaces[ERC721_INTERFACE_ID] = True
	self.supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = True
	self.supportedInterfaces[ERC721_ENUMERABLE_INTERFACE_ID] = True

	# Associate the token with the Burni smart contract and operator address.
	self.payment_address = 0x7bde389181EC80591ED40E011b0Ff576a2Beb74b
	self.burni_address = 0x076a7c93343579355626F1426dE63F8827C9b9B2

@public
@constant
def baseTokenURI() -> string[64]:
	# Returns the base URI address for Burnin tokens.
	return self.base_uri

@public
@constant
def tokenURI(_tokenId: uint256) -> string[320]:
	# Returns the URI address for the specified token (throws if owner is zero).
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS

	multihash: string[256] = self.idToImmutableMultihash[_tokenId]
	if multihash == '': return self.base_uri

	return concat(self.base_uri, multihash)

@public
@constant
def exists(_tokenId: uint256) -> bool:
	# Checks if a token exists.
	owner: address = self.idToOwner[_tokenId]
	return owner != ZERO_ADDRESS

@public
@constant
def totalSupply() -> uint256:
	# The total supply of Burnin will gradually increase as tokens are created from Burni.
	return self.total_supply

@public
@constant
def supportsInterface(_interfaceID: bytes32) -> bool:
	# Returns the supported ERC-165 interface ids.
	return self.supportedInterfaces[_interfaceID]

@public
@constant
def balanceOf(_owner: address) -> uint256:
	# Returns the total Burnins owned by an address (throws if owner is zero).
	assert _owner != ZERO_ADDRESS
	return self.ownerToNFTokenCount[_owner]

@public
@constant
def ownerOf(_tokenId: uint256) -> address:
	# Returns the owner of a Burnin token by id (throws if owner is zero).
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	return owner

@public
@constant
def tokenByIndex(_index: uint256) -> uint256:
	# Tokens are numbered with 1-based indexing (throws if 0-based index is >= supply).
	assert _index < self.total_supply
	return _index + 1

@public
@constant
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
	# Returns the token id by an owner's token index (throws if owner is zero or index >= supply).
	assert _owner != ZERO_ADDRESS
	assert _index < self.ownerToNFTokenCount[_owner]
	return self.ownerIdxToTokenId[_owner][_index]

@public
@constant
def getApproved(_tokenId: uint256) -> address:
	# Returns approved spender for a Burnin token (throws if owner is zero).
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS
	return self.idToApprovals[_tokenId]

@public
@constant
def getValuation(_tokenId: uint256) -> uint256:
	# Returns the Burni used to create the Burnin @ 97.5% of the total Burni tx cost (throws if invalid token).
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS
	return self.idToValuation[_tokenId]

@public
@constant
def getImmutableMultihashOf(_tokenId: uint256) -> string[256]:
	# Returns the permanent multihash for an id (throws if owner is zero).
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	return self.idToImmutableMultihash[_tokenId]

@public
@constant
def isApprovedForAll(_owner: address, _operator: address) -> bool:
	# Checks if an operator is approved for the specified owner.
	return (self.ownerToOperators[_owner])[_operator]

@private
@constant
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
	# Checks if the given spender can transfer a specified token.
	owner: address = self.idToOwner[_tokenId]
	spenderIsOwner: bool = owner == _spender
	spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
	spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
	return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

@private
def _addTokenTo(_to: address, _tokenId: uint256):
	# Adds a token to a new owner (throws if owner is zero).
	assert self.idToOwner[_tokenId] == ZERO_ADDRESS
	self.idToOwner[_tokenId] = _to
	self.idToOwnerIdx[_tokenId] = self.ownerToNFTokenCount[_to]
	self.ownerIdxToTokenId[_to][self.ownerToNFTokenCount[_to]] = _tokenId
	self.ownerToNFTokenCount[_to] += 1

@private
def _removeTokenFrom(_from: address, _tokenId: uint256):
	# Removes a token from a previous owner (throws if the token belongs to another owner).
	assert self.idToOwner[_tokenId] == _from
	self.idToOwner[_tokenId] = ZERO_ADDRESS

	# Checks the owner's token index and reindexes if necessary.
	tokenIdx: uint256 = self.idToOwnerIdx[_tokenId]
	lastTokenIdx: uint256 = self.ownerToNFTokenCount[_from] - 1

	if self.ownerToNFTokenCount[_from] > 1 and tokenIdx < lastTokenIdx:
		# When an inner token is removed, fill the gap using the last token.
		lastTokenId: uint256 = self.ownerIdxToTokenId[_from][lastTokenIdx]
		self.ownerIdxToTokenId[_from][tokenIdx] = lastTokenId
		self.ownerIdxToTokenId[_from][lastTokenIdx] = 0

	self.ownerToNFTokenCount[_from] -= 1

@private
def _clearApproval(_owner: address, _tokenId: uint256):
	# Clear an approval for a specified address (throws if the token belongs to another owner).
	assert self.idToOwner[_tokenId] == _owner
	if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
		self.idToApprovals[_tokenId] = ZERO_ADDRESS

@private
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
	# Transfer to a new owner (throws if unauthorized or invalid recipient).
	assert self._isApprovedOrOwner(_sender, _tokenId)
	assert _to != ZERO_ADDRESS
	self._clearApproval(_from, _tokenId)
	self._removeTokenFrom(_from, _tokenId)
	self._addTokenTo(_to, _tokenId)
	log.Transfer(_from, _to, _tokenId)

@public
def transferFrom(_from: address, _to: address, _tokenId: uint256):
	# Transfer a Burnin token.
	self._transferFrom(_from, _to, _tokenId, msg.sender)

@public
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: bytes[1024]=""):
	# Transfer to a new owner or smart contract (throws if unauthorized or invalid recipient).
	self._transferFrom(_from, _to, _tokenId, msg.sender)
	if _to.is_contract:
		returnValue: bytes32 = BurninReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
		assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", bytes32)

@public
def approve(_approved: address, _tokenId: uint256):
	# Approve an address for a token (throws if the owner is zero or unauthorized).
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	assert _approved != owner
	senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
	senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
	assert (senderIsOwner or senderIsApprovedForAll)
	self.idToApprovals[_tokenId] = _approved
	log.Approval(owner, _approved, _tokenId)

@public
def clearApproval(_from: address, _tokenId: uint256):
	# Removes an approval address (throws if the token is invalid or belongs to another owner).
	owner: address = self.idToOwner[_tokenId]
	assert owner != ZERO_ADDRESS
	assert owner == msg.sender
	self._clearApproval(_from, _tokenId)

@public
def setApprovalForAll(_operator: address, _approved: bool):
	# Approves an operator for an owner's assets (throws if self-approving).
	assert _operator != msg.sender
	self.ownerToOperators[msg.sender][_operator] = _approved
	log.ApprovalForAll(msg.sender, _operator, _approved)

@public
def setImmutableMultihash(_hash: string[256], _tokenId: uint256):
	# Sets a permanent multihash (throws if invalid/predefined hash or the token belongs to another owner).
	assert self.idToOwner[_tokenId] == msg.sender
	assert _hash != ''
	assert self.idToImmutableMultihash[_tokenId] == ''
	assert self.immutableHashToId[_hash] == 0
	self.idToImmutableMultihash[_tokenId] = _hash
	log.Immutable_Multihash(msg.sender, _hash, _tokenId)

@public
def updatePaymentAddress(_payment_address: address):
	# Admin function to change the 2.5% tx fee if necessary (eg. wallet change).
	assert msg.sender == self.payment_address
	self.payment_address = _payment_address

@public
def updateBaseTokenURI(_baseURI: string[64]):
	# Admin function to change baseTokenURI if necessary (eg. domain change).
	assert msg.sender == self.payment_address
	self.base_uri = _baseURI

@public
def onERC20Received(_from: address, _value: uint256) -> bytes32:
	# Mint if 40+ Burni are received (throws if unauthorized or insufficient funds).
	assert msg.sender == self.burni_address
	assert _value >= 40

	# 2.5% of the total Burni are spared.
	fee: uint256 = _value / 40
	valuation: uint256 = _value - fee
	didPayFee: bool = Burni(self.burni_address).transfer(self.payment_address, fee)
	Burni(self.burni_address).burn(valuation)
	assert didPayFee

	# Create token
	self.total_supply += 1
	self.idToValuation[self.total_supply] = valuation
	self._addTokenTo(_from, self.total_supply)

	# Handshake with Burni smart contract.
	return method_id("onERC20Received(address,uint256)", bytes32)