extends SceneTree

var checks: int = 0
var failures: int = 0
var game: Node

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func key(code: int, echo_event: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo_event
	root.push_input(event, true)

func touch(id: int, pos: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = pos
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)

func mouse_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		root.push_input(event, true)

func _initialize() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(540, 960)
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.fixed_seed = 42
	game.start_run()
	key(KEY_D)
	check(game.model.lane == 1, "real keyboard input changes lane")
	key(KEY_A)
	key(KEY_A, true)
	check(game.model.lane == 0, "key repeat is ignored")
	key(KEY_W)
	game._physics_process(0.1)
	check(game.model.height > 0.0, "jump key reaches simulation")
	key(KEY_ESCAPE)
	check(game.model.state == "paused", "escape pauses")
	key(KEY_ESCAPE)
	check(game.model.state == "running", "escape resumes")
	game.start_run()
	touch(0, Vector2(240, 440), true)
	touch(0, Vector2(350, 440), false)
	check(game.model.lane == 1, "real screen swipe changes lane")
	game.start_run()
	touch(0, Vector2(240, 440), true)
	touch(0, Vector2(350, 440), false, true)
	check(game.model.lane == 0, "canceled touch does not move")
	game.start_run()
	touch(0, Vector2(380, 860), true)
	touch(0, Vector2(200, 520), false)
	check(game.model.lane == 0 and game.gestures.pointer == -1, "canceled pointer never becomes an action")
	game.start_run()
	touch(0, Vector2(240, 500), true)
	touch(0, Vector2(244, 504), false)
	check(game.model.feedback_time > 0.0, "a tap anywhere fires a counter attempt")
	touch(0, Vector2(240, 500), true)
	touch(0, Vector2(245, 500), false)
	check(game.model.lane == 0 and game.gestures.pointer == -1, "tiny movements never act as swipes")
	touch(0, Vector2(220, 450), true)
	game.pause_run()
	game.pause_run()
	touch(0, Vector2(350, 450), false)
	check(game.model.lane == 0, "pause clears unfinished gestures")
	game.start_run()
	key(KEY_D)
	for i in range(216):
		game._physics_process(1.0 / 60.0)
	key(KEY_SPACE)
	check(game.model.counter_count == 1, "keyboard dodge and counter work in integrated scene")
	game._physics_process(1.0 / 60.0)
	check(game.camera.fov > 62.0, "counter kicks the camera fov")
	for i in range(40):
		game._physics_process(1.0 / 60.0)
	check(absf(game.camera.fov - 62.0) < 0.01, "camera fov settles back after the counter kick")
	for i in range(60):
		game._physics_process(1.0 / 60.0)
	check(game.model.chain_count == 1 and game.model.score == 587, "projectile clears checkpoint through integrated scene")
	game.return_to_title()
	var start_button: Button = game.get_node("Interface/Title/StartButton")
	mouse_click(start_button.get_global_rect().get_center())
	check(game.model.state == "running", "real mouse click activates Start")
	game.start_run()
	key(KEY_D)
	for i in range(216):
		game._physics_process(1.0 / 60.0)
	mouse_click(Vector2(240, 480))
	check(game.model.counter_count == 1, "a mouse tap counters the recovering shield")
	check(game.model.lane == 1 and game.gestures.pointer == -1, "counter tap does not leak into gesture routing")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.model.state == "paused", "focus loss pauses play")
	game.return_to_title()
	start_button.pressed.emit()
	check(game.model.state == "running", "actual Start button signal is connected")
	game.model.hp = 1
	game.model.last_hit_kind = "shield"
	game.model.state = "dead"
	game._sync_ui()
	check(game.result_overlay.visible, "death shows the result overlay")
	key(KEY_ENTER)
	check(game.model.state == "running", "Enter restarts from the result screen")
	game.model.state = "dead"
	game._sync_ui()
	key(KEY_ESCAPE)
	check(game.model.state == "title", "Escape returns to title from the result screen")
	game.model.state = "dead"
	game._sync_ui()
	key(KEY_C)
	check(game.get_node("Interface/ResultOverlay/CopySeed").text.begins_with("Copied"),
		"C copies the seed from the result screen")
	key(KEY_ENTER)
	check(game.model.state == "running", "restart keys still work after copying")
	# Touch ergonomics: panels pass drags through; menus still fire on touch-down.
	game.start_run()
	touch(0, Vector2(240, 180), true)
	touch(0, Vector2(350, 180), false)
	check(game.model.lane == 1, "swipe starting on the instruction panel reaches the track")
	game.start_run()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = game.get_node("Interface/HUD/PauseButton").get_global_rect().get_center()
	root.push_input(press, true)
	check(game.model.state == "paused", "pause fires on touch-down, not release")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = press.position
	root.push_input(release, true)
	game.start_run()
	print("INPUT: %d/%d checks passed" % [checks - failures, checks])
	game.free()
	quit(1 if failures else 0)
