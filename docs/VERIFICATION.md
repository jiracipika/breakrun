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

## Touch ergonomics slice

- `test_input_scene.gd` (23 assertions): a mouse press alone on Jump fires the jump before any release (buttons use `ACTION_MODE_BUTTON_PRESS`); a swipe starting on the instruction panel reaches the track (panels are `MOUSE_FILTER_IGNORE` — this was a true red before the fix, panels consumed the drag); the disabled Counter carries its own stylebox override; Jump/Slide report disabled outside play.
- Capture review: wider bottom-bar targets (Jump/Slide 124×68, Counter 188×78) with clear gaps, inverted press feedback, dimmed custom disabled state while paused, and the counter-available pulse (suppressed by reduced motion). Hint copy no longer advertises keyboard keys.
- Full `verify.py --render` pass: 11/11 suites, 239 assertions.
- Not proven: real-device touch feel and ergonomics (still no physical phone in the loop).

## Full-screen gestures slice

- Control grammar per user direction: swipe anywhere to move/jump/slide (router already supported this), tap anywhere to counter (router's "" tap class now dispatches an attack attempt), bottom button bar deleted. Menu buttons (Start/Pause/Resume/Run again/Back to title) keep press-to-fire.
- `test_input_scene.gd` (23 assertions): a tap anywhere fires a counter attempt (feedback shown), tiny movements never act as swipes and leave the pointer free, a mouse tap counters the recovering shield through the integrated scene without leaking into gesture routing, pause still fires on touch-down, panel pass-through swipe retained.
- Counter-ready emphasis moved to the instruction bar ("COUNTER NOW · tap anywhere", pulsing, suppressed by reduced motion); the in-world gold counter ring is unchanged.
- Full `verify.py --render` pass: 11/11 suites, 239 assertions. Chain reference 587 and capture choreography (Space counter) unchanged.
- Design-plan deviation recorded: the "dedicated large lower-right attack button" contract in the original design is superseded by tap-to-counter. A future optional assist mode (button controls / wider timing windows) is tracked in NEXT.md rather than silently dropped.
- Not proven: real-device feel and tap-to-counter discoverability — both belong to the human playtest gate.

## Teach, distinguish, celebrate slice (007)

- Gesture legend (test-first, `test_scene.gd` 19 assertions): translucent panel in the space the button bar vacated shows the swipe/tap grammar at run start, hides on the player's first action and after 5 s of running — addressing tap-to-counter discoverability.
- Counter celebration (test-first, `test_input_scene.gd` 25 assertions): successful counter kicks camera FOV +6 easing back to exactly base, plus six opaque paper/saffron impact shards from the counter lane; both suppressed by reduced motion and cleared on restart.
- Shield identity: paper-framed teal plate (distinct silhouette from the cobalt/saffron barrier) with a coral head beacon; bash lunge now translates toward the player, not just tilts.
- Bug found by capture review: the gold dodge-warning lane re-triggered for an already-launched shield flying back through the z 6–12 band, stamping a phantom gold slab beside the runner after every counter — warning now requires `phase == "approach"`. Launched shields also tumble away at 62% scale so the framed plate cannot read as a flat slab.
- Full `verify.py --render` pass: 11/11 suites, 245 assertions. LIVE markers unchanged.
- Not proven: real-device feel; whether the legend measurably improves first-run understanding (human playtest gate).

## Stamp kicker slice (008)

- `test_kicker.gd` (12 assertions): the high sweep catches grounded and airborne players in its lane (jumping does not clear it), sliding or another lane dodges and marks it resolvable, an undodged strike is refused with the slide hint, sliding into recovery earns the strike (base 50, counter count), the launched kicker trips the trailing dummy into a chain, and seeded waves produce the kicker. Damage funnels through a shared `_damage(kind)` helper.
- New seeded **sweep** archetype (kicker, neighbor dummy, lane dummy, lane hurdle): striking the kicker trips the trailing lane dummy and the hurdle asks for the jump — a mini-chain that rewards the slide-then-strike habit. Impact-slice wave assertions generalized to "opens with a strike-able robot (shield or kicker), exactly one per wave."
- Presentation: tall cobalt forked robot with a saffron `Foot` limb that swings through the sweep and a gold ground stripe telegraphing from z 16; the counter ring marks the strike window for both robots; instruction copy generalized and made font-safe; result screen names the kicker.
- Full `verify.py --render` pass: 12/12 suites, 257 assertions. Chain reference 587 and LIVE-STAGGER unchanged; staged kicker capture verified visually.
- Not proven: real-device feel; kicker readability/sweep timing in human hands (playtest gate).

## Spring courier slice (009)

- `test_spring.gd` (15 assertions): the low sweep catches grounded AND sliding players in its lane (the kicker's answer fails here by design), jumping clears and marks it dodged, another lane dodges, a grounded strike is refused with "Strike it mid-air!", the aerial strike launches the courier (base 50), starts a `boost_count` boost that pushes `world_speed()` above the base ramp and decays back to exactly base after 1.2 s, and seeded waves include the courier.
- Boost composes with stagger multiplicatively in `world_speed()`; base speed cap still applies before both factors. Seeded **spring** archetype pairs the courier with dummies.
- Presentation: coiled courier art (teal body, coral head, paper foot rail) that crouches at telegraph and rakes its coil leg on the sweep; counter ring marks its recovery; rising "boost" chirp synthesized alongside the existing SFX; FOV eases +4 while boosting (reduced-motion gated); instruction copy ("JUMP — its sweep is low" / "STRIKE NOW · tap anywhere") and the result screen name the courier.
- Delivered with delegated subagents: one finished presentation wiring + capture step and ran the suite; another updated README/NEXT.md in parallel. The code agent caught that the instruction-loop guard would have skipped springs entirely (dead copy) — fixed by extending the guard.
- Full `verify.py --render` pass: 13/13 suites, 273 assertions. Chain reference 587, LIVE and LIVE-STAGGER markers unchanged; spring capture verified visually.
- Not proven: real-device feel; jump-window timing in human hands (playtest gate).

## Route Inspector slice (010)

- `test_inspector.gd` (20 assertions): spawns once at the 490 m checkpoint and is never culled; bash punishes staying in the marked lane (naming the inspector) and still cycles into recovery after a hit; leaving the lane dodges; sweep dodges via slide but not jump; scanner dodges via jump but not slide; a counter during recovery after a dodge breaks the pattern (+150); three breaks defeat it (+300 clear, 750 per full fight, defeat recorded); a defeated machine chain-clears no wave targets; the same seed replays the same pattern/lane sequence and different seeds differ. No-repeat rule: a pattern never repeats twice in a row.
- Test-harness lessons recorded: the 490 m trip face-tanks waves down to ~83/99 hp, so staged patterns restore a known pip count; tick drift rounds against exact boundaries, so advances are lead + 0.05; the jump dodge needs ~0.25 s of arc, so scanner stagings lead by 0.3.
- Integration fix owned by the model change: the regression soak's dodge AI now reads the inspector's bash telegraph (it is not a wave member) — without this the stagger slowdown shifted the run's endpoint and the spawn-window assertion failed by phase luck.
- Delegated subagents built the presentation (wheeled cobalt machine with coral beacon, saffron stripes and a paper bar pivot; bash lunge / high bar / low bar poses; bash warning lane; per-pattern font-safe instruction copy with break progress; defeat burst + sound; staged capture) and the README/NEXT updates; their reports flagged the soak failure and a stale backlog line, both fixed above.
- Full `verify.py --render` pass: 14/14 suites, 293 assertions. Chain reference 587, LIVE and LIVE-STAGGER unchanged; inspector capture verified visually.
- Not proven: real-device feel; boss fight tuning (telegraph windows, pattern frequency, clear reward) awaits the human playtest gate.

## Review and publication status

Independent spec-review attempt via delegate_task was blocked by GLM HTTP 429 (billing/credits exhausted). It did not review code. A read-only fallback through the installed Codex CLI failed with HTTP 401 because its refresh token had already been used; no authentication configuration was changed. Neither attempt supplies an independent approval.

Parent review and automated checks completed. Independent spec/code-quality review remains pending. A request to waive that gate for a private prototype checkpoint received no response. Therefore no commit, GitHub repository creation or push was performed. Git staging is local only. Do not label this independently reviewed or use a `[verified]` commit prefix until an actual review passes.

An optional AGENTS.md write was blocked by an approval timeout and was not retried. Existing user-requested design SKILL.md remains at `docs/design/breakrun/SKILL.md`.

## Not claimed

No shipped app, phone build, app-store readiness, final models/rigs, audio, saved progress, bosses, upgrades, parkour chunk solver, multiplayer, server validation or demonstrated market demand. See `docs/NEXT.md` for the next bounded slice.
