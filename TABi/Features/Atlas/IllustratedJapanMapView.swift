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
    @State private var zoom: CGFloat = 1
    @State private var panOffset: CGPoint = .zero

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
            // Map content larger than viewport
            let mapContentSize = CGSize(width: 1024 * zoom, height: 1536 * zoom)
            // Clamp panOffset so we never pan beyond the map edges
            let clampedPanOffset = CGSize(
                width: max(0, min(panOffset.x, mapContentSize.width - area.width)),
                height: max(0, min(panOffset.y, mapContentSize.height - area.height))
            )

            ZStack(alignment: .topLeading) {
                // ── The hero: the illustrated page itself ─
                Image("japan_map_base")
                    .resizable()
                    .frame(width: mapContentSize.width, height: mapContentSize.height)
                    .position(x: area.midX + clampedPanOffset.width, y: area.midY + clampedPanOffset.height)

                // ── Sage prefecture fills (moss opacity by visit count) ─────
                SagePrefectureFills(counts: visitedPrefectureCounts, mainShapes: mainShapes)
                    .opacity(1)

                // ── Geographic tap target (dataset, not artwork) ─────────
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: area.width, height: area.height)
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                let screenPt = CGPoint(x: value.location.x, y: value.location.y)
                                let artPt = CGPoint(x: (screenPt.x - panOffset.x) / zoom, y: (screenPt.y - panOffset.y) / zoom)
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
                        panOffset = CGPoint(x: value.translation.width, y: value.translation.height)
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoom = min(2.5, max(1.0, value))
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
                    Path(projection.path(for: shape.rings[0]))
                        .fill(TABiColor.moss.opacity(min(0.30, 0.10 + 0.06 * Double(count))))
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
