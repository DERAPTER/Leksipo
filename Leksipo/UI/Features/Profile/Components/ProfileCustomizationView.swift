import SwiftUI

struct ProfileCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .caption) private var minimumCellWidth: CGFloat = 104
    @ScaledMetric(relativeTo: .caption) private var captionHeight: CGFloat = 44
    @State private var name: String
    @State private var appearance: LexiAvatarAppearance
    private let access: LexiAvatarAccess
    private let onSave: (String, LexiAvatarAppearance) -> Void

    init(name: String, appearance: LexiAvatarAppearance, access: LexiAvatarAccess,
         onSave: @escaping (String, LexiAvatarAppearance) -> Void) {
        _name = State(initialValue: name)
        _appearance = State(initialValue: appearance)
        self.access = access
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
                                   selection: $appearance.neckwear) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiNeckwearArtwork(option: option)
                                .aspectRatio(1.8, contentMode: .fit)
                                .padding(2)
                        }
                    }

                    optionsSection("profile_avatar_glasses", options: LexiAvatarGlasses.allCases,
                                   selection: $appearance.glasses) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiGlassesArtwork(option: option)
                                .aspectRatio(1.8, contentMode: .fit)
                                .padding(2)
                        }
                    }

                    optionsSection("profile_avatar_ear", options: LexiAvatarEarAccessory.allCases,
                                   selection: $appearance.earAccessory) { option in
                        if option == .none {
                            emptyArtwork
                        } else {
                            LexiEarAccessoryArtwork(option: option)
                                .aspectRatio(1.4, contentMode: .fit)
                                .padding(6)
                        }
                    }

                    optionsSection("profile_avatar_background", options: LexiAvatarBackground.allCases,
                                   selection: $appearance.background) { option in
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
                optionsGrid(LexiAvatarHeadwear.allCases, selection: $appearance.headwear) { option in
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

                optionsGrid(LexiAvatarHeadphones.allCases, selection: $appearance.headphones) { option in
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

    private func optionsSection<Option: LexiAvatarOption, Artwork: View>(
        _ key: String,
        options: [Option],
        selection: Binding<Option>,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) -> some View {
        Section(key.localized()) {
            optionsGrid(options, selection: selection, artwork: artwork)
                .padding(8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    private func optionsGrid<Option: LexiAvatarOption, Artwork: View>(
        _ options: [Option],
        selection: Binding<Option>,
        @ViewBuilder artwork: @escaping (Option) -> Artwork
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumCellWidth, maximum: minimumCellWidth * 1.5),
                                    spacing: 8, alignment: .top)], spacing: 8) {
            ForEach(options) { option in
                if let requirement = access.unmetRequirement(for: option) {
                    optionCell(artwork(option), caption: requirement.caption, isLocked: true)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(option.title)
                        .accessibilityValue(requirement.caption)
                        .accessibilityHint("profile_avatar_locked".localized())
                } else {
                    let isSelected = option == selection.wrappedValue
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        optionCell(artwork(option), caption: option.title, isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func optionCell<Artwork: View>(_ artwork: Artwork, caption: String,
                                           isLocked: Bool = false, isSelected: Bool = false) -> some View {
        VStack(spacing: 4) {
            artwork
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .opacity(isLocked ? 0.55 : 1)
                .accessibilityHidden(true)
                .overlay(alignment: .topTrailing) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 22, height: 22)
                            .background(Color.appBackground, in: Circle())
                            .accessibilityHidden(true)
                    }
                }
            Text(caption)
                .font(.caption2.weight(isLocked ? .medium : .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(isLocked ? Color.textSecondary : Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, isSelected ? 16 : 0)
                .frame(minHeight: captionHeight, alignment: .top)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 19, height: 19)
                    .background(Color.textPrimary, in: Circle())
                    .padding(6)
                    .accessibilityHidden(true)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.textPrimary : Color.stroke, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    private var emptyArtwork: some View {
        Image(systemName: "circle.slash")
            .font(.system(size: 20))
            .foregroundStyle(Color.textSecondary)
    }
}
