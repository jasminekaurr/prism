# Console noise: UIContextMenu / RTI / variant selector — v1

**Date:** 2026-09-19

These Xcode console lines are Apple framework chatter, common when focusing TextFields, opening the soft keyboard, paste menus, or emoji search in the Simulator.

- `UIContextMenuInteraction updateVisibleMenuWithBlock` — menu update while menu already dismissed (paste/Edit menu).
- `RTIInputSystemClient` + `UIEmojiSearchOperations` — remote text input session already invalid.
- `variant selector cell index` — long-press accent/key variant UI.

Safe to ignore unless the UI itself fails (e.g. Paste button does nothing).
