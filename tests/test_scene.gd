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
				game.model.hp = 0
				game.model.state = "dead"
				game._physics_process(0.01)
				check(game.result_overlay.visible, "death displays result screen")
				game.start_run()
				check(game.model.hp == 3 and game.model.distance == 0.0, "restart clears old run")
			game.free()
	print("SCENE: %d/%d checks passed" % [checks - failed, checks])
	quit(1 if failed > 0 else 0)
