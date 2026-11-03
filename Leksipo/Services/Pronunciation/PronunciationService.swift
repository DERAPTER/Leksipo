//
//  PronunciationService.swift
//  Leksipo
//
//  Created by Егор Халиков on 06.10.2026.
//

import AVFoundation
import Observation

/// Сервис произношения слов.
///
/// Синглтон — относится к UI-инфраструктуре (как `HapticService`, `ThemeManager`).
/// Использует `AVSpeechSynthesizer` со встроенными голосами iOS.
///
/// Категория аудиосессии — по умолчанию (`.ambient`),
/// то есть воспроизведение уважает переключатель «без звука».
@MainActor
@Observable
final class PronunciationService {
    
    static let shared = PronunciationService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private(set) var availableVoices: [SpeechVoice] = []
    private var preferences: [String: String]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let voiceProvider: () -> [SpeechVoice]
    private static let preferencesKey = "pronunciationVoiceIdentifiers"

    init(defaults: UserDefaults = .standard, voiceProvider: @escaping () -> [SpeechVoice] = {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let languages = Set(voices.compactMap { StudyLanguage(code: $0.language)?.baseCode })
        let systemVoiceIDs = Set(languages.compactMap { AVSpeechSynthesisVoice(language: $0)?.identifier })
        return voices.compactMap { voice in
            guard let language = StudyLanguage(code: voice.language) else { return nil }
            return SpeechVoice(id: voice.identifier, name: voice.name, language: language, quality: voice.quality.rawValue, isNovelty: voice.voiceTraits.contains(.isNoveltyVoice), isSystemPreferred: systemVoiceIDs.contains(voice.identifier))
        }
    }) {
        self.defaults = defaults
        self.voiceProvider = voiceProvider
        // Идентификаторы голосов зависят от устройства и не входят в бэкап карточек.
        preferences = defaults.dictionary(forKey: Self.preferencesKey) as? [String: String] ?? [:]
        refreshVoices()
    }

    func refreshVoices() {
        let voices = voiceProvider().filter { !$0.isNovelty }
        if voices != availableVoices { availableVoices = voices }
    }

    func hasVoice(for language: StudyLanguage) -> Bool {
        availableVoices.contains { $0.language.baseCode == language.baseCode }
    }

    func voices(for language: StudyLanguage) -> [SpeechVoice] {
        availableVoices.filter { $0.language.baseCode == language.baseCode }.sorted {
            if ($0.language == language) != ($1.language == language) { return $0.language == language }
            if $0.quality != $1.quality { return $0.quality > $1.quality }
            if $0.isSystemPreferred != $1.isSystemPreferred { return $0.isSystemPreferred }
            return $0.id < $1.id
        }
    }

    func preferredVoiceID(for language: StudyLanguage) -> String? { preferences[language.code] }

    func selectedVoice(for language: StudyLanguage) -> SpeechVoice? {
        let voices = voices(for: language)
        return voices.first { $0.id == preferences[language.code] } ?? voices.first
    }

    func selectVoice(_ identifier: String?, for language: StudyLanguage) throws {
        refreshVoices()
        if let identifier, !voices(for: language).contains(where: { $0.id == identifier }) {
            throw PronunciationError.unavailable(language)
        }
        preferences[language.code] = identifier
        defaults.set(preferences, forKey: Self.preferencesKey)
    }

    func preview(_ text: String, language: StudyLanguage, voiceID: String) throws {
        try speak(text, language: language, voiceID: voiceID)
    }
    
    // MARK: - Public
    
    /// Произносит текст голосом указанного языка.
    /// Если в момент вызова уже что-то произносится — старая озвучка прерывается.
    func speak(_ text: String, language: StudyLanguage) throws {
        try speak(text, language: language, voiceID: nil)
    }

    private func speak(_ text: String, language: StudyLanguage, voiceID: String?) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        refreshVoices()
        let selected = voiceID.flatMap { identifier in voices(for: language).first { $0.id == identifier } }
            ?? (voiceID == nil ? selectedVoice(for: language) : nil)
        guard let selected, let voice = AVSpeechSynthesisVoice(identifier: selected.id),
              StudyLanguage(code: voice.language)?.baseCode == language.baseCode else {
            throw PronunciationError.unavailable(language)
        }
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        
        synthesizer.speak(utterance)
    }
    
    /// Выбираем только голос того же языка; отсутствие голоса не включает системный язык.
    static func voiceLanguage(for language: StudyLanguage, available: [String]) -> String? {
        available.first { StudyLanguage(code: $0) == language }
            ?? available.sorted().first { StudyLanguage(code: $0)?.baseCode == language.baseCode }
    }

    /// Немедленно останавливает текущее воспроизведение.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}


private enum PronunciationError: LocalizedError {
    case unavailable(StudyLanguage)

    var errorDescription: String? {
        switch self {
        case .unavailable(let language):
            return String(format: "study_voice_unavailable".localized(), language.displayName)
        }
    }
}


struct SpeechVoice: Identifiable, Equatable {
    let id: String
    let name: String
    let language: StudyLanguage
    let quality: Int
    var isNovelty: Bool = false
    var isSystemPreferred: Bool = false

    var qualityName: String {
        switch quality {
        case 3: return "speech_quality_premium".localized()
        case 2: return "speech_quality_enhanced".localized()
        default: return "speech_quality_standard".localized()
        }
    }
}
