# Prism Implementation Plan v1

Date: 2026-09-19

## Goal
Ship local-first Prism iOS MVP per approved plan: SwiftUI + SwiftData, spending pocket, no live Supabase.

## Order
1. Phase 1 — Xcode scaffold, design tokens, domain, mocks, tab shell, docs
2. Phase 2 — Full local product loop
3. Phase 2 tests
4. Phase 3 — Backend stubs + SUPABASE_SETUP
5. Phase 4 — Share Extension scaffold
6. Phase 5 — UITests, privacy, TestFlight docs

## Decisions locked
- Spending pocket soft-preview (A); calendar month; confirmed purchase reduces remaining
- AI Description deferred
- New York system serif (Fraunces fallback documented)
- Bundle ID: `com.jasminekaur.prism` (see `scratchpad/bundle-id-mmn-dev-v1.md`)
