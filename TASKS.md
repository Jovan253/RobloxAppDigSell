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
- [ ] 6. Rebirth system — server logic (`RebirthService`) done, needs UI wired to `Remotes.Rebirth`
- [ ] 7. Leaderboard (`OrderedDataStore` + display)
- [ ] 8. Monetization — gamepasses + developer products
- [ ] 9. Polish — sound/particle feedback on mining, mobile controls check, real art pass (current ore nodes are placeholder grey blocks)
- [ ] 10. Playtest, bugfix, thumbnail/icon, store page copy, soft launch

## Immediate next steps

- [x] Open in Roblox Studio (Rojo plugin installed, `rojo serve` running), playtest the core loop — confirmed live: ore mining + cash gain works
- [x] Retest `PurchaseUpgrade` remote via Command Bar — confirmed working after the `Remotes` naming-collision fix (commit `6e36594`)
- [x] Build Shop UI (StarterGui) wired to `PurchaseUpgrade`/`PurchaseZone`
- [ ] Playtest the new Shop UI live in Studio (untested so far — buy a pickaxe tier and a zone unlock through the panel, not just the command bar)
- [ ] Build Rebirth UI wired to `Rebirth`
