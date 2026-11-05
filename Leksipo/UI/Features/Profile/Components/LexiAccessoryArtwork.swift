import SwiftUI

struct LexiHeadwearArtwork: View {
    let option: LexiAvatarHeadwear

    var body: some View {
        AccessoryCanvas { art in
            switch option {
            case .none: break
            case .beret: drawBeret(art)
            case .bucketHat: drawBucketHat(art)
            case .ushanka: drawUshanka(art)
            case .cap: drawCap(art)
            case .graduationCap: drawGraduationCap(art)
            case .chefHat: drawChefHat(art)
            }
        }
    }

    private func drawBeret(_ art: AccessoryPainter) {
        art.fill(0x922E4C) { path in
            path.move(to: point(18, 38))
            path.addCurve(to: point(85, 31), control1: point(2, 19), control2: point(66, 4))
            path.addQuadCurve(to: point(73, 46), control: point(95, 41))
            path.addQuadCurve(to: point(18, 38), control: point(39, 49))
        }
        art.fill(0xB74D67) { path in
            path.move(to: point(16, 32))
            path.addQuadCurve(to: point(70, 20), control: point(36, 10))
            path.addQuadCurve(to: point(19, 36), control: point(41, 24))
        }
        art.fill(0x622237) { path in
            path.move(to: point(26, 39))
            path.addQuadCurve(to: point(80, 38), control: point(52, 42))
            path.addQuadCurve(to: point(73, 48), control: point(84, 45))
            path.addQuadCurve(to: point(30, 47), control: point(48, 46))
            path.addQuadCurve(to: point(26, 39), control: point(23, 46))
        }
        art.stroke(0x622237, width: 3.5, from: point(49, 16), to: point(45, 11))
    }

    private func drawBucketHat(_ art: AccessoryPainter) {
        art.fill(0x2C6D65) { path in
            path.move(to: point(25, 32))
            path.addQuadCurve(to: point(28, 14), control: point(28, 20))
            path.addQuadCurve(to: point(71, 14), control: point(50, 9))
            path.addQuadCurve(to: point(77, 32), control: point(73, 22))
            path.addQuadCurve(to: point(25, 32), control: point(50, 39))
        }
        art.fill(0xD9B466) { path in
            path.move(to: point(26, 25))
            path.addQuadCurve(to: point(74, 25), control: point(49, 31))
            path.addLine(to: point(77, 33))
            path.addQuadCurve(to: point(24, 33), control: point(50, 39))
        }
        art.fill(0x4A9182) { path in
            path.move(to: point(24, 32))
            path.addQuadCurve(to: point(77, 32), control: point(50, 38))
            path.addQuadCurve(to: point(92, 48), control: point(85, 38))
            path.addQuadCurve(to: point(8, 48), control: point(51, 57))
            path.addQuadCurve(to: point(24, 32), control: point(13, 39))
        }
    }

    private func drawUshanka(_ art: AccessoryPainter) {
        art.fill(0x6D5043) { path in
            path.move(to: point(17, 42))
            path.addCurve(to: point(50, 8), control1: point(16, 20), control2: point(24, 8))
            path.addCurve(to: point(83, 42), control1: point(76, 8), control2: point(84, 20))
            path.addQuadCurve(to: point(17, 42), control: point(50, 49))
        }
        art.rounded(0xA57D60, x: 12, y: 28, width: 16, height: 23, radius: 6)
        art.rounded(0xA57D60, x: 72, y: 28, width: 16, height: 23, radius: 6)
        art.rounded(0xDDC1A0, x: 25, y: 24, width: 50, height: 20, radius: 8)
        art.stroke(0xEED5B7, width: 2.5, from: point(34, 29), to: point(66, 29))
    }

    private func drawCap(_ art: AccessoryPainter) {
        art.fill(0x47688D) { path in
            path.move(to: point(18, 43))
            path.addCurve(to: point(50, 10), control1: point(18, 21), control2: point(31, 10))
            path.addCurve(to: point(78, 39), control1: point(68, 10), control2: point(79, 23))
            path.addQuadCurve(to: point(18, 43), control: point(47, 50))
        }
        art.stroke(0x769CB8, width: 2) { path in
            path.move(to: point(42, 39))
            path.addQuadCurve(to: point(51, 13), control: point(41, 23))
        }
        art.fill(0x2F486D) { path in
            path.move(to: point(38, 42))
            path.addQuadCurve(to: point(77, 36), control: point(57, 44))
            path.addQuadCurve(to: point(96, 48), control: point(93, 39))
            path.addQuadCurve(to: point(38, 42), control: point(76, 56))
        }
    }

    private func drawGraduationCap(_ art: AccessoryPainter) {
        art.rounded(0x39304A, x: 26, y: 25, width: 48, height: 22, radius: 7)
        art.fill(0x594767) { path in
            path.move(to: point(5, 24))
            path.addLine(to: point(50, 7))
            path.addLine(to: point(95, 24))
            path.addLine(to: point(50, 41))
        }
        art.stroke(0xF5C56D, width: 2.8) { path in
            path.move(to: point(50, 24))
            path.addLine(to: point(87, 30))
            path.addLine(to: point(87, 47))
        }
        art.rounded(0xE9AC4B, x: 83, y: 45, width: 8, height: 11, radius: 2)
    }

    private func drawChefHat(_ art: AccessoryPainter) {
        let crown = Path { path in
            path.move(to: point(25, 41))
            path.addLine(to: point(23, 34))
            path.addCurve(to: point(32, 15), control1: point(5, 32), control2: point(12, 13))
            path.addCurve(to: point(68, 15), control1: point(38, 2), control2: point(62, 2))
            path.addCurve(to: point(77, 34), control1: point(88, 13), control2: point(95, 32))
            path.addLine(to: point(75, 41))
            path.closeSubpath()
        }
        let outline: UInt32 = 0x8A6D5D
        art.fill(0xFFF9EA) { $0 = crown }
        art.stroke(outline, width: 3.5) { $0 = crown }
        art.stroke(0xB29A87, width: 3, from: point(38, 25), to: point(42, 36))
        art.stroke(0xB29A87, width: 3, from: point(62, 25), to: point(58, 36))
        art.rounded(outline, x: 23, y: 38, width: 54, height: 12, radius: 4)
        art.rounded(0xE5CDB6, x: 26, y: 41, width: 48, height: 6, radius: 2)
    }
}

struct LexiNeckwearArtwork: View {
    let option: LexiAvatarNeckwear

    var body: some View {
        AccessoryCanvas { art in
            switch option {
            case .none: break
            case .scarf: drawScarf(art)
            case .bandana: drawBandana(art)
            case .bowTie: drawBowTie(art)
            case .collar: drawCollar(art)
            case .sailorScarf: drawSailorScarf(art)
            case .stripedTie: drawStripedTie(art)
            case .buttonCollar: drawButtonCollar(art)
            }
        }
    }

    private func drawScarf(_ art: AccessoryPainter) {
        art.fill(0xB44B4E) { path in
            path.move(to: point(51, 22))
            path.addQuadCurve(to: point(76, 18), control: point(69, 27))
            path.addLine(to: point(89, 51))
            path.addQuadCurve(to: point(65, 57), control: point(79, 58))
        }
        art.fill(0xF0C98C) { path in
            path.move(to: point(59, 39))
            path.addLine(to: point(82, 34))
            path.addLine(to: point(85, 41))
            path.addLine(to: point(61, 46))
        }
        art.fill(0xD25D58) { path in
            path.move(to: point(10, 10))
            path.addQuadCurve(to: point(90, 10), control: point(50, 25))
            path.addQuadCurve(to: point(86, 29), control: point(95, 19))
            path.addQuadCurve(to: point(13, 29), control: point(49, 43))
            path.addQuadCurve(to: point(10, 10), control: point(5, 22))
        }
        art.stroke(0xF0C98C, width: 3, from: point(26, 17), to: point(27, 30))
        art.stroke(0xF0C98C, width: 3, from: point(39, 20), to: point(40, 33))
        art.stroke(0xF0C98C, width: 3, from: point(54, 20), to: point(54, 34))
        art.stroke(0xF0C98C, width: 3, from: point(69, 19), to: point(68, 32))
    }

    private func drawBandana(_ art: AccessoryPainter) {
        var cloth = Path()
        cloth.move(to: point(10, 12))
        cloth.addQuadCurve(to: point(90, 12), control: point(50, 26))
        cloth.addQuadCurve(to: point(50, 56), control: point(72, 46))
        cloth.addQuadCurve(to: point(10, 12), control: point(25, 44))
        art.fill(0xBC474C) { $0 = cloth }

        var clipped = art.context
        clipped.clip(to: cloth)
        let check = AccessoryPainter(context: clipped)
        for offset in stride(from: 12, through: 84, by: 18) {
            let position = CGFloat(offset)
            check.stroke(0xF2BF9F, width: 5, opacity: 0.45,
                         from: point(position, 10), to: point(position, 58))
        }
        for height in [25.0, 41.0] {
            check.stroke(0xF2BF9F, width: 5, opacity: 0.45,
                         from: point(8, height), to: point(92, height))
        }
    }

    private func drawBowTie(_ art: AccessoryPainter) {
        art.fill(0x42759C) { path in
            path.move(to: point(48, 25))
            path.addQuadCurve(to: point(14, 12), control: point(26, 13))
            path.addQuadCurve(to: point(14, 43), control: point(8, 27))
            path.addQuadCurve(to: point(48, 33), control: point(29, 45))
            path.addQuadCurve(to: point(86, 43), control: point(72, 46))
            path.addQuadCurve(to: point(86, 12), control: point(92, 27))
            path.addQuadCurve(to: point(48, 25), control: point(72, 13))
        }
        art.rounded(0x2B5477, x: 42, y: 21, width: 16, height: 17, radius: 5)
        art.stroke(0x79A1BB, width: 2.5, from: point(22, 23), to: point(35, 27))
        art.stroke(0x79A1BB, width: 2.5, from: point(65, 27), to: point(78, 23))
    }

    private func drawCollar(_ art: AccessoryPainter) {
        art.fill(0x4E7967) { path in
            path.move(to: point(11, 14))
            path.addQuadCurve(to: point(89, 14), control: point(49, 28))
            path.addLine(to: point(87, 26))
            path.addQuadCurve(to: point(13, 26), control: point(50, 40))
        }
        art.rounded(0xF2BE55, x: 47, y: 29, width: 6, height: 12, radius: 2)
        art.rounded(0xF2BE55, x: 37, y: 42, width: 26, height: 8, radius: 3)
        art.ellipse(0xF2BE55, x: 33, y: 38, width: 10, height: 10)
        art.ellipse(0xF2BE55, x: 33, y: 45, width: 10, height: 10)
        art.ellipse(0xF2BE55, x: 57, y: 38, width: 10, height: 10)
        art.ellipse(0xF2BE55, x: 57, y: 45, width: 10, height: 10)
    }

    private func drawSailorScarf(_ art: AccessoryPainter) {
        art.fill(0x365779) { path in
            path.move(to: point(8, 11))
            path.addQuadCurve(to: point(50, 26), control: point(30, 14))
            path.addQuadCurve(to: point(92, 11), control: point(70, 14))
            path.addQuadCurve(to: point(57, 34), control: point(86, 30))
            path.addLine(to: point(69, 53))
            path.addLine(to: point(55, 56))
            path.addLine(to: point(50, 42))
            path.addLine(to: point(43, 56))
            path.addLine(to: point(30, 50))
            path.addLine(to: point(43, 34))
            path.addQuadCurve(to: point(8, 11), control: point(15, 28))
        }
        art.stroke(0xF4E7D7, width: 2.8, from: point(18, 18), to: point(43, 29))
        art.stroke(0xF4E7D7, width: 2.8, from: point(82, 18), to: point(57, 29))
        art.rounded(0xD86B64, x: 43, y: 26, width: 14, height: 10, radius: 4)
    }

    private func drawStripedTie(_ art: AccessoryPainter) {
        art.stroke(0x674D73, width: 4) { path in
            path.move(to: point(17, 12))
            path.addQuadCurve(to: point(83, 12), control: point(50, 26))
        }
        art.fill(0x735682) { path in
            path.move(to: point(45, 23))
            path.addLine(to: point(55, 23))
            path.addLine(to: point(60, 48))
            path.addLine(to: point(50, 57))
            path.addLine(to: point(40, 48))
        }
        art.stroke(0xD3A2BA, width: 3, from: point(45, 33), to: point(54, 29))
        art.stroke(0xD3A2BA, width: 3, from: point(43, 43), to: point(56, 38))
        art.stroke(0xD3A2BA, width: 3, from: point(48, 51), to: point(57, 47))
        art.rounded(0x513D62, x: 42, y: 17, width: 16, height: 11, radius: 4)
    }

    private func drawButtonCollar(_ art: AccessoryPainter) {
        art.fill(0xA97868) { path in
            path.move(to: point(12, 12))
            path.addQuadCurve(to: point(88, 12), control: point(50, 29))
            path.addLine(to: point(80, 39))
            path.addQuadCurve(to: point(20, 39), control: point(50, 52))
        }
        art.fill(0xF6E3D2) { path in
            path.move(to: point(14, 12))
            path.addQuadCurve(to: point(50, 24), control: point(32, 19))
            path.addQuadCurve(to: point(86, 12), control: point(68, 19))
            path.addQuadCurve(to: point(64, 39), control: point(84, 39))
            path.addQuadCurve(to: point(50, 31), control: point(55, 37))
            path.addQuadCurve(to: point(36, 39), control: point(45, 37))
            path.addQuadCurve(to: point(14, 12), control: point(16, 39))
        }
        art.ellipse(0xBF8059, x: 43, y: 29, width: 14, height: 14)
        art.stroke(0x724A3A, width: 2, from: point(48, 36), to: point(52, 36))
    }
}

struct LexiGlassesArtwork: View {
    let option: LexiAvatarGlasses

    var body: some View {
        AccessoryCanvas { art in
            switch option {
            case .none: break
            case .round:
                drawOpticalFrames(art, round: true, color: 0xD6A25C)
            case .square:
                drawOpticalFrames(art, round: false, color: 0x69B4A6)
            case .catEye:
                drawSunglasses(art)
            }
        }
    }

    private func drawOpticalFrames(_ art: AccessoryPainter, round: Bool, color: UInt32) {
        art.stroke(color, width: 4) { path in
            path.move(to: point(47, 29))
            path.addQuadCurve(to: point(53, 29), control: point(50, 24))
        }
        for x in [8.0, 52.0] {
            let rect = CGRect(x: x, y: round ? 10 : 14, width: 40, height: round ? 40 : 32)
            let lens = round ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 8)
            art.stroke(0x483440, width: 6) { $0 = lens }
            art.stroke(color, width: 3.5) { $0 = lens }
        }
    }

    private func drawSunglasses(_ art: AccessoryPainter) {
        art.stroke(0x7E3655, width: 5, from: point(45, 27), to: point(55, 27))
        for mirrored in [false, true] {
            let lens = Path { path in
                path.move(to: point(5, 13))
                path.addQuadCurve(to: point(48, 24), control: point(25, 17))
                path.addQuadCurve(to: point(33, 46), control: point(48, 42))
                path.addQuadCurve(to: point(5, 13), control: point(10, 51))
                path.closeSubpath()
            }
            let transform = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 100, ty: 0)
            let shape = mirrored ? lens.applying(transform) : lens
            art.fill(0x392C47) { $0 = shape }
            art.stroke(0xCA6C86, width: 4) { $0 = shape }
        }
        art.stroke(0xA998B2, width: 3, from: point(19, 26), to: point(29, 29))
        art.stroke(0xA998B2, width: 3, from: point(71, 29), to: point(81, 26))
    }
}

struct LexiEarAccessoryArtwork: View {
    let option: LexiAvatarEarAccessory

    var body: some View {
        AccessoryCanvas { art in
            switch option {
            case .none: break
            case .star:
                drawStarClip(art)
            case .bow:
                drawEarBow(art)
            case .flower:
                drawFlower(art)
            }
        }
    }

    private func drawStarClip(_ art: AccessoryPainter) {
        art.stroke(0xB87938, width: 9, from: point(24, 40), to: point(78, 30))
        let star = Path { path in
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let radius: CGFloat = index.isMultiple(of: 2) ? 26 : 12
                let vertex = point(52 + cos(angle) * radius, 29 + sin(angle) * radius)
                if index == 0 { path.move(to: vertex) }
                else { path.addLine(to: vertex) }
            }
            path.closeSubpath()
        }
        art.fill(0xFFD075) { $0 = star }
        art.stroke(0xDB934D, width: 2.8) { $0 = star }
    }

    private func drawEarBow(_ art: AccessoryPainter) {
        art.fill(0xD56584) { path in
            path.move(to: point(49, 23))
            path.addQuadCurve(to: point(16, 9), control: point(24, 5))
            path.addQuadCurve(to: point(13, 46), control: point(7, 23))
            path.addQuadCurve(to: point(49, 34), control: point(23, 54))
            path.addQuadCurve(to: point(86, 46), control: point(77, 55))
            path.addQuadCurve(to: point(86, 9), control: point(93, 27))
            path.addQuadCurve(to: point(49, 23), control: point(77, 5))
        }
        art.stroke(0xA73A60, width: 3, from: point(22, 24), to: point(43, 29))
        art.stroke(0xA73A60, width: 3, from: point(78, 24), to: point(57, 29))
        art.rounded(0xF093A8, x: 42, y: 20, width: 16, height: 17, radius: 5)
    }

    private func drawFlower(_ art: AccessoryPainter) {
        for index in 0..<5 {
            let angle = CGFloat(index) * 2 * .pi / 5 - .pi / 2
            art.ellipse(0xF1B9C6, x: 38 + cos(angle) * 17, y: 19 + sin(angle) * 17, width: 24, height: 22)
        }
        art.ellipse(0xEAA950, x: 41, y: 22, width: 18, height: 16)
        art.ellipse(0xFFD47E, x: 44, y: 24, width: 8, height: 7)
    }
}

struct LexiHeadphonesArtwork: View {
    let option: LexiAvatarHeadphones

    var body: some View {
        AccessoryCanvas { art in
            switch option {
            case .none: break
            case .studio: drawHeadphones(art, band: 0x3D5B82, trim: 0x8BB6D4, studio: true)
            case .retro: drawHeadphones(art, band: 0x96504D, trim: 0xE7B285, studio: false)
            }
        }
    }

    private func drawHeadphones(_ art: AccessoryPainter, band: UInt32, trim: UInt32, studio: Bool) {
        let headband = Path { path in
            path.move(to: point(14, 41))
            path.addCurve(to: point(50, 7), control1: point(14, 19), control2: point(28, 7))
            path.addCurve(to: point(86, 41), control1: point(72, 7), control2: point(86, 19))
        }
        art.stroke(band, width: studio ? 7 : 4.5) { $0 = headband }
        art.stroke(trim, width: 1.8) { $0 = headband }
        if studio {
            for x in [5.0, 75.0] {
                art.rounded(0x2D3B55, x: x, y: 34, width: 20, height: 24, radius: 8)
                art.rounded(band, x: x + 2, y: 36, width: 16, height: 20, radius: 6)
                art.rounded(trim, x: x + 5, y: 40, width: 10, height: 5, radius: 2)
            }
        } else {
            for x in [6.0, 76.0] {
                art.ellipse(band, x: x, y: 37, width: 18, height: 20)
                art.ellipse(trim, x: x + 3, y: 40, width: 12, height: 14)
                art.ellipse(0xF8D9AA, x: x + 6, y: 43, width: 6, height: 8)
            }
        }
    }
}

// Each accessory shares the same coordinates in its tile and on the avatar.
private struct AccessoryCanvas: View {
    let draw: (AccessoryPainter) -> Void

    var body: some View {
        Canvas { context, size in
            var scaled = context
            scaled.scaleBy(x: size.width / 100, y: size.height / 60)
            draw(AccessoryPainter(context: scaled))
        }
        .accessibilityHidden(true)
    }
}

private struct AccessoryPainter {
    let context: GraphicsContext

    func fill(_ hex: UInt32, path: (inout Path) -> Void) {
        var outline = Path()
        path(&outline)
        outline.closeSubpath()
        context.fill(outline, with: .color(color(hex)))
    }

    func rounded(_ hex: UInt32, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat) {
        let shape = Path(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: radius)
        context.fill(shape, with: .color(color(hex)))
    }

    func ellipse(_ hex: UInt32, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let shape = Path(ellipseIn: CGRect(x: x, y: y, width: width, height: height))
        context.fill(shape, with: .color(color(hex)))
    }

    func stroke(_ hex: UInt32, width: CGFloat, opacity: Double = 1, from start: CGPoint, to end: CGPoint) {
        stroke(hex, width: width, opacity: opacity) { path in
            path.move(to: start)
            path.addLine(to: end)
        }
    }

    func stroke(_ hex: UInt32, width: CGFloat, opacity: Double = 1, path: (inout Path) -> Void) {
        context.stroke(Path(path), with: .color(color(hex).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255)
    }
}

private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y)
}
