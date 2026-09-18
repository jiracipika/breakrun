extends SceneTree
## Real GL renderer, deterministic input-driven checkpoints; not a mock screenshot.
var frames: int = 0
var game: Node
var errors: int = 0

func _initialize() -> void:
	root.content_scale_size = Vector2i(540, 960)
	call_deferred("boot")

func boot() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://artifacts")

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)

func capture(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png("res://artifacts/" + name + ".png")
	if result != OK:
		errors += 1
	print("CAPTURE: %s %dx%d error=%d" % [name, image.get_width(), image.get_height(), result])

func _process(_delta: float) -> bool:
	if game == null:
		return false
	frames += 1
	if frames == 25:
		capture("title")
	if frames == 30:
		game.get_node("Interface/Title/StartButton").pressed.emit()
	if frames > 30 and frames < 310:
		game._physics_process(1.0 / 60.0)
	if frames == 80:
		key(KEY_D)
	if frames == 150:
		capture("running")
	if frames == 246:
		capture("counter-ready")
	if frames == 247:
		key(KEY_SPACE)
	if frames == 257:
		capture("counter-launch")
	if frames == 307:
		capture("chain-complete")
		if game.model.counter_count != 1 or game.model.chain_count != 1 or game.model.score != 400:
			printerr("FAIL: live rendered chain did not reach expected state")
			errors += 1
		print("LIVE: counters=%d chains=%d score=%d hp=%d" % [game.model.counter_count,game.model.chain_count,game.model.score,game.model.hp])
	if frames == 311:
		key(KEY_ESCAPE)
	if frames == 320:
		capture("paused")
		if game.model.state != "paused":
			errors += 1
		quit(1 if errors else 0)
	return false
