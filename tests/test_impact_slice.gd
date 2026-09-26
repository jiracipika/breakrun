extends SceneTree
## Impact slice: contact stagger, buffered inputs, and wave archetypes.
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

## Drop the first matching enemy onto the contact line in the runner's lane.
func force_contact(model: RefCounted, kind: String) -> void:
	for e in model.enemies:
		if e.kind == kind:
			e.z = 0.5
			return

## Group spawned enemies per spawn tick (one group = one wave), ordered by z.
func wave_groups(Model, seed_value: int, min_groups: int) -> Array:
	var m = Model.new()
	m.start(seed_value)
	m.hp = 999
	var groups: Array = []
	var known := {}
	var steps: int = 0
	while groups.size() < min_groups and steps < 400000:
		steps += 1
		var before: float = m.distance
		m.step(1.0 / 120.0)
		if m.distance == before:
			break
		var fresh: Array = []
		for e in m.enemies:
			if not known.has(e.id):
				known[e.id] = true
				fresh.append({"kind": e.kind, "lane": int(e.lane), "z": float(e.z)})
		if not fresh.is_empty():
			fresh.sort_custom(func(a, b): return a.z < b.z)
			groups.append(fresh)
	return groups

func groups_key(groups: Array) -> String:
	var key := ""
	for g in groups:
		for member in g:
			key += "%s:%d:%.2f|" % [member.kind, member.lane, member.z]
	return key

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# Task 1 — stagger: a hit slows the run and knocks the offender down.
	var m = Model.new()
	m.start(42)
	m.combo = 3
	force_contact(m, "shield")
	m.step(1.0 / 120.0)
	check(m.hp == 2, "contact costs one pip")
	check(m.stagger_ratio() > 0.9, "contact staggers immediately")
	check(m.world_speed() < m.speed(), "stagger slows the world below the base ramp")
	check(m.style_multiplier() == 1.0, "stagger follows the combo reset")
	var crashed = null
	for e in m.enemies:
		if e.phase == "cleared" and absf(e.z) < 1.5:
			crashed = e
	check(crashed != null, "the struck enemy is knocked down, not left standing")
	check(m.score == 0, "being hit awards nothing")
	advance(m, 1.2)
	check(is_equal_approx(m.world_speed(), m.speed()), "stagger recovers fully")
	# A staggered run loses ground against an unharmed twin.
	var hurt = Model.new()
	hurt.start(42)
	force_contact(hurt, "shield")
	var clean = Model.new()
	clean.start(42)
	advance(hurt, 2.0)
	advance(clean, 2.0)
	check(hurt.distance < clean.distance, "a staggered run loses ground")
	check(hurt.hp == 2, "staged contact cost exactly one pip")

	# Task 2 — input buffer.
	var buf = Model.new()
	buf.start(42)
	buf.act("slide")
	advance(buf, 0.3)
	buf.act("jump")
	check(buf.height == 0.0, "jump during a slide does not fire immediately")
	advance(buf, 0.3)
	check(buf.height > 0.0, "buffered jump fires when the slide ends")
	var exp = Model.new()
	exp.start(42)
	exp.act("slide")
	exp.act("jump")
	advance(exp, 0.9)
	check(exp.height == 0.0, "expired buffer does not fire")
	var last = Model.new()
	last.start(42)
	last.act("slide")
	advance(last, 0.3)
	last.act("slide")
	last.act("jump")
	advance(last, 0.3)
	check(last.height > 0.0, "latest buffered input wins")
	var lane = Model.new()
	lane.start(42)
	lane.act("right")
	lane.act("right")
	check(lane.lane == 1, "edge lane presses are not buffered")

	# Task 3 — wave archetypes: teaching waves, then seeded variety.
	var groups := wave_groups(Model, 42, 8)
	check(groups.size() == 8, "eight waves readable")
	check(groups[0].size() == 5 and groups[0][0].kind == "shield" and groups[0][4].kind == "hurdle",
		"first wave is the teaching checkpoint")
	check(groups[1].size() == 5 and groups[1][0].kind == "shield", "second wave keeps the teaching shape")
	var valid_sizes := {5: true, 4: true, 3: true}
	var strikeable := ["shield", "kicker"]
	for gi in range(groups.size()):
		var g: Array = groups[gi]
		check(valid_sizes.has(g.size()), "wave %d matches a known archetype size" % gi)
		check(g[0].kind in strikeable, "wave %d opens with a strike-able robot" % gi)
		var strikeables: int = 0
		for member in g:
			if member.kind in strikeable:
				strikeables += 1
		check(strikeables == 1, "wave %d has exactly one strike-able robot" % gi)
		for mi in range(1, g.size()):
			check(g[mi].z - g[mi - 1].z >= 5.9, "wave %d keeps readable spacing" % gi)
	# Variety appears, and seeds stay replayable.
	var sizes_seen := {}
	for seed_value in [42, 7, 99]:
		for g in wave_groups(Model, seed_value, 12):
			sizes_seen[g.size()] = true
	check(sizes_seen.size() >= 2, "wave archetypes vary across runs")
	check(groups_key(wave_groups(Model, 42, 6)) == groups_key(wave_groups(Model, 42, 6)),
		"same seed reproduces the same wave sequence")
	check(groups_key(wave_groups(Model, 42, 6)) != groups_key(wave_groups(Model, 7, 6)),
		"different seeds produce different wave sequences")

	print("IMPACT SLICE: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
