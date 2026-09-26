# Slice 007 — teach, distinguish, celebrate

> Scope: presentation-only polish responding to the top open readability items. No simulation changes. Authorized by the user ("continue iteration make better").

## Items

1. **Gesture legend (onboarding).** Slice 006 removed the buttons; the one risk is discoverability of tap-to-counter. A compact translucent panel in the space the bar vacated shows "Swipe ← → move · ↑ jump · ↓ slide / Tap — counter" at run start, and hides itself on the player's first action or after 5 s. Shows every run; self-hides instantly for anyone who plays.
2. **Shield identity.** VERIFICATION flagged the shield robot blending into the barricade. The shield plate becomes a wide paper-framed teal plate (distinct silhouette from the cobalt/saffron barrier) plus a coral head beacon; the bash lunge gains a toward-player translation so the attack reads as a lunge, not a tilt.
3. **Counter celebration.** A successful counter now kicks the camera FOV (+6, easing back over the existing 0.32 s kick window) and bursts six opaque paper/saffron impact shards from the counter lane (art bible: opaque cards, no particle clouds). Both suppressed by reduced motion.

## Tests (test-first)

- `test_scene.gd`: legend visible at run start, hides after the first action, hides itself after 5 s of running.
- `test_input_scene.gd`: camera FOV rises above base after a successful counter and settles back to exactly base.
- Capture review: counter-launch frame shows the burst and wider FOV; running frames show the framed shield plate.

## Verification

- `python3 tools/verify.py --render` all green; LIVE markers unchanged (587 chain).
- Web export rebuilt and deployed; Vercel verified.
- Not proven: real-device feel; whether the legend actually teaches (human playtest gate).
