# 旅 / TABi

**A visual atlas of your memories in Japan.**

You take a photograph. TABi knows where you are. Your Japan Atlas grows.

```text
Capture → Remember → Atlas
```

## What's inside

- **Atlas** — a full-screen illustrated map of Japan. Pan and zoom (opens fit-to-viewport);
  visited prefectures fill with sage green, masked to the painted coastline. Tap a
  prefecture to drill into its places and photos. Progress reads `N / 47 prefectures · M cities`.
- **Camera** — opens immediately with a minimal chrome (flash · shutter · flip). A photo
  auto-saves, then a polaroid confirms it: *Memory saved* with city and date.
- **Memories** — Year → Trip → photos, with location and time filters.

## Requirements

- Xcode with an iOS 17.0+ simulator target
- No third-party dependencies

## Build & run

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

Or open `TABi.xcodeproj` and run. The shared scheme enables the `-seedDemo` launch
argument, which populates a demo atlas (47 prefectures / 47 cities / 47 visits) and
re-seeds automatically when the seed version changes.

## Tests

```bash
xcodebuild test -project TABi.xcodeproj -scheme TABi \
  -destination 'platform=iOS Simulator,name=iPhone 16e'
```

23 unit tests covering geography parsing, projection/hit-testing, visit detection,
trip grouping, the film pipeline, and design tokens.

## Project layout

```text
TABi/Domain/          pure model + logic (no UI frameworks)
TABi/Map/             GeoJSON + projection — coordinates are data, never art pixels
TABi/Features/        Atlas · Camera · Memories (SwiftUI)
TABi/Assets.xcassets/ illustrated map + painted-land mask
TABiTests/            unit tests
TABi_design_kit/      design tokens and reference assets
```

## Design

Quiet, washi-and-sumi photographic aesthetic. Tokens:

| | |
|---|---|
| Washi | `#F6F0E4` |
| Sumi | `#34312C` |
| Indigo | `#557C91` |
| Sky | `#8FC5D8` |
| Moss | `#8FA477` |
| Peach | `#E9A59A` |
| Vermilion | `#C95B45` |
| Sand | `#DCC8A5` |

English primary, Japanese secondary. The map artwork is stylized — geographic truth
comes from GeoJSON; the illustration only carries the mood. Hard product rules live
in [`AGENTS.md`](AGENTS.md).
