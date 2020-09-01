# Burni (based on the ERC-20 specification)
# https://burni.co

from vyper.interfaces import ERC20

implements: ERC20

# Used to verify a transfer into a smart contract.
contract ERC20Receiver:
	def onERC20Received(_from: address, _value: uint256) -> bytes32: modifying

# Events
Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})

allowances: map(address, map(address, uint256))
total_supply: uint256      # 1b
name: public(string[64])   # Burni
symbol: public(string[32]) # BURN
decimals: public(uint256)  # 18 (similar to Wei)
balanceOf: public(map(address, uint256))

@public
def __init__(_name: string[64], _symbol: string[32], _decimals: uint256, _supply: uint256):
	# Define the token and mint the initial supply.
	init_supply: uint256 = _supply * 10 ** _decimals

	self.name = _name
	self.symbol = _symbol
	self.decimals = _decimals
	self.balanceOf[msg.sender] = init_supply
	self.total_supply = init_supply
	log.Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@public
@constant
def totalSupply() -> uint256:
	# The total supply will gradually decrease as tokens are burnt.
	return self.total_supply

@public
@constant
def allowance(_owner: address, _spender: address) -> uint256:
	# Check the amount of Burni allowed to a spender.
	return self.allowances[_owner][_spender]

@public
def transfer(_to: address, _value: uint256) -> bool:
	# Transfer from msg.sender to _to (reverts on insufficient msg.sender balance.)
	self.balanceOf[msg.sender] -= _value
	self.balanceOf[_to] += _value

	if _to.is_contract:
		# Check the method signature when transfering tokens to a contract (eg. Burnin).
		returnValue: bytes32 = ERC20Receiver(_to).onERC20Received(msg.sender, _value)
		assert returnValue == method_id("onERC20Received(address,uint256)", bytes32)

	# Emit Transfer event.
	log.Transfer(msg.sender, _to, _value)
	return True

@public
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
	# Transfer from one account to another (reverts if insufficient allowance or funds.)
	self.allowances[_from][msg.sender] -= _value
	self.balanceOf[_from] -= _value
	self.balanceOf[_to] += _value
	log.Transfer(_from, _to, _value)
	return True

@public
def approve(_spender: address, _value: uint256) -> bool:
	# Approve a new spender / burner.
	self.allowances[msg.sender][_spender] = _value
	log.Approval(msg.sender, _spender, _value)
	return True

@private
def _burn(_to: address, _value: uint256):
	# Removes tokens from circulation (only 2.5% are spared with Burnin minting).
	assert _to != ZERO_ADDRESS
	self.total_supply -= _value
	self.balanceOf[_to] -= _value
	log.Transfer(_to, ZERO_ADDRESS, _value)

@public
def burn(_value: uint256):
	# Burn the tokens, reducing the total supply.
	self._burn(msg.sender, _value)

@public
def burnFrom(_to: address, _value: uint256):
	# Burn from an allowed burner.
	self.allowances[_to][msg.sender] -= _value
	self._burn(_to, _value)