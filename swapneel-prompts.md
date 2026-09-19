# Prism prompt history
# Append-only log of prompts and change summaries for this project.

### Prompt 1 — 2026-09-19
Implement the Prism iOS MVP Plan as specified. Do NOT edit the plan file. Mark todos in_progress as you work. Don't stop until all todos are complete.

**TL;DR:** Shipped local-first Prism iOS MVP: SwiftUI + SwiftData, spending pocket, full save→review→Money Story loop, Share Extension scaffold, docs, and 13 unit tests (all passing).

**Files changed:**
- `project.yml` — [NEW] XcodeGen definition (app, share extension, tests)
- `Prism/` — [NEW] App, Domain, Features, Infrastructure, DesignSystem
- `PrismShareExtension/` — [NEW] Share sheet scaffold + App Group inbox
- `PrismTests/` — [NEW] Unit tests (cooling, money, pocket, decisions, utils, perf)
- `PrismUITests/` — [NEW] UI smoke tests
- `docs/MVP_SCOPE.md` — [NEW] Must / nice / skipped / implemented tracker
- `README.md`, `ARCHITECTURE.md`, `SECURITY.md`, `PRIVACY.md`, `SUPABASE_SETUP.md`, `TESTFLIGHT_CHECKLIST.md`, `.env.example` — [NEW] docs
- `supabase/migrations/20260919000000_init_draft.sql` — [NEW] draft RLS schema
- `scratchpad/implementation-plan-v1.md` — [NEW] execution notes
- `swapneel-prompts.md` — [NEW] prompt log

**Key decisions:** Local-first only for first ship; spending pocket soft-preview (A); New York serif; Figma visuals with product-rule Money Story; Share Extension scaffolded but needs App Group provisioning.

**Errors encountered:** Share Extension empty MainStoryboard blocked install (fixed PrincipalClass); softDelete name clash; MoneyStorySnapshot Equatable tuples; AppRouter.Sheet Equatable for onChange; PerformanceSeed type-check timeout (rewrote loops).
