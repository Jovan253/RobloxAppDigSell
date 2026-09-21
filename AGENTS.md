# Agent notes — Roblox-App

## Planning docs
Feature/implementation plans go in `plans/`, named `<date>-<slug>.md` (e.g. `plans/2026-09-21-mvp-roadmap.md`). Keep them versioned in the repo rather than only in a tool's local plan-mode storage, so they persist across machines/sessions. A plan file is a frozen rationale/design doc — once milestones are underway, track live status in `TASKS.md`, not by editing the plan.

## Task list
`TASKS.md` at the repo root is the current checklist. Update it whenever work is completed or scope changes — it should always reflect what's actually built, not what was originally planned.

## Project structure
Rojo-synced Luau project (`default.project.json`, `aftman.toml`). Map/level geometry is built visually in Roblox Studio, not in code. See `plans/2026-09-21-mvp-roadmap.md` for the full concept, architecture, and milestone breakdown.
