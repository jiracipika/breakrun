# Slice 008 — the stamp kicker

> Scope: the design plan's second enemy, teaching the slide verb the way the shield teaches dodge-and-counter. Test-first. Authorized by the user ("continue iterating").

## Design (from the original contract)

> Stamp kicker: tall forked silhouette; one raised foot and a projected ground stripe; **slide under the high sweep, then strike**; the swept body trips a nearby robot.

## Model contract

- Kicker telegraphs from z 16 (ground stripe lights in its lane), sweeps at z 9–6.
- The sweep is HIGH: grounded **and airborne** players in its lane are hit; sliding players (or any other lane) dodge it and mark it resolvable.
- After the sweep it leans into a recovery (z 6–2) — strike window identical to the shield's (dodged + adjacent lane + once per attack tap).
- A strike launches the kicker as a projectile; the existing projectile sweep makes it trip the dummies/barrier ahead in its lane — the "swept body trips a nearby robot" chain.
- Damage funnels through a new `_damage(kind)` helper shared with the contact branch (sweep hit: hp −1, combo reset, stagger, `last_hit_kind = "kicker"`).
- Wave pool grows to four seeded archetypes: checkpoint, patrol, fence, **sweep** (kicker, neighbor dummy, lane dummy, lane hurdle — striking the kicker trips the trailing dummy, then the hurdle asks for the jump). Waves 1–2 stay the teaching checkpoint.

## Presentation

- Tall cobalt forked robot with a saffron `Foot` limb and a gold `Stripe` lane marker (z ≤ 16, hidden once launched/cleared).
- Sweep: foot swings through the lane; recovery: lean-back (shared pose); counter ring marks the strike window for both robots.
- Instruction copy generalized to font-safe text ("DODGE — leave the marked lane", "SWEEP! Slide the striped lane", "STRIKE NOW · tap anywhere"); result screen names the kicker.

## Tests (test-first, `tests/test_kicker.gd` + impact-slice updates)

- Sweep hits grounded in-lane; sliding dodges; other-lane dodges; jumping does **not** dodge.
- Striking without dodging is rejected with the slide hint; striking in recovery after a slide launches it (base 50, counter count +1).
- Launched kicker trips a trailing dummy (chain + styled score).
- Impact slice: every wave opens with a strike-able robot (shield or kicker) and carries exactly one.
- Capture: staged kicker shows the stripe + sweep pose.

## Verification

- `python3 tools/verify.py --render` all green; chain reference 587 unchanged; LIVE-STAGGER unchanged.
- Web export rebuilt, deployed, hash-verified (including `web/` in the commit).
