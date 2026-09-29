# Slice 014 — perks after the inspector

> Scope: the design plan's upgrade system, first pass. The user opened the playtest gate for new scope ("new scope? lets add to the game"). Simulation + one overlay; no new enemies.

## Design (from plan §5, honest adaptations recorded)

Defeating the Route Inspector offers a choice of **two perk cards** drawn from the unowned pool; the world freezes until one is picked (design: "pause the world at upgrade selection; no timed choice pressure"). Cards are seeded — same seed, same offers — keeping seed replay exact. When every perk is owned, later clears pay no offer.

Five perks ship (the plan's six, minus one that has no honest analog in this simulation):

- **Pinball** — a launched robot ricochets once into an adjacent lane after its first strike, scoring targets there.
- **Springstep** — the courier boost lasts half again as long (plan's mid-air lane correction has no meaning while lane changes are instant; adaptation recorded).
- **Street broom** — launched robots fly half again as far, reaching deeper wave targets.
- **Relay** — two launched robots passing each other pay a one-time +50 Relay event.
- **Second wind** — an inspector clear without taking damage during the fight restores one pip (never above three).

## Model state

`owned_upgrades: Array[String]`, `upgrade_offer: Array` (empty = not choosing), `relays: Dictionary` (pair keys), `_inspector_damaged` (reset at spawn, set by any damage while it lives). `step()` and `act()` freeze while an offer is open; `take_upgrade(name)` validates against the offer, records ownership, resumes. Effects read ownership at their sites (pinball ricochet in the projectile pass, boost/cull duration helpers, relay pass, second-wind heal inside the defeat branch before the offer is drawn).

## Tests (test-first, `tests/test_upgrades.gd`)

- Defeat offers two distinct unowned perks, frozen world (step/act no-ops), take_upgrade resumes and records; offers never repeat owned names; exhausted pool → no offer.
- Pinball: launched robot with one strike ricochets into the adjacent lane holding a target and scores it.
- Springstep: boost decay stretches to 1.8 s; Street broom: launched cull stretches to 2.25 s.
- Relay: two launched robots crossing pay +50 exactly once.
- Second wind: a flawless clear heals one pip (capped at three); a damaged clear does not.
- Scene check (real overlay): defeating a staged inspector shows the perk overlay, picking a card hides it and owns the perk.

## Verification

- `python3 tools/verify.py --render` all green; existing references unchanged. Web export rebuilt, deployed, hash-verified.
- Not proven: perk balance and card-pool pacing (the reopened playtest gate); offers on a second inspector are covered by tests, not a long human run.
