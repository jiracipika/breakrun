# Slice 013 — pooled enemies and a quiet splash

> Scope: engineering hygiene from NEXT.md item 5, plus removing the default boot-splash flash. No gameplay changes. Authorized by the user ("continue").

## Items

1. **Enemy node pooling.** Enemy visuals are created per spawn and freed per cull. They move to a kind-keyed pool: a culled enemy's node is hidden and parked; a spawning enemy takes a hidden node of its kind when available (resetting transform, which `_sync_world` already does per frame), else creates one. Run restarts release to the pool instead of freeing, and clear the id map so ids from a previous run can never adopt a mismatched node kind. The inspector keeps its single dedicated node.
2. **Boot splash.** `project.godot` sets the boot splash to plain ink (`show_image=false`, bg `#0A0A0F`) so the engine logo no longer flashes between the web loading screen and the title.

## Tests (test-first, `tests/test_pool.gd`)

- `Art.enemy()` counts creations in a static counter. Driving the real scene for 60 in-game seconds (hp padded so waves keep coming, inspector included) must keep creation growth bounded (≤ 15): the pre-pool behavior allocates ~30+.
- After a restart, the id map is empty and the pool holds the released nodes.

## Verification

- `python3 tools/verify.py --render` all green; all gameplay references unchanged.
- Web export rebuilt, deployed, hash-verified.
- Not proven: real-device frame-time gains (that measurement belongs to the phone gate).
