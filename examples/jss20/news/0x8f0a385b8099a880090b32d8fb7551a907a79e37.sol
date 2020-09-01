# { SentBy: { ReceivedBy: Amount } }
iou_out: map(address, map(address, uint256))

# { ReceivedBy: { SentBy: Amount } }
iou_in: map(address, map(address, uint256))

# { Address: TotalAmountSent }
iou_out_total: map(address, uint256)

# { Address: TotalAmountReceived }
iou_in_total: map(address, uint256)

@public
def iou(_to: address):
	if self.iou_out[_to][msg.sender] > 0:
		# Reverse debt.
		self.iou_out[_to][msg.sender] -= 1
		self.iou_out_total[_to] -= 1
		self.iou_in[msg.sender][_to] -= 1
		self.iou_in_total[msg.sender] -= 1
	else:
		# Add debt.
		self.iou_out[msg.sender][_to] += 1
		self.iou_out_total[msg.sender] += 1
		self.iou_in[_to][msg.sender] += 1
		self.iou_in_total[_to] += 1

@public
def balance_out(_sender: address, _recipient: address) -> uint256:
	# Returns the IOUs _sender has sent to _recipient.
	return self.iou_out[_sender][_recipient]

@public
def balance_in(_recipient: address, _sender: address) -> uint256:
	# Returns the IOUs _recipient has received from _sender.
	return self.iou_in[_recipient][_sender]

@public
def balance_out_total(_address: address) -> uint256:
	# Returns the total outstanding IOUs by _address.
	return self.iou_out_total[_address]

@public
def balance_in_total(_address: address) -> uint256:
	# Returns the total incoming IOUs by _address.
	return self.iou_in_total[_address]