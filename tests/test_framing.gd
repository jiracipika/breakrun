extends SceneTree

var failed: int = 0
var checks: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var camera: Camera3D = game.get_node("Camera3D")
	var size: Vector2 = root.get_visible_rect().size
	var feet: Vector2 = camera.unproject_position(Vector3(2.5, 0.0, 0.0)) / size
	var outer: Vector2 = camera.unproject_position(Vector3(3.18, 1.4, 0.0)) / size
	check(feet.y < 0.76, "feet clear bottom controls by a useful margin")
	check(outer.x < 0.94, "outer lane silhouette has a side margin")
	check(game.world.get_node("Buildings").get_child(0).position.y < -3.0, "track sits above nearby rooftops rather than in a street canyon")
	print("FRAMING: feet=%s outer=%s %d/%d checks passed" % [feet, outer, checks-failed, checks])
	game.free()
	quit(1 if failed else 0)
