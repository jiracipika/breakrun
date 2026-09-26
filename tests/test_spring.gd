extends SceneTree
## Spring courier: jump the low sweep, strike mid-air, ride the boost.
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

func by_id(model: RefCounted, id: int) -> Dictionary:
	for e in model.enemies:
		if e.id == id:
			return e
	return {}

## Wave 1 cleared, courier staged just before its sweep window.
func spring_run(Model, player_lane: int = 0) -> RefCounted:
	var m = Model.new()
	m.start(42)
	for e in m.enemies:
		e.phase = "cleared"
	m.enemies.append({"id": 910, "kind": "spring", "lane": 0, "z": 10.0,
		"phase": "approach", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": false, "swept": false, "previous_z": 10.0})
	m.lane = player_lane
	return m

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# The low sweep catches a grounded player in its lane.
	var grounded = spring_run(Model, 0)
	var steps: int = 0
	while grounded.hp == 3 and steps < 4000:
		steps += 1
		grounded.step(1.0 / 120.0)
	check(grounded.hp == 2, "low sweep catches a grounded player in its lane")
	check(grounded.last_hit_kind == "spring", "sweep damage names the courier")

	# Sliding does NOT clear a low sweep — the kicker's answer fails here.
	var slider = spring_run(Model, 0)
	slider.act("slide")
	steps = 0
	while slider.hp == 3 and steps < 4000:
		steps += 1
		slider.step(1.0 / 120.0)
	check(slider.hp == 2, "sliding under a low sweep still gets hit")

	# Jumping clears it and marks the courier dodged.
	var jumper = spring_run(Model, 0)
	steps = 0
	while by_id(jumper, 910).z > 9.6 and steps < 4000:
		steps += 1
		jumper.step(1.0 / 120.0)
	jumper.act("jump")
	steps = 0
	while by_id(jumper, 910).z > 5.8 and steps < 4000:
		steps += 1
		jumper.step(1.0 / 120.0)
	check(jumper.hp == 3, "jumping clears the low sweep")
	check(by_id(jumper, 910).dodged, "the jump marks the courier dodged")
	check(by_id(jumper, 910).phase == "recovery", "courier leans into recovery after the sweep")

	# Another lane dodges too.
	var aside = spring_run(Model, 1)
	steps = 0
	while by_id(aside, 910).z > 5.8 and steps < 4000:
		steps += 1
		aside.step(1.0 / 120.0)
	check(aside.hp == 3 and by_id(aside, 910).dodged, "a different lane dodges the sweep")

	# A grounded strike is refused even after the dodge.
	var early = spring_run(Model, 1)
	by_id(early, 910).z = 5.0
	by_id(early, 910).phase = "recovery"
	by_id(early, 910).dodged = true
	early.act("attack")
	check(early.counter_count == 0 and early.feedback.begins_with("Strike it mid-air"),
		"grounded strike refused with the mid-air hint")

	# The full jump-aerial-strike-boost: jump the sweep, tap mid-air, ride the boost.
	var pro = spring_run(Model, 0)
	steps = 0
	while by_id(pro, 910).z > 9.6 and steps < 4000:
		steps += 1
		pro.step(1.0 / 120.0)
	pro.act("jump")
	steps = 0
	while by_id(pro, 910).z > 5.6 and steps < 4000:
		steps += 1
		pro.step(1.0 / 120.0)
	check(pro.height > 0.5, "the jump arc is still airborne in the strike window")
	pro.act("attack")
	check(pro.counter_count == 1 and by_id(pro, 910).phase == "launched",
		"the aerial strike launches the courier")
	check(pro.score == 50, "aerial strike pays its base 50")
	check(pro.boost_count == 1, "the aerial strike starts a boost")
	check(pro.world_speed() > pro.speed(), "the boost pushes the run faster")
	advance(pro, 1.4)
	check(is_equal_approx(pro.world_speed(), pro.speed()), "the boost decays back to base")

	# Seeded waves include the courier.
	var m = Model.new()
	m.start(7)
	m.hp = 999
	var seen_spring: bool = false
	var known := {}
	var steps_total: int = 0
	while steps_total < 40000 and not seen_spring:
		steps_total += 1
		var before: float = m.distance
		m.step(1.0 / 120.0)
		if m.distance == before:
			break
		for e in m.enemies:
			if not known.has(e.id):
				known[e.id] = true
				if e.kind == "spring":
					seen_spring = true
	check(seen_spring, "seeded waves include the spring courier")

	print("SPRING: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
