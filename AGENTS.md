# AGENTS.md — TABi

## What this is

**旅 / TABi** — a visual atlas of your memories in Japan.  
You take a photograph. TABi knows where you are. Your Japan Atlas grows.

## Core loop (only this)

```text
Capture → Remember → Atlas
```

## Hard rules

> **Do not optimize for feature count. Optimize for coherence.**
>
> TABi should feel like one carefully designed object: a Japanese photographic camera that happens to build a geographical atlas.
>
> When deciding between adding functionality and improving the core experience, **improve the core experience**.
>
> Prefer the smallest implementation that preserves the product's emotional experience.

> **Do not invent additional features without first checking whether they strengthen the core loop: Capture → Remember → Atlas.**

## Never build (V1)

Accounts · social · following · recommendations · itineraries · weather · booking · AI captions · world map · Android · cloud sync

**Japan only.**

## Stack (fixed unless user approves change)

- iOS 17.0+, SwiftUI, MapKit, CoreLocation, AVFoundation, Photos (add-only), CoreImage, SwiftData  
- Single Xcode target, folder modules  
- **No third-party dependencies** without explicit approval  
- `Domain/` must not import SwiftUI or UIKit  

## Design tokens

| Token | Hex |
|-------|-----|
| Washi | `#F5F1E8` |
| Sumi | `#252525` |
| Moss | `#68705A` |
| Indigo | `#26384A` |
| Vermilion | `#C95745` (sparingly) |

- English primary / Japanese secondary on camera place labels  
- Atlas stats: `N / 47 prefectures · M cities`  
- Outside Japan: human figure + “Exploring somewhere else in the world”  
- 旅/TABI: splash only  
- After capture: polaroid “Memory saved” card  
- Memories: Year → Trip; filters location + time  

## V1 technical decisions

- Location: foreground + photo-time only (no background tracking)  
- Photos: app sandbox; optional export to system Photos  
- Map: prefecture polygons + city points  
- Visits: deterministic heuristics (no ML)  
- Hierarchy: derived by grouping, not nested tables  

## Docs

- Design: `docs/superpowers/specs/2026-11-04-tabi-v1-design.md`  
- Engineering: `docs/tabi-engineering-guide.md`  
- Plan: `docs/superpowers/plans/2026-11-04-tabi-v1.md`  

## Machine / testing policy (user)

- **Computer is old / slow.** Do **not** run iOS Simulator tests (`xcodebuild test`, simctl boot) during normal development.
- During development: **compile only** (`xcodebuild build`) or syntax checks.
- **Defer all simulator tests to the end** of a work session or release gate.
- **Always ask the user before** running any simulator, device, or heavy test command.
- Prefer fast unit-test loops only when the user explicitly opts in.

## Before you add anything

Ask: **Does this strengthen Capture → Remember → Atlas?**  
If no — stop.
