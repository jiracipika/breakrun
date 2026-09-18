# BREAKRUN — Game Design and Implementation Plan

> **For Hermes:** After the user approves implementation, use the subagent-driven-development skill to implement this plan task-by-task. This document does not authorize implementation.

**Goal:** Prove that an endless runner becomes more replayable when skillful fighting transforms enemies into movement tools and chain reactions.

**Architecture:** Proposed lightweight Godot 4 3D client with authored encounter chunks, a deterministic logical combat simulation, and a presentation layer that cannot change scoring. Start offline; share seed-based challenges before considering any server-side competition.

**Tech stack:** Proposed Godot 4 stable, GDScript, Compatibility renderer first; Blender for original low-poly assets; headless logic tests plus device playtests. Engine version, renderer and export targets require a measured technical spike, not an assumption of mobile compatibility.

**Status:** Astra-led design proposal. No game implementation, repo creation, installation, publishing, or deployment performed. Artwork generated with GPT Image under Astra's direction; not rendered from a game. The existing app/reference remains unidentified.

## 1. Decisions and assumptions

- Working name: BREAKRUN. Not trademark-checked; do not publish under it without clearance.
- Provisional format: portrait, behind-the-character 3D runner. This is an assumption about the user's “3rd running style app,” not a recovered requirement.
- Initial audience hypothesis: players who enjoy quick runner sessions but want expressive mastery and discoverable combat combinations.
- Session target: short first runs, roughly 2–5 minutes for improving players; endless continuation for experts. These are design targets, not measured behavior.
- Business goal: discover a compelling game with expansion potential. Popularity, acquisition costs and retention remain unproven.
- Start with one character, one district, three enemies, one boss, six upgrades. No accounts, multiplayer, battle pass, pet collection, crafting, open world or paid progression in the proof build.
- Art direction selection and whether to extend an existing project are approval gates. Do not silently create a second copy of an existing game.

## 2. The hook

**“You never stop moving. Every enemy is a weapon.”**

A courier runs through a city whose automated enforcement system treats improvisation as a traffic violation. Your delivery is a harmless package that refuses to stay on the approved route. Municipal robots try to stop you; you turn their equipment against them. Stakes are playful, physical and understandable without exposition.

The distinguishing action is not a punch. It is a three-step sequence:

1. Read an approaching shield robot and evade its clearly telegraphed bash.
2. Counter during recovery to kick the robot forward on its shield.
3. Its slide knocks over two robots and breaks a barricade, revealing a risky shortcut.

Everything in the first prototype serves that sequence. If it is not fun with placeholder shapes, more content is not the remedy.

### Design pillars

- **Forward intention:** A successful attack carries the player forward, clears a route, or creates a useful launch. Avoid stopping to grind health bars.
- **Readable mastery:** Players can explain why they were hit. Shape, movement and sound communicate an attack; color alone never does.
- **Authored surprises:** Randomness chooses tested encounters and combinations, never arbitrary obstacle soup.
- **Expressive consequences:** A counter changes the scene, not merely a damage number.
- **Fair replay:** Fast restart, no energy meter, no paid save from a ranked failure, no hidden stat boosts.

## 3. Control contract

Prototype one primary control model rather than teaching gestures and four buttons at once.

| Intent | Touch | Desktop | Rule |
|---|---|---|---|
| Change route lane | Horizontal swipe on playfield | A/D or left/right | One lane per gesture; no movement on UI touches |
| Vault / aerial kick setup | Upward swipe | W or up | Grounded only unless an upgrade explicitly grants one air reset |
| Slide / sweep setup | Downward swipe | S or down | Low obstacles and a particular enemy weakness use the same visual cue |
| Strike / counter | Dedicated large lower-right button | Space | Counter if a valid attack is in its timing window; strike otherwise |
| Pause | Upper-right button | Escape | Freezes simulation and consumes no buffered attack |

Use a separate attack button so a lane-change swipe cannot accidentally attack. Start with a 56 logical-pixel minimum button target, safe-area inset support and left-handed mirroring. Finger motion thresholds must scale with viewport density. Commit one swipe per pointer lifecycle. UI buttons own their pointer until release.

Initial tuning hypotheses: 120 ms input buffer, 180 ms counter window in standard mode, 300 ms in assist mode, roughly 700 ms minimum telegraph for early encounters. These values are starting points to test, not a latency guarantee. Difficulty may add spatial decisions before it shrinks timing windows. Assist mode remains a legitimate local play mode; future competitive challenges must distinguish rulesets without shaming players.

Auto-run does not mean auto-combat. Never require two mutually exclusive inputs at the same moment. A telegraphed wind-up indicates both the attack and its safe response. Do not spawn mandatory hazards behind a foreground impact effect.

## 4. Combat, failure and scoring

### Core states

GroundRun, LaneShift, Jump, Slide, Strike, Counter, Stagger, Defeated, Paused. Define allowed transitions explicitly. A counter requires a matching enemy ID, range, timing and a once-only attack token. A held attack does not repeatedly counter. Interruption cancels obsolete queued actions.

Three integrity pips initially. A hit removes one pip and breaks the style chain. Give recovery invulnerability long enough to escape overlapping contacts; tune first at 1 second. A pit costs a pip and returns the player to a safe authored anchor unless it was the last pip. Never respawn into an active hitbox. No gore or realistic injury.

### Style and flow

- Distance supplies a small baseline score.
- Counters, distinct follow-up actions, environment interactions and boss patterns earn explicit event points.
- Multiplier grows with successful varied actions, to a cap. Repeating an identical safe action does not grow it indefinitely.
- Maintain a flow meter that changes impact presentation and modestly improves forward pace. Do not make high flow create unreadable speeds; cap actual world speed independently.
- No points during pause, after death or while replay scrubbing.
- Exact scoring constants live in one versioned resource. Test results must report the ruleset version.

### Initial enemies

| Enemy | Silhouette and tell | Player response | Consequence |
|---|---|---|---|
| Shield roller | Wide teal trapezoid shield; shoulders tuck before bash | Dodge the bash, then counter its exposed recovery | Slides ahead as a short-lived battering ram |
| Stamp kicker | Tall forked silhouette; one raised foot and projected ground stripe | Slide under a high sweep, then strike | Swept body trips a nearby robot |
| Spring courier | Compact round spring legs; crouch then rising whistle | Jump its low sweep and aerial strike | Grants a forward aerial boost to an authored landing |

Robots are distinct in silhouette and telegraph rhythm, not merely palette. The first build excludes guns and reflected bullets; add those only if the camera and controls can support them.

### Boss: The Route Inspector

A wheeled checkpoint machine moves with the player. Alternate readable shield lanes, sweeping scanner bars and recovery opportunities. Three successful pattern counters expose a final ram opportunity. Missing a counter should usually forfeit damage, not automatically lose the run. Camera remains behind the player; never cut away while input matters. First boss must reuse learned verbs, not introduce a surprise control.

## 5. Run structure and procedural fairness

Tutorial introduction → simple encounters → route choice → pressure sequence → brief breathing section → moving boss → safe upgrade choice → new district variation. Endless play loops through new chunk combinations and enemy interactions with bounded speed.

Early example, with timings only as staging targets:

- 0–10 seconds: move, vault and slide with harmless practice gates.
- 10–25 seconds: one shield robot, generous telegraph, contextual attack prompt.
- 25–45 seconds: replay the shield interaction against two targets and a breakable barricade.
- 45–70 seconds: choose safe route or a visibly harder high-style route.
- 70–100 seconds: recombine two enemy patterns, then offer breathing space.
- Around 100–130 seconds: first Route Inspector encounter.

Do not force these timestamps if the player's pacing differs. Schedule by encounter state and distance, not wall-clock cinematics.

### Chunk contract

Each chunk declares entry/exit lanes, safe traversable lanes over time, required verbs, earliest reaction distance, enemy placements, landing anchors, score opportunities and compatibility tags. Validate consecutive chunks for reachability with the actual lane-change and jump timings. Avoid consecutive high-pressure chunks until the player has learned the necessary verbs. Give branching routes comparable traversal duration where fair score comparison matters.

### Six initial upgrade choices

1. **Pinball:** A kicked shield can ricochet once into an adjacent valid target.
2. **Springstep:** The spring-courier boost grants one mid-air lane correction.
3. **Aftershock:** A perfect counter staggers nearby robots; it does not auto-counter them.
4. **Street broom:** Swept robots slide farther and can break light barriers.
5. **Relay:** Hitting a robot already launched by another interaction awards a distinct relay event.
6. **Second wind:** Completing the boss without damage restores one missing integrity pip, never above the cap.

Combinations should change target choice or route planning. Pinball + Relay supports chain specialists; Springstep + Street broom supports aggressive route changes. Cap chain length and guard against repeated collision scores from the same pair of entities. Pause the world at upgrade selection; no timed choice pressure.

## 6. Three visual directions

See `art/01-directions.png`, arranged left to right. Images are mood proposals, not final assets.

### A. Sunbreak Riot — recommended

Sunlit coral rooftops, cobalt shadows, saffron split-tail courier jacket, teal municipal robots. Graphic cel-shaded low-poly forms with restrained print texture on distant scenery. Exuberant daytime action rather than another neon arena.

Strength: readable silhouettes, a memorable protagonist accent, plausible low-cost production. Risk: sunlight must not flatten obstacle contrast. Use shaded obstacle faces and opaque contact marks, not bloom.

### B. Midnight Broadcast

Indigo rooftops, bone jacket, vermilion signals, giant broadcast dishes. Lean graphic-noir direction rather than cyberpunk signage.

Strength: dramatic cinematic framing. Risk: small-screen dark-scene readability and red hazards competing with environmental signals.

### C. Junkyard Carnival

Ivory dust, ultramarine scrap ramps, tangerine robots, patchwork athletic equipment.

Strength: physical comedy and modular prop reuse. Risk: visual clutter and too many competing silhouettes.

### Recommendation, not a final selection

Develop A first. Keep B and C as genuinely different alternatives, not extra biomes promised for the proof build. The recommended concept sheet is `art/02-sunbreak-concept.png`. User approval may replace this recommendation.

## 7. Art bible for Sunbreak Riot

### Palette and materials

| Token | Hex | Role |
|---|---|---|
| Shell background | #0A0A0F | Menus, pause and result backdrop |
| Shell panel | #1C1C2E | Opaque interface panels |
| Paper | #FFF4DB | Readable warm highlights and impact wedges |
| Saffron | #FFCA45 | Courier jacket and selected action emphasis |
| Coral | #EC725B | Main rooftop architecture |
| Cobalt | #283E78 | Shadow faces, trousers and depth separation |
| Municipal teal | #187C83 | Enforcement robots |

Gameplay is sunlit; menus retain the shared dark app shell. All primary surfaces are opaque. Use mesh streaks and hard-edged impact cards rather than stacked transparent particle clouds. Assign danger cues a unique shape and motion pattern, never depend on a new red tint alone. Test text contrast in actual HUD composites; the palette itself is not accessibility verification.

### Hero

Adult courier, athletic rather than armored, asymmetrical saffron jacket with two short split tails, cobalt trousers, chunky running shoes, cropped hair. The back silhouette is the identity because that is what players see most. Avoid a huge backpack hiding the attack pose. Jacket motion should be simple bone animation, not cloth simulation. No copied franchise motifs.

### Camera and composition

Start with a portrait camera behind and modestly above the runner, three soft lanes across rooftop tracks. The horizon occupies approximately the upper third. Reserve the middle distance for incoming tells. Keep the hero's feet visible; effects must not obscure the next safe lane. Fixed camera pitch first. Camera kick, widening FOV and lateral lean are optional presentation settings, never required to understand a hit.

### Animation language

Anticipation → contact pose → follow-through → return to running. Exaggerate torso twist and leg extension; prioritize readable key poses over motion capture realism. Brief hit-stop is local presentation coordinated with the simulation; never let it silently grant extra scoring opportunities. Slow motion, shake and flashes can be disabled independently. No rapid full-screen strobing.

### Interface type and layout

Proposed display type: Barlow Condensed ExtraBold for score and title; body: Atkinson Hyperlegible for instructions. Acquire and record licenses before shipping; fall back to bundled system fonts during tests.

HUD: integrity at top left; score centered; pause top right. Small chain label below score only during a chain. Attack at bottom right, outside main obstacle-reading zone. No currencies or permanent quest list during play. Upgrade cards appear only in paused breathing sections. Result screen leads with personal improvement and a specific cause of failure, then Restart; share is secondary.

Example failure copy: “Shield bash hit before your counter. Wait for the recovery flash.” Distinguish “counter too early” from a genuine input-registration failure in diagnostics.

### Sound

Rubbery mechanical clacks, shoe scrapes, a distinctive rising spring whistle, and short dry percussion layers responding to flow. Counter success needs an unmistakable sound different from ordinary impact. No licensed commercial music. Haptic feedback is optional, brief and disabled by preference. Never make audio the only hazard warning.

## 8. Asset inventory and handoff

Concept PNGs do not include rigs, meshes, textures, animations or import settings. Before production, obtain licensed/original source assets and record provenance in `art/ASSET_LICENSES.md`.

First-slice production inventory:

- Courier model with front/side/back orthographic references and one simple skeleton.
- Three robot models with consistent scale and contrasting silhouettes.
- Inspector boss built from a small number of reused robot/environment motifs.
- Rooftop floor, parapet, market awning, light barricade, ramp, gap connector, safe landing marker and distant skyline modules.
- Hero animations: run, lane lean left/right, jump, land, slide, strike, counter, stagger, defeat.
- Robot wind-up, attack, recovery, launched and disabled poses; timings derived from gameplay contract.
- Opaque impact wedge, speed slash, counter ring and landing marker.
- HUD icons for integrity, pause, attack and six upgrades.

Provisional performance budgets for measurement: hero under 8k triangles, ordinary robot under 4k, no real-time cloth, no dynamic GI, at most one shadow-casting key light, pooled enemies/effects, bounded physics bodies. Do not mistake these budgets for measured performance or hard platform limits.

## 9. Replayability, growth and business hypotheses

### Why someone returns

Master a clear counter → discover a chain → try a different upgrade pair → improve a recognizable personal best → challenge a friend on the same route. Unlock cosmetics and side-grade styles later, not permanent stat inflation that invalidates mastery.

### Share feature after core validation

Versioned seed + input log + ruleset produces an in-engine replay. Export an optional short highlight video later; this requires a separate capture/encoding spike and is not an automatic consequence of storing inputs. Start with a shareable seed code and a static result card. Replays should not capture personal messages or unrelated device content.

Daily identical-seed runs and friend challenges can work before synchronous multiplayer. Local scores are untrusted. A public competitive leaderboard needs authoritative replay validation or an explicitly noncompetitive label; do not market client-submitted scores as cheat-proof.

### Monetization boundaries

Do not monetize the prototype. If the game earns repeat play, consider cosmetic outfits, trails and a transparent paid content pack. No loot boxes, forced ads between retries, energy timers or purchased score multipliers. A rewarded continue, if ever considered, must be excluded from competitive runs and cannot be the default design.

### Validation, not popularity promises

Use observed sessions before adding growth systems. Recruit a small formative group, then a separate wider cohort if results justify it. Proposed first gate: with 8–12 new players, at least 8 of 10 in a ten-player session understand the counter after the short tutorial and at least 6 of 10 voluntarily replay without prompting. Record actual denominator; do not extrapolate tiny samples to market success.

Collect reasons for stopping, perceived fairness, control confusion, and which moment they would show a friend. Instrument tutorial completion, first counter, first chain, restart, death cause and session exit only with appropriate consent; avoid collecting unnecessary identifiers. Retention thresholds and acquisition viability must be set after a real soft-launch baseline, not copied into a funding claim.

Stop and revise if players call it an ordinary runner with automatic fighting, if they cannot explain damage, or if spectacle hides the next decision. Never add a shop to compensate for weak controls.

## 10. Implementation roadmap — future work only

Proposed project root after approval: a new `breakrun/` directory on roomy project storage, unless the user identifies an existing target. Paths below are relative to that future root. No files at these paths currently exist as part of this work.

For every code task: write its named failing test, run and observe failure, implement the smallest behavior, rerun the test, run the full relevant suite, review the diff, then commit. Pull before editing an existing repository; never overwrite dirty user work. Keep commits scoped and push only according to the user's approved development workflow. The named test runner and smoke commands below are contracts to create, not currently runnable deliverables.

### Gate 0 — approve direction

Confirm reference app/camera, direction A/B/C, new versus existing project, and first physical test device. Completion: written decisions, no ambiguous reuse of an unidentified app.

### Gate 1 — technical spike

Files: `project.godot`, `scenes/spike.tscn`, `scripts/spike.gd`, `docs/device-matrix.md`.

1. Pin a stable installed Godot version and export templates; record exact versions.
2. Render a portrait track, placeholder runner, moving chunks and representative pooled enemies.
3. Compare Compatibility and Mobile only if the target devices support both; choose from evidence.
4. Exercise desktop and one physical phone build; if signing blocks iOS, state that and use a real Android target if available.
5. Measure frame time, memory, thermal behavior and resume after backgrounding. Target stable 60 fps on the agreed device; offer a measured 30 fps mode if needed. Record p50/p95/p99 frame times rather than an isolated peak FPS.

No art polish before this gate passes.

### Gate 2 — input and movement

Files: `scripts/core/run_state.gd`, `scripts/input/gesture_router.gd`, `scripts/player/movement.gd`, `tests/test_input.gd`, `tests/test_movement.gd`, `tests/run_all.gd`.

Separate tasks: swipe classification; UI pointer capture; lane timing; jump/slide states; pause/resume cancellation; left-handed layout. Test diagonal ambiguity, rapid repeated inputs, touch cancellation, safe areas, resize, key repeat and foreground return. Test a complete start→play→pause→resume→death→restart lifecycle. Buffering must never replay an attack after a restart.

### Gate 3 — the signature interaction

Files: `scripts/combat/counter_resolver.gd`, `scripts/enemies/shield_roller.gd`, `scripts/combat/chain_resolver.gd`, `scenes/encounters/shield_chain.tscn`, `tests/test_counter.gd`, `tests/test_chain.gd`.

Separate tasks: telegraph state; valid/early/late counter boundaries; range check; one attack token consumed once; launched shield trajectory; target collision; barrier break; safe route opening. Test simultaneous collisions and prevent score farming from resting contacts. Capture a playable sequence with placeholder art. Gate: the user can deliberately reproduce the chain, not merely watch a scripted animation.

### Gate 4 — fair endless loop

Files: `scripts/track/chunk_director.gd`, `scripts/track/reachability.gd`, `resources/chunks/`, `scripts/core/seed_rng.gd`, `tests/test_chunks.gd`, `tests/test_seed.gd`.

Separate tasks: seed RNG; chunk metadata schema; reachable transition validator; object pooling; difficulty caps; safe landing anchors; run termination and retry. Enumerate a bounded seed corpus and reject impossible transitions. Every required move must fit the actual input and traversal timings. Extended soak tests must show stable object counts and no growing orphan-node count.

### Gate 5 — variety and boss

Files: `scripts/enemies/stamp_kicker.gd`, `scripts/enemies/spring_courier.gd`, `scripts/boss/route_inspector.gd`, `resources/upgrades/`, `tests/test_upgrades.gd`, `tests/test_boss.gd`.

Implement one enemy and one upgrade at a time. Test all upgrade pairs, stacking caps, air reset limits, restoration cap and invulnerability interactions. Boss tests cover each pattern, missed counter, final opportunity, no-damage reward and safe transition to the next segment. Gate: every threat has a visible response and the boss uses already-taught controls.

### Gate 6 — production art and accessibility

Files: `art/source/`, `art/ASSET_LICENSES.md`, `assets/models/`, `assets/audio/`, `scenes/ui/`, `scripts/presentation/`, `tests/test_settings.gd`.

Approve silhouettes in grayscale at phone size before rigging. Replace one placeholder at a time without changing collision dimensions silently. Add animations, impact feedback and sound. Verify reduced motion, shake/flash toggles, muted play, color-vision readability, button targets and dark-shell contrast. Test actual portrait and landscape-safe letterboxing behavior rather than stretching the art.

### Gate 7 — evidence-led playtest

Files: `docs/playtest-protocol.md`, `docs/playtest-results.md`, `scripts/telemetry/local_events.gd`, `tests/test_event_privacy.gd`.

Use the same opening task without coaching. Record observed behavior separately from participant opinions. Check event consent and deletion. Decide continue/pivot/stop against the declared formative gates; improve controls before increasing content.

### Gate 8 — optional challenges and release preparation

Files: `scripts/replay/input_log.gd`, `scripts/replay/replay_driver.gd`, `scripts/share/challenge_code.gd`, `tests/test_replay.gd`, `tests/test_challenge_code.gd`, `README.md`.

Make authoritative combat outcomes deterministic in the logical simulation; Godot physics alone is not a cross-device determinism guarantee. Test identical seeded runs across supported builds, input timestamps, pause, dropped frames and ruleset mismatch rejection. Only then add replay rendering and optional video export. Audit asset rights, privacy, store requirements and trademark before any public launch.

### Planned verification commands

After the test harness exists:

- `godot --headless --path . --script tests/run_all.gd` — must report assertion totals and exit nonzero on failure.
- `godot --headless --path . --editor --quit` — import and parse smoke check; inspect the log for script errors as well as process status.
- `godot --path .` — manual keyboard/touch-emulation gameplay check, not a substitute for a physical phone.

Pin the actual executable path and build/export command in the future README. Do not claim any of these checks have run for this design package.

## 11. Risks and unresolved questions

- Camera/reference ambiguity: resolve before code, not after building the wrong genre.
- One-thumb accessibility versus counter precision: test real hands; allow mirroring and assist rather than reducing meaningful decisions to autoplay.
- Endless fatigue: cap speed, vary encounter rhythm, and reduce grind. More enemies are not automatically more depth.
- Procedural unfairness: validate reachability and reaction times, not just collision-free geometry.
- Visual overload: show one primary threat at a time early; keep the forward route visible during the biggest hit.
- Engine performance/export support: unknown until target-device spike. No promise of iOS packaging without signing/toolchain proof.
- Market appeal: original hook and stylish art are hypotheses, not evidence of demand.
- Concept consistency: generated images need human review and cleanup before becoming model sheets.

## 12. Artwork provenance and verification status

Generated using the image tool with GPT Image 2 medium, directed by Astra:

- `art/01-directions.png`: three proposed art directions; delivered size 1774×887.
- `art/02-sunbreak-concept.png`: recommended gameplay mood, courier views and interaction storyboard; delivered size 1536×1024.

The source prompts are saved in `art/PROMPTS.md`. Local image validity and dimensions are checked separately. An attempted independent visual audit was blocked by the vision provider's exhausted quota (HTTP 429); no retry was made. Therefore character-view consistency, anatomy and exact storyboard fidelity are not independently visually verified. Do not present generated concept art as game screenshots, final rigging references or verified production assets.

## 13. Approval checklist

- [ ] Behind-the-runner 3D portrait format matches the intended reference.
- [ ] Sunbreak Riot chosen, or B/C replaces it.
- [ ] Shield-counter chain reaction chosen as the first playable proof.
- [ ] Existing project identified or a new project approved.
- [ ] First test device identified.

Approve these before starting implementation. Until then, this package is the design baseline, not a build commitment.
