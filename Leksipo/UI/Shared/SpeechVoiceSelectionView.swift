import SwiftUI
import AVFoundation

struct SpeechVoiceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let language: StudyLanguage
    private let speech = PronunciationService.shared
    @State private var previewText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(language.displayName).font(.headline)
                    Text(speech.voices(for: language).isEmpty ? "speech_unavailable".localized() : "speech_available".localized())
                        .foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.cardBackground)

                if !speech.voices(for: language).isEmpty {
                    Section("speech_preview_text".localized()) {
                        TextField("speech_enter_text".localized(), text: $previewText, axis: .vertical)
                            .textInputAutocapitalization(.never)
                        Text("speech_device_preference".localized()).font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .listRowBackground(Color.cardBackground)

                    Section("speech_voice".localized()) {
                        Button {
                            do { try speech.selectVoice(nil, for: language) }
                            catch { errorMessage = error.localizedDescription }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("speech_automatic".localized())
                                    if let voice = speech.voices(for: language).first {
                                        Text(voice.name).font(.caption).foregroundStyle(Color.textSecondary)
                                    }
                                }
                                Spacer()
                                if speech.preferredVoiceID(for: language) == nil { Image(systemName: "checkmark") }
                            }
                        }
                        ForEach(speech.voices(for: language)) { voice in
                            HStack {
                                Button {
                                    do { try speech.selectVoice(voice.id, for: language) }
                                    catch { errorMessage = error.localizedDescription }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(voice.name)
                                            Text("\(voice.language.displayName) · \(voice.qualityName)")
                                                .font(.caption).foregroundStyle(Color.textSecondary)
                                        }
                                        Spacer()
                                        if speech.preferredVoiceID(for: language) == voice.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Button {
                                    do { try speech.preview(previewText, language: language, voiceID: voice.id) }
                                    catch { errorMessage = error.localizedDescription }
                                } label: { Image(systemName: "play.circle").font(.title2) }
                                .buttonStyle(.borderless)
                                .disabled(previewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .accessibilityLabel(String(format: "speech_preview_voice".localized(), voice.name))
                            }
                        }
                        if let preferred = speech.preferredVoiceID(for: language),
                           !speech.voices(for: language).contains(where: { $0.id == preferred }) {
                            Text("speech_missing_preference".localized()).font(.caption).foregroundStyle(Color.textSecondary)
                        }
                    }
                    .listRowBackground(Color.cardBackground)
                }
                Section {
                    Text("speech_download_help".localized()).font(.callout).foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.cardBackground)
            }
            .foregroundStyle(Color.textPrimary)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("speech_voice".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close".localized()) { dismiss() }
                }
            }
            .onAppear { previewText = Self.sampleText(for: language) }
            .onDisappear { speech.stop() }
            .refreshSpeechVoices()
            .alert("error_title".localized(), isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) { Button("ok".localized()) { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
    }

    private static func sampleText(for language: StudyLanguage) -> String {
        ["en": "Hello!", "ru": "Здравствуйте!", "fr": "Bonjour !", "de": "Guten Tag!",
         "es": "¡Hola!", "it": "Buongiorno!", "pt": "Olá!", "ja": "こんにちは。",
         "zh": "你好！", "ko": "안녕하세요!", "ar": "مرحبا", "uk": "Вітаю!",
         "pl": "Dzień dobry!", "tr": "Merhaba!"][language.baseCode] ?? ""
    }
}

private struct SpeechVoiceRefresh: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { PronunciationService.shared.refreshVoices() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { PronunciationService.shared.refreshVoices() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AVSpeechSynthesizer.availableVoicesDidChangeNotification).receive(on: RunLoop.main)) { _ in
                PronunciationService.shared.refreshVoices()
            }
    }
}

extension View {
    func refreshSpeechVoices() -> some View { modifier(SpeechVoiceRefresh()) }
}
