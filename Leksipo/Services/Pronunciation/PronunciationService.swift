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
    func speak(_ text: String, language: AppLanguage) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: language.rawValue)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0
        
        synthesizer.speak(utterance)
    }
    
    /// Немедленно останавливает текущее воспроизведение.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
