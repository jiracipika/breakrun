# Quality Slice 002 — feel, fairness, feedback

> Scope: make the existing dodge→counter→chain loop feel alive without adding new systems. Authorized by the user ("plan the updates and work on game quality"). No bosses, upgrades, or new enemies beyond activating the existing hurdle contract.

## Decisions

- Keep seed 42 for reproducible playtesting; ramp difficulty with speed, not randomness.
- Hurdles activate the already-implemented jump/slide evasion contract, placed AFTER each wave in the wave's own lane, so dodge decisions stay unpolluted.
- Audio is original procedural synthesis at startup (no external files, no licensing surface) with a mute toggle persisted alongside reduced-motion and best score.

## Task 1 — Core: gentle speed ramp (test-first)

- `scripts/core/run_model.gd`: add `speed()` = minf(9.0 + distance * 0.02, 14.0); use for player, enemies, and projectile (projectile = speed() + 18).
- Tests (`tests/test_core_updates.gd`): speed grows with distance, capped at 14; a full stepped chain still completes on the ramp; soak stays bounded.

## Task 2 — Core: hurdles with clean-pass reward (test-first)

- Wave layout gains `hurdle` at wave z + 16, same lane (arrives after the barrier).
- Passing the hurdle line in its lane while airborne or sliding: +25, phase cleared, "Clean!" — once only. Same lane without evasion: existing contact damage path.
- Tests: hurdle spawns behind barrier (z ordering fairness), different-lane pass scores nothing, clean pass scores 25 once, non-evaded contact costs hp.

## Task 3 — Presentation juice

- Shield: forward lunge oscillation during bash, exposed lean-back during recovery, spin while launched.
- Hurdle visual: thin low bar (reads as jump/slide obstacle).
- Hit flash: brief coral full-screen flash on damage, suppressed by reduced motion.
- Counter kick: longer, more readable wind-up.

## Task 4 — Sound and persistence

- Startup-synthesized SFX (counter ding, hit thud, chain crash) via AudioStreamWAV; zero external assets.
- `user://breakrun.cfg` persists best score, mute, reduced motion. Title and result screens show best. Pause overlay gains Sound toggle.

## Verification

- `python3 tools/verify.py` (all suites) and `--render` for the visual pass.
- Update docs/VERIFICATION.md with what is and is not proven (no human playtest claim, no phone claim).
- Commit, push to jiracipika/breakrun, redeploy production, verify wasm + one live browser chain again.
