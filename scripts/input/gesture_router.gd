extends RefCounted

var pointer: int = -1
var origin := Vector2.ZERO

func begin(id: int, position: Vector2) -> void:
	if pointer != -1:
		return
	pointer = id
	origin = position

func cancel() -> void:
	pointer = -1

func finish(id: int, position: Vector2) -> String:
	if id != pointer or pointer == -1:
		return ""
	var difference: Vector2 = position - origin
	cancel()
	if difference.length() < 32.0:
		return ""
	# Every deliberate swipe snaps to its dominant axis; dropping a near-45°
	# gesture would fire a tap attack and leave the runner in the wrong lane.
	# Exact ties break vertical — a jump/slide misfire beats a lane change
	# into traffic.
	if absf(difference.x) > absf(difference.y):
		return "right" if difference.x > 0 else "left"
	return "slide" if difference.y > 0 else "jump"
