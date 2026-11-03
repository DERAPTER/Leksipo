import Foundation
import Testing
@testable import English_Words

@Suite("Выбор голосов")
@MainActor
struct PronunciationServiceTests {
    private func language(_ code: String) throws -> StudyLanguage { try #require(StudyLanguage(code: code)) }

    private func voice(_ id: String, _ code: String, quality: Int = 1) throws -> SpeechVoice {
        SpeechVoice(id: id, name: id, language: try language(code), quality: quality)
    }

    @Test("Автоматический выбор предпочитает качество и не использует чужой язык")
    func automaticSelection() throws {
        let voices = try [voice("standard", "fr-FR"), voice("enhanced", "fr-FR", quality: 2),
                          voice("premium", "fr-CA", quality: 3), voice("foreign", "en-US", quality: 3)]
        try withService(voices) { service, _ in
            let french = try language("fr")
            #expect(service.selectedVoice(for: french)?.id == "premium")
            #expect(!service.hasVoice(for: .russian))
            #expect(service.selectedVoice(for: .russian) == nil)
            #expect(service.voices(for: french).count == 3)
        }
    }

    @Test("Явно выбранный регион имеет приоритет перед качеством другого региона")
    func regionalSelection() throws {
        let voices = try [voice("canadian", "fr-CA"), voice("french", "fr-FR", quality: 3)]
        try withService(voices) { service, _ in
            let canadian = try language("fr-CA")
            #expect(service.selectedVoice(for: canadian)?.id == "canadian")
        }
    }

    @Test("Выбранный голос сохраняется после пересоздания сервиса; сброс возвращает автоматический режим")
    func preferencePersists() throws {
        let voices = try [voice("standard", "fr-FR"), voice("premium", "fr-FR", quality: 3)]
        try withService(voices) { service, defaults in
            let french = try language("fr")
            try service.selectVoice("standard", for: french)
            let reopened = PronunciationService(defaults: defaults, voiceProvider: { voices })
            #expect(reopened.selectedVoice(for: french)?.id == "standard")
            try reopened.selectVoice(nil, for: french)
            #expect(reopened.preferredVoiceID(for: french) == nil)
            #expect(reopened.selectedVoice(for: french)?.id == "premium")
        }
    }

    @Test("Чужой или исчезнувший голос нельзя сохранить как выбор для языка")
    func invalidSelection() throws {
        let voices = try [voice("french", "fr-FR"), voice("english", "en-US")]
        try withService(voices) { service, _ in
            let french = try language("fr")
            try service.selectVoice("french", for: french)
            #expect(throws: (any Error).self) { try service.selectVoice("english", for: french) }
            #expect(throws: (any Error).self) { try service.selectVoice("missing", for: french) }
            #expect(service.preferredVoiceID(for: french) == "french")
        }
    }

    @Test("Загрузка и удаление голосов обновляют доступность; предпочтение восстанавливается при возврате голоса")
    func voiceCatalogChanges() throws {
        let box = VoiceCatalog()
        let preferred = try voice("preferred", "fr-FR", quality: 3)
        let fallback = try voice("fallback", "fr-CA")
        try withService([]) { _, defaults in
            let service = PronunciationService(defaults: defaults, voiceProvider: { box.voices })
            let french = try language("fr")
            #expect(!service.hasVoice(for: french))
            box.voices = [preferred, fallback]
            service.refreshVoices()
            #expect(service.hasVoice(for: french))
            try service.selectVoice(preferred.id, for: french)
            box.voices = [fallback]
            service.refreshVoices()
            #expect(service.selectedVoice(for: french) == fallback)
            box.voices = []
            service.refreshVoices()
            #expect(service.selectedVoice(for: french) == nil)
            box.voices = [preferred]
            service.refreshVoices()
            #expect(service.selectedVoice(for: french) == preferred)
        }
    }

    @Test("Выбор для одного языка не меняет выбор другого")
    func preferencesAreIndependent() throws {
        let voices = try [voice("french", "fr-FR"), voice("english", "en-US")]
        try withService(voices) { service, _ in
            let french = try language("fr")
            try service.selectVoice("french", for: french)
            try service.selectVoice("english", for: .english)
            try service.selectVoice(nil, for: french)
            #expect(service.preferredVoiceID(for: .english) == "english")
        }
    }

    @Test("Шуточные голоса не предлагаются для обучения")
    func excludesNoveltyVoices() throws {
        var novelty = try voice("singing", "en-US", quality: 3)
        novelty.isNovelty = true
        let standard = try voice("normal", "en-US")
        try withService([novelty, standard]) { service, _ in
            #expect(service.voices(for: .english) == [standard])
            #expect(service.selectedVoice(for: .english) == standard)
        }
        try withService([novelty]) { service, _ in
            #expect(!service.hasVoice(for: .english))
        }
    }

    @Test("При одинаковом качестве предпочитается системный голос вместо алфавитного порядка")
    func prefersSystemVoiceAtEqualQuality() throws {
        let other = try voice("aaa-legacy", "en-US")
        var preferred = try voice("zzz-system", "en-US")
        preferred.isSystemPreferred = true
        try withService([other, preferred]) { service, _ in
            #expect(service.selectedVoice(for: .english) == preferred)
        }
    }

    private func withService(_ voices: [SpeechVoice], run: (PronunciationService, UserDefaults) throws -> Void) throws {
        let suite = "PronunciationServiceTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try run(PronunciationService(defaults: defaults, voiceProvider: { voices }), defaults)
    }
}

@MainActor
private final class VoiceCatalog { var voices: [SpeechVoice] = [] }
