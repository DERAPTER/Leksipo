import SwiftUI

enum MascotPose: String, CaseIterable {
    case idle = "dachshund-idle"
    case sad = "dachshund-sad"
    case welcome = "dachshund-welcome"
    case thinking = "dachshund-thinking"
    case support = "dachshund-support"
    case success = "dachshund-success"
    case celebrate = "dachshund-celebrate"
    case rest = "dachshund-rest"
    case face = "dachshund-face"
}

struct MascotView: View {
    let pose: MascotPose

    var body: some View {
        // Состояние экрана описано соседним текстом; маскот служит иллюстрацией.
        Image(decorative: pose.rawValue)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

#if DEBUG
private struct MascotPreviewGallery: View {
    let background: Color

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(MascotPose.allCases, id: \.self) { pose in
                    VStack(spacing: 8) {
                        MascotView(pose: pose)
                            .frame(height: 140)
                        Text(pose.rawValue)
                            .font(.caption)
                    }
                    .padding(8)
                }
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
    }
}

#Preview("Mascot — light") {
    MascotPreviewGallery(background: ThemeColors.forTheme(.beige).background)
        .preferredColorScheme(.light)
}

#Preview("Mascot — dark green") {
    MascotPreviewGallery(background: ThemeColors.forTheme(.green).background)
        .preferredColorScheme(.dark)
}

#Preview("Mascot — dark blue") {
    MascotPreviewGallery(background: ThemeColors.forTheme(.blue).background)
        .preferredColorScheme(.dark)
}

#Preview("Mascot — pink") {
    MascotPreviewGallery(background: ThemeColors.forTheme(.pink).background)
        .preferredColorScheme(.light)
}
#endif
