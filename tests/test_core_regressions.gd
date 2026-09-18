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
	advance(model, 3.6)
	return model

func _init() -> void:
	var model = Model.new()
	model.start(42)
	model.step(0.0)
	check(model.enemies.size() == 4, "zero delta cannot create duplicate waves")
	model.step(1.0 / 60.0)
	check(model.enemies.size() == 4, "first frame has only the initial four enemies")
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
	advance(model, 0.9)
	check(model.chain_count == 1, "three physically reached targets form one chain")
	var cleared: int = 0
	for e in model.enemies:
		if e.phase == "cleared":
			cleared += 1
	check(cleared == 3, "chain clears exactly its two dummies and barricade")
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
	var max_enemies: int = 0
	for i in range(36000):
		# Move to a safe lane using public controls, so death cannot fake a soak.
		for e in model.enemies:
			if e.z < 13 and e.z > 0 and e.lane == model.lane:
				model.act("left" if model.lane >= 0 else "right")
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
