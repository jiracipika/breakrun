extends SceneTree
## Quality-slice core updates: speed ramp and hurdle contract.
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

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")
	var model = Model.new()
	model.start(42)
	check(model.speed() == 9.0, "speed starts at base 9")
	advance(model, 50.0)
	check(model.speed() > 9.0, "speed grows with distance")
	var far = Model.new()
	far.start(42)
	far.distance = 5000.0
	check(far.speed() == 14.0, "speed caps at 14")
	# Full chain still completes on the ramp.
	var chain = Model.new()
	chain.start(42)
	chain.act("right")
	# Advance to the recovery window itself rather than a fixed duration, so the
	# assertion holds at any speed within the capped ramp.
	var waited: float = 0.0
	while waited < 6.0 and not (chain.enemies[0].phase == "recovery" and chain.enemies[0].z <= 6.0 and chain.enemies[0].z >= 2.0):
		chain.step(1.0 / 120.0)
		waited += 1.0 / 120.0
	check(chain.enemies[0].phase == "recovery" and chain.enemies[0].dodged, "ramp keeps dodge timing reachable")
	chain.act("attack")
	check(chain.counter_count == 1, "ramp keeps counter reachable")
	var traveled: float = 0.0
	while traveled < 3.0 and chain.chain_count == 0:
		chain.step(1.0 / 120.0)
		traveled += 1.0 / 120.0
	while traveled < 4.0 and chain.feedback_time > 0.0:
		chain.step(1.0 / 120.0)
		traveled += 1.0 / 120.0
	check(chain.chain_count == 1 and chain.score == 587, "chain still completes on the ramp")
	# Hurdles.
	var h = Model.new()
	h.start(42)
	var barrier = null
	var hurdle = null
	for e in h.enemies:
		if e.kind == "barrier": barrier = e
		if e.kind == "hurdle": hurdle = e
	check(barrier != null and hurdle != null, "wave contains barrier and hurdle")
	if barrier != null and hurdle != null:
		check(hurdle.z > barrier.z, "hurdle arrives after the barrier")
	check(h.score == 0, "no score before play")
	# Clean pass: stay in lane, jump the hurdle line.
	var j = Model.new()
	j.start(42)
	advance(j, 4.9)
	var hj = null
	for e in j.enemies:
		if e.kind == "hurdle": hj = e
	check(hj != null, "hurdle exists for jump test")
	if hj != null:
		# Step to jump range, then jump so the whole crossing is airborne.
		# A grounded tick inside the contact window now trips the runner.
		while hj.z > 2.6:
			j.step(1.0 / 120.0)
		j.act("jump")
		var hp_before: int = j.hp
		var score_before: int = j.score
		advance(j, 0.8)
		check(j.hp == hp_before, "jumping clears the hurdle without damage")
		check(j.score == score_before + 25, "clean hurdle pass awards 25 once")
		advance(j, 2.0)
		check(j.score == score_before + 25, "hurdle does not score twice")
	# Different-lane pass scores nothing.
	var s = Model.new()
	s.start(42)
	advance(s, 4.9)
	s.act("right")
	var hs = null
	for e in s.enemies:
		if e.kind == "hurdle": hs = e
	if hs != null:
		while hs.z > 1.2:
			s.step(1.0 / 120.0)
		advance(s, 0.8)
	# player in lane 1, hurdle lane 0: no clean bonus, and no damage either.
	check(s.score == 0 or s.score < 25, "wrong-lane hurdle pass awards no clean bonus")
	print("QUALITY CORE: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
