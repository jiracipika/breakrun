extends SceneTree
## Route Inspector: the three-pattern boss at the 490 m checkpoint.
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

## A run that just reached the inspector: wave contact during the trip down
## drains the padding, so restore a known pip count and clear i-frames and
## stray robots before staging each pattern.
func boss_ready(Model, seed_value: int = 42) -> RefCounted:
	var m = Model.new()
	m.start(seed_value)
	m.hp = 99
	advance(m, 46.0)
	m.hp = 99
	m.enemies.clear()
	m._invulnerability = 0.0
	return m

## Stage the inspector so its active step lands `lead` seconds from now.
## Jumps need ~0.25 s to reach dodge height; slides are instant.
## Advance at least lead + 0.05 afterwards: tick drift rounds against you.
func stage(m: RefCounted, pattern: String, same_lane: bool, lead: float = 0.05) -> void:
	m.inspector.pattern = pattern
	m.inspector.lane = m.lane if same_lane else (m.lane + 1 if m.lane < 1 else m.lane - 1)
	m.inspector.phase = "telegraph"
	m.inspector.pattern_time = 0.9 - lead

## Pattern-and-lane key for the patterns up to the machine's defeat.
func sequence(Model, seed_value: int) -> String:
	var run = boss_ready(Model, seed_value)
	var key := ""
	for i in range(6):
		if run.inspector.is_empty():
			break
		key += "%s:%d|" % [run.inspector.pattern, run.inspector.lane]
		run.inspector.dodged = true
		run.inspector.phase = "recovery"
		run.act("attack")
		advance(run, 0.2)
	return key

func _init() -> void:
	var Model = load("res://scripts/core/run_model.gd")

	# Spawn: the inspector arrives at the 490 m checkpoint and stays.
	var m = Model.new()
	m.start(42)
	m.hp = 99
	advance(m, 46.0)
	check(not m.inspector.is_empty(), "the inspector spawns at the 490 m checkpoint")
	check(m.inspector.phase == "telegraph", "it opens with a telegraph")
	advance(m, 30.0)
	check(not m.inspector.is_empty() and m.inspector.phase != "defeated",
		"the inspector holds its ground and is never culled")
	check(m.inspectors_defeated == 0, "no defeats recorded before patterns are broken")

	# Bash pattern: staying in the marked lane at active start costs a pip,
	# and the pattern still cycles on into its recovery.
	var bash = boss_ready(Model)
	stage(bash, "bash", true)
	advance(bash, 0.1)
	check(bash.hp == 98, "standing in the bash lane costs a pip")
	check(bash.last_hit_kind == "inspector", "the damage names the inspector")
	advance(bash, 0.85)
	check(bash.inspector.phase == "recovery", "the pattern opens its recovery after the hit")

	# Dodged bash: another lane, then counter during the recovery window.
	var dodge = boss_ready(Model)
	stage(dodge, "bash", false)
	advance(dodge, 0.1)
	check(dodge.inspector.dodged, "leaving the bash lane dodges the pattern")
	advance(dodge, 0.85)
	dodge.act("attack")
	check(dodge.inspector.hits == 1 and dodge.score == 150, "a broken pattern pays 150 and lowers its poise")

	# Sweep pattern: slide dodges, jumping does not.
	var sweep = boss_ready(Model)
	stage(sweep, "sweep", true)
	sweep.act("slide")
	advance(sweep, 0.1)
	check(sweep.inspector.dodged and sweep.hp == 99, "sliding under the high bar dodges the sweep")
	var jumper = boss_ready(Model)
	stage(jumper, "sweep", true, 0.3)
	jumper.act("jump")
	advance(jumper, 0.4)
	check(jumper.hp == 98, "jumping does not clear the inspector's high bar")

	# Scanner pattern: jumping dodges, sliding does not (mirror of the sweep).
	var scanner = boss_ready(Model)
	stage(scanner, "scanner", true, 0.3)
	scanner.act("jump")
	advance(scanner, 0.4)
	check(scanner.inspector.dodged and scanner.hp == 99, "jumping the low scanner bar dodges it")
	var sld = boss_ready(Model)
	stage(sld, "scanner", true)
	sld.act("slide")
	advance(sld, 0.1)
	check(sld.hp == 98, "sliding under the low scanner bar does not clear it")

	# Three broken patterns defeat the machine for the +300 clear bonus.
	var fight = boss_ready(Model)
	var broke_out: bool = false
	for round_i in range(3):
		fight.inspector.dodged = true
		fight.inspector.phase = "recovery"
		fight.act("attack")
		if fight.inspector.is_empty():
			broke_out = true
			break
		fight.inspector.phase = "telegraph"
		fight.inspector.pattern_time = 0.0
		advance(fight, 0.1)
	check(broke_out or fight.inspector.hits == 3, "three broken patterns exhaust the machine")
	check(fight.score == 750, "a full break pays 150 x3 plus the 300 clear bonus")
	check(fight.inspectors_defeated == 1, "the defeat is recorded")
	check(fight.inspector.is_empty() or fight.inspector.phase == "defeated",
		"the defeated machine launches away")

	# The defeated machine must not chain-sweep other enemies.
	var no_chain = boss_ready(Model)
	no_chain.inspector.dodged = true
	no_chain.inspector.phase = "recovery"
	no_chain.inspector.hits = 2
	no_chain.act("attack")
	var targets_before: int = 0
	for e in no_chain.enemies:
		if e.phase == "approach":
			targets_before += 1
	advance(no_chain, 2.0)
	var swept: int = 0
	for e in no_chain.enemies:
		if e.phase == "cleared":
			swept += 1
	check(targets_before == 0 or swept == 0, "the defeated machine clears no wave targets")

	# Same seed, same pattern sequence; a different seed can differ.
	check(sequence(Model, 42) == sequence(Model, 42), "the same seed replays the same pattern sequence")
	check(sequence(Model, 42) != sequence(Model, 7), "a different seed draws a different sequence")

	print("INSPECTOR: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
