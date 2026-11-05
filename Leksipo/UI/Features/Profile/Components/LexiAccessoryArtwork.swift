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
        let line = Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        context.stroke(line, with: .color(color(hex).opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
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
