Iou: event({_to: address})

@public
def iou(_to: address):
	# Emit a stateless IOU event from msg.sender -> _to.
	log.Iou(_to)