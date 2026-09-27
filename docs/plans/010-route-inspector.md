# Slice 010 — the Route Inspector

> Scope: the design plan's boss, reusing the three taught verbs. Test-first. Authorized by the user ("anything else you can do? do it").

## Design (from the original contract)

> A wheeled checkpoint machine moves with the player. Alternate readable shield lanes, sweeping scanner bars and recovery opportunities. Three successful pattern counters expose a final ram opportunity. Missing a counter should usually forfeit damage, not automatically lose the run.

## Contract (first-boss simplification, faithfully reusing taught verbs)

- One inspector spawns when the run first passes **490 m** (wave-7 territory), holding a fixed z=14 ahead of the runner; further inspectors every 490 m after one is defeated. Only one lives at a time.
- It cycles three **taught** patterns, seeded order, each in a (possibly new) marked lane:
  - **bash** — like the shield: dodge by leaving the marked lane; recovery opens the counter.
  - **sweep** — like the kicker: high bar; slide dodges, jumping fails.
  - **scanner** — like the spring: low bar; jump dodges, sliding fails.
- Pattern timing: telegraph 0.9 s (lane/verb announced) → active 0.7 s (dodge evaluated once at active start; failure deals damage via the shared `_damage("inspector")` — the run continues) → recovery 1.0 s (counter window) → next pattern with a fresh seeded lane.
- A successful counter breaks the pattern: **+150**, machine hp 3→2→1. The third counter defeats it: **+300** "ROUTE CLEARED!" and the machine launches away (no chain sweep — it is too big to be a projectile). Missing a recovery just moves on; the boss never leaves on its own and never heals.
- The inspector is exempt from the z-cull while cycling and from projectile targeting both ways.

## Model state

`inspector: Dictionary = {}` on the model (separate from the enemies array — it is a encounter, not a wave member): `{"lane", "pattern", "phase" (telegraph/active/recovery/defeated), "pattern_time", "hits", "dodged", "patterns" (seeded RNG reuses `_rng`)}`. Counter resolution in `_try_counter` consults the inspector after enemies. `inspector_hits` / `inspectors_defeated` exposed for HUD/result.

## Tests (test-first, `tests/test_inspector.gd`)

- Spawn: crossing 490 m yields exactly one inspector; it is still there 30 s later (no cull).
- Bash: staying in its lane at active start costs a pip (`last_hit_kind == "inspector"`); another lane dodges.
- Sweep: sliding dodges, jumping does not. Scanner: jumping dodges, sliding does not.
- Counter in recovery after a dodge: +150, hp 3→2; three counters defeat it (+300 on the last), phase "defeated" → launches away; total 750 for a full break.
- Same seed → same pattern sequence; different seeds can differ.
- A launched/defeated inspector never chain-sweeps other enemies.

## Presentation (delegated) & docs (delegated)

Big wheeled cobalt machine with coral beacon and a scanner bar; warning-lane reuse for bash telegraphs; per-pattern instruction copy with break progress; defeat burst + FOV kick reuse; capture step; README/NEXT/VERIFICATION updates.

## Verification

- `python3 tools/verify.py --render` all green; existing references (587 chain, LIVE-STAGGER) unchanged.
- Web export rebuilt, deployed, hash-verified; live browser check.
