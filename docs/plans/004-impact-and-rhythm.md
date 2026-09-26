# Slice 004 — impact and rhythm

> Scope: make contact physical, make inputs forgiving, and make runs vary. No new enemy kinds, bosses or upgrades. Authorized by the user ("Game is not blocking when bumping into enemies let's fix the game logic and also improve the gameplay").

## Problem

Damaging contact costs a pip but nothing physical happens: the runner keeps full speed and the enemy keeps marching through them. Hits feel like a UI event, not a collision.

## Decisions

- **Stagger on contact (the fix):** a hit sets a 1.0 s stagger. During stagger the whole world (player, enemies, projectiles) moves at `speed() × (1 − 0.8 × stagger_ratio)`, so a stumble reads as the run lurching, and the struck enemy is knocked down (`phase = "cleared"` topple pose) instead of ghosting through the player. Knockdowns award nothing. i-frames still let you pass through other enemies during recovery.
- **Input buffer (0.25 s):** jump pressed while sliding (or slide while jumping/airborne) is buffered and fires the moment it becomes executable; the latest input wins; expired buffers vanish; lane presses at the edge are not buffered. Matches the design plan's input-buffer contract.
- **Wave archetypes (seeded variety):** wave 1–2 stay the teaching "checkpoint" (shield, dummy, dummy, barrier, hurdle — one lane, counter-chain intact). Wave 3+ draws per seed between: *checkpoint* (chain wave), *patrol* (shield + 3 dummies weaving two lanes), *fence* (shield + barrier + hurdle across lanes, 8 m spacing). Every wave keeps exactly one shield, opens with it, keeps ≥ 6 m between members, and never occupies all three lanes at one z.
- **Result-screen keyboard parity:** Enter/Space/R restart a dead run; Escape returns to title; Space also starts from the title. Touch users already had buttons.
- **Presentation:** runner leans back and drops stride amplitude during stagger, nudged toward the camera; capture suite gains a staged stagger step.

## Tasks (test-first)

1. `tests/test_impact_slice.gd`: stagger slows world and recovers, struck enemy cleared, hit awards nothing, staggered run loses ground; buffer fires on slide end, expires, latest-wins, lanes unbuffered; wave groups: first two teaching waves, every wave one shield opening, spacing ≥ 6 m, archetype variety across seeds, same seed → same wave sequence.
2. `scripts/core/run_model.gd`: constants STAGGER_TIME/STAGGER_SLOWDOWN/INPUT_BUFFER, `_stagger`, `_buffered_action`, `_buffer_time`, `_waves_spawned`, `world_speed()`, `stagger_ratio()`, buffer plumbing in `act()/_tick()`, knockdown in the contact branch, archetype `_spawn_wave(z)`.
3. Existing suites: `test_style_slice` wave probe reads shields per spawn batch; `test_core_regressions` soak gets a free-lane dodge policy (waves now occupy two lanes) and padded integrity — its intent is bounds/traversal, not survival skill.
4. `scripts/main.gd`: stagger lean/stride/z-nudge; dead-state and title key handling.
5. `tests/capture_scene.gd` + `tools/verify.py`: staged stagger checkpoint (`LIVE-STAGGER: hp=2 cleared=1 staggered=1`).

## Verification

- `python3 tools/verify.py --render` all green; chain reference 587 unchanged (teaching wave untouched).
- Web export rebuilt, pushed; Vercel production build verified by hash.
- Not proven: human feel of stagger tuning, phone, cross-browser matrix.
