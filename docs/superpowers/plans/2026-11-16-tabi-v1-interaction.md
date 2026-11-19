# TABi V1 Interaction & Visual Implementation Plan

## FINAL TARGET STATE (authoritative — supersedes conflicting task text below)

Reference mockup: `/Users/jervischan/Documents/Code/tabi/2c8b1209-6ca9-4ff7-b1e9-33324bfb7d34.png`

This is the definitive description of the app after all discussions. Where any task
below contradicts this section, **this section wins.**

### Atlas (root screen)
- Full-bleed illustrated Japan map (`japan_map_base.png`) extending **behind** the bottom nav.
- Map is pannable and zoomable. No top header. No TABi logo.
- Visited prefectures filled with a **subtle sage-green** tint.
- **No** city names, no pins, no stamps, no visit labels.
- Stats upper-left, editorial typography, e.g. `47 / 47 PREFECTURES` + `47 CITIES`
  (with `-seedDemo`). Warm washi paper background throughout.
- No new raster assets unless strictly necessary; existing assets + SwiftUI native drawing.
- Native / responsive layout — no hardcoded device sizing.

### Bottom navigation (persistent)
- Warm-washi strip. **Exactly three** controls:
  - `Map` (left)
  - circular shutter camera button (center, slightly overlapping the strip's top edge)
  - `Memories` (right)
- English labels only. **No** icons, tab-bar symbols, pills, or SF Symbols for Map/Memories.
- `Map` selected → subtle hand-drawn vermilion underline. `Memories` inactive/understated.
- Camera control → a simple vermilion circular shutter with a thin cream/dark outline.

### Interaction
- `Map` → Atlas · `Memories` → Memories · center camera → Camera (full-screen cover).
- **No swipe navigation** between Atlas and Memories. (This supersedes Task 6.)

### Camera
- Opens immediately, full-screen. 3:4 viewfinder centered on black.
- × close top-left; shutter; flash toggle; flip camera.
- After capture → travel print: warm paper, photo, ja/en location + date, Save/Cancel.

### Memories
- Photo-first, trips grouped by year.

### Outstanding correctness items
- Fresh `-seedDemo` run must yield `47 / 47 prefectures · 47 cities` and visible sage fills.
- If seen, fix the "single camera button / no map / no nav" launch state (state restoration or
  RootView layout regression).

## Task 1: Atlas viewport — pannable/zoomable full-screen map (Phase 1)

**Planned Start:** Task 1 of TABi V1 Interaction redirection on feat/atlas-v3

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. The atlas map must become a pannable/zoomable full-screen viewport (Japan larger than viewport), replacing the aspect-fit from V3. Initial viewport centered on Tokyo–Kyoto/Osaka region. Taps inverse-project to prefectures via JapanMapProjection. City stamps/labels/pins removed (Task 2). Sage prefecture fills added (Task 3). Stats annotation kept (Task 3). No city markers/Labels/pins.

**Interfaces from earlier tasks:** None (this is the first task on this new redirection; V3 work provides foundation but this task operates on new code paths).

**Ambiguity resolutions (controller decisions — follow these):**
- Brief Step 5 (visual check with device) is NOT yours to run — simulator policy. Note as "pending user verification" in report. You must still run the compile-check step.
- Testing policy: compile-only. Do NOT run `xcodebuild test`, simulators, or any command taking >30s beyond the single build below.
- No new .swift files beyond modifying IllustratedJapanMapView.swift and JapanMapProjection.swift — no xcodegen.
- Commit policy: exactly ONE commit for this task on feat/atlas-v3. Suggested message: `feat: atlas v3 phase 1 — pannable/zoomable map viewport, inverse-projection hit test`.
- The map content size must be larger than the viewport (e.g., 1.7× the viewport dimensions), centered on Tokyo–Kyoto/Osaka region, so Hokkaido/Kyushu are partially outside initial viewport — per brief §13.

**Your Job:**
1. Modify `IllustratedJapanMapView.swift`:
   a. Add `@State private var zoom: CGFloat = 1` and `@State private var panOffset: CGPoint = .zero` to the struct
   b. Replace the `aspectFit` image placement with a `GeometryReader` + drag gesture + magnification gesture setup
   c. Implement `contentSize = CGSize(width: 1024 * zoom, height: 1536 * zoom)` so Japan is larger than viewport
   d. Implement `panOffset` clamping so the viewport always shows map content (no empty edges)
   e. Add `DragGesture` for panning (updates `panOffset` within clamps)
   f. Add `MagnificationGesture` for zooming (updates `zoom` within 1.0–2.5)
   g. Add inverse-projection hit test: `let screenPt = CGPoint(x: location.x, y: location.y)` → `let artPt = CGPoint(x: (screenPt.x - panOffset.x) / zoom, y: (screenPt.y - panOffset.y) / zoom)` → `JapanMapProjection.point(for: artPt)` → prefecture containment test
   h. Remove `visitedMarks` method entirely (stamps removed per §17-18)
   i. Remove `currentLocationMark` and `elsewhereMark` methods (quiet UI per new brief)
   j. Remove `currentCoordinate` and `isInJapan` from init call site and struct params
   k. Remove `visibleCityMarkers` from AtlasView init
2. Modify `JapanMapProjection.swift`:
   a. Add `coordinate(for point: CGPoint, in rect: CGRect) -> CLLocationCoordinate2D` inverse method that converts screen/artwork coordinates back to lat/lon
   b. Ensure `point(for:)` uses the new rect parameter
3. Modify `AtlasView.swift`:
   a. Remove `visibleCityMarkers` from init call
   b. Remove `isInJapan` param from init call
   c. Keep `statsAnnotation` and `hasVisitedOkinawa` 
   l. Keep `showsOkinawaInset` param 
4. Build: `xcodebuild -project TABi.xcodeproj -scheme TABi -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E 'error:|BUILD' | head -20` → must be `** BUILD SUCCEEDED **`
5. Commit: one commit on feat/atlas-v3, message `feat: atlas v3 phase 1 — pannable/zoomable map viewport, inverse-projection hit test`

**Report file:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-1-report.md

**Pending user verification (Step 5 in brief):** Run app, pan/zoom Japan, ensure Tokyo–Kyoto/Osaka centered, taps hit correct prefectures. Do NOT run — note as pending user verification.

**Report file path:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-1-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 2: Sage prefecture fills — re-add moss fills with subtle tint (Phase 2)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. Per brief §17, visited prefectures receive a subtle sage/green tint. This task re-adds the moss fill layer that V3 Task 3 removed, but with a subtle opacity tier based on memory count.

**Interfaces from earlier tasks:**
- `AtlasView.swift` has `prefectureID(matching:)`, `normalize`, `normalizeShape` statics (kept from Task 3)
- `env.confirmedVisits()` returns visit objects with `prefecture: String` and `city: String`
- `env.atlasStats` has `perfectures: Int`, `cities: Int` (kept from V3)
- `IllustratedJapanMapView` has `visitedPrefectureCounts` param (added in Task 1, re-purposed for sage fills)

**Ambiguity resolutions (controller decisions — follow these):**
- Sage fill opacity: `min(0.30, 0.10 + 0.06 * count)` where `count` = distinct cities in that prefecture from confirmed visits. Unvisited=cream (0% sage), 1 city=0.16 sage, 2 cities=0.22 sage, 3+ cities=0.28 sage. Max 0.30 to keep it subtle.
- `visitedPrefectureCounts` param re-added to `IllustratedJapanMapView` init (re-purposed from Task 1)
- `prefectureID(matching:)`, `normalize`, `normalizeShape` kept unchanged (Task 3)
- Visual check not yours to run — note as "pending user verification" in report.
- Testing policy: compile-only (`xcodebuild build`). No simulator/tests.
- No new .swift files beyond the modifications — no xcodegen.
- Commit policy: exactly ONE commit for this task on feat/atlas-v3. Suggested message: `feat: atlas v3 phase 2 — sage prefecture fills, re-add moss fills`.

**Your Job:**
1. Modify `AtlasView.swift`:
   a. Re-add `visitedPrefectureCounts` computed property using `env.confirmedVisits()` and `prefectureID(matching:)` to count distinct cities per prefecture
   b. Pass `visitedPrefectureCounts` to `IllustratedJapanMapView` init (replace/override the param from Task 1)
2. Modify `IllustratedJapanMapView.swift`:
   a. Re-add sage fill layer: for each prefecture in `visitedPrefectureCounts`, fill its polygon with `TABiColor.moss.opacity(min(0.30, 0.10 + 0.06 * count))`
   b. Clip the fill to the map rect via `.mask { Rectangle().frame(width: mapRect.width, height: mapRect.height).position(x: mapRect.midX, y: mapRect.midY) }`
   c. Keep `markDot` and `editorialLabel` (they're separate from sage fills)
   d. Keep `currentLocationMark` if it was kept from V3 (it was removed in Task 1 per new brief — actually per new brief, current location mark should be removed; keep removed)
3. Build check: `xcodebuild -project TABi.xcodeproj -scheme TABi -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E 'error:|BUILD' | head -20` → `** BUILD SUCCEEDED **`.
4. Commit: one commit on feat/atlas-v3, message `feat: atlas v3 phase 2 — sage prefecture fills, re-add moss fills`.

**Report file:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-2-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 3: Stats annotation on new map layout (Phase 3)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. The stats annotation from V3 Task 4 needs placement verification over the new larger map layout. The stats annotation uses `.padding(.leading, 20)`, `.padding(.top, 170)` in AtlasView. On the new larger map (contentSize 1.7× viewport), verify these paddings don't collide with sakura branch (top-left) or other map elements. This is a user-verification item, not a code change.

**Your Job:**
1. Verify the stats annotation placement against the new map layout
2. Note any placement issues in the report
3. Build check: `xcodebuild -project TABi.xcodeproj -scheme TABi -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E 'error:|BUILD' | head -20` → must be `** BUILD SUCCEEDED **`
4. Commit: one commit on feat/atlas-v3, message `feat: atlas v3 phase 3 — stats annotation placement verification`
5. Report file: /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-3-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 4: Remove bottom nav bar + add camera button (Phase 4)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. Per brief §3-5, the persistent bottom navigation bar is removed. Atlas becomes the root screen. Camera button is the primary action, located near the bottom safe area. Memo ries are reached via horizontal edge swipe from Atlas.

**Interfaces from earlier tasks:**
- `RootView.swift` has been restructured (from Task 4) with screen state (.atlas/.memories)
- `IllustratedJapanMapView` has been modified (from Tasks 1-3)
- `CameraView.swift` will be rewritten (Task 5)

**Your Job:**
1. Modify `RootView.swift`:
   a. Remove `RootTab` enum and all its associated code (titleJa, titleEn, iconAsset)
   b. Add `@State private var screen: Screen = .atlas` where `Screen = enum { case atlas, memories }`
   c. Replace the `tabBar` and its usage with a camera button overlay on Atlas only
   d. Add edge-swipe gestures for Atlas↔Memories navigation (leading edge swipe from Atlas → Memories, trailing edge from Memories → Atlas)
   e. Add `.transition(.push(from: .trailing))` animation on screen change
   f. Keep fullScreenCover for camera presentation
2. Create `ShutterButton.swift` — native circular vermilion drawing (camera shutter icon) drawn with Path, PressableStyle
   a. `.scaleEffect(configuration.isPressed ? 0.94 : 1.0)`
   b. `.opacity(configuration.isPressed ? 0.85 : 1)`
   c. `.animation(.easeOut(duration: 0.12), value: configuration.isPressed)`
   d. Add `@State private var isCameraPressed = false` in RootView
   e. Add `.buttonStyle(PressableStyle(isPressed: $isCameraPressed))` to the camera button
3. Modify `CameraView.swift` — (deferred to Task 5, but camera button triggers it)
4. Build check: `xcodebuild -project TABi.xcodeproj -scheme TABi -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E 'error:|BUILD' | head -20` → must be `** BUILD SUCCEEDED **`
5. Commit: one commit on feat/atlas-v3, message `feat: atlas v3 phase 4 — nav removal, camera button, edge-swipe navigation`

**Report file:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-4-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 5: Camera screen rewrite (Phase 5)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. Per brief §5-7, the camera opens immediately (no LOCATING… screen), has a 3:4 viewfinder ratio, a clear × close control, and minimal controls (shutter, flip, flash). After capture, a travel print presentation appears.

**Interfaces from earlier tasks:**
- `CameraCapturing` protocol, `RealCamera` implementation, `TABiFilmProcessor` — all exist and work
- `AppEnvironment` has `captureAndRemember()` but this will be split into `takePhoto()` + `saveMemory()`
- `TravelPrintView.swift` is a new file to create

**Your Job:**
1. Rewrite `CameraView.swift`:
   a. Remove `placeLabel` `LOCATING…` text — camera opens immediately
   b. Add 3:4 viewfinder (AVCaptureVideoPreviewLayer centered in black background)
   c. Add × close control (drawn Path, top-left), shutter (vermilion circular drawn with Path, bottom center), flip camera toggle, flash toggle stub
   d. On capture: `let (processedImage, components) = try await env.takePhoto()` → state.showingPrint = true
   e. Travel print overlay: warm paper bg, photo centered, ja/en location + date, Save button
2. Modify `AppEnvironment.swift`:
   a. Split `captureAndRemember` into `takePhoto()` → returns `(processedImage: UIImage, components: PlaceComponents?)`
   b. Add `saveMemory(processed: UIImage, components: PlaceComponents?, capturedAt: Date) async` — persists memory + visit detection + stats refresh; sets `lastSavedMemory`/`lastSavedImage`; dismisses camera
3. Create `TravelPrintView.swift` — warm paper background, photo centered, ja/en location + date, Save button
4. Build check; fix errors; commit one commit on feat/atlas-v3

**Report file:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-5-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 6: Atlas↔Memories horizontal swipe (Phase 6)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. Per brief §22-23, Memories are reached via horizontal swipe from Atlas. The transition should feel like turning a page in a travel journal. The direction should be consistent: Atlas → Memories with leftward swipe, Memories → Atlas with rightward swipe. Gesture safety: map pan/pinch should not be conflicted.

**Your Job:**
1. Modify `RootView.swift`:
   a. Add `@State private var screen: Screen = .atlas` where `Screen = enum { case atlas, memories }`
   b. Use `ZStack` with `.transition(.push(from: .trailing))` for Atlas→Memories and `.push(from: .leading)` for Memories→Atlas
   c. Add edge-drag gestures: on Atlas, drag from right edge leftward → Memories; on Memories, drag from left edge rightward → Atlas
   d. Add `.highPriority()` on edge gestures so they don't conflict with map pan/pinch when map is being manipulated
   e. Keep `onSelectPrefecture` for drill-down within Atlas
2. Keep `MemoriesView.swift` existing design (photo-first, trips by year)
3. Build check; fix errors; commit one commit on feat/atlas-v3

**Report file:** /Users/jervischan/Documents/Code/tabi/.superpowers/sdd/2026-11-16-tabi-v1-interaction/task-6-report.md

**Reply contract (<15 lines):**
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Commits created (short SHA + subject)
- One-line build summary
- Concerns (including "pending user verification: ..." items)
- The report file path

## Task 7: Polish + §22 acceptance walkthrough (Phase 7)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3. Final polish and acceptance test per §31 of the brief.

**Your Job:**
1. Shutter feedback: subtle haptic or animation on camera press
2. Transitions: `.easeOut(duration: 0.25)` on screen changes
3. §22 walkthrough: run app, save screenshot to `tabi/screenshot.png` per brief acceptance test
4. Optional: end-of-session test run (`xcodebuild test`) — needs explicit user approval per policy
5. Final review of all 8 tasks + fix wave findings

**Your Job:**
1. Compile-only check per task
2. Final whole-branch review on feat/atlas-v3 (780077d → final commit)
3. §22 walkthrough notes
4. Report all findings

**Reply contract (<15 lines):**
- **Status:** DONE | BLOCKED | NEEDS_CONTEXT
- Commits created
- Build summary
- Concerns
- Report file path

**Reply contract (<15 lines):** as per writing-plans skill format.

## Task 8: Atlas screen to match mockup + restore bottom nav (Phase 8 — authoritative)

**Context:**
TABi iOS SwiftUI app at /Users/jervischan/Documents/Code/tabi, branch feat/atlas-v3.
The current app can render as only a camera button with no map/nav (launch-state regression).
Implement the FINAL TARGET STATE above, using the mockup reference image for proportions.

**Your Job:**
1. Fix launch regression: `RootView` must default to `screen == .atlas`, `isCameraPresented == false`,
   and render the Atlas map + nav — never the camera on launch.
2. Rebuild the bottom nav in `RootView.swift` to the mockup: warm-washi strip, `Map` (left, vermilion
   hand-drawn underline when selected), center vermilion shutter overlapping the strip's top edge,
   `Memories` (right, understated). English labels only; no icons/SF Symbols/pills.
3. Remove Atlas↔Memories swipe gestures (Task 6 superseded). Wire taps: Map→Atlas, Memories→Memories,
   center→Camera full-screen cover.
4. `AtlasView`/`IllustratedJapanMapView`: map extends behind the nav (no bottom padding reserving a
   tab bar); stats annotation upper-left in editorial typography.
5. Verify sage fills + `47 / 47` stats on a fresh `-seedDemo` run (compile-only per policy; visual
   check is pending user verification).
6. Build must be `** BUILD SUCCEEDED **`. Compare rendered screen to the reference and iterate on
   map scale, nav height, shutter size/position, typography, and whitespace.
