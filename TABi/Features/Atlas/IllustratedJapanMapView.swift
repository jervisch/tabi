import SwiftUI
import CoreLocation

/// Illustrated Atlas — the map is the page.
///
/// Visual layer: `japan_map_base` artwork only (no added decoration).
/// Overlays: editorial visited marks, quiet current location, printed-atlas Okinawa inset.
/// Hit-testing: geographic dataset via `JapanMapProjection` (authoritative).
struct IllustratedJapanMapView: View {
    let visitedCities: [CityPoint]
    /// Prefecture id → distinct visited cities (drives the graduated green fill).
    var visitedPrefectureCounts: [String: Int] = [:]
    let currentCoordinate: CLLocationCoordinate2D?
    let isInJapan: Bool
    var onSelectPrefecture: (PrefectureShape) -> Void = { _ in }

    @State private var pulse = false

    private static let mapAspect: CGFloat = 1430.0 / 2048.0
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
            // Full-bleed aspect-fit — the illustration IS the page, not a card.
            let mapRect = Self.aspectFit(Self.mapAspect, in: area)

            let insetWidth = min(max(area.width * 0.26, 110), 140)
            let insetHeight = insetWidth / (Self.insetAspect)
            let insetRect = CGRect(
                x: area.minX + 10,
                y: area.maxY - insetHeight - 10,
                width: insetWidth,
                height: insetHeight
            )
            let insetArt = Self.aspectFit(Self.insetAspect, in: insetRect)

            ZStack(alignment: .topLeading) {
                // ── The hero (baked-in decorative green recolored to land) ─
                Image(uiImage: MapArt.cleanedBase)
                    .resizable()
                    .frame(width: mapRect.width, height: mapRect.height)
                    .position(x: mapRect.midX, y: mapRect.midY)

                // ── Visited prefectures: green only where we've been ─────
                // Intensity grows with distinct cities visited (1 → light,
                // 3+ → deep). Clipped to the plate so out-of-window islands
                // (Izu / Ogasawara) don't paint below the map.
                visitedPrefectureFills(mapRect: mapRect)
                    .mask {
                        Rectangle()
                            .frame(width: mapRect.width, height: mapRect.height)
                            .position(x: mapRect.midX, y: mapRect.midY)
                    }

                // ── Visited marks (traveler's ink, not UI cards) ─────────
                visitedMarks(mapRect: mapRect)

                // ── Current location ─────────────────────────────────────
                if let coord = currentCoordinate, isInJapan {
                    currentLocationMark(mapRect: mapRect, coord: coord)
                }

                // ── Geographic tap target (dataset, not artwork) ─────────
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: area.width, height: area.height)
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                if let hit = JapanMapProjection.prefecture(
                                    containing: value.location,
                                    in: mapRect,
                                    shapes: mainShapes
                                ) {
                                    onSelectPrefecture(hit)
                                }
                            }
                    )

                // ── Okinawa: quiet printed inset ─────────────────────────
                okinawaInset(art: insetArt)

                // ── Elsewhere (only when outside Japan) ──────────────────
                if !isInJapan {
                    elsewhereMark(area: area)
                }
            }
            .onAppear {
                guard !pulse else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    // MARK: - Visited prefectures — graduated moss fill

    private func visitedPrefectureFills(mapRect: CGRect) -> some View {
        let projection = JapanMapProjection(rect: mapRect, mainIsland: true)

        return ZStack(alignment: .topLeading) {
            ForEach(visitedPrefectureCounts.keys.sorted(), id: \.self) { id in
                if let count = visitedPrefectureCounts[id],
                   count > 0,
                   let shape = JapanGeography.prefecture(id: id) {
                    PrefectureFillsShape(rings: shape.rings, projection: projection)
                        .fill(TABiColor.moss.opacity(Self.fillOpacity(cityCount: count)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// 1 city → 0.32 · 2 → 0.47 · 3 → 0.62 · 4+ → 0.78
    private static func fillOpacity(cityCount: Int) -> Double {
        min(0.78, 0.32 + 0.15 * Double(cityCount - 1))
    }

    // MARK: - Visited marks — ◉ + Japanese primary + English secondary

    private func visitedMarks(mapRect: CGRect) -> some View {
        let projection = JapanMapProjection(rect: mapRect, mainIsland: true)

        return ZStack(alignment: .topLeading) {
            ForEach(visitedCities) { city in
                if JapanMapProjection.isInMainBounds(
                    city.coordinate.latitude,
                    city.coordinate.longitude
                ) {
                    let pt = projection.point(for: city.coordinate)

                    // Dot sits exactly on the coordinate; label hangs below.
                    markDot
                        .position(x: pt.x, y: pt.y)

                    editorialLabel(ja: city.nameJa, en: city.nameEn)
                        .position(x: pt.x, y: pt.y + 38)
                }
            }
        }
        .allowsHitTesting(false)
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

    private func currentLocationMark(mapRect: CGRect, coord: CLLocationCoordinate2D) -> some View {
        let projection = JapanMapProjection(rect: mapRect, mainIsland: true)
        let pt = projection.point(for: coord)

        return ZStack {
            Circle()
                .fill(TABiColor.vermilion.opacity(0.18))
                .frame(width: pulse ? 26 : 12, height: pulse ? 26 : 12)
            Circle()
                .fill(TABiColor.vermilion)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(TABiColor.washi, lineWidth: 1.5))
        }
        .position(x: pt.x, y: pt.y)
        .allowsHitTesting(false)
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

    // MARK: - Elsewhere — quiet, no card

    private func elsewhereMark(area: CGRect) -> some View {
        VStack(spacing: 3) {
            Image("elsewhere_island")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 110)
            Text("ELSEWHERE")
                .font(TABiFont.caption(8, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(TABiColor.sumi.opacity(0.55))
            Text("Exploring somewhere else\nin the world")
                .font(TABiFont.placeEnglish(9))
                .multilineTextAlignment(.center)
                .foregroundStyle(TABiColor.sumi.opacity(0.4))
        }
        .position(x: area.maxX - 78, y: area.maxY - 96)
        .allowsHitTesting(false)
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

// MARK: - Prefecture fill shape

/// Fills GeoJSON prefecture rings through a `JapanMapProjection`.
private struct PrefectureFillsShape: Shape {
    let rings: [[CLLocationCoordinate2D]]
    let projection: JapanMapProjection

    func path(in _: CGRect) -> Path {
        var path = Path()
        for ring in rings {
            path.addPath(Path(projection.path(for: ring)))
        }
        return path
    }
}

// MARK: - Map art

/// The base illustration, prepared for the visit-state layer.
///
/// The artwork ships with decorative moss-green terrain patches that read as
/// "visited" but aren't — `cleanedBase` recolors those greens to the land
/// cream so **green on the map only ever means "we were here"** (see
/// `visitedPrefectureFills`). One-time cost, cached for the app session.
enum MapArt {
    static let cleanedBase: UIImage = {
        guard let image = UIImage(named: "japan_map_base"),
              let cg = image.cgImage else {
            return UIImage(named: "japan_map_base") ?? UIImage()
        }
        let width = cg.width, height = cg.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return image }

        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return image }
        let px = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // Average land cream sampled from the artwork.
        let creamR = 235.0, creamG = 226.0, creamB = 208.0
        let blend = 0.95
        var i = 0
        let end = width * height * 4
        while i < end {
            let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
            let mx = max(r, max(g, b)), mn = min(r, min(g, b))
            let chroma = mx - mn
            // mx > 150 protects ink outlines and deep shadows (their greenish
            // cast is pigment shading, not a terrain patch).
            if chroma > 3, mx > 150 {
                let saturation = chroma / mx
                var hue: Double
                if mx == r {
                    hue = 60 * ((g - b) / chroma)
                    if hue < 0 { hue += 360 }
                } else if mx == g {
                    hue = 60 * ((b - r) / chroma + 2)
                } else {
                    hue = 60 * ((r - g) / chroma + 4)
                }
                // Green band: moss/sage (≈75°) and olive-khaki (≈46°), at any
                // strength. Cream paper ≈36°, tan edges ≈40°, sea ≈200°.
                if hue >= 44, hue <= 160, saturation > 0.09 {
                    px[i]     = UInt8(min(255, r + (creamR - r) * blend))
                    px[i + 1] = UInt8(min(255, g + (creamG - g) * blend))
                    px[i + 2] = UInt8(min(255, b + (creamB - b) * blend))
                }
            }
            i += 4
        }

        guard let out = context.makeImage() else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }()
}
