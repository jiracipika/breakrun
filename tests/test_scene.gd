extends SceneTree

var checks: int = 0
var failed: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists("res://scenes/main.tscn"), "main scene exists")
	if failed == 0:
		var packed: PackedScene = load("res://scenes/main.tscn")
		check(packed != null, "main scene loads")
		if packed != null:
			var game: Node = packed.instantiate()
			root.add_child(game)
			check(game.get_node_or_null("World") != null, "world mounted")
			check(game.get_node_or_null("World/Runner") != null, "runner silhouette mounted")
			check(game.get_node_or_null("Camera3D") != null, "portrait gameplay camera mounted")
			check(game.get_node_or_null("Interface/Title") != null, "title screen mounted")
			check(game.get_node("Interface/Title").visible, "title visible on boot")
			check(game.has_method("start_run"), "start button can start a run")
			if game.has_method("start_run"):
				game.start_run()
				check(game.model.state == "running", "start enters running state")
				check(not game.title.visible and game.hud.visible, "game HUD replaces title")
				game._physics_process(0.1)
				check(game.model.distance > 0.0, "world advances during play")
				game.pause_run()
				var previous: float = game.model.distance
				game._physics_process(0.1)
				check(game.model.distance == previous, "pause freezes world")
				check(game.pause_overlay.visible, "pause overlay displayed")
				game.pause_run()
				game.dispatch_action("right")
				check(game.model.lane == 1, "UI action reaches logical movement")
				var legend: Control = game.get_node_or_null("Interface/HUD/Legend")
				check(legend != null and not legend.visible, "legend hides after the first action")
				var seed_field: LineEdit = game.get_node_or_null("Interface/Title/SeedInput")
				check(seed_field != null, "title exposes a seed input")
				game.return_to_title()
				if seed_field != null:
					seed_field.text = "12345"
					game.start_run()
					check(game.model.state == "running" and game.model.run_seed == 12345,
						"a typed seed replays that exact run")
					game.return_to_title()
					seed_field.text = "ab12cd34"
					game.start_run()
					check(game.model.run_seed == 1234, "garbage is stripped to its digits")
					game.return_to_title()
					seed_field.text = ""
					game.start_run()
					check(game.model.state == "running" and game.model.run_seed > 0,
						"an empty field rolls a fresh random seed")
				game.start_run()
				check(legend.visible, "gesture legend shows at run start")
				game._physics_process(6.0)
				check(not legend.visible, "legend hides itself after five seconds")
				game.model.hp = 0
				game.model.state = "dead"
				game._physics_process(0.01)
				check(game.result_overlay.visible, "death displays result screen")
				var copy_seed: Button = game.get_node_or_null("Interface/ResultOverlay/CopySeed")
				check(copy_seed != null, "result screen exposes a copy-seed button")
				if copy_seed != null:
					copy_seed.pressed.emit()
					check(copy_seed.text.begins_with("Copied"), "copying acknowledges with feedback")
				var seed_shown: LineEdit = game.get_node_or_null("Interface/ResultOverlay/SeedDisplay")
				check(seed_shown != null and seed_shown.text == str(game.model.run_seed),
					"result screen shows the run seed as its own selectable text")
				check(seed_shown == null or (not seed_shown.editable and seed_shown.select_all_on_focus),
					"the seed display selects itself on focus for manual copying")
				game.return_to_title()
				game.start_run()
				game.model.upgrade_offer = ["pinball", "relay"]
				game._sync_ui()
				var upgrade_overlay: Control = game.get_node_or_null("Interface/UpgradeOverlay")
				check(upgrade_overlay != null and upgrade_overlay.visible,
					"an open offer shows the perk overlay")
				if upgrade_overlay != null and upgrade_overlay.visible:
					# Overlay children: panel, title, subtitle, perk card 0.
					var perk_button: Button = upgrade_overlay.get_child(3)
					perk_button.pressed.emit()
					check(game.model.owned_upgrades.has("pinball") and game.model.upgrade_offer.is_empty(),
						"picking a card owns the perk and resumes")
					check(not upgrade_overlay.visible, "the perk overlay hides after the pick")
				game.start_run()
				check(game.model.hp == 3 and game.model.distance == 0.0, "restart clears old run")
			game.free()
	print("SCENE: %d/%d checks passed" % [checks - failed, checks])
	quit(1 if failed > 0 else 0)
