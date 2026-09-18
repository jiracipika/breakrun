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
	if absf(difference.x) > absf(difference.y) * 1.15:
		return "right" if difference.x > 0 else "left"
	if absf(difference.y) > absf(difference.x) * 1.15:
		return "slide" if difference.y > 0 else "jump"
	return ""
