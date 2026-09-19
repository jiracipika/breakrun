extends Node3D

const Art = preload("res://scripts/art/sunbreak_world.gd")
const Model = preload("res://scripts/core/run_model.gd")
const Gestures = preload("res://scripts/input/gesture_router.gd")
const INK = Color("0a0a0f")
const PANEL = Color("1c1c2e")
const PAPER = Color("fff4db")
const GOLD = Color("ffca45")

var world: Node3D
var runner: Node3D
var interface: CanvasLayer
var title: Control
var model = Model.new()
var gestures = Gestures.new()
var hud: Control
var pause_overlay: Control
var result_overlay: Control
var score_label: Label
var life_label: Label
var distance_label: Label
var instruction: Label
var result_label: Label
var attack_button: Button
var enemy_nodes: Dictionary = {}
var counter_ring: MeshInstance3D
var warning_lane: MeshInstance3D
var kick_timer: float = 0.0
var previous_counters: int = 0
var reduced_motion: bool = false
var _web_status_elapsed: float = 0.0
var hit_flash: ColorRect
var hit_flash_time: float = 0.0
var previous_hp: int = 3
var best_score: int = 0
var muted: bool = false
var audio_players: Dictionary = {}
var last_sound_feedback: String = ""


func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = load("res://assets/fonts/AtkinsonHyperlegible-Regular.ttf")
	ThemeDB.fallback_font = ui_theme.default_font
	world = Art.build(self)
	runner = Art.courier(world)
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f7dcb5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c6cce9")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = env
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -34, 0)
	light.light_color = Color("ffe7c2")
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 8, 14)
	camera.fov = 62
	camera.far = 180
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, -14))
	interface = CanvasLayer.new()
	interface.name = "Interface"
	add_child(interface)
	_build_title()
	_build_hud()
	_build_overlays()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.04
	counter_ring = MeshInstance3D.new()
	counter_ring.mesh = torus
	counter_ring.material_override = Art.material(GOLD)
	world.add_child(counter_ring)
	counter_ring.visible = false
	warning_lane = Art.box(world, Vector3(2.0, 0.025, 5.0), Vector3(0, 0, -4), GOLD)
	warning_lane.visible = false
	hit_flash = ColorRect.new()
	hit_flash.color = Color(Art.CORAL, 0.55)
	hit_flash.size = Vector2(540, 960)
	hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_flash.visible = false
	interface.add_child(hit_flash)
	_build_audio()
	_load_settings()
	previous_hp = model.hp

func panel(parent: Node, rect: Rect2, color: Color = PANEL) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_right = 18
	node.add_theme_stylebox_override("panel", style)
	parent.add_child(node)
	return node

func label(parent: Node, text: String, rect: Rect2, font_size: int, color: Color = PAPER) -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	if font_size >= 40:
		node.add_theme_font_override("font", load("res://assets/fonts/BarlowCondensed-ExtraBold.ttf"))
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 21)
	node.add_theme_color_override("font_color", INK if primary else PAPER)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = GOLD if primary else PANEL
		style.border_color = PAPER
		style.set_border_width_all(2 if state == "focus" or state == "hover" else 0)
		style.set_corner_radius_all(5)
		node.add_theme_stylebox_override(state, style)
	if action.is_valid():
		node.pressed.connect(action)
	parent.add_child(node)
	return node

func _build_title() -> void:
	title = Control.new()
	title.name = "Title"
	interface.add_child(title)
	panel(title, Rect2(28, 40, 484, 222), INK)
	label(title, "BREAKRUN", Rect2(48, 54, 450, 94), 92, GOLD)
	label(title, "SUNBREAK RIOT", Rect2(51, 148, 440, 35), 23)
	label(title, "Every enemy is a weapon.", Rect2(51, 197, 440, 36), 22)
	panel(title, Rect2(28, 624, 484, 303), INK)
	label(title, "Make your own way through.", Rect2(48, 639, 450, 35), 23)
	label(title, "Dodge the bash. Counter the recovery.\nSend the whole checkpoint flying.", Rect2(48, 686, 450, 60), 19)
	button(title, "Start running", Rect2(48, 771, 444, 62), start_run, true).name = "StartButton"
	label(title, "Early interaction build · no accounts or ads", Rect2(48, 849, 444, 28), 16)
	label(title, "Keyboard + touch  /  Built in Godot", Rect2(48, 884, 444, 24), 15)

func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUD"
	interface.add_child(hud)
	panel(hud, Rect2(24, 26, 492, 98), INK)
	life_label = label(hud, "", Rect2(42, 40, 124, 36), 24, GOLD)
	label(hud, "Integrity", Rect2(42, 85, 124, 25), 16)
	score_label = label(hud, "0", Rect2(181, 34, 170, 50), 43)
	distance_label = label(hud, "", Rect2(181, 85, 170, 26), 17)
	button(hud, "Pause", Rect2(395, 46, 100, 56), pause_run).name = "PauseButton"
	panel(hud, Rect2(24, 141, 492, 72), INK)
	instruction = label(hud, "", Rect2(40, 150, 456, 58), 20)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel(hud, Rect2(24, 782, 492, 150), INK)
	label(hud, "Swipe to move  /  A D · W S · Space", Rect2(40, 795, 460, 26), 17)
	button(hud, "Jump", Rect2(40, 843, 107, 65), dispatch_action.bind("jump"))
	button(hud, "Slide", Rect2(158, 843, 107, 65), dispatch_action.bind("slide"))
	attack_button = button(hud, "Counter", Rect2(280, 833, 218, 75), dispatch_action.bind("attack"), true)
	attack_button.name = "CounterButton"
	hud.visible = false

func _build_overlays() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	interface.add_child(pause_overlay)
	panel(pause_overlay, Rect2(24, 291, 492, 415), INK)
	label(pause_overlay, "TAKE A BREATH", Rect2(48, 308, 440, 62), 48, GOLD)
	label(pause_overlay, "The city can wait.", Rect2(48, 384, 440, 35), 23)
	button(pause_overlay, "Resume", Rect2(48, 444, 444, 60), pause_run, true)
	var motion := CheckButton.new()
	motion.text = "Reduced motion"
	motion.position = Vector2(48, 523)
	motion.size = Vector2(213, 56)
	motion.add_theme_font_size_override("font_size", 22)
	motion.button_pressed = reduced_motion
	motion.toggled.connect(func(value: bool) -> void:
		reduced_motion = value
		_save_settings())
	pause_overlay.add_child(motion)
	var sound := CheckButton.new()
	sound.text = "Sound"
	sound.position = Vector2(279, 523)
	sound.size = Vector2(213, 56)
	sound.add_theme_font_size_override("font_size", 22)
	sound.button_pressed = not muted
	sound.toggled.connect(func(value: bool) -> void:
		muted = not value
		_save_settings())
	pause_overlay.add_child(sound)
	button(pause_overlay, "Back to title", Rect2(48, 615, 444, 60), return_to_title)
	pause_overlay.visible = false
	result_overlay = Control.new()
	result_overlay.name = "ResultOverlay"
	interface.add_child(result_overlay)
	panel(result_overlay, Rect2(24, 291, 492, 415), INK)
	label(result_overlay, "ONE MORE RUN?", Rect2(48, 308, 440, 62), 48, GOLD)
	result_label = label(result_overlay, "", Rect2(48, 385, 440, 120), 22)
	button(result_overlay, "Run again", Rect2(48, 530, 444, 64), start_run, true)
	button(result_overlay, "Back to title", Rect2(48, 615, 444, 60), return_to_title)
	result_overlay.visible = false

func start_run() -> void:
	gestures.cancel()
	model.start(42)
	previous_counters = 0
	previous_hp = 3
	kick_timer = 0.0
	for node in enemy_nodes.values():
		node.free()
	enemy_nodes.clear()
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO
	_sync_ui()
	_sync_world(0.0)

func pause_run() -> void:
	gestures.cancel()
	model.toggle_pause()
	_sync_ui()

func return_to_title() -> void:
	gestures.cancel()
	model = Model.new()
	for node in enemy_nodes.values():
		node.free()
	enemy_nodes.clear()
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO
	runner.scale = Vector3.ONE
	_sync_ui()
	_sync_world(0.0)

func dispatch_action(action: String) -> void:
	model.act(action)
	_sync_ui()

func _input(event: InputEvent) -> void:
	# Finish the pointer that began on the track even if release crosses UI.
	if event is InputEventScreenTouch and not event.pressed and gestures.pointer == event.index:
		if event.canceled:
			gestures.cancel()
		else:
			dispatch_action(gestures.finish(event.index, event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and gestures.pointer == -2:
		dispatch_action(gestures.finish(-2, event.position))
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_ESCAPE:
			pause_run()
			get_viewport().set_input_as_handled()
		elif code == KEY_ENTER and model.state == "title":
			start_run()
			get_viewport().set_input_as_handled()
		elif model.state == "running":
			var actions: Dictionary = {KEY_A: "left", KEY_LEFT: "left", KEY_D: "right", KEY_RIGHT: "right", KEY_W: "jump", KEY_UP: "jump", KEY_S: "slide", KEY_DOWN: "slide", KEY_SPACE: "attack"}
			if actions.has(code):
				dispatch_action(actions[code])
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed and model.state == "running":
		gestures.begin(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and model.state == "running":
		gestures.begin(-2, event.position)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and model != null:
		gestures.cancel()
		if model.state == "running":
			pause_run()

func _build_audio() -> void:
	# Original procedural blips synthesized at startup. No external audio assets.
	for name in ["counter", "hit", "chain", "clean"]:
		var tone: AudioStreamWAV = AudioStreamWAV.new()
		var rate: int = 22050
		var length: int = int(rate * 0.18)
		tone.format = AudioStreamWAV.FORMAT_16_BITS
		tone.mix_rate = rate
		var data := PackedByteArray()
		data.resize(length * 2)
		var base_frequency: float = 660.0
		if name == "hit":
			base_frequency = 130.0
		elif name == "chain":
			base_frequency = 440.0
		elif name == "clean":
			base_frequency = 880.0
		for i in range(length):
			var progress: float = float(i) / length
			var envelope: float = 1.0 - progress
			var frequency: float = base_frequency * (1.0 + 0.5 * progress if name == "counter" else 1.0)
			var sample: float = sin(TAU * frequency * i / rate) * envelope * 0.4
			var value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
			data.encode_s16(i * 2, value)
		tone.data = data
		var player := AudioStreamPlayer.new()
		player.stream = tone
		player.volume_db = -8.0
		add_child(player)
		audio_players[name] = player

func play_sound(name: String) -> void:
	if not muted and audio_players.has(name):
		audio_players[name].play()

func _settings_path() -> String:
	return "user://breakrun.cfg"

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_settings_path()) == OK:
		best_score = int(config.get_value("run", "best_score", 0))
		muted = bool(config.get_value("options", "muted", false))
		reduced_motion = bool(config.get_value("options", "reduced_motion", false))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("run", "best_score", best_score)
	config.set_value("options", "muted", muted)
	config.set_value("options", "reduced_motion", reduced_motion)
	config.save(_settings_path())

func _physics_process(delta: float) -> void:
	if model.state == "running":
		model.step(delta)
		_sync_world(delta)
	# Feedback events are level-side: compare previous presentation state.
	if model.counter_count > previous_counters:
		previous_counters = model.counter_count
		play_sound("counter")
	if model.hp < previous_hp:
		previous_hp = model.hp
		hit_flash_time = 0.22
		play_sound("hit")
	if model.hp > previous_hp:
		previous_hp = model.hp
	if hit_flash_time > 0.0 and not reduced_motion:
		hit_flash_time = maxf(0.0, hit_flash_time - delta)
		hit_flash.visible = hit_flash_time > 0.0
		hit_flash.modulate.a = minf(1.0, hit_flash_time / 0.22)
	else:
		hit_flash.visible = false
	_sync_ui()
	if OS.has_feature("web"):
		_web_status_elapsed += delta
		if _web_status_elapsed >= 0.1:
			_web_status_elapsed = 0.0
			# Read-only observability; no browser command mutates the simulation.
			JavaScriptBridge.eval("window.breakrunState = " + JSON.stringify({"state": model.state, "lane": model.lane, "distance": model.distance, "hp": model.hp, "score": model.score, "counters": model.counter_count, "chains": model.chain_count, "hint": instruction.text}) + ";")

func _sync_ui() -> void:
	title.visible = model.state == "title"
	hud.visible = model.state != "title"
	pause_overlay.visible = model.state == "paused"
	result_overlay.visible = model.state == "dead"
	life_label.text = "● ".repeat(maxi(0, model.hp))
	score_label.text = "%04d" % model.score
	distance_label.text = "%d m  /  %d hits" % [int(model.distance), model.combo]
	if model.state == "dead" and model.score > best_score:
		best_score = model.score
		_save_settings()
	result_label.text = "%d points   ·   %d metres\n%d counters   ·   %d chains\nBest: %d\nDodge first. Counter the open ring." % [model.score, int(model.distance), model.counter_count, model.chain_count, best_score]
	var text: String = "Move out of the shield's lane when it winds up."
	var ready_to_counter: bool = false
	for e in model.enemies:
		if e.kind != "shield" or e.phase == "launched" or e.phase == "cleared":
			continue
		if e.z <= 12 and e.z > 6:
			text = "DODGE  ←  Leave the marked lane  →"
		if e.z <= 6 and e.z >= 2 and e.dodged:
			text = "COUNTER NOW  ·  Space / yellow button"
			ready_to_counter = absi(int(e.lane) - model.lane) <= 1
		break
	if model.feedback != "":
		text = model.feedback
		if text.begins_with("Chain") and last_sound_feedback != text + str(model.chain_count):
			last_sound_feedback = text + str(model.chain_count)
			play_sound("chain")
		elif text == "Clean!" and last_sound_feedback != "clean" + str(model.score):
			last_sound_feedback = "clean" + str(model.score)
			play_sound("clean")
	instruction.text = text
	attack_button.text = "Counter NOW" if ready_to_counter else "Counter"
	attack_button.disabled = model.state != "running"

func _sync_world(delta: float) -> void:
	var blend: float = minf(1.0, delta * 16.0)
	runner.position.x = lerpf(runner.position.x, model.lane * 2.5, blend)
	runner.position.y = model.height
	runner.scale.y = 0.55 if model.sliding else 1.0
	var stride: float = sin(model.time * 16.0) * 0.60 if model.state == "running" else 0.0
	runner.get_node("LegL").rotation.x = stride
	runner.get_node("LegR").rotation.x = -stride
	runner.get_node("ArmL").rotation.x = -stride
	runner.get_node("ArmR").rotation.x = stride
	if model.counter_count > previous_counters:
		kick_timer = 0.32
		previous_counters = model.counter_count
	kick_timer = maxf(0.0, kick_timer - delta)
	if kick_timer > 0 and not reduced_motion:
		runner.get_node("LegR").rotation.x = -1.6
		runner.rotation.z = 0.23 * (model.lane - model.last_counter_lane)
	else:
		runner.rotation.z = 0.0
	var index: int = 0
	for tile in world.get_node("Tiles").get_children():
		tile.position.z = 9.0 - fposmod(index * 8.0 - model.distance, 144.0)
		index += 1
	index = 0
	for building in world.get_node("Buildings").get_children():
		building.position.z = 14.0 - fposmod(int(index / 2) * 13.0 - model.distance, 143.0)
		index += 1
	var live_ids: Dictionary = {}
	counter_ring.visible = false
	warning_lane.visible = false
	for enemy in model.enemies:
		live_ids[enemy.id] = true
		if not enemy_nodes.has(enemy.id):
			enemy_nodes[enemy.id] = Art.enemy(world, enemy.kind)
		var actor: Node3D = enemy_nodes[enemy.id]
		actor.position = Vector3(enemy.lane * 2.5, 0, -enemy.z)
		actor.rotation = Vector3.ZERO
		actor.scale = Vector3.ONE
		if enemy.phase == "launched":
			actor.rotation.x += model.time * 9.0  # tumbling spin while flying
			actor.position.y = 0.35
		elif enemy.phase == "approach" and enemy.kind == "dummy":
			# Idle sway so stacked dummies don't merge into one clump.
			actor.rotation.z = 0.05 * sin(model.time * 3.0 + float(enemy.id))
		elif enemy.phase == "cleared":
			if enemy.kind == "hurdle":
				actor.scale = Vector3(0.6, 0.6, 0.6)
			else:
				actor.rotation.z = PI * 0.48
				actor.scale = Vector3(0.45, 0.45, 0.45)
		elif enemy.phase == "bash":
			# Forward lunge wind-up: rocks toward the player as it attacks.
			actor.rotation.x = -0.20 - 0.16 * sin(model.time * 18.0)
		elif enemy.phase == "recovery":
			# Exposed lean-back invites the counter.
			actor.rotation.x = 0.26
		if enemy.kind == "shield" and enemy.z <= 12 and enemy.z > 6:
			warning_lane.visible = true
			warning_lane.position = Vector3(enemy.lane * 2.5, -0.04, -3.0)
		if enemy.kind == "shield" and enemy.phase == "recovery" and enemy.z >= 2:
			counter_ring.visible = true
			counter_ring.position = Vector3(enemy.lane * 2.5, 0.06, -enemy.z)
	for id in enemy_nodes.keys():
		if not live_ids.has(id):
			enemy_nodes[id].free()
			enemy_nodes.erase(id)
