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
- [ ] 9. Polish — in progress, see "Polish: map & Dark Mines" below
- [ ] 10. Playtest, bugfix, thumbnail/icon, store page copy, soft launch

## Polish: map & Dark Mines (decided 2026-09-22)

User's ideas: fix the grey/flat map, spread zones/ores out more, more zones, more ore variety, better-looking ore, and a horror "Dark Mines" zone with a parkour-over-lava section and a "jumpscare prank" monetization item. Design decisions made: jumpscare = buyer pranks nearby players (developer product, not ambient); lava fall = respawn at last checkpoint, no cash loss; 4 total zones (Dark Mines is the new top tier); ore rarity = multiple weighted ore types per zone.

- [x] Rework zone data model in `Config.luau` — real room dimensions, materials/colors, per-zone ore type tables with rarity weights
- [x] Rework `MiningService` zone building — real rooms (floor/walls/ceiling), ore scattered across the floor instead of grid-aligned, zones spaced further apart and much larger
- [x] Ore visuals — material/color per ore type, glowing accent + light on rare types, varied size/rotation instead of uniform grey blocks
- [x] Add Dark Mines zone (Zone4, 25000 cost) — safe entrance ore, lava pit, zigzag jump platforms, 3-stage checkpoint system, treasure platform with rare Cursed Ruby ore
- [x] Lava fall → teleport to last checkpoint + `ZoneToast` "you fell in" message
- [x] Jumpscare Prank plumbing — `MarketplaceService` grant logic + `JumpscareEffect.client.luau` (flash effect; sound left blank, needs a real asset ID), gated behind `Config.JumpscareProductId` (currently nil)
- [ ] Playtest all of the above live in Studio — **none of this has been tested live yet**, this was a large change built in one pass. Expect the Dark Mines jump-platform spacing/lava depth specifically to need tuning (sized for default WalkSpeed/JumpPower, not verified in-engine)
- [ ] Create the "Jumpscare Prank" developer product in the Creator Dashboard, send the ID, so it can be wired into `Config.JumpscareProductId`
- [ ] Find/set a real sound asset ID for the jumpscare effect (`JumpscareEffect.client.luau`'s `SoundId` is blank)
- [ ] Gotcha if re-testing: `MiningService` only builds `MiningZones` if that folder doesn't already exist in Workspace — if Studio's Edit-mode Workspace somehow still has a leftover one from before, delete it manually or the old map will keep showing

## Future ideas (not in MVP scope)

- Auto-Mine gamepass — periodically auto-mines the nearest unlocked ore without clicking, for players who own it

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
