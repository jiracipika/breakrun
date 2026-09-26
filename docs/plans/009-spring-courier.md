# Slice 009 — the spring courier

> Scope: the design plan's third enemy — teaches the jump verb and pays a movement reward. Test-first. Authorized by the user ("continue iterating").

## Design (from the original contract)

> Spring courier: compact round spring legs; crouch then rising whistle; **jump its low sweep and aerial strike**; grants a forward aerial boost to an authored landing.

## Contract

- Perfect inversion of the kicker: the low sweep hits grounded **and sliding** players in its lane; jumping clears it. Telegraph: the coil crouches from z 16.
- Recovery window (z 6–2) opens the strike, but only **mid-air** (height > 0.5): grounded strikes are refused with "Strike it mid-air!". Jumping the sweep naturally keeps you airborne into the window.
- A successful aerial strike launches the courier and boosts the runner: world speed ×1.35 decaying over 1.2 s (the anti-stagger — an enemy that becomes a movement tool). `world_speed()` composes stagger × boost factors; the base speed cap still applies before them.
- Seeded **spring** archetype: courier, then dummies in the neighbor/lane pattern. Waves 1–2 stay the teaching checkpoint; the strike-able set grows to shield/kicker/spring.
- Boost is observable state (`boost_count`, `_boost`), presentation plays a rising chirp and eases FOV wider while boosting (reduced-motion gated).

## Tests (test-first, `tests/test_spring.gd`)

- Low sweep hits grounded and sliding players in-lane; jumping clears and marks dodged; other lane dodges.
- Grounded strike refused with the mid-air hint; aerial strike in the window launches it (base 50, boost starts, `world_speed() > speed()`).
- Boost decays back to exactly base after 1.2 s.
- Seeded waves produce the courier; impact slice: strike-able set includes the spring.

## Verification

- `python3 tools/verify.py --render` all green; chain reference 587 and LIVE markers unchanged.
- Web export rebuilt, deployed, hash-verified.
