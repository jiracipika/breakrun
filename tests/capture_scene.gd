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
	game.fixed_seed = 42
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
	if frames > 30 and frames < 316:
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
		if game.model.counter_count != 1 or game.model.chain_count != 1 or game.model.score != 587:
			printerr("FAIL: live rendered chain did not reach expected state")
			errors += 1
		print("LIVE: counters=%d chains=%d score=%d hp=%d" % [game.model.counter_count,game.model.chain_count,game.model.score,game.model.hp])
	if frames == 308:
		# Force a stagger: drop a dummy onto the runner's lane at the contact line.
		game.model.enemies.append({"id": 999, "kind": "dummy", "lane": game.model.lane,
			"z": 0.5, "phase": "approach", "dodged": false, "age": 0.0,
			"hits": 0, "rewarded": false, "previous_z": 0.5})
	if frames == 312:
		var crashed = null
		for e in game.model.enemies:
			if e.id == 999:
				crashed = e
		if crashed == null or game.model.hp != 2 or game.model.stagger_ratio() <= 0.0 or crashed.phase != "cleared":
			printerr("FAIL: contact did not stagger and clear the enemy")
			errors += 1
		print("LIVE-STAGGER: hp=%d cleared=%d staggered=%d" % [game.model.hp,
			1 if (crashed != null and crashed.phase == "cleared") else 0,
			1 if game.model.stagger_ratio() > 0.0 else 0])
		capture("stagger")
	if frames == 315:
		key(KEY_ESCAPE)
	if frames == 318:
		capture("paused")
		if game.model.state != "paused":
			errors += 1
		key(KEY_ESCAPE)
	if frames == 320:
		# End the run deterministically to capture the new result screen.
		game.model.hp = 1
		game.model.last_hit_kind = "shield"
		game.model.state = "dead"
		game._sync_ui()
	if frames == 328:
		capture("result")
		quit(1 if errors else 0)
	return false
