import SwiftUI

/// The Tagwise mark: a faceted gold price tag in the low-poly gem style of the
/// app icon. With `shimmer`, a light band sweeps across the facets.
struct LowPolyLogo: View {
    var shimmer = true

    var body: some View {
        LowPolyIcon(kind: .tag, shimmer: shimmer)
    }
}

/// Flat-shaded, gem-cut icons with ink outlines (see "Low-Poly Gem Icon Style").
/// Each is an outer silhouette, an inset "table" and bevel facets lit from the top-left.
struct LowPolyIcon: View {
    enum Kind { case tag, calculator, gear, camera }

    let kind: Kind
    var shimmer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if shimmer && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                canvas(time: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            canvas(time: nil)
        }
    }

    private func canvas(time: TimeInterval?) -> some View {
        let design = Self.design(for: kind)
        return Canvas { context, size in
            design.draw(in: &context, size: size, sweep: time.map(Self.sweepPosition))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// 0...1 across the icon, then a pause off-screen, every 3 seconds.
    private static func sweepPosition(_ time: TimeInterval) -> Double {
        time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 1.8 - 0.4
    }

    private static func design(for kind: Kind) -> Design {
        switch kind {
        case .tag: return tag
        case .calculator: return calculator
        case .gear: return gear
        case .camera: return camera
        }
    }

    // MARK: - Designs (1024 artboard)

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// Gem-cut shape: bevel facets between `outer` and `inner`, outlines on both,
    /// and a seam from each outer corner to its inner corner.
    private static func gemCut(outer: [CGPoint], inner: [CGPoint], bevelColors: [UInt32]) -> [Facet] {
        outer.indices.map { i in
            let j = (i + 1) % outer.count
            return Facet(points: [outer[i], outer[j], inner[j], inner[i]], color: bevelColors[i])
        }
    }

    private static let tag: Design = {
        let outer = [p(230, 512), p(380, 352), p(800, 352), p(800, 672), p(380, 672)]
        let inner = [p(320, 512), p(410, 412), p(740, 412), p(740, 612), p(410, 612)]
        // tip-upper, top, right, bottom, tip-lower
        var facets = gemCut(outer: outer, inner: inner,
                            bevelColors: [0xF6D772, 0xFBE8A6, 0xC48D14, 0x9E6C0A, 0xD29E20])
        facets.append(Facet(points: [inner[0], inner[1], inner[2], inner[4]], color: 0xF1CD5A))
        facets.append(Facet(points: [inner[4], inner[2], inner[3]], color: 0xE2B53A))
        return Design(
            facets: facets, outlines: [outer, inner], seams: zip(outer, inner).map { ($0, $1) } + [(inner[4], inner[2])],
            dots: [(p(392, 512), 27)], rotation: -28, center: p(515, 512), extent: 690
        )
    }()

    private static let calculator: Design = {
        let outer = [p(312, 212), p(712, 212), p(712, 812), p(312, 812)]
        let inner = [p(356, 256), p(668, 256), p(668, 768), p(356, 768)]
        // top, right, bottom, left
        var facets = gemCut(outer: outer, inner: inner, bevelColors: [0xB4DFFB, 0x2B66C4, 0x1E4E9C, 0x8FCBFF])
        facets.append(Facet(points: inner, color: 0x5EA7FF))
        let screen = [p(392, 292), p(632, 292), p(632, 426), p(392, 426)]
        facets.append(Facet(points: screen, color: 0x12305E))
        // Screen glint, as one sharp facet.
        facets.append(Facet(points: [p(392, 292), p(500, 292), p(392, 380)], color: 0x2B66C4))
        var keys: [[CGPoint]] = []
        for (row, y) in [470.0, 610.0].enumerated() {
            for (col, x) in [392.0, 532.0].enumerated() {
                let key = [p(x, y), p(x + 100, y), p(x + 100, y + 100), p(x, y + 100)]
                keys.append(key)
                facets.append(Facet(points: key, color: (row + col).isMultiple(of: 2) ? 0xCFE9FD : 0x8FCBFF))
            }
        }
        return Design(
            facets: facets, outlines: [outer, inner, screen] + keys, seams: zip(outer, inner).map { ($0, $1) },
            dots: [], rotation: 0, center: p(512, 512), extent: 700
        )
    }()

    /// Shades each bevel by which way its edge faces: light from the top-left.
    /// `outer` must run clockwise on screen.
    private static func facingShades(_ outer: [CGPoint], palette: [UInt32]) -> [UInt32] {
        outer.indices.map { i in
            let a = outer[i], b = outer[(i + 1) % outer.count]
            let facing = atan2(Double(-(b.x - a.x)), Double(b.y - a.y))   // outward normal
            let light = cos(facing - atan2(-1.0, -1.0))                   // 1 = facing the light
            return palette[Int(((1 - light) / 2 * Double(palette.count - 1)).rounded())]
        }
    }

    private static let camera: Design = {
        let gold: [UInt32] = [0xFBE8A6, 0xF6D772, 0xE2B53A, 0xC48D14, 0x9E6C0A]
        let sapphire: [UInt32] = [0xB4DFFB, 0x8FCBFF, 0x5EA7FF, 0x2B66C4, 0x1E4E9C]

        let hump = [p(402, 352), p(452, 282), p(572, 282), p(622, 352)]
        let outer = [p(272, 352), p(752, 352), p(792, 392), p(792, 712),
                     p(752, 752), p(272, 752), p(232, 712), p(232, 392)]
        let inner = [p(296, 392), p(728, 392), p(752, 416), p(752, 688),
                     p(728, 712), p(296, 712), p(272, 688), p(272, 416)]
        func octagon(_ radius: CGFloat) -> [CGPoint] {
            (0..<8).map { k in
                let angle = (-112.5 + 45 * Double(k)) * .pi / 180
                return p(512 + radius * CGFloat(cos(angle)), 552 + radius * CGFloat(sin(angle)))
            }
        }
        let lensOuter = octagon(150), lensInner = octagon(92)

        var facets = [Facet(points: hump, color: 0xF1CD5A)]
        facets += gemCut(outer: outer, inner: inner, bevelColors: facingShades(outer, palette: gold))
        facets.append(Facet(points: inner, color: 0xEBC24C))
        facets += gemCut(outer: lensOuter, inner: lensInner, bevelColors: facingShades(lensOuter, palette: sapphire))
        facets.append(Facet(points: lensInner, color: 0x12305E))
        // Lens glint, as one sharp facet.
        facets.append(Facet(points: [lensInner[6], lensInner[7], lensInner[0]], color: 0x2B66C4))

        return Design(
            facets: facets,
            outlines: [hump, outer, inner, lensOuter, lensInner],
            seams: zip(outer, inner).map { ($0, $1) } + zip(lensOuter, lensInner).map { ($0, $1) },
            dots: [(p(690, 440), 18)], rotation: 0, center: p(512, 517), extent: 660
        )
    }()

    private static let gear: Design = {
        // Octagonal nut: the eight bevels are shaded by which way they face.
        func octagon(_ radius: CGFloat) -> [CGPoint] {
            (0..<8).map { k in
                let angle = (22.5 + 45 * Double(k)) * .pi / 180
                return p(512 + radius * CGFloat(cos(angle)), 512 + radius * CGFloat(sin(angle)))
            }
        }
        let outer = octagon(330), inner = octagon(225)
        let silver: [UInt32] = [0xF2F4F7, 0xDCE1E8, 0xC3CAD4, 0xA3ADBA, 0x7F8A99]
        let colors: [UInt32] = outer.indices.map { i in
            // Facet faces outward at angle 45 * (i + 1); light comes from the top-left (225°).
            let facing = Double(45 * (i + 1)) * .pi / 180
            let light = cos(facing - 225 * .pi / 180)          // 1 = facing the light
            let index = Int(((1 - light) / 2 * Double(silver.count - 1)).rounded())
            return silver[index]
        }
        var facets = gemCut(outer: outer, inner: inner, bevelColors: colors)
        facets.append(Facet(points: inner, color: 0xDCE1E8))
        facets.append(Facet(points: [inner[4], inner[5], inner[6], inner[7], inner[0]], color: 0xEEF1F5))
        return Design(
            facets: facets, outlines: [outer, inner], seams: zip(outer, inner).map { ($0, $1) } + [(inner[4], inner[0])],
            dots: [(p(512, 512), 92)], rotation: 0, center: p(512, 512), extent: 760
        )
    }()
}

// MARK: - Drawing

private struct Facet {
    let points: [CGPoint]
    let color: UInt32
}

private struct Design {
    let facets: [Facet]
    let outlines: [[CGPoint]]
    let seams: [(CGPoint, CGPoint)]
    let dots: [(CGPoint, CGFloat)]
    let rotation: Double          // degrees
    let center: CGPoint
    /// The artwork fits in roughly this square of the 1024 artboard.
    let extent: CGFloat

    static let ink = Color(red: 11 / 255, green: 22 / 255, blue: 38 / 255)

    func draw(in context: inout GraphicsContext, size: CGSize, sweep: Double?) {
        let scale = min(size.width, size.height) / extent
        let transform = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
            .scaledBy(x: scale, y: scale)
            .rotated(by: rotation * .pi / 180)
            .translatedBy(x: -center.x, y: -center.y)

        func path(_ points: [CGPoint]) -> Path {
            var path = Path()
            path.addLines(points)
            path.closeSubpath()
            return path.applying(transform)
        }

        let xs = facets.flatMap { $0.points.map(\.x) }
        let minX = xs.min() ?? 0, width = max((xs.max() ?? 1) - minX, 1)

        for facet in facets {
            var r = Double((facet.color >> 16) & 0xFF) / 255
            var g = Double((facet.color >> 8) & 0xFF) / 255
            var b = Double(facet.color & 0xFF) / 255
            if let sweep {
                // Brighten facets near the moving band, by facet center left to right.
                let cx = facet.points.map(\.x).reduce(0, +) / CGFloat(facet.points.count)
                let glow = max(0, 1 - abs(Double((cx - minX) / width) - sweep) / 0.28)
                let amount = 0.55 * glow * glow
                r += (1 - r) * amount
                g += (1 - g) * amount
                b += (1 - b) * amount
            }
            context.fill(path(facet.points), with: .color(Color(red: r, green: g, blue: b)))
        }

        let stroke = StrokeStyle(lineWidth: 9 * scale, lineJoin: .round)
        for outline in outlines {
            context.stroke(path(outline), with: .color(Self.ink), style: stroke)
        }
        var seamPath = Path()
        for (a, b) in seams {
            seamPath.move(to: a)
            seamPath.addLine(to: b)
        }
        context.stroke(seamPath.applying(transform), with: .color(Self.ink), style: stroke)

        for (dotCenter, radius) in dots {
            let rect = CGRect(x: dotCenter.x - radius, y: dotCenter.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect).applying(transform), with: .color(Self.ink))
        }
    }
}
