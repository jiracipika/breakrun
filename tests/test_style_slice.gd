extends SceneTree
## Style slice: run seeds, combo multiplier, and readable damage cause.
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func advance(model: RefCounted, duration: float, dt: float = 1.0 / 120.0) -> void:
	for i in range(roundi(duration / dt)):
		model.step(dt)

## Advance until the model loses one hp or the step budget runs out.
func until_damaged(model: RefCounted, max_steps: int = 20000) -> void:
	var steps: int = 0
	while model.hp == 3 and steps < max_steps:
		steps += 1
		model.step(1.0 / 120.0)

## Lane of each spawned wave's shield, recorded per spawn batch (archetype
## waves hold 3-5 members, so shield ids are no longer fixed strides).
## The probe runner takes hits, so it runs with padded integrity to stay alive.
func wave_lanes(Model, seed_value: int, waves: int) -> Array:
	var m = Model.new()
	m.start(seed_value)
	m.hp = 999
	var lanes: Array = []
	var known := {}
	var steps: int = 0
	while lanes.size() < waves and steps < 400000:
		steps += 1
		var before: float = m.distance
		m.step(1.0 / 120.0)
		if m.distance == before:
			break
		for e in m.enemies:
			if not known.has(e.id):
				known[e.id] = true
				if e.kind == "shield":
					lanes.append(int(e.lane))
	return lanes

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# Task 1 — run seed recorded and replayable.
	var seeded = Model.new()
	seeded.start(7)
	check(seeded.run_seed == 7, "start records the run seed")
	var a = Model.new()
	a.start(42)
	var b = Model.new()
	b.start(42)
	advance(a, 30.0)
	advance(b, 30.0)
	check(a.distance == b.distance and a.score == b.score and a.combo == b.combo,
		"same seed reproduces an identical run")
	var lanes_a := wave_lanes(Model, 42, 6)
	var lanes_b := wave_lanes(Model, 7, 6)
	check(lanes_a.size() == 6 and lanes_b.size() == 6, "wave lanes readable for six waves")
	check(lanes_a != lanes_b, "different seeds produce different wave lanes")

	# Task 2 — style multiplier from combo, capped.
	var m = Model.new()
	m.start(42)
	check(m.style_multiplier() == 1.0, "multiplier starts at 1.0")
	m.combo = 2
	check(m.style_multiplier() == 1.5, "multiplier grows with combo")
	m.combo = 8
	check(m.style_multiplier() == 3.0, "multiplier caps at 3.0")
	m.combo = 20
	check(m.style_multiplier() == 3.0, "multiplier stays capped beyond 8 combo")
	# Reference chain: counter 50, then chain hits at x1.25/x1.5/x1.75.
	var chain = Model.new()
	chain.start(42)
	chain.act("right")
	var waited: float = 0.0
	while waited < 6.0 and not (chain.enemies[0].phase == "recovery" and chain.enemies[0].z <= 6.0 and chain.enemies[0].z >= 2.0):
		chain.step(1.0 / 120.0)
		waited += 1.0 / 120.0
	chain.act("attack")
	check(chain.counter_count == 1 and chain.score == 50, "lone counter still pays its base 50")
	check(chain.combo == 1 and chain.best_combo == 1, "counter grows combo and best combo")
	var traveled: float = 0.0
	while traveled < 3.0 and chain.chain_count == 0:
		chain.step(1.0 / 120.0)
		traveled += 1.0 / 120.0
	# Let the remaining chain hits land and their feedback expire.
	var settled: float = 0.0
	while settled < 4.0 and chain.feedback_time > 0.0:
		chain.step(1.0 / 120.0)
		settled += 1.0 / 120.0
	check(chain.score == 50 + 125 + 150 + 262, "style chain reference score is 587")
	check(chain.best_combo == 4, "chain raises best combo to 4")
	# Damage resets the multiplier and records the cause.
	var hit = Model.new()
	hit.start(42)
	hit.combo = 4
	until_damaged(hit)
	check(hit.hp == 2, "forced contact costs one pip")
	check(hit.style_multiplier() == 1.0, "damage resets the multiplier")
	check(hit.last_hit_kind == "shield", "shield contact records its kind")
	# Each kind records itself: place the obstacle on the contact line directly.
	for kind in ["dummy", "barrier", "hurdle"]:
		var k = Model.new()
		k.start(42)
		for e in k.enemies:
			if e.kind == kind:
				e.z = 0.5
		until_damaged(k)
		check(k.hp == 2 and k.last_hit_kind == kind, kind + " contact records its kind")

	print("STYLE SLICE: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
