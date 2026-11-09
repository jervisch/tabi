# TABi — Engineering Guide

A plain-language map of how the app is built, and why.

---

## 0. One sentence

**TABi is a single iPhone app that turns a shutter press into a place-tagged memory, and turns memories into a map of Japan.**

Core loop:

```text
open app → see atlas → take photo → photo + GPS + time
→ place identified → visit confidence → atlas lights up
```

Everything in the codebase exists to serve that loop.

---

## 1. The dollhouse (project structure)

One Xcode project, one app target, folders as rooms:

```text
TABi/
├── App/           # entry point, root tabs, design tokens (colors/type)
├── Features/      # screens: Atlas, Camera, Memories, Place
├── Domain/        # Memory, Visit — pure data, no UI
├── Location/      # “where am I?”, geocoding, visit rules
├── Camera/        # live camera + film-look processor
├── Map/           # Japan shapes + city points (bundled data)
├── Persistence/   # save/load on-device (SwiftData)
└── Export/        # optional save to system Photos
```

**Rule:** Features may talk to Domain/Location/Camera/Map/Persistence.  
Domain must not import UIKit/SwiftUI — so a future personal geography engine can reuse it without dragging in screens.

---

## 2. The three nouns (data model)

### Memory — one photograph that matters

```text
id, image bytes, capturedAt,
latitude, longitude, accuracy,
placeName, city, prefecture, country,
visitID (optional link)
```

### Visit — “we were here for a while”

```text
id, place, city, prefecture,
startedAt, endedAt,
confidence (0…1),
status: candidate | confirmed | rejected,
memories[]
```

### Place hierarchy — NOT stored as nested tables

Japan → Prefecture → City → Place is **derived** by grouping memories and visits:

```text
group by prefecture → city → placeName
```

Why: less schema churn; the atlas always recomputes from memories + visits.

**Geography data (bundled, offline):**

- 47 prefecture polygons (GeoJSON in app bundle) → draw/fill the map  
- City coordinates → dots + labels for drill-down  
- Reverse geocoding (Apple) turns GPS into strings like “Kyoto”

---

## 3. Location pipeline (V1: foreground + photo-time only)

```text
CoreLocation
    → LocationSample (lat, lon, accuracy, timestamp)
    → RecentLocationStore (short buffer while app is open)
    → CLGeocoder (async reverse geocode)
    → PlaceComponents (city / prefecture / place / country)
```

**V1 policy:**

- No background tracking (that is V2)
- Strongest signal: user opened TABi and took a photo on purpose
- Dwell evidence only from samples collected **while the app is open**
- Battery: standard accuracy while foregrounded
- Outside Japan: still record the photo; atlas stays; UI shows “Exploring somewhere else in the world”

**Failure modes (always handled):**

- Permission denied → camera can still work; place = unknown; banner explains  
- Geocoder timeout/fail → keep lat/lon; label fallback  
- Poor accuracy (>100m) → lower visit confidence; never block saving  

---

## 4. Visit detection (deterministic heuristics, no ML in V1)

```text
photo captured
    + fix (prefer accuracy ≤ 50m)
    + place resolved OR Japan bounding box
    → create or extend Visit candidate

confidence =
  0.55  intentional photo
+ 0.25  accuracy ≤ 50m
+ 0.20  dwell ≥ 15 min same city (while app open)
clamp 0…1

confidence ≥ 0.7 → status = confirmed → atlas updates
same city + place within 12h → append to existing visit
```

No cloud, no model training. Pure rules so tests stay boring and reliable.

---

## 5. Camera stack

```text
CameraManager (AVCaptureSession)
    → preview (SwiftUI representable)
    → shutter → AVCapturePhotoOutput
    → JPEG/HEIF bytes
    → TABiFilmProcessor (CoreImage chain)
    → write processed file to app sandbox
    → insert Memory row (SwiftData)
    → optional: save to system Photos (add-only permission)
```

**TABiFilmProcessor** = ordered, composable stages:

1. Gentle contrast  
2. Saturation pull-down  
3. Split tone (warm highlights, cool shadows)  
4. Lifted blacks  
5. Subtle grain  
6. Soft highlight rolloff  
7. Hint of halation (optional)

Skin tones and Japanese reds stay natural. The look can evolve without rewriting the shutter path.

**Polaroid confirm UI** is SwiftUI over the same processed image — no second render path.

---

## 6. Atlas rendering

```text
bundled GeoJSON → [PrefectureShape]
SwiftData → confirmed visit prefecture set + city counts

MapKit map
    → fill visited prefectures (Moss tint)
    → city points where confirmed visits exist
    → current location pulse if in Japan
    → human figure + “Exploring somewhere else in the world” if not

NavigationStack: Japan → Prefecture → City → Place → grid / detail
Stats: `N / 47 prefectures · M cities` from confirmed visits
```

---

## 7. Memories organization

Primary browser: **Year → Trip → photos** (iPhone Photos–like).

```text
Trip = cluster of memories
  new trip if date gap > 2 days
  OR region change with gap > 12h
```

Secondary: filters by location (prefecture/city) and date range.  
Atlas drill-down remains place-first. Both read the same Memory store.

---

## 8. Persistence & sandbox

- SwiftData on-device  
- Images under Application Support/Memories/  
- Optional export → PHPhotoLibrary (add-only)  
- No cloud sync in V1  
- Demo seed behind launch argument `-seedDemo` or DEBUG  

---

## 9. Testing strategy

Protocol seams — real vs mock:

| Seam | Real | Mock |
|------|------|------|
| LocationProvider | CoreLocation | Scripted timeline |
| CameraCapturing | AVFoundation | Fixture images |
| PhotoLibraryExporting | Photos | Spy |
| FilmProcessor | CoreImage | Pure fn + fixtures |

Scripted journeys: Tokyo → Shibuya → Kyoto → Gion, assert atlas sets, confidence, grouping.

---

## 10. Build phases

| Phase | Demo | Risk burned down |
|-------|------|------------------|
| 1 Foundation | beautiful empty map | project, design system, geo bundle |
| 2 Atlas | fake drill-down | navigation, map styling, counts |
| 3 Camera | real photo in sandbox | permissions, AVFoundation |
| 4 Photo+place | Kyoto photo under Kyoto | geocode + SwiftData glue |
| 5 Visits | new city lights up | confidence rules |
| 6 Film | coherent look on samples | CoreImage pipeline |
| 7 Memories | year/trip + filters | grouping, export |

Parallel after Phase 2: camera UI ∥ location wiring, joined at Phase 4.

---

## 11. Explicit non-goals (anti-drift)

Do not add: accounts, social, itineraries, weather, booking, recommendations, AI captions, world map, Android, cloud.

**Check before any new feature:** Does it strengthen Capture → Remember → Atlas? If not, it waits.

---

## 12. Long runway (not V1)

```text
V1  Capture → Location → Memory → Atlas
V2  background location → visit inference → journeys
V3  photo intelligence → clustering → memory books
V4  personal geography engine (Domain already UI-free)
```
