# Next slice: make the first encounter worth replaying

Foundation complete: first physical chain, lifecycle, input routing, procedural art and repeatable verification. The full design remains a roadmap, not an implemented feature list.

1. Human playtest the first shield without coaching. Can players identify the dodge lane, understand the adjacent counter, and repeat it intentionally? Capture specific confusion rather than adding content immediately.
2. Give the shield a stronger authored wind-up/lunge and the courier a clearer reaching kick. Current box-based limbs are a silhouette scaffold, not final character art. Improve perceived contact before adding particles.
3. Introduce one jump/slide obstacle as a test-first authored encounter. Add actual lane traversal timing and validate reachability before combining hazards. Current logical lane selection is instantaneous while visual movement interpolates.
4. Add original or licensed impact/run audio with independent mute. There is no sound in the current slice.
5. Pool rendered enemy models and materials before increasing population. Current logic is bounded but visuals allocate at each new wave; this is acceptable only at current low population, not a production budget claim.
6. Select a physical test phone, verify safe-area insets, touch ergonomics, left-handed controls, sustained frame time and thermal behavior. No phone build is presently verified.
7. Add the other enemy types, boss and upgrades only after the shield interaction passes a human playtest.

Known scaffold limitations: repeated flat rooftop runway rather than parkour chunks; fixed seed in UI; no persisted scores/settings; reduced-motion toggle only removes kick lean; no input buffer, assist mode, save system, export presets, leaderboard, replay or monetization. The distant decorative gantry remains fixed in the initial presentation and should be moved into the reusable chunk system with future environment work.

Review policy: independent code review cannot be called passed when a provider returns a quota/billing error. Record the actual fallback review result or leave the gate outstanding.

Web-specific follow-ups: no favicon set in project settings yet (default Godot icon is exported); Web Audio and touch ergonomics are untested on real phones; consider narrowing the exported pck further (vercel.json currently ships unthrottled). Also revisit runtime debug hooks (`breakrunState`) and keep them out of any future production build if they are not wanted.
