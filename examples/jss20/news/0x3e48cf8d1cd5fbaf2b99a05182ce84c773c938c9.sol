# Event
Iou: event({_from: address, _to: address})

# IOU balance between two accounts.
ious: map(address, map(address, int128))

@public
def iou(_to: address):
	# Avoid self-referential calls.
	assert _to != msg.sender

	# Adds 1 IOU, sorted by address.
	if convert(msg.sender, uint256) < convert(_to, uint256):
		self.ious[msg.sender][_to] += 1
	else:
		self.ious[_to][msg.sender] -= 1

	# Log event.
	log.Iou(msg.sender, _to)

@public
def iou_balance(_a: address, _b: address) -> int128:
	# Returns the IOUs from _a -> _b.
	if convert(_a, uint256) < convert(_b, uint256):
		return self.ious[_a][_b]
	return self.ious[_b][_a] * -1