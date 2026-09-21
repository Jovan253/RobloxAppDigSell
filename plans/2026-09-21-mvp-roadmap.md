# Roblox Game: "Dig & Sell" Mining Simulator — MVP Plan

## Context

The working directory (`Roblox-App`) started as a brand-new, empty project. The user is a software developer who wants to build a Roblox game with real potential to be popular, while keeping scope simple enough for a solo dev to actually finish.

We worked through the concept together:
- **Genre: Simulator/incremental** — chosen because it's Roblox's most proven "simple to build, high ceiling for popularity" formula (see Pet Simulator, Mining Simulator, etc.). The core loop is almost entirely data/number-tuning rather than complex gameplay systems, and it's naturally extensible post-launch (new zones, new upgrades) without redesigning anything.
- **Concept: "Dig & Sell Simulator"** (mining simulator lineage) — chosen over a meme-trend concept (Brainrot Collector) specifically because it's evergreen rather than trend-dependent, so it won't feel dated if development or growth takes longer than expected. Core loop: mine ore nodes → sell for Cash → upgrade pickaxe/unlock zones → rebirth for permanent multipliers.
- **Experience level: some Roblox/Luau exposure** — plan assumes basic familiarity with Studio and Luau syntax, but spells out tooling setup and Roblox-specific service usage rather than assuming prior project structure knowledge.
- **Scope: 2-4 week MVP** — a real soft-launchable first version (a few upgrade tiers, persistence, basic monetization, leaderboard), not a bare prototype and not a fully polished long-tail project.

Goal of this plan: get from empty folder to a soft-launchable Roblox experience.

## Tooling & Project Structure

Since the user is a software dev, we set this up as a real version-controlled codebase using **Rojo** (the standard tool for syncing a filesystem project into Roblox Studio), instead of working directly inside a `.rbxl` file with no diffing/history.

Setup steps (one-time):
1. Install Roblox Studio (if not already installed).
2. Install the **Rojo** CLI (via Aftman, the standard Roblox toolchain manager) and the **Rojo Studio plugin**.
3. `git init` the project directory and commit the scaffold.
4. In Studio → Game Settings → Security → enable **"Enable Studio Access to API Services"** so DataStores work in local testing.

Project structure (Luau + Rojo, no TypeScript build step — keeps things simple per the "simple" goal):

```
Roblox-App/
  aftman.toml              # pins rojo version
  default.project.json     # Rojo project file, maps src/ folders to Roblox services
  src/
    ReplicatedStorage/
      Config.luau           # tunable numbers: ore values, prices, zone unlock costs
      Remotes.luau          # RemoteEvent/RemoteFunction definitions
    ServerScriptService/
      MiningService.luau    # validates hits, grants cash, respawns nodes
      DataService.luau      # DataStore load/save for player progress
      ShopService.luau      # handles upgrade purchases
      RebirthService.luau
      MarketplaceService.luau  # gamepass/dev product handling
    StarterPlayer/
      StarterPlayerScripts/
        MiningClient.luau   # input handling, fires remotes, plays effects
      StarterGui/
        MainUi/              # cash display, shop menu, rebirth menu (ScreenGui)
  docs/                      # reference/architecture docs
  plans/                     # this file and future planning docs
```

The map itself (dig zones, rock/ore part layout, terrain) will be built visually in Roblox Studio rather than defined in code — that's the normal workflow even in code-driven Roblox projects.

## Core Loop & Systems

1. **Mining**: Player holds a pickaxe tool; hitting an ore node (a Part tagged/named appropriately) fires a RemoteEvent to the server. Server validates the hit (debounce, range/tool check — basic anti-exploit for MVP, not full hardening) and grants Cash directly (skip a separate ore-inventory step to keep MVP simple). Node respawns after a short delay.
2. **Currency & Shop UI**: Cash counter in a ScreenGui, updated via a RemoteEvent/attribute change. Shop UI lets the player spend Cash on:
   - Pickaxe tiers (more cash per hit / faster swing)
   - Zone unlocks (2-3 zones total for MVP, each with higher-value ore)
3. **Persistence**: `DataService.luau` uses `DataStoreService` to save/load Cash, current pickaxe tier, unlocked zones, and rebirth count, keyed by `player.UserId`. Load on `PlayerAdded`, save on `PlayerRemoving` and periodically (autosave every few minutes) to reduce data loss risk.
4. **Rebirth**: Once Cash crosses a threshold, player can reset Cash/upgrades in exchange for a permanent multiplier (stored in DataStore, persists across rebirths).
5. **Leaderboard**: `OrderedDataStore` for a global Cash (or Rebirths) leaderboard, displayed via a in-game leaderboard model (common Roblox pattern — a physical board with a `SurfaceGui`, or a UI panel).
6. **Monetization**: `MarketplaceService` for:
   - Gamepasses: 2x Cash, auto-mine/magnet convenience
   - Developer products: instant Cash packs
   (Wire these up but don't over-invest in monetization polish for MVP — get the core loop right first.)

## Milestones (2-4 week MVP)

1. **Setup** — Rojo/Studio/git scaffolding, confirm sync works end-to-end (few hours)
2. **Core mining loop** — pickaxe, ore nodes, hit → cash, respawn (days 1-3)
3. **Currency + shop UI** — cash display, pickaxe upgrade purchases (days 3-6)
4. **Zones/progression** — 2-3 zones gated by cash/purchase (days 6-9)
5. **DataStore persistence** — save/load, autosave (days 9-11)
6. **Rebirth system** (days 11-13)
7. **Leaderboard** (days 13-14)
8. **Monetization** — gamepasses + dev products (days 14-16)
9. **Polish** — sound/particle feedback on mining, mobile controls check (Roblox traffic is majority mobile), basic low-poly art pass (days 16-19)
10. **Playtest, bugfix, thumbnail/icon, store page copy, soft launch** (days 19-21+)

Live status for these milestones is tracked in `TASKS.md` at the repo root, not duplicated here — this file is the frozen rationale/design doc, `TASKS.md` is the current checklist.

## Verification

Roblox development doesn't use a typical automated test suite for gameplay — verification is primarily manual:
- Use Studio's **Play** (F5) and **Play Here** for solo iteration on each system as it's built.
- Use Studio's **Team Test** (multiple local clients) before shipping multiplayer-sensitive systems (leaderboard, DataStore, remotes) to catch sync/race issues a single client won't reveal.
- Specifically verify: DataStore values survive a rejoin (test in Team Test or a published test place, since local Play sessions can behave differently), remotes reject invalid/spoofed calls (sanity check server validation), mobile touch controls work for mining and UI (test via Studio's device emulator).
- Before soft launch: publish to a **private/unlisted place** first, invite a couple friends to test the full loop including monetization purchases (Robux purchases can be tested with actual small Robux spend or via Studio's test-purchase tooling), then make it public.

## Implementation notes (post-approval deviations)

- Mining interaction uses a `ClickDetector` on each ore node rather than a swung pickaxe tool with raycast hit-detection. Simpler to implement and reliably testable without live Studio access during the session that built the scaffold. Can be swapped for a real tool-swing later without touching `DataService`/`ShopService`/`RebirthService`.
- Cash is read client-side from `leaderstats.Cash` rather than pushed over a dedicated `CashUpdated` RemoteEvent — avoids keeping two sources of truth in sync. Only `PurchaseUpgrade`, `PurchaseZone`, and `Rebirth` remotes exist.
