# Security

## Client secrets

- iOS may only ship public Supabase URL + anon key (later).
- **Never** commit service-role keys, provisioning profiles, or certificates.
- Use gitignored local xcconfig / `.env` when cloud is enabled.

## Local data

- Media written with Data Protection (complete until first unlock).
- Auth tokens (future) go in Keychain (`KeychainStore`).
- Optional Face ID / Touch ID app lock.
- Notifications omit item titles on the lock screen.

## Networking (future)

- HTTPS only.
- Do not log signed media URLs.
- Open source links via system browser (`openURL`).
- No advertising or behavioral tracking SDKs in MVP.

## Input

- URL validation rejects non-http(s) schemes.
- Images re-encoded to strip EXIF/location when possible.
- No HTML rendering from external sources.
- Clipboard only after explicit paste into fields.

## Crash / analytics

- `RedactingCrashReporter` and `PrivacySafeAnalytics` avoid titles, reflections, prices, URLs, media, and PII.
