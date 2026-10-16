extends Node3D

const Art = preload("res://scripts/art/sunbreak_world.gd")
const Model = preload("res://scripts/core/run_model.gd")
const Gestures = preload("res://scripts/input/gesture_router.gd")
const MusicBox = preload("res://scripts/core/music_box.gd")
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
var legend: Panel
var _legend_age: float = 0.0
var _legend_done: bool = false
var seed_input: LineEdit
var seed_display: LineEdit
var copy_seed_button: Button
var copy_seed_timer: float = 0.0
var camera: Camera3D
var burst_pieces: Array = []
var score_label: Label
var life_label: Label
var distance_label: Label
var best_score_label: Label
var motion_toggle: CheckButton
var sound_toggle: CheckButton
var instruction: Label
var result_label: Label
var upgrade_overlay: Control
var perk_buttons: Array = []
var enemy_nodes: Dictionary = {}
var enemy_kinds: Dictionary = {}
var enemy_pool: Dictionary = {}
var inspector_node: Node3D
var counter_ring: MeshInstance3D
var warning_lane: MeshInstance3D
var kick_timer: float = 0.0
var previous_counters: int = 0
var previous_boosts: int = 0
var previous_inspectors: int = 0
var reduced_motion: bool = false
var _web_status_elapsed: float = 0.0
var hit_flash: ColorRect
var hit_flash_time: float = 0.0
var slide_scale: float = 1.0
var previous_hp: int = 3
var best_score: int = 0
var muted: bool = false
var audio_players: Dictionary = {}
var music_player: AudioStreamPlayer
var menu_music: AudioStreamWAV
var run_music: AudioStreamWAV
var last_sound_feedback: String = ""
## Deterministic-run hook for tests and rendered capture. 0 = each run draws a fresh seed.
var fixed_seed: int = 0


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
	self.camera = camera
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
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(PAPER, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(INK, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
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
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_font_size_override("font_size", 22)
	node.add_theme_constant_override("outline_size", 1)
	node.add_theme_color_override("font_color", INK if primary else PAPER)
	node.add_theme_color_override("font_disabled_color", Color(PAPER, 0.45))
	node.add_theme_color_override("font_hover_color", INK if primary else GOLD)
	node.add_theme_color_override("font_focus_color", INK if primary else GOLD)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		if state == "pressed":
			style.bg_color = PAPER if primary else PANEL.lightened(0.28)
		elif state == "disabled":
			style.bg_color = Color("16161f")
		else:
			style.bg_color = GOLD if primary else PANEL
		style.border_color = PAPER if state in ["focus", "hover", "pressed"] else Color(PAPER, 0.14)
		style.set_border_width_all(2 if state in ["focus", "hover", "pressed"] else 1)
		style.set_corner_radius_all(10)
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
	label(title, "CITY COURIER DIVISION  /  001", Rect2(52, 54, 430, 22), 15, GOLD)
	label(title, "BREAKRUN", Rect2(45, 75, 450, 93), 98, GOLD)
	label(title, "SUNBREAK RIOT", Rect2(52, 174, 420, 30), 22)
	label(title, "DODGE.  COUNTER.  CHAIN.", Rect2(52, 212, 430, 28), 19)
	panel(title, Rect2(28, 624, 484, 303), INK)
	label(title, "ROOFTOP RUN  /  ENDLESS", Rect2(50, 642, 430, 22), 15, GOLD)
	label(title, "Every enemy is a weapon.", Rect2(50, 672, 440, 40), 29)
	label(title, "Swipe to move, jump or slide.\nTap to counter after dodging an attack.", Rect2(50, 715, 430, 42), 17)
	seed_input = LineEdit.new()
	seed_input.name = "SeedInput"
	seed_input.placeholder_text = "Seed (optional) — race a friend's run"
	seed_input.position = Vector2(48, 763)
	seed_input.size = Vector2(444, 38)
	seed_input.max_length = 12
	seed_input.add_theme_font_size_override("font_size", 17)
	seed_input.add_theme_color_override("font_color", PAPER)
	var seed_style := StyleBoxFlat.new()
	seed_style.bg_color = PANEL
	seed_style.border_color = Color("39394f")
	seed_style.set_border_width_all(1)
	seed_style.set_corner_radius_all(8)
	seed_input.add_theme_stylebox_override("normal", seed_style)
	var seed_focus := seed_style.duplicate()
	seed_focus.border_color = PAPER
	seed_focus.set_border_width_all(2)
	seed_input.add_theme_stylebox_override("focus", seed_focus)
	title.add_child(seed_input)
	button(title, "START RUN   →", Rect2(48, 810, 444, 58), start_run, true).name = "StartButton"
	best_score_label = label(title, "BEST  %04d" % best_score, Rect2(50, 880, 128, 22), 16, GOLD)
	label(title, "WASD / SPACE  ·  SWIPE / TAP", Rect2(190, 882, 300, 20), 14)
func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUD"
	interface.add_child(hud)
	panel(hud, Rect2(24, 26, 492, 100), INK)
	label(hud, "INTEGRITY", Rect2(42, 37, 124, 20), 14, GOLD)
	life_label = label(hud, "", Rect2(42, 58, 124, 36), 24, GOLD)
	label(hud, "SCORE", Rect2(181, 37, 170, 20), 14, GOLD)
	score_label = label(hud, "0", Rect2(181, 54, 170, 44), 40)
	distance_label = label(hud, "", Rect2(181, 101, 300, 20), 14)
	button(hud, "PAUSE", Rect2(405, 47, 88, 56), pause_run).name = "PauseButton"
	panel(hud, Rect2(24, 151, 492, 68), INK)
	var accent := ColorRect.new()
	accent.position = Vector2(24, 151)
	accent.size = Vector2(5, 68)
	accent.color = GOLD
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(accent)
	instruction = label(hud, "", Rect2(46, 157, 450, 56), 19)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend = panel(hud, Rect2(102, 630, 336, 112), Color(INK, 0.88))
	legend.name = "Legend"
	label(legend, "QUICK CONTROLS", Rect2(20, 12, 296, 24), 14, GOLD)
	label(legend, "Swipe — move · jump · slide", Rect2(20, 39, 296, 28), 17)
	label(legend, "Tap — counter", Rect2(20, 69, 296, 28), 18, GOLD)
	hud.visible = false
func _build_overlays() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	interface.add_child(pause_overlay)
	panel(pause_overlay, Rect2(24, 276, 492, 430), INK)
	label(pause_overlay, "RUN PAUSED", Rect2(48, 295, 440, 24), 16, GOLD)
	label(pause_overlay, "Take a breath.", Rect2(48, 323, 440, 58), 46, GOLD)
	label(pause_overlay, "The city can wait.", Rect2(48, 385, 440, 35), 22)
	button(pause_overlay, "RESUME RUN   →", Rect2(48, 445, 444, 60), pause_run, true)
	motion_toggle = CheckButton.new()
	var motion := motion_toggle
	motion.text = "Reduced motion"
	motion.position = Vector2(48, 523)
	motion.size = Vector2(213, 56)
	motion.add_theme_font_size_override("font_size", 20)
	motion.button_pressed = reduced_motion
	motion.toggled.connect(func(value: bool) -> void:
		reduced_motion = value
		_save_settings())
	pause_overlay.add_child(motion)
	sound_toggle = CheckButton.new()
	var sound := sound_toggle
	sound.text = "Sound"
	sound.position = Vector2(279, 523)
	sound.size = Vector2(213, 56)
	sound.add_theme_font_size_override("font_size", 20)
	sound.button_pressed = not muted
	sound.toggled.connect(func(value: bool) -> void:
		muted = not value
		_apply_music()
		_save_settings())
	pause_overlay.add_child(sound)
	button(pause_overlay, "BACK TO TITLE", Rect2(48, 615, 444, 60), return_to_title)
	pause_overlay.visible = false
	result_overlay = Control.new()
	result_overlay.name = "ResultOverlay"
	interface.add_child(result_overlay)
	panel(result_overlay, Rect2(24, 276, 492, 430), INK)
	label(result_overlay, "RUN COMPLETE  /  REPORT", Rect2(48, 295, 440, 24), 16, GOLD)
	label(result_overlay, "One more run?", Rect2(48, 323, 440, 58), 46, GOLD)
	result_label = label(result_overlay, "", Rect2(48, 385, 440, 118), 21)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_seed_button = button(result_overlay, "COPY SEED", Rect2(48, 510, 200, 38), copy_seed)
	copy_seed_button.name = "CopySeed"
	# The seed as selectable text: the honest fallback when a context refuses
	# clipboard writes — click it (or press C) and the digits select themselves
	# for Ctrl+C / long-press copy.
	seed_display = LineEdit.new()
	seed_display.name = "SeedDisplay"
	seed_display.text = ""
	seed_display.editable = false
	seed_display.select_all_on_focus = true
	seed_display.context_menu_enabled = false
	seed_display.position = Vector2(260, 510)
	seed_display.size = Vector2(232, 38)
	seed_display.max_length = 12
	seed_display.add_theme_font_size_override("font_size", 17)
	seed_display.add_theme_color_override("font_color", GOLD)
	seed_display.add_theme_color_override("font_uneditable_color", GOLD)
	seed_display.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var display_style := StyleBoxFlat.new()
	display_style.bg_color = PANEL
	display_style.border_color = Color("39394f")
	display_style.set_border_width_all(1)
	display_style.set_corner_radius_all(8)
	seed_display.add_theme_stylebox_override("normal", display_style)
	var display_focus := display_style.duplicate()
	display_focus.border_color = PAPER
	display_focus.set_border_width_all(2)
	seed_display.add_theme_stylebox_override("focus", display_focus)
	result_overlay.add_child(seed_display)
	button(result_overlay, "RUN AGAIN   →", Rect2(48, 558, 444, 58), start_run, true)
	button(result_overlay, "BACK TO TITLE", Rect2(48, 626, 444, 60), return_to_title)
	result_overlay.visible = false
	# Perk choice after a Route Inspector clear: the world is frozen until a
	# card is picked, so there is no timer and no way to lose here.
	upgrade_overlay = Control.new()
	upgrade_overlay.name = "UpgradeOverlay"
	interface.add_child(upgrade_overlay)
	panel(upgrade_overlay, Rect2(24, 251, 492, 495), INK)
	label(upgrade_overlay, "PICK A PERK", Rect2(48, 268, 440, 62), 48, GOLD)
	label(upgrade_overlay, "The inspector drops a boon. The city waits.", Rect2(48, 342, 440, 30), 19)
	for i in range(2):
		var perk: Button = button(upgrade_overlay, "", Rect2(48, 392 + i * 104, 444, 88), pick_perk.bind(i), true)
		perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perk.add_theme_font_size_override("font_size", 18)
		perk_buttons.append(perk)
	upgrade_overlay.visible = false
func pick_perk(index: int) -> void:
	if index < model.upgrade_offer.size():
		model.take_upgrade(model.upgrade_offer[index])
		_sync_ui()

## Put the shown seed on the clipboard so sharing needs no retyping. Web uses
## the async navigator API where it exists (HTTPS plus this press gesture
## satisfy its rules) and falls back to a hidden textarea + execCommand copy
## for plain file:// and other non-secure contexts where the clipboard is
## unavailable; native builds use the display server. If every write path is
## refused, the button never claims "Copied!" — it asks for Ctrl+C and selects
## the seed field instead, so the digits are one keystroke away.
func copy_seed() -> void:
	var seed_text: String = str(model.run_seed)
	var copied: bool = false
	if OS.has_feature("web"):
		# One-shot probe run inside the page: prefer the async clipboard API on
		# secure origins; anywhere else (plain file:// among them) fall back to
		# a hidden textarea + execCommand inside the same gesture. Kept flush
		# on purpose: GDScript has no strip_margin to dedent this safely.
		var js: String = """
(function(text) {
try {
if (window.isSecureContext && navigator.clipboard && navigator.clipboard.writeText) {
navigator.clipboard.writeText(text);
return true;
}
var area = document.createElement('textarea');
area.value = text;
area.setAttribute('readonly', '');
area.style.position = 'fixed';
area.style.opacity = '0';
document.body.appendChild(area);
area.focus();
area.select();
var ok = document.execCommand('copy');
document.body.removeChild(area);
return ok;
} catch (error) {
return false;
}
})(%d)""" % model.run_seed
		copied = bool(JavaScriptBridge.eval(js, true))
	else:
		DisplayServer.clipboard_set(seed_text)
		copied = true  # The platform API has no failure signal on desktop.
	if copied:
		copy_seed_button.text = "Copied!"
	else:
		copy_seed_button.text = "PRESS CTRL+C"
		seed_display.grab_focus()  # select_all_on_focus selects the digits.
	copy_seed_timer = 1.5 if copied else 2.5

func _tick_copy_feedback(delta: float) -> void:
	if copy_seed_timer > 0.0:
		copy_seed_timer = maxf(0.0, copy_seed_timer - delta)
		if copy_seed_timer == 0.0:
			copy_seed_button.text = "Copy seed"

func _fresh_seed() -> int:
	# Global RNG is entropy-seeded in Godot 4; mix the clock so rapid restarts differ.
	return absi(int(Time.get_ticks_usec()) ^ randi())

## The title's optional seed field: forgiving digits-only parse; anything
## empty or unparseable rolls the usual fresh random seed.
func _title_seed() -> int:
	var digits := ""
	for character in seed_input.text:
		if character >= "0" and character <= "9":
			digits += character
	if digits.is_empty():
		return 0
	return clampi(int(digits), 1, 2147483647)

func start_run() -> void:
	gestures.cancel()
	var seed_value: int = fixed_seed
	if seed_value == 0 and model.state == "title":
		seed_value = _title_seed()
	if seed_value == 0:
		seed_value = _fresh_seed()
	model.start(seed_value)
	previous_counters = 0
	previous_boosts = 0
	previous_inspectors = 0
	previous_hp = 3
	kick_timer = 0.0
	_legend_age = 0.0
	_legend_done = false
	legend.visible = true
	for burst in burst_pieces:
		burst["node"].free()
	burst_pieces.clear()
	_release_all_enemy_nodes()
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO
	_sync_ui()
	_sync_world(0.0)

## Retire an enemy node into the kind-keyed pool instead of freeing it.
func _release_enemy_node(kind: String, node: Node3D) -> void:
	node.visible = false
	if not enemy_pool.has(kind):
		enemy_pool[kind] = []
	enemy_pool[kind].append(node)

func _release_all_enemy_nodes() -> void:
	for id in enemy_nodes.keys():
		_release_enemy_node(enemy_kinds[id], enemy_nodes[id])
	enemy_nodes.clear()
	enemy_kinds.clear()

func pause_run() -> void:
	gestures.cancel()
	model.toggle_pause()
	_sync_ui()

func return_to_title() -> void:
	gestures.cancel()
	model = Model.new()
	_release_all_enemy_nodes()
	runner.position = Vector3.ZERO
	runner.rotation = Vector3.ZERO
	runner.scale = Vector3.ONE
	_sync_ui()
	_sync_world(0.0)

func dispatch_action(action: String) -> void:
	model.act(action)
	_legend_done = true
	legend.visible = false
	_sync_ui()

## A finished pointer is either a swipe direction or a tap; taps attack.
func _dispatch_gesture(action: String) -> void:
	dispatch_action("attack" if action == "" else action)

func _input(event: InputEvent) -> void:
	# Finish the pointer that began on the track even if release crosses UI.
	if event is InputEventScreenTouch and not event.pressed and gestures.pointer == event.index:
		if event.canceled:
			gestures.cancel()
		else:
			_dispatch_gesture(gestures.finish(event.index, event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and gestures.pointer == -2:
		_dispatch_gesture(gestures.finish(-2, event.position))
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_ESCAPE and model.state != "dead":
			pause_run()
			get_viewport().set_input_as_handled()
		elif model.state == "title" and (code == KEY_ENTER or code == KEY_SPACE):
			start_run()
			get_viewport().set_input_as_handled()
		elif model.state == "dead" and code == KEY_ESCAPE:
			return_to_title()
			get_viewport().set_input_as_handled()
		elif model.state == "dead" and (code == KEY_ENTER or code == KEY_SPACE or code == KEY_R):
			start_run()
			get_viewport().set_input_as_handled()
		elif model.state == "dead" and code == KEY_C:
			copy_seed()
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
	for name in ["counter", "hit", "chain", "clean", "boost"]:
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
		elif name == "boost":
			base_frequency = 520.0
		for i in range(length):
			var progress: float = float(i) / length
			var envelope: float = 1.0 - progress
			var rises: bool = name == "counter" or name == "boost"
			var frequency: float = base_frequency * (1.0 + 0.5 * progress if rises else 1.0)
			var sample: float = sin(TAU * frequency * i / rate) * envelope * 0.4
			var value: int = int(clampf(sample, -1.0, 1.0) * 32767.0)
			data.encode_s16(i * 2, value)
		tone.data = data
		var player := AudioStreamPlayer.new()
		player.stream = tone
		player.volume_db = -8.0
		add_child(player)
		audio_players[name] = player
	# The soundtrack: two synthesized loops (menu idles mellow, the run loop
	# brings drums and the lead hook) on their own player, under the blips.
	menu_music = MusicBox.make_menu_loop()
	run_music = MusicBox.make_run_loop()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -7.0
	music_player.stream = menu_music
	add_child(music_player)
	_apply_music()

func play_sound(name: String) -> void:
	if not muted and audio_players.has(name):
		audio_players[name].play()

## Keep the soundtrack on the right loop for the model state, honoring mute.
## _sync_ui calls this every physics frame; every branch is idempotent.
func _apply_music() -> void:
	if music_player == null:
		return
	var in_run: bool = model.state == "running" or model.state == "paused"
	var wanted: AudioStreamWAV = run_music if in_run else menu_music
	if music_player.stream != wanted:
		music_player.stream = wanted
	if muted:
		music_player.stop()
		return
	if not music_player.playing:
		music_player.play()
	music_player.stream_paused = model.state == "paused"

func _settings_path() -> String:
	return "user://breakrun.cfg"

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(_settings_path()) == OK:
		best_score = int(config.get_value("run", "best_score", 0))
		muted = bool(config.get_value("options", "muted", false))
		reduced_motion = bool(config.get_value("options", "reduced_motion", false))
	if motion_toggle != null:
		motion_toggle.set_pressed_no_signal(reduced_motion)
	if sound_toggle != null:
		sound_toggle.set_pressed_no_signal(not muted)
	if best_score_label != null:
		best_score_label.text = "BEST  %04d" % best_score

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
	# The counter sound lives in _sync_world's counter branch — it used to be
	# checked here, after _sync_world had already consumed previous_counters,
	# so it could never fire.
	if model.boost_count > previous_boosts:
		previous_boosts = model.boost_count
		play_sound("boost")
	if model.inspectors_defeated > previous_inspectors:
		previous_inspectors = model.inspectors_defeated
		play_sound("chain")
		if not reduced_motion:
			_spawn_burst()
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
	if model.state == "running" and legend.visible and not _legend_done:
		_legend_age += delta
		if _legend_age >= 5.0:
			legend.visible = false
	_sync_ui()
	# Read-only observability for local debugging; kept out of release exports.
	if OS.has_feature("web") and OS.is_debug_build():
		_web_status_elapsed += delta
		if _web_status_elapsed >= 0.1:
			_web_status_elapsed = 0.0
			JavaScriptBridge.eval("window.breakrunState = " + JSON.stringify({"state": model.state, "lane": model.lane, "distance": model.distance, "hp": model.hp, "score": model.score, "counters": model.counter_count, "chains": model.chain_count, "hint": instruction.text}) + ";")

## Readable failure: name what ended the run and its remedy, not a generic goodbye.
func _failure_line() -> String:
	match model.last_hit_kind:
		"shield":
			return "Shield bash caught you — counter it."
		"inspector":
			return "Its pattern caught you — dodge it."
		"kicker":
			return "A stamp sweep caught you — slide under it."
		"spring":
			return "A low sweep caught you — jump it."
		"dummy":
			return "A robot clipped you — counter clears."
		"barrier":
			return "A barrier hit you — launch a shield."
		"hurdle":
			return "A hurdle tripped you — jump or slide."
		_:
			return "Dodge first. Counter the open ring."

## Opaque impact shards flung from the counter lane (art bible: cards, not clouds).
func _spawn_burst() -> void:
	var origin := Vector3(model.last_counter_lane * 2.5, 0.9, -1.2)
	for i in range(6):
		var piece := Art.box(world, Vector3(0.24, 0.08, 0.02), origin, PAPER if i % 2 == 0 else Art.SAFFRON)
		var angle := TAU * float(i) / 6.0
		burst_pieces.append({"node": piece,
			"velocity": Vector3(cos(angle) * 3.4, sin(angle) * 2.2 + 1.4, -0.8),
			"spin": randf_range(-7.0, 7.0), "age": 0.0})

func _update_bursts(delta: float) -> void:
	var surviving: Array = []
	for burst in burst_pieces:
		burst["age"] += delta
		if burst["age"] < 0.38:
			var node: MeshInstance3D = burst["node"]
			node.position += burst["velocity"] * delta
			burst["velocity"] = burst["velocity"] + Vector3(0.0, -9.0 * delta, 0.0)
			node.rotation.z += burst["spin"] * delta
			surviving.append(burst)
		else:
			burst["node"].free()
	burst_pieces = surviving

func _sync_ui() -> void:
	title.visible = model.state == "title"
	hud.visible = model.state != "title"
	pause_overlay.visible = model.state == "paused"
	result_overlay.visible = model.state == "dead"
	_apply_music()
	upgrade_overlay.visible = not model.upgrade_offer.is_empty()
	if upgrade_overlay.visible:
		for i in range(perk_buttons.size()):
			if i < model.upgrade_offer.size():
				var perk_name: String = model.upgrade_offer[i]
				perk_buttons[i].text = "%s\n%s" % [perk_name.capitalize(), Model.UPGRADES[perk_name]]
	life_label.text = "●  ".repeat(maxi(0, model.hp)) if model.hp > 0 else "—"
	life_label.add_theme_color_override("font_color", GOLD if model.hp > 1 else Art.CORAL)
	score_label.text = "%04d" % model.score
	var style: String = "  ×%.1f" % model.style_multiplier() if model.combo > 0 else ""
	distance_label.text = "%d m  ·  %d hits%s" % [int(model.distance), model.combo, style]
	if model.state == "dead" and model.score > best_score:
		best_score = model.score
		_save_settings()
	best_score_label.text = "BEST  %04d" % best_score
	var best_mark: String = "  (new!)" if model.state == "dead" and model.score == best_score and model.score > 0 else ""
	var perks: String = ""
	for name in model.owned_upgrades:
		perks += name.capitalize() + " "
	if perks != "":
		perks = " · " + perks.strip_edges()
	if seed_display.text != str(model.run_seed):
		seed_display.text = str(model.run_seed)  # Kept so a selection survives the frame.
	result_label.text = "%d points · %d metres%s\nCounters %d · Chains %d · best ×%.2f\nBest: %d · Seed %d%s\n%s" % [model.score, int(model.distance), best_mark, model.counter_count, model.chain_count, model.style_multiplier(), best_score, model.run_seed, perks, _failure_line()]
	var text: String = "Move out of the shield's lane when it winds up."
	var ready_to_counter: bool = false
	if not model.inspector.is_empty():
		# The checkpoint machine owns the lecture until it is beaten.
		match model.inspector.phase:
			"telegraph":
				match model.inspector.pattern:
					"bash":
						text = "CHANGE LANE — its bash is winding up"
					"sweep":
						text = "SLIDE — its bar sweeps high"
					"scanner":
						text = "JUMP — its bar sweeps low"
			"active":
				text = "NOW!"
			"recovery":
				if model.inspector.dodged:
					text = "BREAK IT  ·  tap anywhere  (%d/%d)" % [model.inspector.hits, Model.INSPECTOR_HP]
					ready_to_counter = true
				else:
					text = "MISSED — recover and wait"
	else:
		for e in model.enemies:
			if (e.kind != "shield" and e.kind != "kicker" and e.kind != "spring") or e.phase == "launched" or e.phase == "cleared":
				continue
			if e.kind == "kicker":
				if e.z <= 16 and e.z > 9:
					text = "SWEEP!  Slide the striped lane"
				if e.z <= 6 and e.z >= 2 and e.dodged:
					text = "STRIKE NOW  ·  tap anywhere"
					ready_to_counter = absi(int(e.lane) - model.lane) <= 1
			elif e.kind == "spring":
				if e.z <= 16 and e.z > 9:
					text = "JUMP  —  its sweep is low"
				if e.z <= 6 and e.z >= 2 and e.dodged:
					text = "STRIKE NOW  ·  tap anywhere"
					ready_to_counter = absi(int(e.lane) - model.lane) <= 1
			else:
				if e.z <= 12 and e.z > 6:
					text = "DODGE  —  leave the marked lane"
				if e.z <= 6 and e.z >= 2 and e.dodged:
					text = "COUNTER NOW  ·  tap anywhere"
					ready_to_counter = absi(int(e.lane) - model.lane) <= 1
			break
	# The next checkpoint machine announces itself so it never arrives cold.
	if model.feedback == "" and model.inspector.is_empty():
		var next_at: float = Model.INSPECTOR_DISTANCE * float(model.inspectors_defeated + 1)
		if model.distance >= next_at - 40.0:
			text = "INSPECTOR AHEAD — reach the checkpoint"
	if model.feedback != "":
		text = model.feedback
		if text.begins_with("Chain") and last_sound_feedback != text + str(model.chain_count):
			last_sound_feedback = text + str(model.chain_count)
			play_sound("chain")
		elif text == "Clean!" and last_sound_feedback != "clean" + str(model.score):
			last_sound_feedback = "clean" + str(model.score)
			play_sound("clean")
	instruction.text = text
	if ready_to_counter and not reduced_motion and model.state == "running":
		instruction.modulate.a = 0.72 + 0.28 * sin(model.time * 12.0)
	else:
		instruction.modulate.a = 1.0

func _sync_world(delta: float) -> void:
	# The runner crosses lanes exponentially at the model's shared LANE_RATE;
	# run_model.gd derives the traversal window every hazard must respect.
	var blend: float = minf(1.0, delta * Model.LANE_RATE)
	runner.position.x = lerpf(runner.position.x, model.lane * 2.5, blend)
	runner.position.y = model.height
	# Slide settles in and out at the lane-blend ease instead of snapping.
	slide_scale = lerpf(slide_scale, 0.55 if model.sliding else 1.0, blend * 1.6)
	runner.scale.y = slide_scale
	# Stumble feedback: lean back, drop stride, nudge toward the camera.
	var stagger: float = model.stagger_ratio() if model.state == "running" else 0.0
	runner.rotation.x = -0.5 * stagger
	runner.position.z = 0.6 * stagger
	var stride: float = sin(model.time * 16.0) * 0.60 * (1.0 - 0.7 * stagger) if model.state == "running" else 0.0
	runner.get_node("LegL").rotation.x = stride
	runner.get_node("LegR").rotation.x = -stride
	runner.get_node("ArmL").rotation.x = -stride
	runner.get_node("ArmR").rotation.x = stride
	if model.counter_count > previous_counters:
		kick_timer = 0.32
		previous_counters = model.counter_count
		play_sound("counter")
		if not reduced_motion:
			_spawn_burst()
	kick_timer = maxf(0.0, kick_timer - delta)
	if kick_timer > 0 and not reduced_motion:
		# A reaching kick: leg swings high and the torso leans into it.
		runner.get_node("LegR").rotation.x = -2.1
		runner.rotation.x = 0.18
		runner.rotation.z = 0.23 * (model.lane - model.last_counter_lane)
	else:
		# Lane-change lean: tilt into the lateral blend while crossing.
		runner.rotation.z = clampf((model.lane * 2.5 - runner.position.x) * 0.12, -0.24, 0.24)
	_tick_copy_feedback(delta)
	# Counter kick punches the view wider; a boost eases it wider still.
	var fov_kick: float = 0.0
	if kick_timer > 0 and not reduced_motion:
		fov_kick = 6.0 * (kick_timer / 0.32)
	var fov_boost: float = 0.0 if reduced_motion else 4.0 * model.boost_ratio()
	# Impact punch: the view jolts while the hit flash decays.
	var fov_hit: float = 0.0 if reduced_motion else 3.0 * maxf(0.0, hit_flash_time) / 0.22
	camera.fov = 62.0 + fov_kick + fov_boost + fov_hit
	if hit_flash_time > 0.0 and not reduced_motion:
		var shake: float = 0.045 * (hit_flash_time / 0.22)
		camera.h_offset = randf_range(-shake, shake)
		camera.v_offset = randf_range(-shake, shake)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
	_update_bursts(delta)
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
			var node: Node3D = null
			var pool: Array = enemy_pool.get(enemy.kind, [])
			if pool.size() > 0:
				node = pool.pop_back()
				node.visible = true
				# A reused node keeps its last life's telegraph poses.
				for pivot_name in ["Foot", "SweepLeg"]:
					var pivot: Node3D = node.get_node_or_null(pivot_name)
					if pivot != null:
						pivot.rotation = Vector3.ZERO
						pivot.scale = Vector3.ONE
						if pivot.has_meta("home"):
							pivot.position = pivot.get_meta("home")
				var stripe: Node3D = node.get_node_or_null("Stripe")
				if stripe != null:
					stripe.visible = false
			else:
				node = Art.enemy(world, enemy.kind)
			node.set_meta("kind", enemy.kind)
			enemy_nodes[enemy.id] = node
			enemy_kinds[enemy.id] = enemy.kind
		var actor: Node3D = enemy_nodes[enemy.id]
		actor.position = Vector3(enemy.lane * 2.5, 0, -enemy.z)
		actor.rotation = Vector3.ZERO
		actor.scale = Vector3.ONE
		if enemy.phase == "launched":
			actor.rotation.x += model.time * 9.0  # tumbling spin while flying
			actor.position.y = 0.35
			# Cartwheel away small: a full-size flat plate reads as a slab.
			actor.scale = Vector3(0.62, 0.62, 0.62)
		elif enemy.phase == "approach" and enemy.kind == "shield" and enemy.z <= 12.0:
			# Authored wind-up: pull back before the bash lunge so the attack
			# reads as anticipation then release.
			actor.rotation.x = 0.14
			actor.position.z -= 0.35
		elif enemy.phase == "approach" and enemy.kind == "dummy":
			# Idle sway so stacked dummies don't merge into one clump.
			actor.rotation.z = 0.05 * sin(model.time * 3.0 + float(enemy.id))
		elif enemy.phase == "cleared":
			if enemy.kind == "hurdle":
				actor.scale = Vector3(0.6, 0.6, 0.6)
			else:
				actor.rotation.z = PI * 0.48
				actor.scale = Vector3(0.45, 0.45, 0.45)
		elif enemy.phase == "sweep":
			# High stamp: the saffron foot swings through the lane while the
			# body lunges into the strike.
			var kicker_foot: Node3D = actor.get_node_or_null("Foot")
			if kicker_foot != null:
				kicker_foot.rotation.x = -1.9 - 0.5 * sin(model.time * 20.0)
				actor.position.z += 0.32
			# Low sweep: the courier's coil leg stretches into a reaching
			# rake, body pitched into the kick.
			var spring_leg: Node3D = actor.get_node_or_null("SweepLeg")
			if spring_leg != null:
				spring_leg.rotation.x = 1.2 + 0.4 * sin(model.time * 22.0)
				spring_leg.scale = Vector3(1.3, 1.45, 1.3)
				actor.rotation.x = -0.14
				actor.position.z += 0.38
		elif enemy.kind == "kicker" and enemy.phase == "approach" and enemy.z <= 14.0:
			# Authored wind-up: the stamp foot rears up as the range closes,
			# so the sweep reads as release, not teleport.
			var ramp: float = 1.0 - clampf(enemy.z / 14.0, 0.0, 1.0)
			var foot: Node3D = actor.get_node_or_null("Foot")
			if foot != null:
				foot.rotation.x = 0.85 * ramp
				var home: Vector3 = foot.get_meta("home")
				foot.position.y = home.y + 0.5 * ramp
			actor.rotation.x = 0.10 * ramp
		elif enemy.kind == "spring" and enemy.phase == "approach" and enemy.z <= 16.0:
			# Coil crouches deeper as the range closes: the squash IS the
			# telegraph for the low sweep.
			actor.scale.y = 0.66 + 0.06 * clampf(enemy.z / 16.0, 0.0, 1.0)
		elif enemy.phase == "bash":
			# Forward lunge wind-up: rocks toward the player as it attacks.
			actor.rotation.x = -0.20 - 0.16 * sin(model.time * 18.0)
			actor.position.z += 0.5 + 0.35 * sin(model.time * 18.0)
		elif enemy.phase == "recovery":
			# Exposed lean-back invites the counter.
			actor.rotation.x = 0.26
		# Warn only for an approaching shield: a launched one re-enters this
		# z band flying away and must not resurrect the dodge warning.
		if (enemy.kind == "shield" and enemy.phase == "approach" and enemy.z <= 12 and enemy.z > 6) \
				or (enemy.kind == "spring" and enemy.phase == "approach" and enemy.z <= 16 and enemy.z > 6):
			# Lane paint warns for the bash AND the low sweep — the spring's
			# crouch alone reads too late at run speed.
			warning_lane.visible = true
			warning_lane.position = Vector3(enemy.lane * 2.5, -0.04, -3.0)
		if enemy.kind == "kicker":
			var stripe: Node3D = actor.get_node_or_null("Stripe")
			if stripe != null:
				stripe.visible = (enemy.phase == "approach" or enemy.phase == "sweep") and enemy.z <= 16.0
		if (enemy.kind == "shield" or enemy.kind == "kicker" or enemy.kind == "spring") and enemy.phase == "recovery" and enemy.z >= 2:
			counter_ring.visible = true
			counter_ring.position = Vector3(enemy.lane * 2.5, 0.06, -enemy.z)
	for id in enemy_nodes.keys():
		if not live_ids.has(id):
			_release_enemy_node(enemy_kinds[id], enemy_nodes[id])
			enemy_nodes.erase(id)
			enemy_kinds.erase(id)
	if model.inspector.is_empty():
		if inspector_node != null:
			inspector_node.free()
			inspector_node = null
	else:
		if inspector_node == null:
			inspector_node = Art.inspector(world)
		var inspect: Dictionary = model.inspector
		inspector_node.position = Vector3(lerpf(inspector_node.position.x, inspect.lane * 2.5, blend), 0.0, -14.0)
		inspector_node.rotation = Vector3.ZERO
		inspector_node.scale = Vector3.ONE
		var bar: Node3D = inspector_node.get_node_or_null("Bar")
		var beacon: Node3D = inspector_node.get_node_or_null("Beacon")
		if bar != null:
			bar.rotation = Vector3.ZERO
			bar.scale = Vector3.ONE
		if beacon != null:
			beacon.scale = Vector3.ONE
		if inspect.phase == "telegraph":
			# Slow lean forward; the beacon pulses to announce the machine.
			inspector_node.rotation.x = -0.12
			if beacon != null and not reduced_motion:
				var pulse: float = 1.0 + 0.2 * sin(model.time * 8.0)
				beacon.scale = Vector3(pulse, pulse, pulse)
		elif inspect.phase == "active":
			match inspect.pattern:
				"bash":
					# Chassis lunge toward the player, like the shield bash.
					inspector_node.rotation.x = -0.3
					inspector_node.position.z += 0.5 + 0.35 * sin(model.time * 18.0)
				"sweep":
					if bar != null:
						bar.rotation.x = -1.4
				"scanner":
					if bar != null:
						bar.rotation.x = 1.2
						bar.scale.y = 0.6
		else:
			# Leans back with the bar parked: the counter window is open.
			inspector_node.rotation.x = 0.22
		# The bash marks its lane from wind-up through the strike. This runs
		# after the shield warning above, so the inspector's lane wins the mesh.
		if inspect.pattern == "bash" and (inspect.phase == "telegraph" or inspect.phase == "active"):
			warning_lane.visible = true
			warning_lane.position = Vector3(inspect.lane * 2.5, -0.04, -12.0)
