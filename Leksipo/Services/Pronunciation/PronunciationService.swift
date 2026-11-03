//
//  PronunciationService.swift
//  Leksipo
//
//  Created by Егор Халиков on 06.10.2026.
//

import AVFoundation

/// Сервис произношения слов.
///
/// Синглтон — относится к UI-инфраструктуре (как `HapticService`, `ThemeManager`).
/// Использует `AVSpeechSynthesizer` со встроенными голосами iOS.
///
/// Категория аудиосессии — по умолчанию (`.ambient`),
/// то есть воспроизведение уважает переключатель «без звука».
@MainActor
final class PronunciationService {
    
    static let shared = PronunciationService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    // MARK: - Public
    
    /// Произносит текст голосом указанного языка.
    /// Если в момент вызова уже что-то произносится — старая озвучка прерывается.
    func speak(_ text: String, language: StudyLanguage) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard let code = Self.voiceLanguage(for: language, available: voices.map(\.language)),
              let voice = voices.first(where: { $0.language == code }) else {
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
