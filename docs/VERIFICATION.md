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

## Style and variety slice (per-run seeds, multiplier, readable failure)

- `test_style_slice.gd` (18 assertions): seed recorded and replayed (same seed → identical distance/score/combo after equal steps), distinct seeds → distinct wave-lane sequences, multiplier growth/cap/reset, reference chain score 50+125+150+262=587, best-combo tracking, and `last_hit_kind` recorded for shield/dummy/barrier/hurdle contact.
- Contract repair: plan 002 documented "non-evaded hurdle contact still damages" but the shipped `continue` made hurdles harmless. Grounded contact inside the crossing window now trips the runner (airborne/sliding ticks never do); the jump-timing test was moved earlier so the whole crossing is airborne, mirroring an anticipatory jump.
- Existing exact-score assertions updated for the multiplier (587) in `test_core_updates`, `test_core_regressions`, `test_input_scene`, `capture_scene` and `tools/verify.py`; all other suites unchanged and passing.
- Presentation verified in fresh GL captures: HUD style readout fits its panel, result screen shows points/metres/(new!), counters/chains/best style, best score, seed, and a cause-specific failure line (custom result capture step added).
- Full `verify.py --render` pass: 10/10 suites, 162 assertions. Web export rebuilt; exported `index.html` carries the original programmatic icon, favicon links and social meta. The `breakrunState` hook is compiled only into debug builds; release exports no longer ship it.
- vercel.json now sends COOP/COEP headers to match the export's `ensureCrossOriginIsolationHeaders`; live-header check recorded below after deploy.
- Post-deploy live check (production `https://breakrun-jiracipikas-projects.vercel.app/`): response carries `cross-origin-opener-policy: same-origin` and `cross-origin-embedder-policy: require-corp`; served `index.icon.png` and `index.pck` SHA-256 hashes match the local build byte-for-byte; a real browser session booted the engine under the new isolation headers, clicked Start on the title screen and reached running gameplay ("3 m / 0 hits" HUD, first wave visible). Desktop-browser proof only; not a phone or full-chain live re-run.
- Not proven: human playtest of the multiplier feel, phone behavior, cross-browser GPU matrix, style variety enforcement (combo counts any successes, not distinct action types — simplification recorded in the plan).

## Impact and rhythm slice (contact stagger, input buffer, wave archetypes)

- `test_impact_slice.gd` (69 assertions): contact staggers immediately and slows the world below the base ramp, stagger recovers fully after 1 s, the struck enemy is knocked down (`cleared`) and awards nothing, a staggered twin run loses ground; buffered jump fires at slide end within the 0.25 s window, expired buffers vanish, latest input wins, edge lane presses are not buffered; first two waves keep the teaching shape, every wave opens with exactly one shield, member spacing ≥ 6 m, archetype sizes vary across seeds, and the same seed reproduces the same wave sequence.
- Design consequence caught by a test timeout (infinite loop on a dead model): with stagger, invulnerability windows no longer chain across a face-tanked wave, so running straight through a wave is now lethal — the hurdle tests were changed to isolate the hurdle contract instead of face-tanking, and the regression soak now dodges into a free lane with padded integrity (its intent is bounds/traversal, not survival skill).
- Presentation verified in the GL capture: staged contact shows the coral flash, two pips, the stumble lean with the knocked-down dummy beside the runner (`LIVE-STAGGER: hp=2 cleared=1 staggered=1` enforced by `tools/verify.py`).
- `test_input_scene.gd` (19 assertions): Enter restarts from the result screen, Escape returns to title.
- Full `verify.py --render` pass: 11/11 suites, 235 assertions. Chain reference 587 unchanged (teaching wave untouched by archetype variety).
- Not proven: human feel of stagger tuning (duration/slowdown are first-pass values), phone behavior, cross-browser matrix.

## Review and publication status

Independent spec-review attempt via delegate_task was blocked by GLM HTTP 429 (billing/credits exhausted). It did not review code. A read-only fallback through the installed Codex CLI failed with HTTP 401 because its refresh token had already been used; no authentication configuration was changed. Neither attempt supplies an independent approval.

Parent review and automated checks completed. Independent spec/code-quality review remains pending. A request to waive that gate for a private prototype checkpoint received no response. Therefore no commit, GitHub repository creation or push was performed. Git staging is local only. Do not label this independently reviewed or use a `[verified]` commit prefix until an actual review passes.

An optional AGENTS.md write was blocked by an approval timeout and was not retried. Existing user-requested design SKILL.md remains at `docs/design/breakrun/SKILL.md`.

## Not claimed

No shipped app, phone build, app-store readiness, final models/rigs, audio, saved progress, bosses, upgrades, parkour chunk solver, multiplayer, server validation or demonstrated market demand. See `docs/NEXT.md` for the next bounded slice.
