extends RefCounted
## Logical simulation owns hits and score. Rendering reads but never writes it.

const PLAYER_SPEED: float = 9.0
const MAX_SPEED: float = 14.0
const HURDLE_BONUS: int = 25
const SPAWN_DISTANCE: float = 37.0
const WAVE_SPACING: float = 70.0
const SHIELD_WARNING_Z: float = 12.0
const SHIELD_BASH_Z: float = 9.0
const SHIELD_RECOVERY_Z: float = 6.0
const COUNTER_MIN_Z: float = 2.0
const COUNTER_MAX_Z: float = 6.0
const KICKER_TELEGRAPH_Z: float = 16.0
const KICKER_SWEEP_Z: float = 9.0
const KICKER_RECOVERY_Z: float = 6.0
const SPRING_SWEEP_Z: float = 9.0
const SPRING_RECOVERY_Z: float = 6.0
const BOOST_TIME: float = 1.2
const BOOST_MULT: float = 0.35
const INSPECTOR_DISTANCE: float = 490.0
const INSPECTOR_HOLD_Z: float = 14.0
const INSPECTOR_TELEGRAPH: float = 0.9
const INSPECTOR_ACTIVE: float = 0.7
const INSPECTOR_RECOVERY: float = 1.0
const INSPECTOR_HP: int = 3
const INSPECTOR_BREAK_SCORE: int = 150
const INSPECTOR_CLEAR_SCORE: int = 300
const INSPECTOR_PATTERNS: Array = ["bash", "sweep", "scanner"]

## Perks from design plan §5 (Springstep adapted: the boost lasts longer, since
## lane changes are instant and a mid-air correction has no meaning here).
const UPGRADES := {
	"pinball": "Launched robots ricochet once into the next lane",
	"springstep": "Courier boost lasts half again as long",
	"streetbroom": "Launched robots fly half again as far",
	"relay": "Launched robots passing each other pay a +50 Relay",
	"second wind": "A flawless inspector clear restores one pip",
}
const STAGGER_TIME: float = 1.0
const STAGGER_SLOWDOWN: float = 0.8
const INPUT_BUFFER: float = 0.25
## Lane traversal timing. Logical lane selection is instant (act() sets lane
## immediately) while the scene's runner visually blends toward the selected
## lane exponentially at LANE_RATE per second (main.gd shares this constant).
## A crossing is effectively complete — 95% of the 2.5-unit lane span — after
## log(20)/LANE_RATE seconds, about 0.19 s. Any hazard that demands a lane
## switch must leave at least this long, or it asks the player to be somewhere
## their runner is visibly not yet.
const LANE_RATE: float = 16.0
const LANE_TRAVERSAL_TIME: float = log(20.0) / LANE_RATE
# Wave archetypes: [kind, z offset]. Checkpoint is the teaching chain wave;
# patrol and fence vary lanes while keeping one shield and readable spacing.
const CHECKPOINT_WAVE: Array = [["shield", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["barrier", 18.0], ["hurdle", 24.0]]
const PATROL_WAVE: Array = [["shield", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["dummy", 18.0]]
const FENCE_WAVE: Array = [["shield", 0.0], ["barrier", 8.0], ["hurdle", 16.0]]
const SWEEP_WAVE: Array = [["kicker", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["hurdle", 18.0]]
const SPRING_WAVE: Array = [["spring", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["dummy", 18.0]]

var state: String = "title"
var lane: int = 0
var distance: float = 0.0
var hp: int = 3
var score: int = 0
var combo: int = 0
var height: float = 0.0
var sliding: bool = false
var time: float = 0.0
var feedback: String = ""
var feedback_time: float = 0.0
var enemies: Array = []
var counter_count: int = 0
var chain_count: int = 0
var last_counter_lane: int = 0
var run_seed: int = 42
var last_hit_kind: String = ""
var best_combo: int = 0
var boost_count: int = 0
var inspector: Dictionary = {}
var inspector_hits: int = 0
var inspectors_defeated: int = 0
var owned_upgrades: Array = []
var upgrade_offer: Array = []
var relays: Dictionary = {}
var _inspector_damaged: bool = false
var _stagger: float = 0.0
var _boost: float = 0.0
var _buffered_action: String = ""
var _buffer_time: float = 0.0
var _waves_spawned: int = 0
var _rng := RandomNumberGenerator.new()
var _next_id: int = 0
var _next_wave_distance: float = WAVE_SPACING
var _invulnerability: float = 0.0
var _jump: float = 0.0
var _slide: float = 0.0

func start(seed_value: int = 42) -> void:
	_rng.seed = seed_value
	run_seed = seed_value
	state = "running"
	lane = 0
	distance = 0.0
	hp = 3
	score = 0
	combo = 0
	height = 0.0
	sliding = false
	time = 0.0
	feedback = ""
	feedback_time = 0.0
	enemies.clear()
	counter_count = 0
	chain_count = 0
	last_counter_lane = 0
	last_hit_kind = ""
	best_combo = 0
	boost_count = 0
	inspector = {}
	inspector_hits = 0
	inspectors_defeated = 0
	owned_upgrades = []
	upgrade_offer = []
	relays = {}
	_inspector_damaged = false
	_stagger = 0.0
	_boost = 0.0
	_buffered_action = ""
	_buffer_time = 0.0
	_waves_spawned = 0
	_next_id = 0
	_next_wave_distance = WAVE_SPACING
	_invulnerability = 0.0
	_jump = 0.0
	_slide = 0.0
	_spawn_wave(SPAWN_DISTANCE)

func act(action: String) -> void:
	if state != "running" or not upgrade_offer.is_empty():
		return
	match action:
		"left": lane = maxi(-1, lane - 1)
		"right": lane = mini(1, lane + 1)
		"jump":
			if _jump <= 0.0 and _slide <= 0.0:
				_jump = 0.5
			else:
				_buffer("jump")
		"slide":
			if _slide <= 0.0 and _jump <= 0.0:
				_slide = 0.5
				sliding = true
			else:
				_buffer("slide")
		"attack": _try_counter()

func toggle_pause() -> void:
	if state == "running":
		state = "paused"
	elif state == "paused":
		state = "running"

func step(delta: float) -> void:
	if state != "running" or not upgrade_offer.is_empty() or not is_finite(delta) or delta <= 0.0:
		return
	# Small bounded steps prevent collision and phase tunneling on slow frames.
	var remaining: float = minf(delta, 1.0)
	while remaining > 0.00000001 and state == "running":
		var dt: float = minf(remaining, 1.0 / 120.0)
		_tick(dt)
		remaining -= dt

## Current forward speed. Grows gently with distance, hard-capped so late runs stay readable.
func speed() -> float:
	return minf(PLAYER_SPEED + distance * 0.02, MAX_SPEED)

## World speed with the hit-stagger slowdown and courier boost applied. Player,
## enemies and projectiles all move at this, so stumbles and boosts read as the
## whole run lurching or surging.
func world_speed() -> float:
	var factor: float = 1.0
	if _stagger > 0.0:
		factor *= 1.0 - STAGGER_SLOWDOWN * (_stagger / STAGGER_TIME)
	if _boost > 0.0:
		factor *= 1.0 + BOOST_MULT * (_boost / _boost_time())
	if factor == 1.0:
		return speed()
	return speed() * factor

## 1.0 right after a hit, easing to 0.0 as the stagger recovers.
func stagger_ratio() -> float:
	return clampf(_stagger / STAGGER_TIME, 0.0, 1.0)

## Boost window, stretched by the Springstep perk.
func _boost_time() -> float:
	return BOOST_TIME * 1.5 if _has_perk("springstep") else BOOST_TIME

## How long a launched robot stays airborne, stretched by Street broom.
func _launched_max_age() -> float:
	return 1.5 * 1.5 if _has_perk("streetbroom") else 1.5

## 1.0 right after an aerial strike, easing to 0.0 as the boost fades.
func boost_ratio() -> float:
	return clampf(_boost / _boost_time(), 0.0, 1.0)

## Style multiplier: 1.0 at combo 0, +0.25 per uninterrupted success, capped at 3.0.
func style_multiplier() -> float:
	return 1.0 + 0.25 * mini(combo, 8)

## Award for a score event at the current style level. Integer math keeps awards
## exact and deterministic: base x (4 + combo, capped 8) / 4.
func _event_score(base: int) -> int:
	@warning_ignore("integer_division")
	return base * (4 + mini(combo, 8)) / 4

func _reward(base: int) -> void:
	score += _event_score(base)
	combo += 1
	best_combo = maxi(best_combo, combo)

func _buffer(action: String) -> void:
	_buffered_action = action
	_buffer_time = INPUT_BUFFER

## Shared damage path: pip loss, style reset, stagger, readable cause.
func _damage(kind: String) -> void:
	if _invulnerability > 0.0:
		return
	hp -= 1
	combo = 0
	last_hit_kind = kind
	_stagger = STAGGER_TIME
	_invulnerability = 1.0
	if not inspector.is_empty():
		_inspector_damaged = true
	_message("Hit! Change lane before contact.", 1.5)
	if hp <= 0:
		state = "dead"
		_message("Run ended. Try the recovery counter.", 999.0)

func take_upgrade(name: String) -> void:
	if upgrade_offer.has(name) and UPGRADES.has(name) and not owned_upgrades.has(name):
		owned_upgrades.append(name)
		upgrade_offer.clear()
		_message("%s acquired!" % name.capitalize(), 1.4)

func _draw_upgrade_offer() -> void:
	upgrade_offer.clear()
	var unowned: Array = []
	for name in UPGRADES:
		if not owned_upgrades.has(name):
			unowned.append(name)
	if unowned.is_empty():
		return
	if unowned.size() == 1:
		upgrade_offer.append(unowned[0])
		return
	var first: int = _rng.randi_range(0, unowned.size() - 1)
	var second: int = _rng.randi_range(0, unowned.size() - 2)
	if second >= first:
		second += 1
	upgrade_offer.append(unowned[first])
	upgrade_offer.append(unowned[second])

func _has_perk(name: String) -> bool:
	return owned_upgrades.has(name)

## Fire a buffered jump/slide the moment it becomes executable.
func _try_buffered_action() -> void:
	if _buffered_action == "jump" and _jump <= 0.0 and _slide <= 0.0:
		_buffered_action = ""
		act("jump")
	elif _buffered_action == "slide" and _slide <= 0.0 and _jump <= 0.0:
		_buffered_action = ""
		act("slide")

func _tick(dt: float) -> void:
	time += dt
	var current_speed: float = world_speed()
	distance += current_speed * dt
	_jump = maxf(0.0, _jump - dt)
	_slide = maxf(0.0, _slide - dt)
	_invulnerability = maxf(0.0, _invulnerability - dt)
	_stagger = maxf(0.0, _stagger - dt)
	_boost = maxf(0.0, _boost - dt)
	_boost = minf(_boost, _boost_time())
	_buffer_time = maxf(0.0, _buffer_time - dt)
	if _buffer_time == 0.0:
		_buffered_action = ""
	_try_buffered_action()
	height = 1.5 * sin((1.0 - _jump / 0.5) * PI) if _jump > 0.000001 else 0.0
	sliding = _slide > 0.000001
	feedback_time = maxf(0.0, feedback_time - dt)
	if feedback_time == 0.0:
		feedback = ""
	for e in enemies:
		e["previous_z"] = e.z
		e.z += ((current_speed + 18.0) if e.phase == "launched" else -current_speed) * dt
		if e.phase == "launched":
			e["age"] += dt
		elif e.kind == "shield" and e.phase != "cleared":
			if e.z <= SHIELD_RECOVERY_Z:
				e.phase = "recovery"
			elif e.z <= SHIELD_BASH_Z:
				e.phase = "bash"
				if e.lane != lane:
					e.dodged = true
		elif e.kind == "kicker" and e.phase != "cleared":
			if e.z <= KICKER_RECOVERY_Z:
				e.phase = "recovery"
			elif e.z <= KICKER_SWEEP_Z:
				e.phase = "sweep"
				if not e["swept"]:
					e["swept"] = true
					if e.lane != lane or sliding:
						# Sliding under the high sweep — or not being there — dodges it.
						e.dodged = true
					else:
						# The sweep is high: jumping does not clear it.
						_damage("kicker")
		elif e.kind == "spring" and e.phase != "cleared":
			if e.z <= SPRING_RECOVERY_Z:
				e.phase = "recovery"
			elif e.z <= SPRING_SWEEP_Z:
				e.phase = "sweep"
				if not e["swept"]:
					e["swept"] = true
					if e.lane != lane or height > 0.5:
						# The sweep is low: only air clears it.
						e.dodged = true
					else:
						_damage("spring")
	# Advance projectiles before testing ordinary contact. Each target scores once.
	for projectile in enemies:
		if projectile.phase != "launched":
			continue
		for target in enemies:
			# Hurdles are only cleared by player evasion, never by projectiles;
			# launched robots are projectiles and cannot strike anything —
			# including themselves.
			if target.phase == "cleared" or target.phase == "launched" or target.kind == "shield" or target.kind == "hurdle" or target.lane != projectile.lane:
				continue
			if target.z >= projectile.previous_z - current_speed * dt and target.z <= projectile.z + 0.5:
				target.phase = "cleared"
				projectile["hits"] += 1
				if projectile.hits == 1:
					chain_count += 1
				_reward(150 if target.kind == "barrier" else 100)
				_message("Checkpoint cleared!" if projectile.hits >= 3 else "Chain x%d!" % projectile.hits, 1.5)
			# Pinball: after its first strike the projectile hops one lane
			# toward another strike-able target, once per launch.
			if projectile.hits >= 1 and _has_perk("pinball") and not projectile["ricocheted"]:
				for side in [1, -1]:
					var next_lane: int = clampi(int(projectile.lane) + side, -1, 1)
					if next_lane == int(projectile.lane):
						continue
					var quarry: bool = false
					for candidate in enemies:
						if candidate.phase != "cleared" and candidate.phase != "launched" \
								and candidate.kind != "shield" and candidate.kind != "hurdle" \
								and int(candidate.lane) == next_lane \
								and candidate.z >= projectile.z - 2.0 and candidate.z <= projectile.z + 24.0:
							quarry = true
					if quarry:
						projectile.lane = next_lane
						projectile["ricocheted"] = true
						_message("Pinball!", 1.2)
						break
	# Relay: launched robots that cross paths pay a one-time bonus.
	if _has_perk("relay"):
		var flyers: Array = []
		for e in enemies:
			if e.phase == "launched":
				flyers.append(e)
		for i in range(flyers.size()):
			for j in range(i + 1, flyers.size()):
				var pair: String = "%d_%d" % [mini(flyers[i].id, flyers[j].id), maxi(flyers[i].id, flyers[j].id)]
				if not relays.has(pair) and absf(flyers[i].z - flyers[j].z) < 1.2:
					relays[pair] = true
					score += 50
					_message("Relay!", 1.0)
	for e in enemies:
		if e.phase == "cleared" or e.phase == "launched":
			continue
		if e.z <= 0.8 and e.previous_z >= -0.8 and e.lane == lane:
			if e.kind == "hurdle":
				# Airborne or sliding passes are intentional evasion, not contact.
				if height > 0.5 or sliding:
					if not e["rewarded"]:
						e["rewarded"] = true
						e.phase = "cleared"
						_reward(HURDLE_BONUS)
						_message("Clean!", 0.8)
					continue
				# Same lane without evasion trips the runner into the damage path.
			if e.kind == "kicker" and sliding:
				continue  # a slide slips between the fork legs
			if _invulnerability <= 0.0:
				_damage(e.kind)
				e.phase = "cleared"
	# No mutation of array structure during iteration.
	enemies = enemies.filter(func(e: Dictionary) -> bool:
		return e.z >= -5.0 and (e.phase != "launched" or e.age < _launched_max_age()))
	_tick_inspector(dt)
	if distance >= _next_wave_distance and state == "running":
		_spawn_wave(SPAWN_DISTANCE - (distance - _next_wave_distance))
		_next_wave_distance += WAVE_SPACING
	if inspector.is_empty() and distance >= INSPECTOR_DISTANCE * float(inspectors_defeated + 1):
		inspector = {"lane": 0, "pattern": INSPECTOR_PATTERNS[_rng.randi_range(0, 2)],
			"phase": "telegraph", "pattern_time": 0.0, "hits": 0, "dodged": false}
		_inspector_damaged = false

## The checkpoint machine: telegraph a taught pattern, punish failure at the
## active step, open the counter window, roll the next pattern.
func _tick_inspector(dt: float) -> void:
	if inspector.is_empty():
		return
	inspector.pattern_time += dt
	var pattern: String = inspector.pattern
	if inspector.phase == "telegraph" and inspector.pattern_time >= INSPECTOR_TELEGRAPH:
		inspector.phase = "active"
		inspector.pattern_time = 0.0
		inspector.dodged = false
		var in_lane: bool = inspector.lane == lane
		match pattern:
			"bash":
				inspector.dodged = not in_lane
			"sweep":
				inspector.dodged = not in_lane or sliding
			"scanner":
				inspector.dodged = not in_lane or height > 0.5
		if not inspector.dodged:
			_damage("inspector")
	elif inspector.phase == "active" and inspector.pattern_time >= INSPECTOR_ACTIVE:
		inspector.phase = "recovery"
		inspector.pattern_time = 0.0
	elif inspector.phase == "recovery" and inspector.pattern_time >= INSPECTOR_RECOVERY:
		_next_inspector_pattern()

func _next_inspector_pattern() -> void:
	inspector.phase = "telegraph"
	inspector.pattern_time = 0.0
	inspector.dodged = false
	var next: int = _rng.randi_range(0, 2)
	if INSPECTOR_PATTERNS[next] == inspector.pattern:
		next = (next + 1) % 3  # never repeat the same pattern twice in a row
	inspector.pattern = INSPECTOR_PATTERNS[next]
	var shift: int = _rng.randi_range(-1, 1)
	inspector.lane = clampi(int(inspector.lane) + shift, -1, 1)

func _break_inspector() -> void:
	inspector.hits += 1
	inspector_hits += 1
	score += INSPECTOR_BREAK_SCORE
	if inspector.hits >= INSPECTOR_HP:
		score += INSPECTOR_CLEAR_SCORE
		inspectors_defeated += 1
		if _has_perk("second wind") and not _inspector_damaged and hp < 3:
			hp += 1
			_message("Second wind!", 1.6)
		else:
			_message("ROUTE CLEARED!", 1.6)
		inspector = {}
		_draw_upgrade_offer()
	else:
		_message("Pattern broken!  %d / %d" % [inspector.hits, INSPECTOR_HP], 1.2)
		_next_inspector_pattern()

## Lane assignment for every member of an archetype wave given its target lane.
## The one source of truth for both spawning and reachability checks, so a
## future layout change cannot make them disagree.
static func wave_member_lanes(archetype: Array, target_lane: int) -> Array:
	var neighbor: int = clampi(target_lane + (1 if target_lane <= 0 else -1), -1, 1)
	var lanes: Array = []
	for i in range(archetype.size()):
		var lane: int = target_lane
		if archetype == PATROL_WAVE and i == 2:
			lane = neighbor
		elif archetype == SWEEP_WAVE and i == 1:
			lane = neighbor
		elif archetype == SPRING_WAVE and (i == 1 or i == 2):
			lane = neighbor
		elif archetype == FENCE_WAVE and i == 1:
			lane = neighbor
		elif archetype == FENCE_WAVE and i == 2:
			lane = 0 if neighbor == 1 else -1
		lanes.append(lane)
	return lanes

## Kinds whose only grounded answer is "not this lane" when the member arrives.
## Hurdles are answered in place (jump/slide), and the kicker/spring sweeps keep
## an in-lane verb (slide/jump), so none of them strictly demand a lane switch.
static func kind_locks_lane(kind: String) -> bool:
	return kind == "shield" or kind == "dummy" or kind == "barrier"

## Shortest time a wave layout demands for a lane switch: the closest pair of
## consecutive lane-locked members placed in different lanes, measured at the
## speed cap (the fastest the world ever moves, so the shortest real window).
## INF when no pair in the layout demands a switch at all.
static func wave_switch_window(archetype: Array, target_lane: int) -> float:
	var lanes := wave_member_lanes(archetype, target_lane)
	var window: float = INF
	for i in range(archetype.size() - 1):
		if kind_locks_lane(archetype[i][0]) and kind_locks_lane(archetype[i + 1][0]) \
				and int(lanes[i]) != int(lanes[i + 1]):
			var gap: float = float(archetype[i + 1][1] - archetype[i][1]) / MAX_SPEED
			window = minf(window, gap)
	return window

func _spawn_wave(z: float) -> void:
	# The first two waves teach the checkpoint chain; later waves draw an
	# archetype from the seed so runs vary while staying readable and fair.
	var archetype: Array = CHECKPOINT_WAVE
	var target_lane: int = 0
	if _waves_spawned >= 1:
		target_lane = _rng.randi_range(-1, 1)
	if _waves_spawned >= 2:
		match _rng.randi_range(0, 4):
			0:
				archetype = PATROL_WAVE
			1:
				archetype = FENCE_WAVE
			2:
				archetype = SWEEP_WAVE
			3:
				archetype = SPRING_WAVE
			4:
				pass
	# Reachability gate before hazards combine: a layout that demanded a lane
	# switch faster than the visual traversal allows must never ship. Stripped
	# from release exports; tests/test_traversal.gd checks the same invariant
	# explicitly across every archetype and target lane.
	assert(wave_switch_window(archetype, target_lane) >= LANE_TRAVERSAL_TIME,
		"wave demands a lane switch faster than lane traversal allows")
	var lanes := wave_member_lanes(archetype, target_lane)
	for i in range(archetype.size()):
		var member: Array = archetype[i]
		enemies.append({"id": _next_id, "kind": member[0], "lane": lanes[i],
			"z": z + member[1], "phase": "approach", "dodged": false,
			"age": 0.0, "hits": 0, "rewarded": false, "swept": false, "ricocheted": false, "previous_z": z + member[1]})
		_next_id += 1
	_waves_spawned += 1

func _try_counter() -> void:
	var nearest: Dictionary = {}
	for e in enemies:
		if e.phase == "launched" and feedback_time > 0.0:
			return # Repeated taps must not overwrite earned success feedback.
		var strikeable: bool = (e.kind == "shield" or e.kind == "kicker" or e.kind == "spring") and e.phase != "cleared" and e.phase != "launched"
		if strikeable:
			if nearest.is_empty() or e.z < nearest.z:
				nearest = e
	# The checkpoint machine takes priority while its counter window is open.
	if not inspector.is_empty() and inspector.phase == "recovery":
		if not inspector.dodged:
			_message("Break its pattern first!", 0.8)
		else:
			_break_inspector()
			return
	if nearest.is_empty():
		_message("Watch for the next shield.", 0.8)
	elif nearest.z > COUNTER_MAX_Z:
		_message("Wait for recovery — dodge the marked lane.", 0.8)
	elif nearest.z < COUNTER_MIN_Z:
		_message("Too late. Counter while the ring is open.", 0.8)
	elif not nearest.dodged:
		if nearest.kind == "kicker":
			_message("Slide under its sweep first!", 0.8)
		elif nearest.kind == "spring":
			_message("Jump its low sweep first!", 0.8)
		else:
			_message("Dodge its bash first!", 0.8)
	elif nearest.kind == "spring" and height <= 0.5:
		_message("Strike it mid-air!", 0.8)
	elif absi(int(nearest.lane) - lane) > 1:
		_message("Move beside it to counter.", 0.8)
	else:
		nearest.phase = "launched"
		counter_count += 1
		last_counter_lane = nearest.lane
		_reward(50)
		if nearest.kind == "spring":
			# The courier springs away and shoves the runner forward.
			boost_count += 1
			_boost = _boost_time()
			_message("Boost!", 1.0)
		else:
			_message("Swept!" if nearest.kind == "kicker" else "Counter!", 1.0)

func _message(text: String, duration: float) -> void:
	feedback = text
	feedback_time = duration
