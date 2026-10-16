extends SceneTree

const Router = preload("res://scripts/input/gesture_router.gd")
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _init() -> void:
	var router = Router.new()
	var origin := Vector2(200, 400)
	for case in [[Vector2(100, 0), "right"], [Vector2(-100, 0), "left"], [Vector2(0, -100), "jump"], [Vector2(0, 100), "slide"], [Vector2(10, 0), ""], [Vector2(80, 80), "slide"], [Vector2(80, 70), "right"], [Vector2(70, 80), "slide"], [Vector2(60, -70), "jump"], [Vector2.ZERO, ""]]:
		router.begin(0, origin)
		check(router.finish(0, origin + case[0]) == case[1], "gesture classification %s" % case[0])
	check(router.finish(0, origin + Vector2(100, 0)) == "", "release only produces an action once")
	router.begin(0, origin)
	router.begin(1, origin + Vector2(100, 0))
	check(router.finish(1, origin) == "", "secondary pointer cannot finish primary swipe")
	check(router.finish(0, origin + Vector2(100, 0)) == "right", "primary pointer retains original position")
	router.begin(0, origin)
	router.cancel()
	check(router.finish(0, origin + Vector2(100, 0)) == "", "cancel removes in-flight gesture")
	router.begin(-2, origin)
	check(router.finish(-2, origin + Vector2(100, 0)) == "right", "mouse emulation supports reserved pointer")
	print("GESTURES: %d/%d checks passed" % [checks-failures, checks])
	quit(1 if failures else 0)
