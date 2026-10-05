extends SceneTree
## Lane traversal timing (NEXT.md: validate reachability before combining
## hazards). Logical lane selection is instant; the runner visually crosses a
## lane in log(20)/LANE_RATE seconds. No archetype wave — and no boss pattern —
## may demand a lane switch in less time than that crossing takes.

var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

## Advance a run while recording the arrival time and lane of every lane-locked
## enemy (shield/dummy/barrier) at the contact plane. Returns the shortest gap
## between consecutive arrivals that landed in different lanes: the worst
## back-to-back lane demand this seed actually produced.
func worst_switch_demand(Model, seed_value: int, waves: int) -> float:
	var m = Model.new()
	m.start(seed_value)
	m.hp = 999
	var arrived: Dictionary = {}
	var events: Array = []
	var steps: int = 0
	while m._waves_spawned < waves and steps < 200000:
		steps += 1
		m.step(1.0 / 120.0)
		for e in m.enemies:
			if not arrived.has(e.id) and e.z <= 0.8 and Model.kind_locks_lane(e.kind):
				arrived[e.id] = true
				events.append([m.time, int(e.lane)])
	var worst: float = INF
	for i in range(1, events.size()):
		if events[i][1] != events[i - 1][1]:
			worst = minf(worst, events[i][0] - events[i - 1][0])
	return worst

## Frames of simulated presentation at the given frame rate until the runner
## has visually covered 95% of the lane span, after a full-span lane demand.
func visual_crossing_time(game: Node, fps: float) -> float:
	game.start_run()
	game.model.lane = 1  # demand a full crossing: 0.0 -> 2.5
	var dt: float = 1.0 / fps
	var elapsed: float = 0.0
	for i in range(600):
		game._sync_world(dt)
		elapsed += dt
		if game.runner.position.x >= 0.95 * 2.5:
			return elapsed
	return INF

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var Model = load("res://scripts/core/run_model.gd")
	var traversal: float = Model.LANE_TRAVERSAL_TIME

	# The traversal window is the scene's 95% visual crossing: log(20)/rate.
	check(traversal > 0.15 and traversal < 0.25,
		"lane traversal time sits in a sane sub-quarter-second band")
	check(absf(traversal - log(20.0) / Model.LANE_RATE) < 0.0001,
		"traversal equals log(20)/LANE_RATE — 95% of the lane span")

	# The static lane layout is the exact one spawning uses (shared truth).
	check(Model.wave_member_lanes(Model.FENCE_WAVE, 1) == [1, 0, -1],
		"fence lanes walk across all three lanes for target 1")
	check(Model.wave_member_lanes(Model.PATROL_WAVE, -1) == [-1, -1, 0, -1],
		"patrol sends its third member to the neighbor lane")
	check(absf(Model.wave_switch_window(Model.FENCE_WAVE, 0) - 8.0 / Model.MAX_SPEED) < 0.0005,
		"fence members 8 m apart demand their switch at the speed cap")
	check(is_inf(Model.wave_switch_window(Model.CHECKPOINT_WAVE, 0)),
		"the teaching checkpoint chain never demands a lane switch")

	# Every archetype in every target lane must leave at least one traversal
	# for each demanded switch. _spawn_wave asserts the same thing at spawn
	# time in debug builds — this is the explicit, per-archetype proof.
	var archetypes: Array = [Model.CHECKPOINT_WAVE, Model.PATROL_WAVE, Model.FENCE_WAVE, Model.SWEEP_WAVE, Model.SPRING_WAVE]
	var worst_window: float = INF
	var finite_windows: int = 0
	for archetype in archetypes:
		for target_lane in [-1, 0, 1]:
			var window: float = Model.wave_switch_window(archetype, target_lane)
			if not is_inf(window):
				finite_windows += 1
				worst_window = minf(worst_window, window)
			check(window >= traversal,
				"archetype %s at lane %d leaves a full traversal for its switch" % [str(archetype[0][0]), target_lane])
	check(finite_windows > 0, "at least one archetype demands a lane switch")
	check(absf(worst_window - 6.0 / Model.MAX_SPEED) < 0.0005,
		"the worst authored window is the 6 m member gap at the speed cap (0.43 s)")

	# Cross-wave boundary: the last member of a wave to the first (always
	# lane-locked) member of the next one, at the speed cap.
	var boundary: float = INF
	for archetype in archetypes:
		var last_offset: float = archetype[archetype.size() - 1][1]
		boundary = minf(boundary, (Model.WAVE_SPACING - last_offset) / Model.MAX_SPEED)
	check(boundary >= traversal, "adjacent waves leave a full traversal between their lane demands")

	# The first shield teaches the bash from the player's own starting lane:
	# the run start to its strike point must span a traversal too.
	check((Model.SPAWN_DISTANCE - Model.SHIELD_BASH_Z) / Model.PLAYER_SPEED >= traversal,
		"the teaching shield leaves a full traversal to leave its lane")

	# Seeded play must actually contain the worst case — and it must fit.
	var observed_worst: float = INF
	for seed_value in [7, 42, 2024, 99999, 31337]:
		observed_worst = minf(observed_worst, worst_switch_demand(Model, seed_value, 6))
	check(observed_worst >= traversal - 0.0001,
		"every back-to-back lane demand in seeded play spans a full traversal")
	check(observed_worst <= 0.5,
		"the seeded runs reproduced the tight 6 m back-to-back demand (worst %.3f s)" % observed_worst)

	# The inspector shifts its marked lane between patterns; the telegraph is
	# the window to clear the marked lane, and shifts stay within one lane.
	check(Model.INSPECTOR_TELEGRAPH >= traversal,
		"the inspector telegraph leaves a full traversal to clear the marked lane")
	var boss = Model.new()
	boss.start(9)
	boss.hp = 999
	var steps: int = 0
	while boss.inspector.is_empty() and steps < 300000:
		steps += 1
		boss.step(1.0 / 120.0)
	check(not boss.inspector.is_empty(), "seeded play reaches the inspector")
	if not boss.inspector.is_empty():
		var previous_lane: int = int(boss.inspector.lane)
		var previous_pattern: String = boss.inspector.pattern
		var patterns_seen: int = 0
		var max_shift: int = 0
		while patterns_seen < 6 and steps < 600000:
			steps += 1
			boss.step(1.0 / 120.0)
			if not boss.inspector.is_empty() and boss.inspector.pattern != previous_pattern:
				previous_pattern = boss.inspector.pattern
				patterns_seen += 1
				max_shift = maxi(max_shift, absi(int(boss.inspector.lane) - previous_lane))
				previous_lane = int(boss.inspector.lane)
		check(patterns_seen >= 4, "the inspector cycles several patterns in play")
		check(max_shift <= 1, "every pattern lane shift stays within one lane of the last")

	# The scene crosses a lane no slower than the validated window, at the
	# frame rates the game actually runs.
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	for fps in [30.0, 60.0, 120.0]:
		var crossed: float = visual_crossing_time(game, fps)
		check(crossed <= traversal,
			"at %.0f fps the runner visually crosses a lane within the traversal window (%.3f s)" % [fps, crossed])
	game.free()

	print("TRAVERSAL: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
