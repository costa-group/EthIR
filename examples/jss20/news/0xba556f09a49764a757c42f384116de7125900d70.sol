# IOU balance between two accounts.
ious: map(address, map(address, int128))

@public
def iou(_to: address):
	# Adds 1 IOU, sorted by address.
	assert _to != msg.sender

	if convert(msg.sender, uint256) < convert(_to, uint256):
		self.ious[msg.sender][_to] += 1
	else:
		self.ious[_to][msg.sender] -= 1

@public
def iou_balance(_a: address, _b: address) -> int128:
	# Returns the IOUs from _a -> _b.
	if convert(_a, uint256) < convert(_b, uint256):
		return self.ious[_a][_b]
	return self.ious[_b][_a] * -1