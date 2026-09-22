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
- [ ] 8. Monetization — gamepasses + developer products
- [ ] 9. Polish — sound/particle feedback on mining, mobile controls check, real art pass (current ore nodes are placeholder grey blocks)
- [ ] 10. Playtest, bugfix, thumbnail/icon, store page copy, soft launch

## Immediate next steps

- [x] Open in Roblox Studio (Rojo plugin installed, `rojo serve` running), playtest the core loop — confirmed live: ore mining + cash gain works
- [x] Retest `PurchaseUpgrade` remote via Command Bar — confirmed working after the `Remotes` naming-collision fix (commit `6e36594`)
- [x] Build Shop UI (StarterGui) wired to `PurchaseUpgrade`/`PurchaseZone`
- [x] Playtest the Shop UI live in Studio — confirmed: pickaxe purchase and zone unlock both work
- [x] Build Rebirth UI wired to `Rebirth`
- [x] Playtest the Rebirth UI live in Studio — confirmed working (tested with `Config.Rebirth.CashRequired` temporarily lowered to 50, reverted to 50000 after)
- [x] Build the leaderboard (`LeaderboardService` + `LeaderboardUi`)
- [x] Playtest the leaderboard live in Studio — confirmed: Ranks button now visible and working (fixed by disabling the default PlayerList overlay that was hiding it — commit `e28cf21`)
