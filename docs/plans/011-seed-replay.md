# Slice 011 — seed replay

> Scope: let a player actually replay the seed shown on the result screen — closing the design plan's fair-replay promise ("same seed, same run") and its challenge-a-friend pillar. Presentation + one small parse helper; no simulation changes. Authorized by the user ("continue iterations").

## Design

- Title screen gains a numeric "Seed (optional)" field next to the Start button's flow: leaving it empty starts a fresh random run (the norm); typing a seed starts exactly that run. The result screen's shown seed then names the run a friend can re-run.
- Parsing is forgiving: strip everything but digits; empty after stripping → random; overflow clamps to a 31-bit int (model seeds are ints). No error states, no modal nag — worst case you get a random run.
- "Run again" / Enter / R keep rolling fresh random seeds; the field is read only from the title's Start path. `fixed_seed` (test/capture hook) still wins over everything.
- The field keeps its text after a run so "run again from title" replays conveniently; Escape-to-title keeps it too.

## Tests (test-first, additions to `tests/test_scene.gd`)

- The title exposes a `SeedInput` LineEdit.
- Typing "12345" and pressing Start enters a run whose `model.run_seed == 12345`.
- Garbage "ab12cd34" parses to 1234; empty yields a positive random seed (and a valid running state).

## Verification

- `python3 tools/verify.py --render` all green; existing references unchanged.
- Web export rebuilt, deployed, hash-verified; live check of the title screen.
