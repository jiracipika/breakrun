# Slice 003 — style, variety, and web production hygiene

> Scope: deepen the existing loop's reward and replayability without new enemies, bosses or systems. Resolves the highest-value open items from docs/NEXT.md. Authorized by the user ("work on breakrun … plan it out first then execute then commit github so the vercel can build").

## Decisions

- Per-run seeds: each started run uses a fresh entropy-derived seed; the seed is shown on the result screen so any run can be replayed exactly. Tests and the rendered capture stay deterministic through an explicit `fixed_seed` hook on the scene root (0 = random).
- Style multiplier instead of a second meter: `1 + 0.25 × min(combo, 8)` (cap ×3). Combo already counts uninterrupted varied successes (counters, chain hits, clean hurdle passes) and resets on damage, so no new state machine is needed. Score events multiply by the multiplier in effect *before* their own combo increment.
- Readable failure: the model records the kind of the last contact that dealt damage; the result screen names it with a one-line remedy, per the design pillar "players can explain why they were hit".
- Web hygiene: original programmatic favicon replaces the default Godot icon; the read-only `breakrunState` observability hook ships only in debug builds; vercel.json gains COOP/COEP headers to match the export's `ensureCrossOriginIsolationHeaders` (site is fully same-origin, so `require-corp` is safe).

## Task 1 — Core: run seed recorded, exposure for replay (test-first)

- `scripts/core/run_model.gd`: `start()` stores `run_seed`.
- Tests: same seed twice → identical enemy layout and score after identical steps; distinct seeds → wave lane sequences eventually differ (empirically chosen seed pair).

## Task 2 — Core: style multiplier (test-first)

- `scripts/core/run_model.gd`: `style_multiplier()`; applied to counter (50), chain hit (100), barrier (150), hurdle clean pass (25). Combo increments on counter too; track `best_combo`.
- New reference chain total: counter ×1.0 (50) + hits at ×1.25/×1.5/×1.75 (125+150+175) = 500.
- Update exact assertions in `tests/test_core_updates.gd`, `tests/test_core_regressions.gd`, `tests/test_input_scene.gd`, `tests/capture_scene.gd`, `tools/verify.py`.
- New tests: multiplier grows to cap, resets to ×1 after damage, hurdle bonus scales with current combo.

## Task 3 — Core: damage cause (test-first)

- `scripts/core/run_model.gd`: `last_hit_kind` set on each damaging contact, cleared on start.
- Test: forced contact with each kind records that kind.

## Task 4 — Presentation

- `scripts/main.gd`: `fixed_seed` hook; HUD distance line shows live style `×N.NN`; result screen shows seed, best style and cause-specific remedy; title hint unchanged.

## Task 5 — Web production

- `project.godot` gains `config/icon`; `icon.png` generated programmatically (PIL): saffron speed chevrons on ink — original artwork, no third-party assets.
- `web_shell/index.html` gains Open Graph/Twitter meta using the bundled icon.
- `scripts/main.gd`: gate `breakrunState` behind `OS.is_debug_build()`.
- `vercel.json`: add `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

## Verification

- `python3 tools/verify.py` — all suites green with updated reference chain score 500.
- `python3 tools/verify.py --render` — live rendered chain checkpoint updated to score=500.
- Rebuild web export; inspect `web/index.html` (icon links, meta), sizes.
- Not proven by this slice: phone touch feel, human playtest, cross-browser GPU matrix. Recorded in docs/VERIFICATION.md.
