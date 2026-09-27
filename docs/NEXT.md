# Next slice: make the first encounter worth replaying

Foundation complete: first physical chain, lifecycle, input routing, procedural art and repeatable verification. The full design remains a roadmap, not an implemented feature list.

Resolved since this file was last rewritten: per-run seeds with result-screen replay codes and wave archetypes for run variety (slice 003/004, four archetypes since 008); style multiplier with HUD readout; contact stagger — hits slow the run and knock the offender down instead of ghosting through (slice 004); 0.25 s jump/slide input buffer; cause-specific failure lines; result-screen keyboard shortcuts; original favicon + social meta; cross-origin isolation headers; `breakrunState` gated to debug builds; hurdle contact matches the documented contract; touch ergonomics (slice 005); full-screen gestures — the whole screen is the controller (swipe anywhere, tap anywhere to counter), replacing the button bar (slice 006); self-hiding gesture legend, framed shield identity with lunge translation, counter FOV kick + impact burst, and the phantom post-counter warning-lane fix (slice 007); the stamp kicker with its sweep archetype (slice 008); the spring courier with its jump-verb sweep, aerial strike and boost (slice 009); the Route Inspector boss cycling bash/sweep/scanner patterns of all three taught verbs (slice 010); the title seed field that replays shared seeds exactly (slice 011).

1. Human playtest the first shield **and the stamp kicker** without coaching. Can players identify the dodge/slide answer, understand the adjacent strike, and repeat it intentionally? Capture specific confusion rather than adding content immediately. Also watch whether the stagger duration and slowdown feel fair and whether the archetype mix reads as variety rather than noise.
2. Give the shield a stronger authored wind-up and the courier a clearer reaching kick. Current box-based limbs are a silhouette scaffold, not final character art. Improve perceived contact before adding particles.
3. Tune the Route Inspector fight from human playtests (telegraph windows, pattern frequency, lane-shift reachability, and whether a clear should restore a pip); make the result screen's seed copyable so sharing does not require retyping digits.
4. Add actual lane traversal timing and validate reachability before combining hazards. Current logical lane selection is instantaneous while visual movement interpolates; fence waves rely on this.
5. Pool rendered enemy models and materials before increasing population. Current logic is bounded but visuals allocate at each new wave; this is acceptable only at current low population, not a production budget claim.
6. Select a physical test phone, verify safe-area insets, touch ergonomics, left-handed controls, sustained frame time and thermal behavior. No phone build is presently verified.
7. Upgrades stay gated behind the human playtest of the robots and the inspector fight.
8. Optional assist mode: slice 006 removed the on-screen action buttons in favor of whole-screen gestures (tap = counter). If playtests surface players who prefer buttons or need wider timing windows, reintroduce controls as an explicit assist toggle — not as the default.
9. Style-depth follow-up: the design's "varied actions" rule is currently simplified — combo counts any uninterrupted success, so repeated identical safe actions still grow the multiplier until the cap. Track action types if playtests show farming.

Known scaffold limitations: repeated flat rooftop runway rather than parkour chunks; no assist mode, save system, leaderboard, replay or monetization. The result screen shows the seed but there is no seed-entry UI to replay an exact run yet.

Review policy: independent code review cannot be called passed when a provider returns a quota/billing error. Record the actual fallback review result or leave the gate outstanding.

Web-specific follow-ups: the exported wasm is ~39 MB unstripped (custom stripped templates are future work); Web Audio and touch ergonomics are untested on real phones.
