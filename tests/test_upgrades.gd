extends SceneTree
## Perks after the inspector: offers, freeze, and the five effects.
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

## A run that just reached the inspector, cleaned for staging.
func boss_ready(Model, seed_value: int = 42) -> RefCounted:
	var m = Model.new()
	m.start(seed_value)
	m.hp = 99
	advance(m, 46.0)
	m.hp = 3
	m.enemies.clear()
	m._invulnerability = 0.0
	return m

## Break the live inspector's pattern once through the public counter path.
func break_pattern(m: RefCounted) -> void:
	m.inspector.dodged = true
	m.inspector.phase = "recovery"
	m.act("attack")
	advance(m, 0.2)

func launched(m: RefCounted, id: int, lane: int, z: float) -> void:
	m.enemies.append({"id": id, "kind": "dummy", "lane": lane, "z": z,
		"phase": "launched", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": true, "swept": true, "ricocheted": true, "previous_z": z})

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# Defeat draws a two-perk offer and freezes the world until a pick.
	var run = boss_ready(Model)
	for round_i in range(3):
		break_pattern(run)
	check(run.inspectors_defeated == 1, "the inspector is defeated")
	check(run.upgrade_offer.size() == 2, "the defeat offers two perks")
	check(run.upgrade_offer[0] != run.upgrade_offer[1], "the offer never repeats a perk")
	check(not run.owned_upgrades.has(run.upgrade_offer[0]), "the offer excludes owned perks")
	var frozen_distance: float = run.distance
	var frozen_lane: int = run.lane
	advance(run, 1.0)
	check(run.distance == frozen_distance, "the world freezes during the choice")
	run.act("left")
	check(run.lane == frozen_lane, "inputs freeze during the choice")
	run.take_upgrade(run.upgrade_offer[0])
	check(run.upgrade_offer.is_empty() and run.owned_upgrades.size() == 1,
		"picking a card resumes the run and owns the perk")
	var resumed: float = run.distance
	advance(run, 0.5)
	check(run.distance > resumed, "the run moves again after the pick")

	# Pinball: after its first own-lane strike, the projectile hops to the
	# adjacent lane's target and scores it.
	var pin = boss_ready(Model)
	pin.owned_upgrades.append("pinball")
	pin.enemies.append({"id": 50, "kind": "shield", "lane": 0, "z": 4.0,
		"phase": "launched", "dodged": true, "age": 0.0, "hits": 0,
		"rewarded": true, "swept": true, "ricocheted": false, "previous_z": 4.0})
	pin.enemies.append({"id": 51, "kind": "dummy", "lane": 0, "z": 6.0,
		"phase": "approach", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": false, "swept": false, "ricocheted": false, "previous_z": 6.0})
	pin.enemies.append({"id": 52, "kind": "dummy", "lane": 1, "z": 9.0,
		"phase": "approach", "dodged": false, "age": 0.0, "hits": 0,
		"rewarded": false, "swept": false, "ricocheted": false, "previous_z": 9.0})
	advance(pin, 1.2)
	check(pin.score == 100 + 125, "pinball scores its own lane and the ricochet lane")
	var bounced: bool = false
	for e in pin.enemies:
		if e.id == 50:
			bounced = bool(e.ricocheted)
	check(bounced, "the projectile marks its ricochet once")

	# Springstep: the boost decays half again as slowly.
	var tail = boss_ready(Model)
	tail.owned_upgrades.append("springstep")
	tail.boost_count = 1
	tail._boost = tail._boost_time()
	advance(tail, 1.4)
	check(tail._boost > 0.0, "springstep keeps the boost alive past 1.2 s")
	advance(tail, 0.6)
	check(is_zero_approx(tail._boost), "springstep's boost still ends")

	# Street broom: launched robots fly to 2.25 s before despawning.
	var broom = boss_ready(Model)
	broom.owned_upgrades.append("streetbroom")
	launched(broom, 60, -1, 30.0)
	advance(broom, 1.6)
	var still_flying: bool = false
	for e in broom.enemies:
		if e.id == 60:
			still_flying = true
	check(still_flying, "street broom keeps launched robots past 1.5 s")
	advance(broom, 1.0)
	still_flying = false
	for e in broom.enemies:
		if e.id == 60:
			still_flying = true
	check(not still_flying, "street broom's robots still despawn")

	# Relay: two launched robots crossing pay +50 exactly once.
	var relay = boss_ready(Model)
	relay.owned_upgrades.append("relay")
	launched(relay, 70, -1, 20.0)
	launched(relay, 71, 1, 20.5)
	var base: int = relay.score
	advance(relay, 0.5)
	check(relay.score == base + 50, "crossing launched robots pay one relay")
	advance(relay, 1.0)
	check(relay.score == base + 50, "the same pair never pays twice")

	# Second wind: a flawless clear heals one pip, capped at three.
	var wind = boss_ready(Model)
	wind.owned_upgrades.append("second wind")
	wind.hp = 2
	for round_i in range(3):
		break_pattern(wind)
	check(wind.hp == 3, "a flawless clear restores one pip")
	check(wind.inspector.is_empty(), "second wind still defeats the machine")
	var unhurt = boss_ready(Model)
	unhurt.hp = 3
	for round_i in range(3):
		break_pattern(unhurt)
	check(unhurt.hp == 3, "second wind never exceeds three pips")
	var hurt = boss_ready(Model)
	hurt.owned_upgrades.append("second wind")
	hurt.hp = 2
	hurt.inspector.dodged = false
	hurt.inspector.phase = "telegraph"
	hurt.inspector.pattern_time = 0.85
	advance(hurt, 0.1)
	check(hurt.hp == 1, "the staged fight damage registers")
	for round_i in range(3):
		if hurt.inspector.is_empty():
			break
		break_pattern(hurt)
	check(hurt.hp == 1, "a damaged clear earns no heal")

	# Offers never include owned perks; an exhausted pool offers nothing.
	var picky = boss_ready(Model)
	for name in ["pinball", "springstep", "streetbroom", "relay"]:
		picky.owned_upgrades.append(name)
	for round_i in range(3):
		break_pattern(picky)
	if not picky.upgrade_offer.is_empty():
		picky.take_upgrade(picky.upgrade_offer[0])
		if not picky.upgrade_offer.is_empty():
			picky.take_upgrade(picky.upgrade_offer[0])
	check(picky.owned_upgrades.has("second wind"), "the last perk is still offered")
	check(picky.upgrade_offer.is_empty() or not picky.owned_upgrades.has(picky.upgrade_offer[0]),
		"offers exclude owned perks")

	print("UPGRADES: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
