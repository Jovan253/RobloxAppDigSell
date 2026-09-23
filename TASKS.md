# Tasks — Dig & Sell Simulator

Live checklist for the MVP. Full rationale/design doc: `plans/2026-09-21-mvp-roadmap.md`. Keep this file in sync with what's actually built — check items off as they're done, add new ones as scope changes.

## MVP Milestones

- [x] 1. Setup — Rojo/git scaffolding
- [x] 2. Core mining loop — ore nodes, click → cash, respawn
- [x] 3. Currency + shop UI
  - [x] Cash HUD
  - [x] Shop UI (pickaxe upgrades) — `ShopUi.client.luau`, toggle button / "B" key
  - [x] Zone-unlock UI — same panel, wired to `Remotes.PurchaseZone`
- [x] 4. Zones/progression — 3 zones scaffolded server-side, gated by cash, unlockable from the shop UI
- [x] 5. DataStore persistence — save/load, autosave, save-on-leave/shutdown
- [x] 6. Rebirth system — UI added as a section in the shop panel (2-click confirm), wired to `Remotes.Rebirth`
- [x] 7. Leaderboard — `LeaderboardService` (OrderedDataStore, all-time, updates every 30s) + `LeaderboardUi.client.luau` panel ("Ranks" button / "L" key)
- [x] 8. Monetization — 2x Cash gamepass (1988462502) + Cash Pack developer products (Small 3714204369/5000, Huge 3714204408/50000), `MarketplaceService` + shop "Store" section
- [x] 9. Polish — map/ore/Dark Mines overhaul complete across 5 follow-up rounds, all confirmed live (see "Polish: map & Dark Mines" and "Follow-up round 2-5" below); further polish ideas (Gem system, Wheel Spin, Auto-Mine) deferred to "Future ideas"
- [x] 10. Launch prep — bugfix pass done, store copy drafted, launch checklist given, **published live** (2026-09-23). Icon/thumbnail upload still on the user (needs real screenshots I can't take myself).

## Polish: map & Dark Mines (decided 2026-09-22)

User's ideas: fix the grey/flat map, spread zones/ores out more, more zones, more ore variety, better-looking ore, and a horror "Dark Mines" zone with a parkour-over-lava section and a "jumpscare prank" monetization item. Design decisions made: jumpscare = buyer pranks nearby players (developer product, not ambient); lava fall = respawn at last checkpoint, no cash loss; 4 total zones (Dark Mines is the new top tier); ore rarity = multiple weighted ore types per zone.

- [x] Rework zone data model in `Config.luau` — real room dimensions, materials/colors, per-zone ore type tables with rarity weights
- [x] Rework `MiningService` zone building — real rooms (floor/walls/ceiling), ore scattered across the floor instead of grid-aligned, zones spaced further apart and much larger
- [x] Ore visuals — material/color per ore type, glowing accent + light on rare types, varied size/rotation instead of uniform grey blocks
- [x] Add Dark Mines zone (Zone4, 25000 cost) — safe entrance ore, lava pit, zigzag jump platforms, 3-stage checkpoint system, treasure platform with rare Cursed Ruby ore
- [x] Lava fall → teleport to last checkpoint + `ZoneToast` "you fell in" message
- [x] Jumpscare Prank plumbing — `MarketplaceService` grant logic + `JumpscareEffect.client.luau` (flash effect; sound left blank, needs a real asset ID), gated behind `Config.JumpscareProductId` (currently nil)
- [x] Playtest map/ore visuals live in Studio — confirmed "looks ok for most part" (2026-09-23)
- [x] Playtest the Dark Mines lava/parkour/checkpoint flow live — confirmed working (2026-09-23, across this and the following rounds' wall/sign fixes)
- [x] Create the "Jumpscare Prank" developer product in the Creator Dashboard — done, ID 3714340075, wired into `Config.JumpscareProductId`
- [x] Find/set a real sound asset ID for the jumpscare effect — done (139162107746216), wired into `JumpscareEffect.client.luau`
- [x] Playtest the Jumpscare Prank purchase/effect (flash + sound) live — confirmed working; tuned to white flash + fade matching audio length per feedback, "satisfactory" (2026-09-23)
- [ ] Gotcha if re-testing: `MiningService` only builds `MiningZones` if that folder doesn't already exist in Workspace — if Studio's Edit-mode Workspace somehow still has a leftover one from before, delete it manually or the old map will keep showing

## Follow-up round 2 (2026-09-23, based on first live look)

User feedback after seeing the map/ore/Dark Mines work: layout felt like one long corridor rather than a hub, no visual indicator blocking locked zones, and ore should stop reappearing in the exact same spot.

- [x] Hub-and-spoke layout — Zone1 (Sunny Quarry) is now a wide-open central hub with no walls; Zone2/3/4 sit in separate X lanes along its north edge, each reachable directly from the hub rather than one zone after another
- [x] Locked-zone barriers — red translucent Part blocks each locked zone's entrance, client-side only (`ZoneBarriers.client.luau`) so it's per-player correct (blocks you specifically until *you* unlock that zone) without needing per-player CollisionGroups; real security stays server-side in `MiningService`'s existing unlock check
- [x] Destroy-and-relocate ore respawn — mining now destroys the node outright (no more ghost-transparency) and respawns a new one at a random slot from that zone's fixed pool of positions, so ore drifts around instead of always reappearing in the same spot
- [x] Playtest hub/barriers/ore-respawn live in Studio — confirmed working, "barrier is fine" (2026-09-23)

## Follow-up round 3 (2026-09-23)

- [x] Barrier text labels — "`<Zone> / N Cash to Unlock`" on each locked barrier, hidden once unlocked
- [x] Replace default grey Baseplate with themed ground fill (`EnvironmentService`) + light distance fog, so the map doesn't bleed into an ugly infinite grey sandbox at the edges
- [x] Playtest both live in Studio — confirmed, "barrier is fine" (2026-09-23)

## Follow-up round 4 (2026-09-23)

User feedback: barrier text confirmed working (asked for it in round 3), grey void around the map still bothering them (addressed above), plus new requests — wooden "what zone is this" signs, and zones arranged one-per-side of the hub rather than fanned along one edge.

- [x] Wooden zone-name signs — post + board at each zone's entrance (hub gets one at its center), labeled on both readable faces, visible regardless of lock state (unlike the barrier label, which disappears once unlocked)
- [x] Radial hub layout — Zone2 (West), Zone3 (East), Zone4/Dark Mines (North), South left open for spawn. Added `ZoneGeometry` (shared orientation-aware local-to-world transform) so MiningService/ZoneBarriers/EnvironmentService all agree on where each zone's entrance and footprint actually are; Dark Mines' own lava/parkour geometry stays hardcoded North-only (documented in `Config.luau`)
- [x] Playtest both live in Studio — confirmed working; found one bug (sign post poking through the board), fixed same round (commit `4c82009`)

## Follow-up round 5 (2026-09-23)

- [x] Sign post still overlapped the board after the first fix (matched thickness but not vertical extent) — now stops exactly at the board's bottom edge, no overlap — confirmed fixed
- [x] Dark Mines lava pit — side/back walls now extend well below floor level so the pit has continuous cave wall on its sides instead of open void (commit `b65afe0`) — confirmed good on the long sides
- [x] Pit was still open void at the front/back ends (entrance drop-off and treasure-platform edge) — added matching end walls there too (commit `b0331a9`)
- [x] Playtest the pit end walls live in Studio — confirmed, "looks great" (2026-09-23)

## Follow-up round 6 (2026-09-23) — dev tooling

- [x] Admin account system — `Config.AdminUserIds`/`Config.IsAdmin`; on join, admins get all zones unlocked, max pickaxe tier, and the 2x Cash multiplier applied for free (doesn't cover Robux purchases — those still need real payment). Activated for UserId 2323949512.
- [x] Playtest live in Studio — confirmed working (2026-09-23). To test as a normal player, just ask to temporarily comment out the UserId in `Config.AdminUserIds` (one-line toggle, no in-game UI needed for this)
- [x] Disabled admin for normal-player testing per request (commit `f5b4867`) — re-enable by uncommenting the UserId in `Config.AdminUserIds`

## Launch prep (2026-09-23)

- [x] Bugfix pass — found and fixed a real data-loss risk: DataStore load failures (including transient ones) were silently treated as "new player," which would then save over real progress. Added retries + kick-instead-of-reset-on-failure (commit `1510f9b`)
- [x] Store page copy drafted (name + description) — see conversation; not yet pasted into the Dashboard by the user
- [x] Icon/thumbnail specs + guidance given (512x512 icon, 1920x1080 thumbnails) — actual images need to come from the user, can't generate/screenshot them myself
- [x] Launch checklist given (dashboard fields, Access setting, final playtest, invite testers)
- [x] **Published live to Roblox** (2026-09-23) — first time the actual live/public place matched what's been tested via Rojo live-sync this whole time

## Follow-up round 7 (2026-09-23) — post-launch feedback

User feedback after playing the live version: multiplayer server sizing, wanting all 4 hub sides used, more ore quantity, a request to assess pacing/motivation, a future reskin idea, and equipping an actual pickaxe with a swing + multi-hit mining.

- [x] Balance assessment — computed real numbers from Config: ~60 clicks to first pickaxe upgrade (healthy), ~500x expected-value range from Zone1/tier1 to Zone3/tier5+luck (normal exponential curve for the genre). Flagged real risk: one-click-destroy mining with only 10-30 ore slots per zone means multiplayer contention could stall players waiting for respawns, and there was no physical feedback per click beyond the number changing.
- [x] Server size recommendation — cap Max Player Count in Game Settings (Basic Info) to roughly 20-30; this is a solo-optimization simulator, not a game that benefits from huge crowded servers. **User action needed**: set this in the Dashboard/Studio, no code involved.
- [x] Ore count increase — Zone1/3: 30→50, Zone2: 28→45, Dark Mines entrance: 10→16, Dark Mines treasure: 6→10 (commit `90d8a76`)
- [x] Pickaxe tool + swing + multi-hit mining — see design decision below
- [x] Sky Ruins (5th zone, South side, floating-platform parkour over a bottomless drop) — see "Sky Ruins + hub rework" section below

**Design decision — multi-hit mining:** hits-required scales with pickaxe tier (fewer hits = better pickaxe), not just cash-per-hit. Wooden/Stone = 3 hits, Iron/Gold = 2, Diamond = 1 (instant), uniform across all ore types/zones (`Config.OreMaxHealth` + each tier's `Damage`).

### Pickaxe troubleshooting (2026-09-23) — several real bugs found via playtesting

- [x] Pickaxe shape looked like a "torch" — head part was rotated 90° around the wrong axis, aligning it with the handle instead of across it. Fixed (commit `9ae0a52`).
- [x] Mining did nothing with pickaxe equipped, attempt 1 — `CanQuery` (defaults true independent of `CanCollide`) meant the held tool's own parts blocked the click raycast from ever reaching the ore behind it. Fixed (commit `0847478`), but this wasn't the whole story.
- [x] Mining *still* did nothing with pickaxe equipped, attempt 2 — real root cause: Roblox's default controls stop evaluating `ClickDetector` hover/clicks entirely once **any** Tool is equipped (confirmed by the reported symptom: cursor stopped reacting to ore hover the moment a pickaxe was equipped). Requiring an equipped tool and triggering mining via ClickDetector could never have worked together. **Architecture change**: removed ClickDetector from ore nodes entirely; mining now fires on the pickaxe's `Tool.Activated` event → `Remotes.MineHit` → server picks the nearest ore within 10 studs of the player. Confirmed working (commit `25da3db`).
- [x] Mining particles invisible — `ParticleEmitter` needs a `Texture` to render anything; left unset betting on an engine default that didn't work. Replaced with plain Neon Parts flying outward + fading (no texture dependency). (commit `6673720`)
- [x] Swapped to a free Toolbox pickaxe asset (`ServerStorage.PickaxeAsset`) instead of the procedural shape — user inserted it, `PickaxeToolService` now clones and strips it (removes any bundled scripts, disables `CanQuery`) rather than building geometry from scratch. One color for all tiers for now. (commit `6673720`)
- [x] Confirmed Diamond Pickaxe one-shots every ore — correct by design (`Config.OreMaxHealth` is uniform at 3, Diamond's `Damage` is 3)
- [x] Pickaxe crashed on equip — `PickaxeAsset` turned out to be a `Model`, not a `Tool` (`CanBeDropped` doesn't exist on a Model). Now builds a real Tool around the Model's contents, picking a Handle part and welding the rest to it (commit `f3f3f99`)
- [x] Playtest the free-asset pickaxe + fixed particles live — confirmed working, "really cool"
- [x] Grip orientation (sharp edge leading, not flat side) — two blind guesses (Z-axis, then X-axis) were both wrong, X actively broke it (handle stuck out sideways from the hand). Stopped guessing and had the user live-tune it via the Command Bar instead (much faster iteration loop than a code round-trip per guess) — found value was Y-axis, 90°, now baked into `PickaxeToolService.luau` (commit `2878d4a`)

## Sky Ruins + hub rework (2026-09-23)

User request: add Sky Ruins so all 4 hub sides are used, move spawn to hub center, make the hub bigger, and size each zone to exactly match a hub side so there's no gap.

- [x] Hub grew 120x120 → 150x150; every spoke zone's width now matches the hub's side length exactly (150), zero gap on any side. Ore counts scaled up proportionally.
- [x] Sky Ruins (Zone5, South side, 75000 to unlock — new top tier above Dark Mines) — safe entrance ore, open bottomless-drop gap (non-solid kill-trigger far below floor, not lava), zigzag jump platforms, 3-stage checkpoints, treasure platform with rare Sky Shard ore. Built via `ZoneGeometry` throughout (orientation-aware), unlike Dark Mines which stays hardcoded North-only.
- [x] **Bug found and fixed while building this**: checkpoint tracking was keyed only by player, not by zone — invisible with one parkour zone, but with two (Dark Mines + Sky Ruins), falling in one before touching its checkpoints would've sent the player back to wherever they last checkpointed in the *other* zone. Checkpoints are now scoped per-zone. Generalized `setupLavaKillZone` into `setupFallKillZone` (zone-scoped lookup, caller-supplied message) so both zones share the same fall-recovery logic.
- [x] Spawn moved to the hub's center (`EnvironmentService.setupSpawn`) — replaces any existing SpawnLocation with exactly one, since no hub side is left open as an entrance anymore.
- [x] Playtest all of the above live in Studio — confirmed: "hub is good, spawn is good, no gaps"
- [x] Sky Ruins jumps "slightly too hard" — eased zigzag offset (8→6 studs) and enlarged landing platforms (6x1x5→7x1x6) for both Dark Mines and Sky Ruins, since they share the same math
- [x] Removed the Sky Ruins mid-gap checkpoint per feedback (entrance + treasure only now; Dark Mines keeps its mid-checkpoint, untouched)
- [x] Playtest the eased jump difficulty + checkpoint removal — confirmed, but now "too easy"
- [x] Platforms now drift side-to-side (oscillating tween, randomized period/phase per platform) instead of sitting still, adding a timing element on top of jump distance — shared `addOscillatingPlatform` helper for both zones; Dark Mines' mid-checkpoint widened to cover the swing range since it's tied to a now-moving platform
- [x] Playtest the moving platforms live — confirmed, "works a charm"

## Gem system (2026-09-24) — design finalized across two discussion rounds, building now

Full design history in conversation; final decisions below. Staged like Dark Mines/Sky Ruins: build core system first, spends next round.

**Earn:**
- Ongoing trickle scaled by ore rarity tier (Common 0 / Uncommon 1 / Rare 3 gems per mine)
- **Collection Journal** — one-time bonus (10 gems) the first time ANY ore type is ever mined; a Journal/Collection UI tab shows all types with collected/uncollected state. User: "players like to collect something, feel like they can achieve things."
- Playtime trickle from the original design **dropped** — not reaffirmed in discussion, keeping scope tighter
- Gem Pack developer product (direct Robux purchase) — fast-follow once we have a product ID, not blocking

**More ore variety (user: "maybe we need more ores?"):** adding a 3rd "Uncommon" tier ore to all 5 zones (between existing Common/Rare), bringing total ore types from 10 to 15 — richer mining variety and a meatier Journal.

**Spend, v1 (this round... next round, see below):**
- Speed Boost tiers (WalkSpeed, like Pickaxe tiers but for movement) — agreed
- Pickaxe **skins via cases** (not a direct shop) — user: spend gems to open a case with a horizontal spinning reveal animation, weighted-rarity pool of skins, **rarer skins get an attached particle effect** (not just recolors). This is real scope on its own (reveal UI + rarity table), not a quick add.

**Spend, deferred to fast-follow rounds (not v1):**
- Slap (Gem-gated version of the Jumpscare Prank pattern) — user idea, approved
- Hover (parkour skip) — user idea, approved; as **consumable charges** (~10s each) rather than a permanent toggle, so it doesn't trivialize the parkour content
- Lucky Charm (temporary boost to rare-ore drop weight) — user: "I like it"
- Pets — already flagged as its own bigger feature (following AI, rarity table, equip UI)

**Explicitly deferred, not v1:**
- Fast Travel between hub/zones — user: zones aren't big enough yet to need it; revisit once zones grow (user wants them bigger eventually — noted as a future direction, not actionable now)
- **Sell Shop** (mine ore → inventory → walk to sell instead of instant cash) — user's own idea, separate from Gems. Good pattern (AutoSeller gamepass tie-in), but changes the core loop's reward timing across a lot of already-tuned/tested code. Recommended and user agreed: own future round, doesn't block or depend on Gems either way.

### Stage 1 (building now): ore expansion + Gem currency/earn + Collection Journal
- [ ] Add 15 total ore types (5 zones x 3 tiers: Common/Uncommon/Rare) to `Config.luau`, each with a `Gems` value
- [ ] `Config.CollectionBonusGems` for the first-time-per-type bonus
- [ ] `DataService`: `Gems` + `CollectedOreTypes` on the profile, `AddGems`/`SetGems`, `MarkOreTypeCollected` (returns whether it was new)
- [ ] `MiningService`: grant Gems + check collection bonus on ore break, `ZoneNotice` toast on first-time discovery
- [ ] Gems readout in the HUD
- [ ] Collection Journal UI panel (all 15 types, grouped by zone, collected/uncollected)
- [ ] Playtest live

### Stage 2 (next round): Speed Boost + case-opening skins
- [ ] Not started

## Immediate next steps

- [x] Open in Roblox Studio (Rojo plugin installed, `rojo serve` running), playtest the core loop — confirmed live: ore mining + cash gain works
- [x] Retest `PurchaseUpgrade` remote via Command Bar — confirmed working after the `Remotes` naming-collision fix (commit `6e36594`)
- [x] Build Shop UI (StarterGui) wired to `PurchaseUpgrade`/`PurchaseZone`
- [x] Playtest the Shop UI live in Studio — confirmed: pickaxe purchase and zone unlock both work
- [x] Build Rebirth UI wired to `Rebirth`
- [x] Playtest the Rebirth UI live in Studio — confirmed working (tested with `Config.Rebirth.CashRequired` temporarily lowered to 50, reverted to 50000 after)
- [x] Build the leaderboard (`LeaderboardService` + `LeaderboardUi`)
- [x] Playtest the leaderboard live in Studio — confirmed: Ranks button now visible and working (fixed by disabling the default PlayerList overlay that was hiding it — commit `e28cf21`)
- [x] Publish the place to Roblox (even privately) — done
- [x] Create the "2x Cash" gamepass and Cash Pack developer product(s) in the Creator Dashboard, send IDs
- [x] Wire up `MarketplaceService` handling for the above
- [x] Playtest monetization live in Studio — confirmed working
