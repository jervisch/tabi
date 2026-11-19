import SwiftUI
import CoreLocation

/// Illustrated Atlas — the map is the page.
///
/// Visual layer: `japan_map_base` artwork only (no added decoration).
/// Overlays: sage prefecture fills (by visit count), editorial visited marks,
/// quiet current location, printed-atlas Okinawa inset.
/// Hit-testing: geographic dataset via `JapanMapProjection` (authoritative).
struct IllustratedJapanMapView: View {
    let visitedCities: [CityPoint] = []
    /// Distinct cities visited per prefecture from confirmed visits.
    let visitedPrefectureCounts: [String: Int]
    /// Okinawa inset only appears once the traveler has visited Okinawa.
    var showsOkinawaInset: Bool = true
    var onSelectPrefecture: (PrefectureShape) -> Void = { _ in }

    @State private var pulse = false
    /// `nil` = not pinched yet → resolves to the live fit-to-viewport zoom
    /// every render (safe even if the first layout reports a zero size).
    @State private var zoom: CGFloat?
    @State private var panOffset: CGPoint = .zero
    /// Base state captured when a gesture begins, so pan/zoom accumulate
    /// across successive gestures instead of snapping back to zero.
    @State private var panStart: CGPoint?
    @State private var zoomStart: CGFloat?
    @State private var isPinching = false

    private static let mapAspect: CGFloat = 1024.0 / 1536.0
    private static let insetAspect: CGFloat = 512.0 / 407.0

    private var mainShapes: [PrefectureShape] {
        JapanGeography.prefectures().filter { shape in
            shape.rings.contains { ring in
                ring.contains { JapanMapProjection.isInMainBounds($0.latitude, $0.longitude) }
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let area = CGRect(origin: .zero, size: geo.size)
            // Zoom-out floor: the whole map fits inside the viewport.
            let fitZoom = max(0.05, min(area.width / 1024, area.height / 1536))
            // Effective zoom: start at fit (entire map visible) until first pinch.
            let z = zoom ?? fitZoom
            // Map content larger than viewport
            let mapContentSize = CGSize(width: 1024 * z, height: 1536 * z)
            // Center-anchored pan limits — the art may slide, but never
            // reveal empty space past its edges.
            let maxPan = CGSize(
                width: max(0, (mapContentSize.width - area.width) / 2),
                height: max(0, (mapContentSize.height - area.height) / 2)
            )
            let pan = CGPoint(
                x: min(maxPan.width, max(-maxPan.width, panOffset.x)),
                y: min(maxPan.height, max(-maxPan.height, panOffset.y))
            )
            // Top-left of the map art in view coordinates. The image and the
            // sage fills share this origin so they stay exactly registered.
            let imageOrigin = CGPoint(
                x: area.midX + pan.x - mapContentSize.width / 2,
                y: area.midY + pan.y - mapContentSize.height / 2
            )

            ZStack(alignment: .topLeading) {
                // ── The hero: the illustrated page itself ─
                Image("japan_map_base")
                    .resizable()
                    .frame(width: mapContentSize.width, height: mapContentSize.height)
                    .offset(x: imageOrigin.x, y: imageOrigin.y)

                // ── Sage prefecture fills (moss opacity by visit count) ─────
                // Masked to the painted landmass (art coords), then given the
                // exact same transform as the image so they stay registered.
                SagePrefectureFills(counts: visitedPrefectureCounts, mainShapes: mainShapes)
                    .mask {
                        Image("japan_land_mask")
                            .resizable()
                            .frame(width: 1024, height: 1536)
                    }
                    .frame(width: 1024, height: 1536)
                    .scaleEffect(z, anchor: .topLeading)
                    .offset(x: imageOrigin.x, y: imageOrigin.y)
                    .allowsHitTesting(false)

                // ── Geographic tap target (dataset, not artwork) ─────────
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: area.width, height: area.height)
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let screenPt = CGPoint(x: value.location.x, y: value.location.y)
                                let artPt = CGPoint(
                                    x: (screenPt.x - imageOrigin.x) / z,
                                    y: (screenPt.y - imageOrigin.y) / z
                                )
                                if let hit = JapanMapProjection.prefecture(
                                    containing: artPt,
                                    in: CGRect(x: 0, y: 0, width: 1024, height: 1536),
                                    shapes: mainShapes
                                ) {
                                    onSelectPrefecture(hit)
                                }
                            }
                    )
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isPinching else { return }
                        if panStart == nil { panStart = panOffset }
                        let base = panStart ?? panOffset
                        let raw = CGPoint(
                            x: base.x + value.translation.width,
                            y: base.y + value.translation.height
                        )
                        panOffset = CGPoint(
                            x: min(maxPan.width, max(-maxPan.width, raw.x)),
                            y: min(maxPan.height, max(-maxPan.height, raw.y))
                        )
                    }
                    .onEnded { _ in
                        panStart = nil
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        if zoomStart == nil {
                            zoomStart = z
                            isPinching = true
                        }
                        zoom = min(2.5, max(fitZoom, (zoomStart ?? z) * value))
                    }
                    .onEnded { _ in
                        zoomStart = nil
                        isPinching = false
                    }
            )
            .onAppear {
                guard !pulse else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var markDot: some View {
        ZStack {
            Circle()
                .stroke(TABiColor.vermilion, lineWidth: 1.25)
                .frame(width: 9, height: 9)
            Circle()
                .fill(TABiColor.vermilion)
                .frame(width: 4, height: 4)
        }
    }

    private func editorialLabel(ja: String, en: String) -> some View {
        VStack(spacing: 1) {
            Text(ja)
                .font(TABiFont.placeJapanese(11, weight: .medium))
                .foregroundStyle(TABiColor.sumi)

            Text(en.uppercased())
                .font(TABiFont.placeEnglish(8))
                .tracking(1.2)
                .foregroundStyle(TABiColor.sumi.opacity(0.55))
        }
        .fixedSize()
    }

// MARK: - Okinawa inset — printed atlas, low contrast

    private func okinawaInset(art: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            Image("okinawa_inset")
                .resizable()
                .frame(width: art.width, height: art.height)
                .opacity(0.92)
                .position(x: art.midX, y: art.midY)

            // hairline rule — like a plate border in a printed atlas
            Rectangle()
                .stroke(TABiColor.sumi.opacity(0.2), lineWidth: 0.5)
                .frame(width: art.width, height: art.height)
                .position(x: art.midX, y: art.midY)
        }
        .allowsHitTesting(false)
    }

// MARK: - Sage prefecture fills layer

    struct SagePrefectureFills: View {
        let counts: [String: Int]
        let mainShapes: [PrefectureShape]

        var body: some View {
            ForEach(counts.keys.sorted(), id: \.self) { prefectureID in
                if let count = counts[prefectureID],
                   let shape = mainShapes.first(where: { $0.id == prefectureID }) {
                    let projection = JapanMapProjection(rect: CGRect(x: 0, y: 0, width: 1024, height: 1536))
                    let opacity = min(0.50, 0.25 + 0.10 * Double(count))
                    // Every ring — main body and island chains alike.
                    ForEach(shape.rings.indices, id: \.self) { index in
                        Path(projection.path(for: shape.rings[index]))
                            .fill(TABiColor.moss.opacity(opacity))
                    }
                }
            }
            .mask {
                Rectangle()
                    .frame(width: 1024, height: 1536)
            }
        }
    }

// MARK: - Geometry

    private static func aspectFit(_ aspect: CGFloat, in rect: CGRect) -> CGRect {
        guard aspect > 0, rect.width > 0, rect.height > 0 else { return rect }
        let w = rect.width
        let h = w / aspect
        if h <= rect.height {
            let y = rect.minY + (rect.height - h) / 2
            return CGRect(x: rect.minX, y: y, width: w, height: h)
        } else {
            let w2 = rect.height * aspect
            let x = rect.minX + (rect.width - w2) / 2
            return CGRect(x: x, y: rect.minY, width: w2, height: rect.height)
        }
    }
}
