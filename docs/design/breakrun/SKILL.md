---
name: breakrun-design
description: Use when designing or building BREAKRUN.
version: 0.1.0
author: rs-mac, Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    editorial_name: BREAKRUN Design and Build Contract
    editorial_description: Preserve the combat-runner hook, art direction, fair controls and evidence gates across development sessions.
    tags: [game-design, runner, combat, art-direction]
    requires_tools: [read_file, write_file, terminal]
---

# BREAKRUN Design and Build Contract

This is a project-local handoff skill, not an installed global Hermes skill. Read the adjacent `PLAN.md` for the full proposal. When moved into a game repository, place this package under `docs/design/breakrun/` and preserve its relative links. A user approval or correction overrides the provisional design.

## When to use

- Continuing the BREAKRUN combat-runner design or implementing an approved slice.
- Reviewing combat, encounter generation, assets, controls or presentation for this project.
- Do not apply these constraints to unrelated game repositories.

## Prerequisites

- Identify the actual project path and read its current instructions and Git status before editing.
- Confirm whether the current request permits implementation. Planning and concept-art requests do not authorize a game build, installation, publishing or paid services.
- Read `PLAN.md`, its approval checklist, and any later approved decision notes.
- The behind-the-character camera and Sunbreak Riot direction are provisional until approved. Do not claim the reference app has been identified.
- Generated PNGs are concept artwork, not sprites, 3D models, rigging blueprints or proof of a playable game.

## Procedure

1. **Resolve scope.** State the chosen project and approved milestone. If modifying an existing repository, inspect changes and pull before editing without overwriting user work. Completion: one unambiguous project and a bounded slice.
2. **Protect the hook.** Preserve the dodge → counter → launched-enemy → environmental-chain loop. Completion: the slice changes a player decision or proves that loop, rather than adding unrelated menus or systems.
3. **Specify before implementing.** Name inputs, state transitions, failure cases, affected files and acceptance tests. Completion: every requested behavior has an observable verification.
4. **Use test-first logic.** Run a failing test for timing boundaries, scoring, seed behavior or lifecycle before implementing it. Completion: the new test passes and existing relevant tests remain passing.
5. **Separate simulation from spectacle.** Score only logical events with unique IDs. Keep physics, camera shake and particles from awarding duplicate points. Completion: repeated contact, pause, low FPS and restart cannot create extra rewards.
6. **Preserve input ownership.** UI touches do not also move the character; one pointer lifecycle produces one swipe; buffered actions expire across pause and restart. Completion: touch cancellation, diagonal swipes, safe areas and key repeat are tested.
7. **Enforce procedural fairness.** Validate lane reachability, reaction distance, landing anchors and chunk transitions using actual movement timings. Completion: the declared seed corpus contains no impossible mandatory path.
8. **Stage art.** Approve silhouettes and grayscale contrast at phone size before investing in rigs. Keep original asset provenance and licenses. Completion: source, license, scale, collision envelope and animations are recorded for each shipped asset.
9. **Exercise the game.** Run headless tests, parse/import smoke checks and an actual interactive session. Inspect logs even when the process exits successfully. Completion: start, counter chain, hit, pause, death and restart all work in the tested build.
10. **Measure on target.** Record device, build, resolution, frame-time distribution and settings. Completion: performance claims name tested hardware and do not equate desktop or simulator results with physical-phone proof.
11. **Report honestly.** Distinguish implemented, tested, concept-only and blocked items. Completion: every success claim has a command result, artifact, capture or observed playtest behind it.

## Art constraints

- Recommended world: coral daytime rooftops, cobalt shadows, saffron courier, teal municipal robots.
- UI shell: opaque #0A0A0F background, #1C1C2E panels, readable light text. Match web/mobile shell if both exist.
- Keep the player, middle-distance threats and route distinct. Every hazard needs shape/motion cues, not color alone.
- Use opaque impact shapes, bounded effects and simple jacket bones. No required bloom, volumetric fog, cloth simulation or translucent particle blankets.
- Make shake, flashes, haptics and motion independently optional where feasible. Do not hide future hazards behind celebratory effects.
- Keep all characters, music, models and branding original or appropriately licensed. Working title clearance remains pending.

## Scope boundaries

- Prove the shield chain before adding a roster, second district, online systems or monetization.
- Treat 3 enemies, 1 boss and 6 upgrades as the initial content ceiling, not tasks to parallelize before the core loop passes.
- Never promise popularity or call a tiny playtest market validation.
- Seed codes are not video exports. Deterministic input logs require versioned simulation rules; engine physics is not sufficient proof.
- Local scores are untrusted. Do not ship a supposedly fair public leaderboard without validation.
- Do not work on automated-newsletter or pitchforge/pitch-therapy as part of this project or any background handoff.

## Pitfalls

- Auto-run becoming auto-combat: preserve deliberate timing and route choices.
- Generated art implying impossible mechanics: implement the tested interaction, not every flourish in the PNG.
- Three alternative concepts silently becoming three promised biomes: only the approved direction enters the first production slice.
- A beautiful menu disguising unreadable combat: evaluate the playable loop before interface polish.
- Swapping engines or camera styles without approval: record the measured reason and request a decision.
- Claiming visual review after a tool failure: report the limit and preserve the uncertainty.

## Verification

For design-only work: verify required documents, image decoding and dimensions, prompt provenance and explicit assumptions. Do not run or claim game tests when no game exists.

For approved implementation: invoke the project's actual test harness with `terminal`, inspect real output, and manually exercise the requested loop. The future `godot --headless --path . --script tests/run_all.gd` command is valid only after that harness has been created. Export success, device installation and interactive play are separate claims and require separate evidence.

Update this skill only with reusable project rules and newly verified pitfalls. Keep temporary progress and task logs in decision or verification documents, not in global memory.
