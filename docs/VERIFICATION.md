# Foundation verification

## Executed

Engine: Godot 4.7.1.stable.official.a13da4feb.
Renderer: OpenGL 4.1 Compatibility, Intel UHD Graphics 630 on this Mac.

`python3 tools/verify.py --render` completed successfully:

| Suite | Assertions passed |
|---|---:|
| Core regressions | 17 |
| Camera framing | 3 |
| Gesture routing | 12 |
| Integrated input scene | 16 |
| Model lifecycle/combat | 66 |
| Scene lifecycle | 16 |
| Total | 130 |

Live browser verification of the Web export: served the exported build locally over HTTP and drove a real Chromium session through a full run using trusted CDP input events — clicked Start (state → running), performed a swipe (lane → 1), clicked the on-canvas Counter button (counters → 1, score 400, chains → 1), and the run continued with intact state reporting. Headless canvas-game interaction caveats apply: the first full-chain attempt required multiple trusted clicks, and one unattended run died from missed inputs before the successful chain; treat this as a desktop-browser render/input proof, not an idle-player UX guarantee.

The wrapper also completed asset import and a real GL-rendered capture run, rejecting `SCRIPT ERROR`, `Parse Error`, `ERROR:` and failing assertion markers even if process exit was zero. Machine-readable results and full logs are in ignored `artifacts/verification.json` and `artifacts/*.log`.

The live rendered sequence returned: `LIVE: counters=1 chains=1 score=400 hp=3`. It drove a real scene through Start, lane input, Space counter, projectile contacts and pause. This is automated input-driven verification, not a claim of human playtesting.

Core regression soak: ten minutes of simulated travel with public lane actions keeping the player alive; traversal exceeded 5390 metres, maximum active enemy count was four. This measures logical state bounds, not ten minutes of physical-device rendering or thermal stability.

Real mouse-event tests activate Start and Counter. Screen-touch events verify swipes, cancellation and exclusion of touches starting on UI. Focus-loss pause is tested. Physical phone ergonomics and synthesized-touch-to-native-button behavior still need device testing.

Generated concept files are preserved as design references. Actual title/gameplay screenshots are under `docs/screenshots/`, copied from GL viewport captures. A visual review of the revised gameplay capture found no blocking clipping or visibility issue; the prototype still reads partly like a raised road rather than a fully authored rooftop course.

## Fixes verified with red-to-green checks

- Landing no longer drives the courier below the roof.
- Zero-delta / first-frame updates do not duplicate waves.
- Spawn positions remain relative over long runs.
- Shields travel through targets rather than scoring them instantly.
- Projectile motion/scoring is consistent across tested frame partitions.
- Repeated attacks cannot double-score or overwrite current success feedback.
- Player feet and outer-lane silhouette clear the controls and screen edge.
- Keyboard, swipe, mouse button, pause and restart paths reach the actual scene.

## Review and publication status

Independent spec-review attempt via delegate_task was blocked by GLM HTTP 429 (billing/credits exhausted). It did not review code. A read-only fallback through the installed Codex CLI failed with HTTP 401 because its refresh token had already been used; no authentication configuration was changed. Neither attempt supplies an independent approval.

Parent review and automated checks completed. Independent spec/code-quality review remains pending. A request to waive that gate for a private prototype checkpoint received no response. Therefore no commit, GitHub repository creation or push was performed. Git staging is local only. Do not label this independently reviewed or use a `[verified]` commit prefix until an actual review passes.

An optional AGENTS.md write was blocked by an approval timeout and was not retried. Existing user-requested design SKILL.md remains at `docs/design/breakrun/SKILL.md`.

## Not claimed

No shipped app, phone build, app-store readiness, final models/rigs, audio, saved progress, bosses, upgrades, parkour chunk solver, multiplayer, server validation or demonstrated market demand. See `docs/NEXT.md` for the next bounded slice.
