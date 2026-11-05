import SwiftUI

enum LexiAvatarBackground: String, CaseIterable, Identifiable {
    case sand, sky, mint, lavender, rose, gingham, rain, snow, stars, none

    var id: Self { self }
    var title: String { "profile_avatar_background_\(rawValue)".localized() }

    var color: Color {
        switch self {
        case .none: return .clear
        case .sand, .gingham: return Color(red: 0.97, green: 0.85, blue: 0.67)
        case .sky, .rain: return Color(red: 0.76, green: 0.88, blue: 0.98)
        case .mint: return Color(red: 0.75, green: 0.91, blue: 0.82)
        case .lavender, .snow: return Color(red: 0.87, green: 0.82, blue: 0.97)
        case .rose: return Color(red: 0.98, green: 0.80, blue: 0.83)
        case .stars: return Color(red: 0.31, green: 0.36, blue: 0.60)
        }
    }
}

enum LexiAvatarHeadwear: String, CaseIterable, Identifiable {
    case none, beret, bucketHat, ushanka

    var id: Self { self }
    var title: String { "profile_avatar_hat_\(rawValue)".localized() }
}

enum LexiAvatarNeckwear: String, CaseIterable, Identifiable {
    case none, scarf, bandana, bowTie, collar

    var id: Self { self }
    var title: String { "profile_avatar_neck_\(rawValue)".localized() }
}

struct LexiAvatarAppearance {
    var background: LexiAvatarBackground
    var headwear: LexiAvatarHeadwear
    var neckwear: LexiAvatarNeckwear
}

struct LexiAvatarView: View {
    let appearance: LexiAvatarAppearance
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            LexiAvatarBackdrop(background: appearance.background)
            MascotView(pose: .face)
                .frame(width: size * 0.9, height: size * 0.9)
                .offset(y: size * 0.05)
            if appearance.headwear != .none {
                LexiHeadwearArtwork(option: appearance.headwear)
                    .frame(width: size * 0.64, height: size * 0.32)
                    .offset(y: -size * 0.02)
            }
            if appearance.neckwear != .none {
                LexiNeckwearArtwork(option: appearance.neckwear)
                    .frame(width: size * 0.43, height: size * 0.23)
                    .offset(y: size * 0.69)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

struct LexiAvatarBackdrop: View {
    let background: LexiAvatarBackground

    var body: some View {
        background.color.overlay {
            Canvas { context, size in
                if background == .gingham {
                    let step = size.width / 10
                    let stripe = Color(red: 0.74, green: 0.39, blue: 0.28).opacity(0.22)
                    for index in stride(from: 0, to: 10, by: 2) {
                        let offset = CGFloat(index) * step
                        context.fill(Path(CGRect(x: offset, y: 0, width: step, height: size.height)), with: .color(stripe))
                        context.fill(Path(CGRect(x: 0, y: offset, width: size.width, height: step)), with: .color(stripe))
                    }
                } else if let motif = motif {
                    let symbol = context.resolve(Text(Image(systemName: motif))
                        .font(.system(size: size.width * 0.075))
                        .foregroundColor(motifColor))
                    for row in 0..<5 {
                        for column in 0..<5 {
                            let x = (CGFloat(column) + (row.isMultiple(of: 2) ? 0.35 : 0.8)) / 5
                            let y = (CGFloat(row) + 0.5) / 5
                            context.draw(symbol, at: CGPoint(x: size.width * x, y: size.height * y))
                        }
                    }
                }
            }
        }
    }

    private var motif: String? {
        switch background {
        case .rain: return "drop.fill"
        case .snow: return "snowflake"
        case .stars: return "star.fill"
        default: return nil
        }
    }

    private var motifColor: Color {
        switch background {
        case .rain: return Color(red: 0.20, green: 0.51, blue: 0.72).opacity(0.48)
        case .stars: return Color(red: 1, green: 0.90, blue: 0.60)
        default: return .white.opacity(0.9)
        }
    }
}
