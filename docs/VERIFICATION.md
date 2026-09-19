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

## Quality slice (speed ramp + hurdles + juice)

- `test_core_updates.gd` (14 assertions): speed ramp growth/cap, chain reachable across the ramp, hurdle placement after the barrier, clean-pass 25 once-only, wrong-lane pass awards nothing, non-evaded hurdle contact still damages.
- Launched shields no longer sweep hurdles (hurdles clear only via player evasion) — regression caught by test when the hurdle was added to waves.
- Procedural startup-synthesized SFX (counter/hit/chain/clean), coral hit flash suppressed by reduced motion, bash lunge / recovery lean-back animation, launched-shield tumble.
- `user://breakrun.cfg` persists best score, sound and reduced-motion toggles; pause overlay has Sound and Reduced motion switches.
- Full suite plus `--render` capture pass; Web export re-verified headless and redeployed: the production `index.pck` SHA-256 matches the local build byte-for-byte, and a live Chromium session confirmed the updated build is served. No human playtest or phone claim.

## Readability pass (vision-QC driven)

A visual QC of fresh GL captures flagged three issues; all fixed and re-captured:
1. The fixed decorative gantry at z=-65 read as a distant finish gate — removed entirely (chunk arches are future work, tracked in NEXT.md).
2. Wave obstacles stacked into one merged clump — wave spacing widened from 4 m to 6 m per member, dummies given a slight lateral offset and idle sway, and the chain-time test updated to poll for contact instead of a fixed duration.
3. Hurdle bars were nearly invisible at distance — taller saffron bar with a paper stripe, cobalt posts, and a ground shadow stripe.

Post-fix capture QC: no gate remains, obstacles read as separate depth-separated items, no HUD regressions. Remaining noted items: player still sits close to the bottom control bar on short screens (framing test guards the 540x960 baseline only), and the shield robot could use a stronger color identity versus the barricade.

## Review and publication status

Independent spec-review attempt via delegate_task was blocked by GLM HTTP 429 (billing/credits exhausted). It did not review code. A read-only fallback through the installed Codex CLI failed with HTTP 401 because its refresh token had already been used; no authentication configuration was changed. Neither attempt supplies an independent approval.

Parent review and automated checks completed. Independent spec/code-quality review remains pending. A request to waive that gate for a private prototype checkpoint received no response. Therefore no commit, GitHub repository creation or push was performed. Git staging is local only. Do not label this independently reviewed or use a `[verified]` commit prefix until an actual review passes.

An optional AGENTS.md write was blocked by an approval timeout and was not retried. Existing user-requested design SKILL.md remains at `docs/design/breakrun/SKILL.md`.

## Not claimed

No shipped app, phone build, app-store readiness, final models/rigs, audio, saved progress, bosses, upgrades, parkour chunk solver, multiplayer, server validation or demonstrated market demand. See `docs/NEXT.md` for the next bounded slice.
