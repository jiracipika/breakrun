extends SceneTree
## Pooled enemies: enemy visuals are reused, not reallocated per wave.
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.fixed_seed = 42
	game.start_run()
	var ArtScript = load("res://scripts/art/sunbreak_world.gd")
	var before: int = ArtScript.created_count
	# Sixty in-game seconds: eight-ish waves, multi-lane archetypes, the
	# inspector arriving near the end, and a restart in the middle.
	game.model.hp = 99
	var half: int = 1800
	for i in range(half):
		game._physics_process(1.0 / 60.0)
	game.start_run()
	game.model.hp = 99
	for i in range(half):
		game._physics_process(1.0 / 60.0)
	var growth: int = ArtScript.created_count - before
	check(growth <= 15, "sixty seconds allocate at most a warm-up of nodes (created %d)" % growth)
	check(game.enemy_nodes.size() <= 12, "live enemy mapping stays bounded")
	var pooled: int = 0
	for kind in game.enemy_pool:
		pooled += game.enemy_pool[kind].size()
	check(game.enemy_nodes.size() + pooled <= 24, "live plus pooled nodes stay bounded")
	check(game.model.state == "running", "pooled run stays alive throughout")
	print("POOL: %d/%d checks passed (growth %d, live %d, pooled %d)" % [checks - failures, checks, growth, game.enemy_nodes.size(), pooled])
	game.free()
	quit(1 if failures else 0)
