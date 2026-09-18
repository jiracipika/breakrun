# BREAKRUN Foundation Implementation Plan

> For Hermes: use subagent-driven-development with non-overlapping ownership and review spec before quality. Current user authorized starting the project; proceed with the recommended Sunbreak Riot direction and behind-runner portrait camera. Reference app identity is still unknown.

Goal: a runnable first interaction, not the entire design document. Godot 4.7.1 stable is installed. Use Compatibility renderer, a deterministic RefCounted simulation and procedural opaque low-poly presentation. Original generated concept images are the design reference, not game screenshots.

## Scope for this slice

- Private new project on main; no parent repository or pre-existing breakrun directory found. Initial pull is inapplicable until an origin exists.
- Copy design package into docs/design/breakrun; preserve historical plan as proposal.
- Title, play, pause, death, restart; portrait-friendly HUD and mouse/keyboard/touch.
- Three-lane rooftop runway; saffron courier, teal shield robots, coral rooftops and cobalt shadows.
- Telegraph a locked-lane shield bash, dodge to an adjacent lane, counter in recovery; launched shield strikes two dummies and a barricade.
- Procedural enemy waves with deterministic seeds and bounded object count. This is an interaction lab, not full validated procedural parkour.
- Touch and desktop input integration tests, deterministic core tests, actual rendered smoke capture and runnable desktop launch.
- No boss, upgrades, shops, leaderboard, replay export, mobile build or market claims in this slice.

## Ownership and sequence

1. Parent: project.godot, scenes/main.tscn, docs, visual presentation, UI/input, boot/render smoke tests and verification tooling.
2. Core implementer: scripts/core/run_model.gd and tests/test_run_model.gd ONLY. Test-first vertical increments for lifecycle, movement, shield interaction, chain and bounded waves. Run Godot headless with bounded subprocess and inspect logs. No Git commits while parent is writing.
3. Separate spec review of core; then quality review. Parent re-runs every claimed test.
4. Parent integrates visual state with model API; tests scene lifecycle and input before final GUI capture.
5. Commit and push to new private GitHub repository; read back visibility and commit SHA. No automatic CI minutes or external jobs.

## Fixed core API for integration

RefCounted script without autoloads/class_name dependencies. Fields: state (title/running/paused/dead), lane (-1/0/1), distance (float), hp (3 initial), score (int), combo (int), height (float), sliding (bool), time (float), feedback (String), feedback_time (float), enemies (Array of Dictionaries), counter_count (int), chain_count (int), last_counter_lane (int).

Methods: start(seed_value:int=42), act(action:String), step(delta:float), toggle_pause(). act names: left/right/jump/slide/attack. Reject actions outside running. Pause and death freeze all simulation. Reset clears every run-derived state. step is bounded and ignores negative input.

Enemy dictionary contract: id:int, kind:String(shield/dummy/barrier/hurdle), lane:int, z:float (positive ahead), phase:String(approach/bash/recovery/launched/cleared), dodged:bool. No deletion during iteration. Remove behind player and far-spent projectiles. Presentation reads but never mutates logical state.

Shield tells: lock lane, warning at z<=12; bash enters z<=9. A different player lane during bash marks dodge; recovery at z<=6. Counter at z in [2,6], enemy dodged=true and player at most one lane away. Missed/early attacks provide explicit feedback; successful attack consumes shield once and launches it forward through its same-lane targets. Collision damage never drains multiple pips in the same grace interval. Stable event scoring, no duplicate chain rewards. Target layout: shield then two dummies then barrier ahead, safe adjacent lanes. Exact spawn constants may be tuned and must be documented by implementer.

## Parent tracer bullets

A. Test missing main scene fails cleanly; scaffold scene, title and terrain; boot test passes.
B. Test Start, pause/resume and retry against real model; connect UI and HUD; passes.
C. Test keyboard and touch routes (UI consumes touches), lane changes/jump/slide/attack; implement input and visuals; passes.
D. Render title and running scene to PNG on real GL renderer; verify pixel diversity and image dimensions; run automated live scene counter sequence. Open game only after errors are resolved.

## Verification commands

- godot --headless --path . --import --quit
- godot --headless --path . --script tests/test_run_model.gd
- godot --headless --path . --script tests/test_scene.gd
- python3 tools/verify.py (create timeout and log-error-aware wrapper)
- godot --path . (interactive desktop build)

Tests are not a physical phone performance test. Record actual test output and any unverified platform claims in docs/VERIFICATION.md. README includes clean-clone import/run steps and controls.
