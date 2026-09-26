# Slice 006 — full-screen gestures

> Scope: replace the button bar with the standard runner control grammar: swipe anywhere to move/jump/slide, tap anywhere to counter. User-driven ("clearer controls like how other games have it… the whole side of the screen can be a button"). The user's zone proposal was considered and answered with the simpler whole-screen scheme: zones add a second mental model (where you touch) on top of gestures (how you move), while the swipe grammar is already implemented and is what players of Subway Surfers / Temple Run already know.

## Design decisions

- **Whole screen is the controller.** Swipes already work everywhere on the track (gesture router, ≥32 px, diagonal exclusion). The button bar hid this behind three labeled buttons — deleting the bar makes the existing grammar the only grammar.
- **Tap = counter.** The router already classifies sub-32 px touches as "" (no action). "" now dispatches an attack attempt. A tap with no counter available shows the existing hint ("Watch for the next shield.") — informative, never penalized. The design plan's misfire worry (lane swipe accidentally attacking) is structurally solved: tap and swipe are disjoint classifications.
- **Counter-ready emphasis moves to the instruction bar.** The gold 3D counter ring already marks the moment in-world; the instruction text becomes "COUNTER NOW · tap anywhere" and pulses (suppressed by reduced motion).
- **Keyboard/mouse parity unchanged.** Space counters, WASD/arrows move; a mouse click (no drag) now also counters — matching tap semantics.
- **Menus keep buttons.** Start/Resume/Run-again/Back-to-title and Pause stay as buttons; only the in-play action bar goes away.
- **Deviation recorded:** docs/design/breakrun/PLAN.md's "dedicated large lower-right attack button" contract is superseded by this user decision. The assist-mode concern (players who prefer buttons) is tracked in NEXT.md as a future optional toggle, not silently dropped.

## Changes

- `scripts/main.gd`: release paths dispatch "attack" when the gesture router returns ""; bottom panel, hint label and the three action buttons removed; `jump_button`/`slide_button`/`attack_button` vars removed; counter-ready pulse moved to the instruction label; title-screen copy teaches the grammar ("Swipe anywhere to move, jump and slide — tap to counter.").
- `web_shell/index.html`: help sidebar and canvas aria-label updated to the tap grammar.
- `tests/test_input_scene.gd`: button-dependent tests replaced — tap anywhere fires a counter attempt, tiny-movement touches never act as swipes, mouse click counters through the choreographed chain, Pause button keeps press-to-fire; button disabled-state checks removed with the buttons.
- No simulation changes; scoring/chain reference 587 untouched; capture choreography (Space counter) untouched.

## Verification

- `python3 tools/verify.py --render` all green; capture review shows a button-free bottom with full track visibility.
- Web export rebuilt and deployed; Vercel build verified.
- Not proven: real-device feel; discoverability of tap-to-counter needs the human playtest already tracked in NEXT.md.
