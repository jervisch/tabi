# 旅 / TABi — V1 Product Design

**Date:** 2026-11-04  
**Status:** Approved

## North star

> **旅 is a visual atlas of your memories in Japan.**  
> You take a photograph. TABi knows where you are. Your Japan Atlas grows.

### Core loop

```text
GO SOMEWHERE → OPEN TABi → TAKE A PHOTO → LOCATION + TIMESTAMP
→ PLACE IDENTIFIED → MEMORY CREATED → ATLAS UPDATED
```

The app is a **Japanese travel journal / photographic atlas**, not a travel planner.

**Governing rule:** Do not optimize for feature count. Optimize for coherence. Prefer the smallest implementation that preserves Capture → Remember → Atlas. Do not invent features that do not strengthen that loop.

---

## V1 scope

### Build

1. **Japan Atlas** — interactive map, current location, visited prefectures/cities, drill-down Japan → Prefecture → City → Place
2. **TABi Camera** — custom camera, capture, TABi photographic treatment, GPS + timestamp, place identification
3. **Automatic visit detection** — photo → visit candidate → confidence → confirmed visits on Atlas
4. **Memories** — year → trip organization (iPhone Photos–like), filters by location and time, photo detail

### Explicitly do not build

Accounts, social, following, recommendations, itinerary planning, AI descriptions, trip planning, weather, booking, global world map, Android, cloud sync. **Japan only.**

---

## Platform & stack

- iOS 17.0+, iPhone first
- Swift, SwiftUI, MapKit, CoreLocation, AVFoundation, Photos (add-only export), CoreImage, SwiftData
- No third-party dependencies without approval

---

## Decisions (locked)

| Topic | Decision |
|-------|----------|
| Architecture | Single Xcode target, folder modules; Domain is Foundation-only |
| V1 location | Foreground + photo-time only; no background tracking |
| Photo storage | App sandbox primary; optional export to system Photos |
| Map geometry | Prefecture polygons + city points (no municipal polygons) |
| Hierarchy storage | Derived by grouping (prefecture → city → placeName), not nested tables |
| Visit logic | Deterministic heuristics, no ML |
| Shell | Atlas (root NavigationStack) · center Camera cover · Memories |

---

## Data model

### Memory
`id`, `imageData`, `capturedAt`, `latitude`, `longitude`, `accuracy`, `placeName`, `city`, `prefecture`, `country`, `visitID`

### Visit
`id`, `placeName`, `city`, `prefecture`, `startedAt`, `endedAt`, `confidence`, `status` (`candidate` | `confirmed` | `rejected`), memories

### Geography (bundled)
- Prefecture: id (JIS), Japanese name, English name, polygon geometry (47)
- City: id, Japanese/English name, prefectureID, coordinate point

---

## Screen design (approved revisions)

### Splash
旅 / TABi branding **only** on loading/splash. Never permanent chrome on Atlas.

### Atlas (hero)
- Large Japan map (primary real estate)
- Stats: `N / 47 prefectures · M cities` from confirmed visits
- Visited prefectures softly tinted (Moss); city points where confirmed
- Current location pulse when in Japan
- **Outside Japan:** human figure + caption **“Exploring somewhere else in the world”** (atlas remains visible)
- Drill-down: Japan → Prefecture → City → Place → photo grid
- Quiet: washi/sumi palette, no Google-Maps overload

### Camera (hero)
- Minimal chrome; photo > UI
- Place label **above shutter**, English primary, Japanese secondary:
  - `KYOTO / GION`
  - `京都 · 祇園`
- Fallback while locating: `LOCATING…` then `SOMEWHERE`
- **After capture:** polaroid-style card — photo in white frame, bottom strip “Memory saved” + place, then dismiss or open detail

### Memories
- Organized **Year → Trip → photos** (like iPhone Photos)
- Trip = temporal/spatial cluster (gap > 2 days starts a new trip; same-region overnight stays one trip)
- **Filters:** location (prefecture/city) and time range
- Photo detail: full image, metadata, optional Save to Photos
- Place-first browsing remains available via Atlas drill-down (same store)

---

## Design system

### Colors
| Token | Hex |
|-------|-----|
| Washi | `#F5F1E8` |
| Sumi | `#252525` |
| Moss | `#68705A` |
| Indigo | `#26384A` |
| Vermilion | `#C95745` (sparingly) |

### Typography
- Japanese serif/Mincho for place names and editorial titles
- Restrained modern sans for UI chrome
- Quiet whitespace, editorial rhythm, subtle tactile texture

### Principles
Quiet · Editorial · Tactile · Japanese — **never stereotypical**  
Avoid: random sakura, excess torii, anime aesthetics, flag motifs, “tourist Japan” clichés.

---

## Location pipeline (V1)

```text
CoreLocation → LocationSample → RecentLocationStore (while foreground)
→ reverse geocode → PlaceComponents (prefecture/city/place/country)
```

- Retention: max ~500 samples or 24h
- Strongest visit signal: intentional photo capture
- Denied permission: photos still save; place may be unknown; explain in UI
- Outside Japan: record country; do not increment Japan stats

---

## Visit detection (V1 heuristic)

```text
photo + (resolved place OR Japan bbox)
confidence = 0.55 (photo) + 0.25 (accuracy ≤ 50m) + 0.20 (dwell ≥ 15m same city)
clamp 0…1
≥ 0.7 → confirmed; else candidate
same city+place within 12h → extend visit
```

---

## TABi film treatment

Composable CoreImage pipeline (`TABiFilmProcessor`):

1. Gentle contrast  
2. Reduced saturation (~0.85)  
3. Split tone: warm highlights, cool shadows  
4. Lifted blacks  
5. Subtle grain  
6. Soft highlight rolloff  
7. Very subtle halation (optional, ≤5%)

Preserve skin tones and Japanese reds. **Acceptance:** intentionally photographic, not obviously filtered.

Tune against fixtures: daylight, cloudy, indoor, night, neon, portrait, greenery.

---

## Testing

- `LocationProvider`, `CameraCapturing`, `PhotoLibraryExporting` — real vs mock
- `TABiFilmProcessor` — pure functions, fixture tests
- Scripted journeys: Tokyo → Shibuya → Kyoto → Gion
- Acceptance: empty atlas → Kyoto photo → drill to photo → leave Japan → multi-shot coherent look

---

## Phases

| Phase | Deliverable |
|-------|-------------|
| 1 Foundation | Launches to beautiful static Atlas |
| 2 Atlas | Fake-data drill-down Japan → Gion |
| 3 Camera | Real photo in TABi |
| 4 Photo+place | Kyoto photo under Kyoto |
| 5 Visits | Photo can mark city visited |
| 6 Film | Coherent TABi aesthetic |
| 7 Memories | Year/trip + filters + export |

---

## Long runway (not V1)

V2 background location → journeys · V3 photo clustering → memory books · V4 personal geography engine (Domain stays UI-free)
