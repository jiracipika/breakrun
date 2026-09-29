# Slice 012 — share and punch

> Scope: two backlog items that need no playtest gate. Presentation only; no simulation changes. Authorized by the user ("continue iterations").

## Items

1. **Copyable seed (NEXT.md item 3).** The result screen gains a "Copy seed" button: writes `model.run_seed` to the clipboard (web: `navigator.clipboard.writeText` via JavaScriptBridge — HTTPS and a real tap gesture satisfy its requirements; native: `DisplayServer.clipboard_set`). Button flips to "Copied!" for ~1.5 s as acknowledgment. Headless tests assert the button exists, pressing it is safe, and the acknowledgment fires; actual clipboard contents are only provable on a real desktop/browser and stay unclaimed.
2. **Authored wind-up and reach (NEXT.md item 2).** The shield robot now *pulls back* during the last stretch of its approach (z 12→9) before the bash lunge, so the attack reads as anticipation → release. The courier's counter kick raises the leg further and leans the torso into it, so the kick reads as a reach instead of a leg twitch. Both respect `reduced_motion` where motion is added (the wind-up is a pose, kept; the kick lean is suppressed like the existing kick lean).

## Tests (test-first, `tests/test_scene.gd`)

- The result screen exposes a `CopySeed` button; pressing it on the death screen is safe and flips its text to "Copied!".

## Verification

- `python3 tools/verify.py --render` all green; references unchanged. Web export rebuilt, deployed, hash-verified.
- Not proven: real clipboard contents (desktop headless + web clipboard both need a real session); punch readability (playtest gate).
