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
const STAGGER_TIME: float = 1.0
const STAGGER_SLOWDOWN: float = 0.8
const INPUT_BUFFER: float = 0.25
# Wave archetypes: [kind, z offset]. Checkpoint is the teaching chain wave;
# patrol and fence vary lanes while keeping one shield and readable spacing.
const CHECKPOINT_WAVE: Array = [["shield", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["barrier", 18.0], ["hurdle", 24.0]]
const PATROL_WAVE: Array = [["shield", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["dummy", 18.0]]
const FENCE_WAVE: Array = [["shield", 0.0], ["barrier", 8.0], ["hurdle", 16.0]]
const SWEEP_WAVE: Array = [["kicker", 0.0], ["dummy", 6.0], ["dummy", 12.0], ["hurdle", 18.0]]

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
var _stagger: float = 0.0
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
	_stagger = 0.0
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
	if state != "running":
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
	if state != "running" or not is_finite(delta) or delta <= 0.0:
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

## World speed with the hit-stagger slowdown applied. Player, enemies and
## projectiles all move at this, so a stumble reads as the whole run lurching.
func world_speed() -> float:
	if _stagger <= 0.0:
		return speed()
	return speed() * (1.0 - STAGGER_SLOWDOWN * (_stagger / STAGGER_TIME))

## 1.0 right after a hit, easing to 0.0 as the stagger recovers.
func stagger_ratio() -> float:
	return clampf(_stagger / STAGGER_TIME, 0.0, 1.0)

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
	_message("Hit! Change lane before contact.", 1.5)
	if hp <= 0:
		state = "dead"
		_message("Run ended. Try the recovery counter.", 999.0)

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
	# Advance projectiles before testing ordinary contact. Each target scores once.
	for projectile in enemies:
		if projectile.phase != "launched":
			continue
		for target in enemies:
			# Hurdles are only cleared by player evasion, never by projectiles.
			if target.phase == "cleared" or target.kind == "shield" or target.kind == "hurdle" or target.lane != projectile.lane:
				continue
			if target.z >= projectile.previous_z - current_speed * dt and target.z <= projectile.z + 0.5:
				target.phase = "cleared"
				projectile["hits"] += 1
				if projectile.hits == 1:
					chain_count += 1
				_reward(150 if target.kind == "barrier" else 100)
				_message("Checkpoint cleared!" if projectile.hits >= 3 else "Chain x%d!" % projectile.hits, 1.5)
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
		return e.z >= -5.0 and (e.phase != "launched" or e.age < 1.5))
	if distance >= _next_wave_distance and state == "running":
		_spawn_wave(SPAWN_DISTANCE - (distance - _next_wave_distance))
		_next_wave_distance += WAVE_SPACING

func _spawn_wave(z: float) -> void:
	# The first two waves teach the checkpoint chain; later waves draw an
	# archetype from the seed so runs vary while staying readable and fair.
	var archetype: Array = CHECKPOINT_WAVE
	var target_lane: int = 0
	if _waves_spawned >= 1:
		target_lane = _rng.randi_range(-1, 1)
	if _waves_spawned >= 2:
		match _rng.randi_range(0, 3):
			0:
				archetype = PATROL_WAVE
			1:
				archetype = FENCE_WAVE
			2:
				archetype = SWEEP_WAVE
			3:
				pass
	var neighbor: int = clampi(target_lane + (1 if target_lane <= 0 else -1), -1, 1)
	for i in range(archetype.size()):
		var member: Array = archetype[i]
		var lane: int = target_lane
		if archetype == PATROL_WAVE and i == 2:
			lane = neighbor
		elif archetype == SWEEP_WAVE and i == 1:
			lane = neighbor
		elif archetype == FENCE_WAVE and i == 1:
			lane = neighbor
		elif archetype == FENCE_WAVE and i == 2:
			lane = 0 if neighbor == 1 else -1
		enemies.append({"id": _next_id, "kind": member[0], "lane": lane,
			"z": z + member[1], "phase": "approach", "dodged": false,
			"age": 0.0, "hits": 0, "rewarded": false, "swept": false, "previous_z": z + member[1]})
		_next_id += 1
	_waves_spawned += 1

func _try_counter() -> void:
	var nearest: Dictionary = {}
	for e in enemies:
		if e.phase == "launched" and feedback_time > 0.0:
			return # Repeated taps must not overwrite earned success feedback.
		var strikeable: bool = (e.kind == "shield" or e.kind == "kicker") and e.phase != "cleared" and e.phase != "launched"
		if strikeable:
			if nearest.is_empty() or e.z < nearest.z:
				nearest = e
	if nearest.is_empty():
		_message("Watch for the next shield.", 0.8)
	elif nearest.z > COUNTER_MAX_Z:
		_message("Wait for recovery — dodge the marked lane.", 0.8)
	elif nearest.z < COUNTER_MIN_Z:
		_message("Too late. Counter while the ring is open.", 0.8)
	elif not nearest.dodged:
		_message("Slide under its sweep first!" if nearest.kind == "kicker" else "Dodge its bash first!", 0.8)
	elif absi(int(nearest.lane) - lane) > 1:
		_message("Move beside it to counter.", 0.8)
	else:
		nearest.phase = "launched"
		counter_count += 1
		last_counter_lane = nearest.lane
		_reward(50)
		_message("Swept!" if nearest.kind == "kicker" else "Counter!", 1.0)

func _message(text: String, duration: float) -> void:
	feedback = text
	feedback_time = duration
