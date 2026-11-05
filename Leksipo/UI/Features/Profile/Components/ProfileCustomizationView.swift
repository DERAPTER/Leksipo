import SwiftUI

struct ProfileCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var appearance: LexiAvatarAppearance
    private let onSave: (String, LexiAvatarAppearance) -> Void

    init(name: String, appearance: LexiAvatarAppearance, onSave: @escaping (String, LexiAvatarAppearance) -> Void) {
        _name = State(initialValue: name)
        _appearance = State(initialValue: appearance)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LexiAvatarView(appearance: appearance, size: 128)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                Form {
                    nameSection

                    headwearSection

                    optionsSection("profile_avatar_neckwear", options: LexiAvatarNeckwear.allCases,
                                   selection: $appearance.neckwear, title: \.title) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiNeckwearArtwork(option: option)
                                .aspectRatio(1.8, contentMode: .fit)
                                .padding(2)
                        }
                    }

                    optionsSection("profile_avatar_glasses", options: LexiAvatarGlasses.allCases,
                                   selection: $appearance.glasses, title: \.title) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiGlassesArtwork(option: option)
                                .aspectRatio(1.8, contentMode: .fit)
                                .padding(2)
                        }
                    }

                    optionsSection("profile_avatar_ear", options: LexiAvatarEarAccessory.allCases,
                                   selection: $appearance.earAccessory, title: \.title) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiEarAccessoryArtwork(option: option)
                                .aspectRatio(1.4, contentMode: .fit)
                                .padding(6)
                        }
                    }

                    optionsSection("profile_avatar_background", options: LexiAvatarBackground.allCases,
                                   selection: $appearance.background, title: \.title) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiAvatarBackdrop(background: option)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .padding(5)
                        }
                    }
                }
                .listSectionSpacing(18)
                .contentMargins(.top, 8, for: .scrollContent)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("profile_editor_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save".localized()) {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), appearance)
                        dismiss()
                    }
                }
            }
        }
    }

    private var nameSection: some View {
        Section {
            TextField("onboarding_name_placeholder".localized(), text: $name)
                .textContentType(.nickname)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .listRowBackground(Color.cardBackground)
        } header: {
            Text("profile_name".localized())
        } footer: {
            Text("profile_name_empty_hint".localized())
        }
    }

    private var headwearSection: some View {
        Section("profile_avatar_hats".localized()) {
            VStack(alignment: .leading, spacing: 12) {
                optionsGrid(LexiAvatarHeadwear.allCases, selection: $appearance.headwear, title: \.title) { option in
                    if option == .none {
                        emptyArtwork
                    } else {
                        LexiHeadwearArtwork(option: option)
                            .aspectRatio(1.8, contentMode: .fit)
                            .padding(2)
                    }
                }

                Text("profile_avatar_headphones".localized())
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityAddTraits(.isHeader)

                optionsGrid(LexiAvatarHeadphones.allCases, selection: $appearance.headphones, title: \.title) { option in
                    if option == .none {
                        emptyArtwork
                    } else {
                        LexiHeadphonesArtwork(option: option)
                            .aspectRatio(1.1, contentMode: .fit)
                            .padding(5)
                    }
                }
            }
            .padding(8)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private func optionsSection<Option: Identifiable & Equatable, Artwork: View>(
        _ key: String,
        options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) -> some View {
        Section(key.localized()) {
            optionsGrid(options, selection: selection, title: title, artwork: artwork)
                .padding(8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    private func optionsGrid<Option: Identifiable & Equatable, Artwork: View>(
        _ options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48, maximum: 76), spacing: 8)], spacing: 8) {
            ForEach(options) { option in
                let isSelected = option == selection.wrappedValue
                Button {
                    selection.wrappedValue = option
                } label: {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.cardBackground)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { artwork(option).accessibilityHidden(true) }
                        .overlay(alignment: .bottomTrailing) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.appBackground)
                                    .frame(width: 17, height: 17)
                                    .background(Color.textPrimary, in: Circle())
                                    .padding(4)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 11)
                                .strokeBorder(isSelected ? Color.textPrimary : Color.stroke, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(option))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var emptyArtwork: some View {
        Image(systemName: "circle.slash")
            .font(.system(size: 20))
            .foregroundStyle(Color.textSecondary)
    }
}
