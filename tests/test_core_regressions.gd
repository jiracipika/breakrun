extends SceneTree

const Model = preload("res://scripts/core/run_model.gd")
var total: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	total += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func advance(model: RefCounted, duration: float, dt: float = 1.0 / 60.0) -> void:
	for i in range(roundi(duration / dt)):
		model.step(dt)

func prepared() -> RefCounted:
	var model = Model.new()
	model.start(42)
	model.act("right")
	# Advance to the recovery window itself; a fixed duration overshoots at ramped speed.
	var waited: float = 0.0
	while waited < 6.0 and not (model.enemies[0].phase == "recovery" and model.enemies[0].z <= 6.0 and model.enemies[0].z >= 2.0):
		model.step(1.0 / 120.0)
		waited += 1.0 / 120.0
	return model

func _init() -> void:
	var model = Model.new()
	model.start(42)
	model.step(0.0)
	check(model.enemies.size() == 5, "zero delta cannot create duplicate waves")
	model.step(1.0 / 60.0)
	check(model.enemies.size() == 5, "first frame has only the initial wave")
	model.act("jump")
	advance(model, 0.6)
	check(is_zero_approx(model.height), "jump lands without sinking below roof")
	model = prepared()
	check(model.enemies[0].phase == "recovery" and model.enemies[0].dodged, "actual stepped dodge reaches recovery")
	model.act("attack")
	check(model.counter_count == 1, "actual dodge can counter")
	check(model.enemies[1].phase != "cleared", "counter does not instantly erase distant targets")
	var success: String = model.feedback
	var start_z: float = model.enemies[0].z
	model.act("attack")
	check(model.feedback == success, "repeated attack preserves success feedback")
	model.step(1.0 / 60.0)
	check(model.enemies[0].z > start_z, "launched shield travels forward using delta")
	var traveled: float = 0.0
	while traveled < 3.0 and model.chain_count == 0:
		model.step(1.0 / 120.0)
		traveled += 1.0 / 120.0
	check(model.chain_count == 1, "three physically reached targets form one chain")
	# Let the projectile finish sweeping all three targets before asserting the settled score.
	while traveled < 4.0 and model.feedback_time > 0.0:
		model.step(1.0 / 120.0)
		traveled += 1.0 / 120.0
	check(model.score == 587, "chain scores counter 50 + styled hits 125/150/262")
	var score_before: int = model.score
	model.act("attack")
	check(model.score == score_before, "duplicate attack adds no score")
	var fine = prepared()
	var coarse = prepared()
	fine.act("attack")
	coarse.act("attack")
	advance(fine, 0.6, 1.0 / 120.0)
	advance(coarse, 0.6, 1.0 / 30.0)
	check(fine.score == coarse.score, "chain score does not depend on frame partition")
	check(is_equal_approx(fine.enemies[0].z, coarse.enemies[0].z), "projectile trajectory does not depend on frame partition")
	model = Model.new()
	model.start(42)
	# Padded integrity: the soak measures population bounds and traversal over
	# time, not survival skill against multi-lane wave archetypes.
	model.hp = 99
	var max_enemies: int = 0
	for i in range(36000):
		# Dodge into a lane with no approaching enemy, so death cannot fake a soak.
		var occupied := {}
		for e in model.enemies:
			if e.z < 14.0 and e.z > 0.0 and e.phase != "cleared":
				occupied[int(e.lane)] = true
		# The inspector is not a wave member: the soak AI must read its
		# telegraph like a player would or eat every bash.
		if not model.inspector.is_empty() and model.inspector.pattern == "bash" \
				and model.inspector.phase in ["telegraph", "active"]:
			occupied[int(model.inspector.lane)] = true
		if occupied.has(model.lane):
			var candidate: int = model.lane
			for offset in [1, -1, 2, -2]:
				var option: int = clampi(model.lane + offset, -1, 1)
				if not occupied.has(option):
					candidate = option
					break
			if candidate > model.lane:
				model.act("right")
			elif candidate < model.lane:
				model.act("left")
		model.step(1.0 / 60.0)
		max_enemies = maxi(max_enemies, model.enemies.size())
	check(model.state == "running", "ten-minute soak genuinely stays alive")
	check(model.distance > 5390.0, "ten-minute soak traverses the whole duration")
	check(max_enemies <= 12, "ten-minute soak keeps enemy population bounded")
	var nearest: float = 9999
	for e in model.enemies:
		if e.z > 0:
			nearest = minf(nearest, e.z)
	check(nearest < 110, "late waves use relative, not absolute, spawn coordinates")
	print("REGRESSIONS: %d/%d checks passed; max enemies %d" % [total-failures,total,max_enemies])
	quit(1 if failures else 0)
