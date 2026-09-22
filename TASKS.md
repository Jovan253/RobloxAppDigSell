# Tasks — Dig & Sell Simulator

Live checklist for the MVP. Full rationale/design doc: `plans/2026-09-21-mvp-roadmap.md`. Keep this file in sync with what's actually built — check items off as they're done, add new ones as scope changes.

## MVP Milestones

- [x] 1. Setup — Rojo/git scaffolding
- [x] 2. Core mining loop — ore nodes, click → cash, respawn
- [ ] 3. Currency + shop UI
  - [x] Cash HUD
  - [ ] Shop UI (pickaxe upgrades) — server logic (`ShopService`) already done, needs a `StarterGui` menu wired to `Remotes.PurchaseUpgrade`
  - [ ] Zone-unlock UI — server logic already done, needs UI wired to `Remotes.PurchaseZone`
- [x] 4. Zones/progression — 3 zones scaffolded server-side, gated by cash (no UI yet to trigger unlock, see above)
- [x] 5. DataStore persistence — save/load, autosave, save-on-leave/shutdown
- [ ] 6. Rebirth system — server logic (`RebirthService`) done, needs UI wired to `Remotes.Rebirth`
- [ ] 7. Leaderboard (`OrderedDataStore` + display)
- [ ] 8. Monetization — gamepasses + developer products
- [ ] 9. Polish — sound/particle feedback on mining, mobile controls check, real art pass (current ore nodes are placeholder grey blocks)
- [ ] 10. Playtest, bugfix, thumbnail/icon, store page copy, soft launch

## Immediate next steps

- [x] Open in Roblox Studio (Rojo plugin installed, `rojo serve` running), playtest the core loop — confirmed live: ore mining + cash gain works
- [ ] Retest `PurchaseUpgrade`/`PurchaseZone`/`Rebirth` remotes via Command Bar (fixed a `Remotes` folder/ModuleScript naming collision that broke them — see commit `6e36594`)
- [ ] Build Shop UI (StarterGui) wired to `PurchaseUpgrade`/`PurchaseZone`
- [ ] Build Rebirth UI wired to `Rebirth`
