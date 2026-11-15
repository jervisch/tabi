# TABi Atlas V3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the header/card Atlas with a full-screen illustrated watercolor atlas (`japan_map_base.png` 1024×1536), calibrated geographic overlay, vermilion-only visited stamps, quiet stats annotation, gated Okinawa inset, and branded splash — "a Japanese watercolor atlas that slowly becomes yours."

**Architecture:** The map view stays a single layered ZStack (art → overlays → hit-testing). Geographic truth stays in `JapanMapProjection` (linear lat/lon → artwork rect, recalibrated per artwork); the illustration is atmosphere only. Green graduated fills and the `MapArt` recolor pass are deleted — the new artwork ships quiet, and visited state is carried exclusively by vermilion stamps + stats. All edits are to existing files; no new source files, so no `xcodegen` step is required unless a task explicitly adds one.

**Tech Stack:** iOS 17+, SwiftUI, bundled fonts (Noto Serif/Sans CJK JP, EB Garamond), existing `TABiColor` tokens, GeoJSON prefecture dataset, SwiftData-backed `AppEnvironment.atlasStats`.

## Global Constraints

- Japan only · no third-party dependencies · no MapKit basemap · no standard iOS tab bar/cards/pills/shadows.
- Palette: Washi `#F6F0E4`, Sumi `#34312C`, Indigo `#557C91`, Sky `#8FC5D8`, Moss `#8FA477`, Peach `#E9A59A`, Vermilion `#C95B45`, Sand `#DCC8A5`. No iOS blue accents, no saturated colors, no pure-white cards.
- Japanese primary / English secondary. Fonts via `TABiFont` only (Noto Serif JP, EB Garamond, Noto Sans JP) — never `.system(...)` in shipped UI.
- Green must NOT be a visited/unvisited state signal. Unvisited Japan stays quiet cream/blue. Vermilion is the visited accent.
- Artwork = atmosphere; GeoJSON + `JapanMapProjection` = coordinates/hit-testing. Never infer coordinates from artwork pixels at runtime.
- The map is the page: no container, no card, no shadow, no large corner radius around the artwork. No decorative assets overlaid on the map (clouds/waves/Fuji/sakura are baked in).
- **Testing policy:** compile-only (`xcodebuild build`) during development. Do NOT run `xcodebuild test`, simulator boots, or any command expected to exceed ~30s without asking first. Batch test runs to end of session with user approval.
- **Commit policy (user-approved 2026-11-16):** one baseline commit for pre-existing work, then exactly one commit per completed task on `main`. (Supersedes the original no-commit line; SDD reviews need per-task commit ranges.)
- If any task adds a new `.swift` file, run `xcodegen generate` before building.

---

### Task 1: Swap in the new map artwork + make Atlas full-screen (Phase 1)

**Files:**
- Modify: `TABi/Assets.xcassets/japan_map_base.imageset/japan_map_base.png` (binary replace)
- Modify: `TABi/Features/Atlas/IllustratedJapanMapView.swift:19` (`mapAspect`), `:48` (image), `:269-335` (delete `MapArt`)
- Modify: `TABi/Features/Atlas/AtlasView.swift:69-107` (remove `header` usage), `:109-131` (delete `header` property)

**Interfaces:**
- Produces: `IllustratedJapanMapView` renders `Image("japan_map_base")` (raw, no recolor) at aspect `1024/1536`; `AtlasView` body has no header — only the map filling the space above the bottom nav.

- [ ] **Step 1: Replace the imageset PNG with the new artwork**

```bash
cp "TABi_design_kit/assets/map/japan_map_base.png" \
   "TABi/Assets.xcassets/japan_map_base.imageset/japan_map_base.png"
md5 "TABi_design_kit/assets/map/japan_map_base.png" \
    "TABi/Assets.xcassets/japan_map_base.imageset/japan_map_base.png"
```

Expected: both MD5s identical (`de34dbeb243587df69ba752cceff90fa`). The imageset `Contents.json` already points at `japan_map_base.png` — no catalog edit needed.

- [ ] **Step 2: Update the aspect and drop the recolor pass**

In `IllustratedJapanMapView.swift`, change:

```swift
private static let mapAspect: CGFloat = 1024.0 / 1536.0
```

Replace the hero image (line ~48):

```swift
// ── The hero: the illustrated page itself ─
Image("japan_map_base")
    .resizable()
    .frame(width: mapRect.width, height: mapRect.height)
    .position(x: mapRect.midX, y: mapRect.midY)
```

Delete the entire `enum MapArt { ... }` block (lines ~269–335). The new artwork intentionally has no baked green — the recolor is dead weight.

- [ ] **Step 3: Remove the Atlas header**

In `AtlasView.swift`, delete the `header` property (lines ~109–131) and its use in `body` (line ~72). The body becomes:

```swift
var body: some View {
    NavigationStack(path: $path) {
        IllustratedJapanMapView(
            visitedCities: visibleCityMarkers,
            visitedPrefectureCounts: visitedPrefectureCounts,
            currentCoordinate: env.currentSample.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            },
            isInJapan: isInJapan,
            onSelectPrefecture: { shape in
                path.append(PrefectureRoute(
                    id: shape.id,
                    nameEn: shape.nameEn,
                    nameJa: shape.nameJa
                ))
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Clear the bottom navigation — the map remains the page.
        .padding(.bottom, 72)
        .washiBackground()
        .navigationDestination(for: PrefectureRoute.self) { route in
            PrefectureDetailView(route: route, path: $path)
        }
        .navigationDestination(for: CityRoute.self) { route in
            CityDetailView(route: route, path: $path)
        }
        .navigationDestination(for: PlaceRoute.self) { route in
            PlaceDetailView(route: route)
        }
        .task {
            await env.refreshCurrentLocation()
        }
    }
}
```

(`visitedPrefectureCounts` stays for now — Task 3 removes it.)

- [ ] **Step 4: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **` (no errors; `MapArt` references are gone with Step 2).

- [ ] **Step 5: Visual check (ask user to run app)**

Map should be full-bleed watercolor Japan, no header, aspect-fit → roughly 82–88% of usable height. Japan recognizable Hokkaido→Kyushu without zoom. If Japan reads too small (map height < ~80% of usable area), note it for Task 2's fit adjustment — do not hack padding here.

---

### Task 2: Recalibrate geographic projection to the new artwork (Phase 2)

**Files:**
- Modify: `TABi/Map/JapanMapProjection.swift:18-23` (bounds constants)
- Temp (not committed): `/var/folders/77/td5ffhg51sz5w8yymz7d25180000gn/T/opencode/calibrate_v3.swift` + output PNGs

**Interfaces:**
- Consumes: `TABi_design_kit/assets/map/japan_map_base.png` (1024×1536), `TABi_design_kit/assets/map/japan_map_bounds.json` (starting guess), `TABi/Map/Resources/japan_prefectures.geojson`.
- Produces: updated `mainMinLat/mainMaxLat/mainMinLon/mainMaxLon` used by `JapanMapProjection.init(rect:mainIsland:)`, `point(for:)`, `prefecture(containing:in:shapes:)` — unchanged signatures.

- [ ] **Step 1: Write the offline overlay calibration script**

Create `/var/folders/77/td5ffhg51sz5w8yymz7d25180000gn/T/opencode/calibrate_v3.swift` — a standalone macOS Swift script that: loads the PNG via `NSImage`, parses the GeoJSON (`JSONSerialization`, Polygon + MultiPolygon), projects every ring with candidate bounds linearly across the full image rect, strokes the outlines in vermilion onto the image, also plots hardcoded seed-city dots (Kyoto 35.0116/135.7681, Osaka 34.6937/135.5023, Tokyo 35.6762/139.6503, Sapporo 43.0618/141.3545, Fukuoka 33.5904/130.4017, Naha 26.2124/127.6809 excluded — outside main bounds — plus Sendai 38.2682/140.8694, Hiroshima 34.3853/132.4553), and writes `overlay_v3.png`.

Seed constants at the top of the script so bounds are one edit:

```swift
var minLat = 30.2, maxLat = 45.8, minLon = 128.5, maxLon = 146.5  // japan_map_bounds.json
```

Projection inside the script (mirrors `JapanMapProjection.point`):

```swift
func project(_ lat: Double, _ lon: Double, w: CGFloat, h: CGFloat) -> CGPoint {
    CGPoint(
        x: CGFloat((lon - minLon) / (maxLon - minLon)) * w,
        y: CGFloat((maxLat - lat) / (maxLat - minLat)) * h
    )
}
```

Run:

```bash
cd /var/folders/77/td5ffhg51sz5w8yymz7d25180000gn/T/opencode
swift calibrate_v3.swift
```

- [ ] **Step 2: View the overlay and iterate bounds**

Read `overlay_v3.png` with the Read tool (single image read — do not parallelize image reads). Check: outline traces the painted coastlines (Hokkaido, Noto, Kii, Shikoku, Kyushu), seed dots sit on the correct cities. Adjust the four constants and re-run until aligned. Expect the JSON guess to be close but needing a few iterations (the previous artwork needed `27.7–45.9 / 129.2–146.3`; this artwork is a redraw — do not reuse old numbers without visual proof).

- [ ] **Step 3: Write calibrated bounds into the projection**

```swift
/// Mainland bounds — calibrated to the 1024×1536 `japan_map_base.png`
/// (GeoJSON outlines overlaid on the artwork until coastlines traced).
static let mainMinLat: Double = <calibrated>
static let mainMaxLat: Double = <calibrated>
static let mainMinLon: Double = <calibrated>
static let mainMaxLon: Double = <calibrated>
```

(Fill in the actual numbers from Step 2 — no placeholders may remain in the file.)

- [ ] **Step 4: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Visual check with seed demo (ask user)**

User runs app with `-seedDemo` (Kyoto/Osaka/Tokyo). Stamp dots must land exactly on those cities; tapping a prefecture must drill into the right one. Also confirm map fills 82–88% height — if the artwork leaves too much empty ocean, compensate by letting `aspectFit` slightly overflow width (crop side ocean only, keep top/bottom intact); change only `aspectFit` usage in `IllustratedJapanMapView`, not the projection.

---

### Task 3: Vermilion-only visited state — remove green fills (Phase 3)

**Files:**
- Modify: `TABi/Features/Atlas/IllustratedJapanMapView.swift:12`, `:53-62`, `:106-127`, `:253-267`
- Modify: `TABi/Features/Atlas/AtlasView.swift:22-30`, `:75-76`

**Interfaces:**
- Produces: `IllustratedJapanMapView` init no longer takes `visitedPrefectureCounts`; visited signal = existing `visitedCities` vermilion stamps only. `AtlasView` keeps `prefectureID(matching:)`/`normalize`/`normalizeShape` statics (Task 5 reuses them).

- [ ] **Step 1: Delete the fill layer from the map view**

Remove from `IllustratedJapanMapView.swift`:
- the `visitedPrefectureCounts` stored property (line ~12)
- the `visitedPrefectureFills(mapRect:)` call + its `.mask { ... }` block (lines ~53-62)
- the entire `// MARK: - Visited prefectures` section (`visitedPrefectureFills` + `fillOpacity`, lines ~106-127)
- the `private struct PrefectureFillsShape` (lines ~253-267)

- [ ] **Step 2: Remove the counts plumbing from AtlasView**

Delete the `visitedPrefectureCounts` computed property (lines ~22-30) and the `visitedPrefectureCounts:` argument (line ~75). Keep `prefectureID`, `normalize`, `normalizeShape` untouched.

- [ ] **Step 3: Keep the stamps, confirm they carry the state**

Existing `markDot` (vermilion ring + core) and `editorialLabel` (京都 / KYOTO) stay as-is — they are the "I left a mark here" metaphor from §10. No green anywhere in the overlay stack.

- [ ] **Step 4: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **` (grep the build log for `visitedPrefecture|PrefectureFillsShape` — zero hits expected).

---

### Task 4: Stats as quiet atlas annotation (Phase 4)

**Files:**
- Modify: `TABi/Features/Atlas/AtlasView.swift` (add overlay sibling to the map)

**Interfaces:**
- Consumes: `env.atlasStats` (`AtlasStats` with `prefectures: Int`, `cities: Int` — already refreshed in `AppEnvironment`).
- Produces: `private var statsAnnotation: some View` — used as an overlay on the map in `body`.

- [ ] **Step 1: Add the annotation view**

```swift
/// Printed-on-the-atlas progress note. No card, no pill, no shadow.
private var statsAnnotation: some View {
    VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(env.atlasStats.prefectures) / 47")
                .font(TABiFont.placeEnglish(20, weight: .medium))
                .foregroundStyle(TABiColor.sumi.opacity(0.7))
            Text("PREFECTURES")
                .font(TABiFont.caption(8, weight: .medium))
                .tracking(2)
                .foregroundStyle(TABiColor.sumi.opacity(0.4))
        }
        VStack(alignment: .leading, spacing: 1) {
            Text("\(env.atlasStats.cities)")
                .font(TABiFont.placeEnglish(20, weight: .medium))
                .foregroundStyle(TABiColor.sumi.opacity(0.7))
            Text("CITIES")
                .font(TABiFont.caption(8, weight: .medium))
                .tracking(2)
                .foregroundStyle(TABiColor.sumi.opacity(0.4))
        }
    }
    .allowsHitTesting(false)
}
```

(If `placeEnglish` has no `weight:` default-arg form, use `TABiFont.placeEnglish(20)` — match the existing signatures already used in this file.)

- [ ] **Step 2: Overlay it over open ocean, clear of taps**

In `body`, wrap the map:

```swift
ZStack(alignment: .topLeading) {
    IllustratedJapanMapView(...)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 72)

    statsAnnotation
        .padding(.leading, 20)
        .padding(.top, 170)
}
```

Placement target: left-edge ocean band below the top-left sakura branch (the new art's emptiest region). `allowsHitTesting(false)` keeps prefecture taps working underneath.

- [ ] **Step 3: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Visual check (ask user)**

Stats read like printed atlas marginalia over ocean; numbers slightly stronger than labels; no overlap with Japan or sakura. If they collide with the top sakura branch, move `.padding(.top, 170)` down until clear.

---

### Task 5: Gate the Okinawa inset on an actual visit (§13)

**Files:**
- Modify: `TABi/Features/Atlas/AtlasView.swift` (compute + pass flag)
- Modify: `TABi/Features/Atlas/IllustratedJapanMapView.swift` (new param + conditional)

**Interfaces:**
- Consumes: `Self.prefectureID(matching:)` (kept in Task 3), `env.confirmedVisits()` (visits carry `prefecture: String`).
- Produces: `var showsOkinawaInset: Bool = true` on `IllustratedJapanMapView`; default `true` keeps previews/existing call sites working, AtlasView passes the real value.

- [ ] **Step 1: Compute whether Okinawa has been visited (AtlasView)**

```swift
private var hasVisitedOkinawa: Bool {
    guard let okinawaID = Self.prefectureID(matching: "Okinawa") else { return false }
    return env.confirmedVisits().contains {
        Self.prefectureID(matching: $0.prefecture) == okinawaID
    }
}
```

Pass it at the call site: `showsOkinawaInset: hasVisitedOkinawa,`.

- [ ] **Step 2: Conditionally render the inset (map view)**

Add the stored property next to the other params:

```swift
/// Okinawa only joins the atlas page once the traveler has been there.
var showsOkinawaInset: Bool = true
```

Replace the unconditional inset call:

```swift
// ── Okinawa: printed atlas detail, only once visited ─────
if showsOkinawaInset {
    okinawaInset(art: insetArt)
}
```

(The `insetArt` geometry computation may stay — it is cheap — or move inside the `if`; either compiles.)

- [ ] **Step 3: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Behavior check (ask user, seedDemo)**

With Kyoto/Osaka/Tokyo seed: no inset bottom-left. (Okinawa visit can be verified later by user or a temporary seed — do not build one now.)

---

### Task 6: Bottom navigation conformance check (Phase 5)

**Files:**
- Inspect: `TABi/App/RootView.swift` (already implements §14–15)

**Interfaces:** none changed unless the audit finds a violation.

- [ ] **Step 1: Audit `RootView` against the brief**

Verify each rule — all should already pass from the previous round:
- illustrations `nav_atlas` / `nav_camera` / `nav_memories` sit on washi with **no** circles/pills/cards/selection backgrounds
- camera `frame(height: 32)` vs tabs `24` → 1.33× (within 1.2–1.4×), offset `y: -4`, no shadow/glow/FAB chrome
- inactive tabs: `opacity(0.55)` + `scaleEffect(0.96)`; selected: `1.0` / `1.0`, animation `.easeOut(0.15)`
- labels separate from illustrations: 地図/Atlas, 思い出/Memories, `TABiFont` only
- camera opens `CameraView` via `fullScreenCover` (capture = core action, not a tab switch)

- [ ] **Step 2: Fix only real violations**

If a rule fails, edit `RootView.swift` minimally to match. If all pass, make **no changes** — do not churn working code.

- [ ] **Step 3: Compile-check (only if Step 2 changed anything)**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 7: Splash screen — strongest TABi branding (Phase 6)

**Files:**
- Modify: `TABi/App/SplashView.swift`

**Interfaces:**
- Consumes: `TABiFont` (`title(_:)`, `placeEnglish(_:weight:)`), `TABiColor` tokens. Launch flow in `TABIApp.swift` (900ms → 0.4s crossfade) stays unchanged.

- [ ] **Step 1: Restyle with bundled editorial fonts and restrained atmosphere**

```swift
import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            TABiColor.washi.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("旅")
                    .font(TABiFont.title(84))
                    .foregroundStyle(TABiColor.sumi)
                Text("TABi")
                    .font(TABiFont.placeEnglish(16, weight: .medium))
                    .tracking(10)
                    .foregroundStyle(TABiColor.sumi.opacity(0.65))
            }
        }
    }
}

#Preview {
    SplashView()
}
```

Rules: no illustration overload — if the composition feels bare after a visual check, add at most one restrained element (e.g. a `TABiColor.vermilion` hairline rule 40pt wide, 1pt, opacity 0.35, between 旅 and TABi). No sakura stickers, no logo images, no animation beyond the existing app-level crossfade.

- [ ] **Step 2: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Visual check (ask user)**

Sequence: TABi splash (旅 + TABi, journal-grade typography) → crossfade → full-screen Atlas. Branding recedes after entry (no TABi logo anywhere on Atlas — Task 1 guaranteed this).

---

### Task 8: Polish + §22 quality gate (Phase 7)

**Files:**
- Modify: `TABi/Features/Atlas/IllustratedJapanMapView.swift` (stamp transition)
- Modify: `TABi/App/RootView.swift` (camera press feedback)

**Interfaces:** no signature changes.

- [ ] **Step 1: Stamp arrival animation**

On the stamps ZStack (the `visitedMarks(mapRect:)` return):

```swift
.animation(.easeOut(duration: 0.35), value: visitedCities.count)
```

and on `markDot` + `editorialLabel` individually:

```swift
.transition(.opacity)
```

A newly confirmed visit fades its mark in — "quiet Japan → marked Japan."

- [ ] **Step 2: Camera press feedback (subtle, not FAB)**

In `RootView`, hold press state:

```swift
@State private var isCameraPressed = false
```

On the camera button label: `.scaleEffect(isCameraPressed ? 0.94 : 1.0)` with `.animation(.easeOut(duration: 0.12), value: isCameraPressed)`, wired via `ButtonStyle`:

```swift
.buttonStyle(PressableStyle(isPressed: $isCameraPressed))
```

with:

```swift
struct PressableStyle: ButtonStyle {
    @Binding var isPressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
```

(Simpler: apply the style only to the camera button; tabs need no press effect.)

- [ ] **Step 3: Compile-check**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'generic/platform=iOS Simulator' build 2>&1 \
  | grep -E 'error:|BUILD' | head -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: §22 quality walkthrough with the user (screenshot to stable path)**

Ask the user to run the app and save screenshots to `tabi/screenshot.png` (stable path — temp paths expire). Walk the checklist:

1. **First impression** — "My illustrated map of Japan," not a tracking app.
2. **Composition** — Japan dominates; map 82–88% of usable height; no header.
3. **Branding** — TABi only on splash; Atlas is MY JAPAN.
4. **Geography** — Hokkaido→Honshu→Shikoku→Kyushu instantly recognizable; stamps on correct cities; prefecture taps drill correctly.
5. **Memories** — visited cities meaningful (vermilion ◉ + 京都/KYOTO); unvisited quiet.
6. **Color** — no green state signal; vermilion is the only strong accent.
7. **UI** — nothing reads as stock iOS (no tab bar chrome, no cards, no SF Symbols on Atlas).
8. **Restraint** — name any element whose removal would improve the page; remove it.

- [ ] **Step 5: End-of-session test run (ONLY with explicit user approval)**

```bash
xcodebuild -project TABi.xcodeproj -scheme TABi \
  -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | tail -30
```

Per machine policy this is deferred to session end and requires the user's OK first. Existing suites (`GeographyTests`, `DesignSystemTests`, …) have no projection-bound assertions, so Task 2's new constants should not break them — if any fail, fix before closing.

---

## Spec coverage map

| Brief section | Task |
|---|---|
| §2/§8 full-screen, no header | 1 |
| §3 branding recedes / §16 splash | 1 (removal), 7 (splash) |
| §4 new artwork asset | 1 |
| §5 green not visited-state | 1 (drop recolor), 3 (drop fills) |
| §6 map scale | 1 (aspect + fit), 2 (Step 5 overflow note) |
| §7 artwork vs geographic data | 2 (recalibrate from dataset, offline overlay) |
| §9 stats annotation | 4 |
| §10/§11 vermilion stamps | 3 (kept), 8 (arrival animation) |
| §12 no over-decoration | Global Constraints + §22 Step 4 |
| §13 Okinawa gating | 5 |
| §14/§15 navigation + camera | 6, 8 (press feedback) |
| §17 screen structure | 1 + 4 (compose the page) |
| §18 typography | 4, 7 (`TABiFont` only) |
| §19–21 color/restraint/principle | Global Constraints + §22 Step 4 |
| §22 quality test | 8 Step 4 |
| §23 phase order | Tasks run in order 1→8 |

## Self-review notes

- No placeholders: Task 2 Step 3 intentionally says "fill in calibrated numbers from Step 2" — the numbers are produced by an executable calibration procedure in the same task, not deferred work.
- Type consistency: `showsOkinawaInset` (Task 5) matches call-site and property spellings; `statsAnnotation` uses existing `AtlasStats` fields `prefectures`/`cities`; `prefectureID(matching:)` survives Task 3 for Task 5's reuse.
- No new files → no `xcodegen` required (noted in Global Constraints for safety).
