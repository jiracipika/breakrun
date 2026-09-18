extends SceneTree
## BREAKRUN core model tests — SceneTree, synchronous, no await.
## Counts assertions, prints PASS/FAIL per test, quits nonzero on failure.

var _assert_count: int = 0
var _pass_count: int = 0
var _fail_count: int = 0
var _failures: Array = []

const SCRIPT_PATH = "res://scripts/core/run_model.gd"
var RunModel: GDScript = null

func _init() -> void:
	_print_sep()
	print("=== BREAKRUN run_model test suite ===")
	_print_sep()

	# Step 1: Script must exist as a loadable resource.
	_test_script_exists()
	if _fail_count > 0:
		_print_summary()
		quit(1)
		return

	# Load the script for all subsequent tests
	RunModel = load(SCRIPT_PATH)
	if RunModel == null:
		print("FATAL: could not load %s" % SCRIPT_PATH)
		quit(1)
		return

	# --- Lifecycle ---
	_test_initial_state_title()
	_test_start_sets_running_and_resets()
	_test_pause_freezes_sim()
	_test_dead_freezes_sim()
	_test_toggle_pause_resumes()
	_test_start_after_death_resets()
	_test_reject_action_outside_running()

	# --- Lane / movement ---
	_test_lane_limits()
	_test_act_left_right()
	_test_jump_duration_and_height()
	_test_slide_duration()

	# --- Delta clamping ---
	_test_negative_delta_ignored()
	_test_large_delta_clamped()

	# --- Shield interaction ---
	_test_shield_early_attack_rejected()
	_test_shield_late_attack_rejected()
	_test_shield_non_dodged_rejected()
	_test_dodge_then_counter_succeeds()
	_test_attack_after_consumed_no_success()

	# --- Chain ---
	_test_chain_scores_dummies_and_barrier_once()
	_test_duplicate_rewards_blocked()

	# --- Damage / invulnerability ---
	_test_contact_damage_reduces_hp()
	_test_invuln_window_prevents_multi_hit()
	_test_death_at_zero_hp()

	# --- Seeds / soak ---
	_test_seeded_repeatability()
	_test_bounded_enemies_in_long_soak()

	_print_summary()
	quit(1 if _fail_count > 0 else 0)

# ===========================================================================
# Tests
# ===========================================================================

# --- Script exists ---

func _test_script_exists() -> void:
	_begin_test("script_exists")
	var exists = ResourceLoader.exists(SCRIPT_PATH)
	_assert_true(exists, "ResourceLoader.exists(%s)" % SCRIPT_PATH)
	_end_test()

# --- Lifecycle ---

func _test_initial_state_title() -> void:
	_begin_test("initial_state_title")
	var m = RunModel.new()
	_assert_eq(m.state, "title", "default state is title")
	_assert_eq(m.hp, 3, "default hp is 3")
	_assert_eq(m.lane, 0, "default lane is 0")
	_assert_eq(m.score, 0, "default score is 0")
	_end_test()

func _test_start_sets_running_and_resets() -> void:
	_begin_test("start_sets_running_and_resets")
	var m = RunModel.new()
	m.hp = 1
	m.score = 99
	m.lane = -1
	m.distance = 50.0
	m.start(42)
	_assert_eq(m.state, "running", "state running after start")
	_assert_eq(m.hp, 3, "hp reset to 3")
	_assert_eq(m.score, 0, "score reset to 0")
	_assert_eq(m.lane, 0, "lane reset to 0")
	_assert_eq(m.distance, 0.0, "distance reset to 0")
	_assert_eq(m.time, 0.0, "time reset to 0")
	_assert_eq(m.enemies.size() > 0, true, "enemies spawned on start")
	_assert_eq(m.combo, 0, "combo reset")
	_assert_eq(m.counter_count, 0, "counter_count reset")
	_assert_eq(m.chain_count, 0, "chain_count reset")
	_end_test()

func _test_pause_freezes_sim() -> void:
	_begin_test("pause_freezes_sim")
	var m = RunModel.new()
	m.start(42)
	var dist_before = m.distance
	m.toggle_pause()
	_assert_eq(m.state, "paused", "state is paused")
	m.step(0.1)
	_assert_eq(m.distance, dist_before, "distance frozen on pause")
	_end_test()

func _test_dead_freezes_sim() -> void:
	_begin_test("dead_freezes_sim")
	var m = RunModel.new()
	m.start(42)
	m.hp = 1
	m.state = "dead"
	var dist_before = m.distance
	m.step(0.1)
	_assert_eq(m.distance, dist_before, "distance frozen when dead")
	_end_test()

func _test_toggle_pause_resumes() -> void:
	_begin_test("toggle_pause_resumes")
	var m = RunModel.new()
	m.start(42)
	m.toggle_pause()
	_assert_eq(m.state, "paused", "paused after first toggle")
	m.toggle_pause()
	_assert_eq(m.state, "running", "running after second toggle")
	_end_test()

func _test_start_after_death_resets() -> void:
	_begin_test("start_after_death_resets")
	var m = RunModel.new()
	m.start(42)
	m.hp = 0
	m.state = "dead"
	m.score = 500
	m.start(7)
	_assert_eq(m.state, "running", "running again after start")
	_assert_eq(m.hp, 3, "hp restored")
	_assert_eq(m.score, 0, "score cleared")
	_end_test()

func _test_reject_action_outside_running() -> void:
	_begin_test("reject_action_outside_running")
	var m = RunModel.new()
	# In title state
	var lane0 = m.lane
	m.act("left")
	_assert_eq(m.lane, lane0, "left ignored in title")
	m.start(42)
	m.toggle_pause()
	var lane_p = m.lane
	m.act("right")
	_assert_eq(m.lane, lane_p, "right ignored in paused")
	_end_test()

# --- Lane / movement ---

func _test_lane_limits() -> void:
	_begin_test("lane_limits")
	var m = RunModel.new()
	m.start(42)
	# Try to go left beyond -1
	m.act("left")
	m.act("left")
	m.act("left")
	_assert_eq(m.lane, -1, "lane clamped to -1")
	# Try to go right beyond 1
	m.act("right")
	m.act("right")
	m.act("right")
	m.act("right")
	_assert_eq(m.lane, 1, "lane clamped to 1")
	_end_test()

func _test_act_left_right() -> void:
	_begin_test("act_left_right")
	var m = RunModel.new()
	m.start(42)
	m.act("left")
	_assert_eq(m.lane, -1, "lane -1 after left")
	m.act("right")
	_assert_eq(m.lane, 0, "lane 0 after right from -1")
	m.act("right")
	_assert_eq(m.lane, 1, "lane 1 after right")
	_end_test()

func _test_jump_duration_and_height() -> void:
	_begin_test("jump_duration_and_height")
	var m = RunModel.new()
	m.start(42)
	m.act("jump")
	_assert_eq(m.height > 0.0, false, "height 0 at jump start (peak at mid)")
	# Step to ~midpoint
	m.step(0.25)
	_assert_eq(m.height > 0.0, true, "height > 0 during jump")
	# Step past duration
	m.step(0.35)
	_assert_eq(m.height, 0.0, "height 0 after jump lands")
	_end_test()

func _test_slide_duration() -> void:
	_begin_test("slide_duration")
	var m = RunModel.new()
	m.start(42)
	m.act("slide")
	_assert_eq(m.sliding, true, "sliding true after slide")
	m.step(0.6)  # past slide duration
	_assert_eq(m.sliding, false, "sliding false after duration")
	_end_test()

# --- Delta clamping ---

func _test_negative_delta_ignored() -> void:
	_begin_test("negative_delta_ignored")
	var m = RunModel.new()
	m.start(42)
	var dist_before = m.distance
	m.step(-1.0)
	_assert_eq(m.distance, dist_before, "distance unchanged with negative delta")
	_end_test()

func _test_large_delta_clamped() -> void:
	_begin_test("large_delta_clamped")
	var m = RunModel.new()
	m.start(42)
	m.step(100.0)
	# A 100s clamp now travels at ramped speed, so the assertion must use speed(), not the constant.
	_assert_eq(m.distance <= m.speed() * 1.0 + 0.001, true, "large delta clamped to 1.0s max")
	_end_test()

# --- Shield interaction ---

func _test_shield_early_attack_rejected() -> void:
	_begin_test("shield_early_attack_rejected")
	var m = RunModel.new()
	m.start(42)
	# Find the shield enemy
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	# Move it close but not in counter range (z > 6)
	shield.z = 7.0
	shield.phase = "approach"
	m.act("attack")
	_assert_eq(m.counter_count, 0, "no counter when too far")
	_assert_eq(m.feedback != "", true, "feedback given for early attack")
	_end_test()

func _test_shield_late_attack_rejected() -> void:
	_begin_test("shield_late_attack_rejected")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	shield.z = 1.0
	shield.phase = "recovery"
	shield.dodged = true
	m.act("attack")
	_assert_eq(m.counter_count, 0, "no counter when too late (z < 2)")
	_assert_eq(m.feedback != "", true, "feedback given for late attack")
	_end_test()

func _test_shield_non_dodged_rejected() -> void:
	_begin_test("shield_non_dodged_rejected")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	# In range but not dodged
	shield.z = 4.0
	shield.phase = "bash"
	shield.dodged = false
	m.act("attack")
	_assert_eq(m.counter_count, 0, "no counter when not dodged")
	_assert_eq(m.feedback != "", true, "feedback given for non-dodged attack")
	_end_test()

func _test_dodge_then_counter_succeeds() -> void:
	_begin_test("dodge_then_counter_succeeds")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	# Shield is in lane 0 (first wave center). Player dodges to lane 1.
	_assert_eq(shield.lane, 0, "first wave shield in lane 0")
	m.act("right")  # lane 0 -> 1
	# Set shield to bash phase with z in counter range, dodged=true
	shield.z = 5.0
	shield.phase = "bash"
	# Simulate the dodge detection (player in different lane during bash)
	shield.dodged = true
	m.act("attack")
	_assert_eq(m.counter_count, 1, "counter registered")
	_assert_eq(shield.phase, "launched", "shield launched after counter")
	_end_test()

func _test_attack_after_consumed_no_success() -> void:
	_begin_test("attack_after_consumed_no_success")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	# Counter it
	shield.z = 5.0
	shield.phase = "bash"
	shield.dodged = true
	m.act("attack")
	var cc1 = m.counter_count
	# Attack again
	var fb_before = m.feedback
	m.act("attack")
	_assert_eq(m.counter_count, cc1, "counter count unchanged on repeated attack")
	_assert_eq(m.feedback, fb_before, "repeated attack preserves existing success feedback")
	_end_test()

# --- Chain ---

func _test_chain_scores_dummies_and_barrier_once() -> void:
	_begin_test("chain_scores_dummies_and_barrier_once")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	var score_before = m.score
	shield.z = 5.0
	shield.phase = "bash"
	shield.dodged = true
	m.act("attack")
	_assert_eq(m.score > score_before, true, "score increased after chain")
	m.step(1.0) # Chain credit occurs on projectile contact, not the attack button.
	_assert_eq(m.chain_count, 1, "chain_count incremented after contact")
	_end_test()

func _test_duplicate_rewards_blocked() -> void:
	_begin_test("duplicate_rewards_blocked")
	var m = RunModel.new()
	m.start(42)
	var shield = _find_shield(m)
	_assert_true(shield != null, "shield enemy exists")
	if shield == null:
		_end_test()
		return
	shield.z = 5.0
	shield.phase = "bash"
	shield.dodged = true
	m.act("attack")
	var score1 = m.score
	# Try to attack again — should not increase score
	m.act("attack")
	_assert_eq(m.score, score1, "score unchanged on duplicate attack")
	_end_test()

# --- Damage / invulnerability ---

func _test_contact_damage_reduces_hp() -> void:
	_begin_test("contact_damage_reduces_hp")
	var m = RunModel.new()
	m.start(42)
	var hp_before = m.hp
	# Force a contact: place a dummy in player's lane at z=0
	var e = {
		"id": 9999,
		"kind": "dummy",
		"lane": m.lane,
		"z": 0.0,
		"phase": "approach",
		"dodged": false,
	}
	m.enemies.append(e)
	m.step(0.01)  # trigger contact processing
	_assert_eq(m.hp, hp_before - 1, "hp reduced by 1 on contact")
	_end_test()

func _test_invuln_window_prevents_multi_hit() -> void:
	_begin_test("invuln_window_prevents_multi_hit")
	var m = RunModel.new()
	m.start(42)
	var hp_before = m.hp
	# Place two enemies in player's lane
	m.enemies.append(_make_enemy(9990, "dummy", m.lane, 0.0))
	m.enemies.append(_make_enemy(9991, "dummy", m.lane, 0.5))
	m.step(0.01)
	_assert_eq(m.hp, hp_before - 1, "only 1 hp lost within invuln window")
	_end_test()

func _test_death_at_zero_hp() -> void:
	_begin_test("death_at_zero_hp")
	var m = RunModel.new()
	m.start(42)
	m.hp = 1
	# Contact
	m.enemies.append(_make_enemy(9992, "dummy", m.lane, 0.0))
	m.step(0.01)
	_assert_eq(m.state, "dead", "state dead at 0 hp")
	_end_test()

# --- Seeds / soak ---

func _test_seeded_repeatability() -> void:
	_begin_test("seeded_repeatability")
	var m1 = RunModel.new()
	var m2 = RunModel.new()
	m1.start(42)
	m2.start(42)
	_assert_eq(m1.enemies.size(), m2.enemies.size(), "same enemy count on same seed")
	# Step both by same deltas
	for i in range(10):
		m1.step(0.1)
		m2.step(0.1)
	_assert_eq(m1.distance, m2.distance, "same distance after same steps")
	_assert_eq(m1.score, m2.score, "same score after same steps")
	_end_test()

func _test_bounded_enemies_in_long_soak() -> void:
	_begin_test("bounded_enemies_in_long_soak")
	var m = RunModel.new()
	m.start(42)
	var max_enemies = 0
	# Step for ~30 seconds of game time
	for i in range(600):
		m.step(0.05)
		var sz = m.enemies.size()
		if sz > max_enemies:
			max_enemies = sz
	print("  max enemies during soak: %d" % max_enemies)
	_assert_eq(max_enemies < 100, true, "enemy count bounded in long soak (< 100)")
	_assert_eq(m.state != "title", true, "still not in title after soak")
	_end_test()

# ===========================================================================
# Helpers
# ===========================================================================

func _begin_test(name: String) -> void:
	print("[TEST] %s" % name)

func _end_test() -> void:
	pass

func _assert_true(cond: bool, label: String) -> void:
	_assert_count += 1
	if cond:
		_pass_count += 1
		print("  PASS: %s" % label)
	else:
		_fail_count += 1
		_failures.append(label)
		print("  FAIL: %s" % label)

func _assert_eq(a, b, label: String) -> void:
	_assert_count += 1
	if a == b:
		_pass_count += 1
		print("  PASS: %s (got %s)" % [label, str(a)])
	else:
		_fail_count += 1
		_failures.append(label)
		print("  FAIL: %s — expected %s, got %s" % [label, str(b), str(a)])

func _print_sep() -> void:
	print("---------------------------------------------------")

func _print_summary() -> void:
	_print_sep()
	print("Total assertions: %d  Pass: %d  Fail: %d" % [_assert_count, _pass_count, _fail_count])
	if _fail_count > 0:
		print("FAILURES:")
		for f in _failures:
			print("  - %s" % f)
	_print_sep()

func _find_shield(m) -> Dictionary:
	for e in m.enemies:
		if e.kind == "shield":
			return e
	return {}

func _make_enemy(id: int, kind: String, elane: int, z: float) -> Dictionary:
	return {
		"id": id,
		"kind": kind,
		"lane": elane,
		"z": z,
		"phase": "approach",
		"dodged": false,
	}
