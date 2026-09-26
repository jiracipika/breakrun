# Slice 005 — touch ergonomics

> Scope: fix the touch controls UI and buttons. Presentation/input only — no simulation changes. Authorized by the user ("Fix touch controls UI and buttons").

## Problems in the current bottom bar

1. **Buttons fire on release.** Godot's default action mode triggers on release; in a runner, touch actions must land on touch-down to feel instant.
2. **No press feedback.** Secondary buttons look identical pressed and idle (border-only change), so taps feel dead.
3. **No disabled style.** The helper overrides normal/hover/pressed/focus only, so the disabled Counter button falls back to the engine theme and looks washed out next to the custom panels.
4. **Jump/Slide stay lit while paused or dead** — only Counter is disabled.
5. **Cramped targets.** Jump/Slide are 107 px wide with ~11 px gaps; primary/secondary hierarchy is weak.
6. **Stale hint copy.** The touch bar advertises keyboard keys ("A D · W S · Space"); keyboard hints already live in the web shell's help sidebar.
7. **HUD panels stop mouse input.** On desktop-web a drag starting on a panel is consumed (emulated-mouse path), killing the swipe; panels should pass input through.

## Changes (all in `scripts/main.gd`)

- `button()` helper: `ACTION_MODE_PRESS`; pressed state inverts (primary → paper bg/ink text, secondary → lightened panel with border); disabled state gets a dim custom style + dimmed font color.
- `panel()` helper: `mouse_filter = IGNORE` so panels never consume drags.
- Bottom bar: Jump/Slide 124×68, Counter 188×78, wider gaps; jump/slide/counter stored as members and disabled when not running.
- Counter button pulses its opacity while a counter is available (suppressed by reduced motion).
- Hint line becomes "Swipe the track to move / tap the buttons".

## Tests (`tests/test_input_scene.gd` additions)

- Mouse press alone on Jump fires the jump before any release (red today, green after).
- Swipe starting on the instruction panel still moves the runner (guards the pass-through path).
- Disabled Counter carries its own stylebox override.
- Existing press+release click tests must stay green (no double-fire from press mode).

## Verification

- `python3 tools/verify.py --render` all green; capture review of the new bottom bar, paused dim state, and pulse frame.
- Web export rebuilt and deployed; Vercel build verified.
- Not proven: real-device touch feel (no physical phone in the loop yet).
