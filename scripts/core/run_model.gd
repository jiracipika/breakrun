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
var _rng := RandomNumberGenerator.new()
var _next_id: int = 0
var _next_wave_distance: float = WAVE_SPACING
var _invulnerability: float = 0.0
var _jump: float = 0.0
var _slide: float = 0.0

func start(seed_value: int = 42) -> void:
	_rng.seed = seed_value
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
	_next_id = 0
	_next_wave_distance = WAVE_SPACING
	_invulnerability = 0.0
	_jump = 0.0
	_slide = 0.0
	_spawn_wave(SPAWN_DISTANCE, 0)

func act(action: String) -> void:
	if state != "running":
		return
	match action:
		"left": lane = maxi(-1, lane - 1)
		"right": lane = mini(1, lane + 1)
		"jump":
			if _jump <= 0.0 and _slide <= 0.0:
				_jump = 0.5
		"slide":
			if _slide <= 0.0 and _jump <= 0.0:
				_slide = 0.5
				sliding = true
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

func _tick(dt: float) -> void:
	time += dt
	var current_speed: float = speed()
	distance += current_speed * dt
	_jump = maxf(0.0, _jump - dt)
	_slide = maxf(0.0, _slide - dt)
	_invulnerability = maxf(0.0, _invulnerability - dt)
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
				combo += 1
				score += 150 if target.kind == "barrier" else 100
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
						score += HURDLE_BONUS
						combo += 1
						_message("Clean!", 0.8)
				continue
			if _invulnerability <= 0.0:
				hp -= 1
				combo = 0
				_invulnerability = 1.0
				_message("Hit! Change lane before contact.", 1.5)
				if hp <= 0:
					state = "dead"
					_message("Run ended. Try the recovery counter.", 999.0)
	# No mutation of array structure during iteration.
	enemies = enemies.filter(func(e: Dictionary) -> bool:
		return e.z >= -5.0 and (e.phase != "launched" or e.age < 1.5))
	if distance >= _next_wave_distance and state == "running":
		_spawn_wave(SPAWN_DISTANCE - (distance - _next_wave_distance), _rng.randi_range(-1, 1))
		_next_wave_distance += WAVE_SPACING

func _spawn_wave(z: float, target_lane: int) -> void:
	var kinds: Array[String] = ["shield", "dummy", "dummy", "barrier", "hurdle"]
	for i in range(kinds.size()):
		enemies.append({"id": _next_id, "kind": kinds[i], "lane": target_lane,
			"z": z + 4.0 * i, "phase": "approach", "dodged": false,
			"age": 0.0, "hits": 0, "rewarded": false, "previous_z": z + 4.0 * i})
		_next_id += 1

func _try_counter() -> void:
	var nearest: Dictionary = {}
	for e in enemies:
		if e.phase == "launched" and feedback_time > 0.0:
			return # Repeated taps must not overwrite earned success feedback.
		if e.kind == "shield" and e.phase != "cleared" and e.phase != "launched":
			if nearest.is_empty() or e.z < nearest.z:
				nearest = e
	if nearest.is_empty():
		_message("Watch for the next shield.", 0.8)
	elif nearest.z > COUNTER_MAX_Z:
		_message("Wait for recovery — dodge the marked lane.", 0.8)
	elif nearest.z < COUNTER_MIN_Z:
		_message("Too late. Counter while the ring is open.", 0.8)
	elif not nearest.dodged:
		_message("Dodge its bash first!", 0.8)
	elif absi(int(nearest.lane) - lane) > 1:
		_message("Move beside the shield to counter.", 0.8)
	else:
		nearest.phase = "launched"
		counter_count += 1
		last_counter_lane = nearest.lane
		score += 50
		_message("Counter!", 1.0)

func _message(text: String, duration: float) -> void:
	feedback = text
	feedback_time = duration
