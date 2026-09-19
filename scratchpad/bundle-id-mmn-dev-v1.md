# Bundle ID alignment — mmn_dev — v1

Date: 2026-09-19

## Goal
Make `com.jasminekaur.prism` the canonical bundle ID on `mmn_dev`, matching the Apple Developer / Xcode signing already applied.

## Changes
- App: `com.jasminekaur.prism`
- Share: `com.jasminekaur.prism.share`
- Tests: `com.jasminekaur.prism.tests` / `.uitests`
- App Group: `group.com.jasminekaur.prism`
- Development Team: `84UWSJTPV6` (keep in project.yml so xcodegen does not wipe it)
