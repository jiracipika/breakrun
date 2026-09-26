extends SceneTree
## Stamp kicker: slide under the high sweep, then strike.
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

## Build a run with wave 1 cleared and a kicker staged just before its sweep.
func kicker_run(Model, player_lane: int = 0) -> RefCounted:
	var m = Model.new()
	m.start(42)
	# Neutralize wave 1 so only the staged kicker matters.
	for e in m.enemies:
		e.phase = "cleared"
	m.enemies.append({"id": 900, "kind": "kicker", "lane": 0, "z": 10.0,
		"phase": "approach", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": false, "previous_z": 10.0, "swept": false})
	m.lane = player_lane
	return m

## Find the staged enemy by id (array positions shift as cleared robots despawn).
func by_id(model: RefCounted, id: int) -> Dictionary:
	for e in model.enemies:
		if e.id == id:
			return e
	return {}

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# The high sweep hits a grounded player in its lane.
	var grounded = kicker_run(Model, 0)
	var steps: int = 0
	while grounded.hp == 3 and steps < 4000:
		steps += 1
		grounded.step(1.0 / 120.0)
	check(grounded.hp == 2, "high sweep catches a grounded player in its lane")
	check(grounded.last_hit_kind == "kicker", "sweep damage names the kicker")

	# Jumping does not dodge a high sweep.
	var jumper = kicker_run(Model, 0)
	jumper.act("jump")
	steps = 0
	while jumper.hp == 3 and steps < 4000:
		steps += 1
		jumper.step(1.0 / 120.0)
	check(jumper.hp == 2, "jumping does not clear the high sweep")

	# Sliding in-lane dodges the sweep.
	var slider = kicker_run(Model, 0)
	slider.act("slide")
	steps = 0
	while by_id(slider, 900).z > 5.8 and steps < 4000:
		steps += 1
		slider.step(1.0 / 120.0)
	check(slider.hp == 3, "sliding under the sweep avoids damage")
	check(by_id(slider, 900).dodged, "slide marks the kicker dodged")
	check(by_id(slider, 900).phase == "recovery", "kicker leans into recovery after the sweep")

	# Another lane dodges too.
	var aside = kicker_run(Model, 1)
	steps = 0
	while by_id(aside, 900).z > 5.8 and steps < 4000:
		steps += 1
		aside.step(1.0 / 120.0)
	check(aside.hp == 3 and by_id(aside, 900).dodged, "a different lane dodges the sweep")

	# Striking without dodging is rejected with the slide hint.
	var greedy = kicker_run(Model, 1)
	by_id(greedy, 900).z = 5.0
	by_id(greedy, 900).phase = "recovery"
	greedy.act("attack")
	check(greedy.counter_count == 0 and greedy.feedback.begins_with("Slide under"),
		"an undodged kicker refuses the strike with the slide hint")

	# The full sweep-strike-chain: slide under, strike in recovery, kicker trips the dummy.
	var chain = kicker_run(Model, 0)
	chain.act("slide")
	steps = 0
	while by_id(chain, 900).z > 5.5 and steps < 4000:
		steps += 1
		chain.step(1.0 / 120.0)
	chain.act("attack")
	check(chain.counter_count == 1 and by_id(chain, 900).phase == "launched",
		"sliding under earns the strike")
	check(chain.score == 50, "kicker strike pays its base 50")
	steps = 0
	while chain.chain_count == 0 and steps < 4000:
		steps += 1
		chain.step(1.0 / 120.0)
	check(chain.chain_count == 1, "the launched kicker trips the trailing dummy")

	# Seeded waves can produce a sweep archetype, and waves keep one strike-able robot.
	var m = Model.new()
	m.start(7)
	m.hp = 999
	var seen_kicker: bool = false
	var known := {}
	var steps_total: int = 0
	while steps_total < 40000 and not seen_kicker:
		steps_total += 1
		var before: float = m.distance
		m.step(1.0 / 120.0)
		if m.distance == before:
			break
		for e in m.enemies:
			if not known.has(e.id):
				known[e.id] = true
				if e.kind == "kicker":
					seen_kicker = true
	check(seen_kicker, "seeded waves include the stamp kicker")

	print("KICKER: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
