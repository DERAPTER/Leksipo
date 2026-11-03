//
//  ImportDataViewModel.swift
//  Leksipo
//
//  Created by Егор Халиков on 21.10.2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ImportGroupDTO: Codable {
    let name: String
    let cards: [ImportCardDTO]
}

struct ImportCardDTO: Codable {
    let origin: String
    let translated: String
    let originDescription: String?
    let translatedDescription: String?
}

@MainActor
@Observable
final class ImportDataViewModel {
    
    // MARK: - Templates (static)
    
    static let jsonTemplate = """
    [
      {
        "name": "Название группы",
        "cards": [
          {
            "origin": "word",
            "translated": "перевод",
            "originDescription": "",
            "translatedDescription": ""
          }
        ]
      }
    ]
    """
    
    static var aiPromptTemplate: String {
        let localizedPrompt = "import_ai_prompt_text".localized()
        return "\(localizedPrompt)\n\n\(jsonTemplate)"
    }
    
    // MARK: - State
    
    var jsonText: String = "" {
        didSet {
            parsedGroups = []
            showDuplicateAlert = false
            showSuccessAlert = false
        }
    }
    var showFileImporter = false
    var errorMessage: String?
    
    var showDuplicateAlert = false
    var showSuccessAlert = false
    var successMessage = ""
    
    private var parsedGroups: [ImportGroupDTO] = []
    private(set) var previewMessage = ""
    private let achievementsService: AchievementsService?
    private let cardRepository: CardRepository
    private let groupRepository: GroupRepository
    private let transaction: PersistenceTransaction
    private let onComplete: () -> Void
    
    init(cardRepository: CardRepository, groupRepository: GroupRepository, transaction: PersistenceTransaction, achievementsService: AchievementsService? = nil, onComplete: @escaping () -> Void) {
        self.cardRepository = cardRepository
        self.groupRepository = groupRepository
        self.onComplete = onComplete
        self.transaction = transaction
        self.achievementsService = achievementsService
    }
    
    // MARK: - Paste from clipboard
    
    func pasteFromClipboard() {
        guard let string = UIPasteboard.general.string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "import_error_empty_clipboard".localized()
            jsonText = ""
            return
        }
        jsonText = string
        errorMessage = nil
        
        // Тактильный отклик, что текст вставился
        HapticService.shared.success()
    }
    
    // MARK: - File Handling
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            jsonText = ""
            guard let url = urls.first else {
                errorMessage = "import_error_file".localized()
                return
            }
            
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                if let text = String(data: data, encoding: .utf8) {
                    jsonText = text
                    errorMessage = nil
                    HapticService.shared.success()
                } else {
                    errorMessage = "import_error_encoding".localized()
                }
            } catch {
                errorMessage = "import_error_file".localized()
            }
        case .failure:
            jsonText = ""
            errorMessage = "import_error_file".localized()
        }
    }
    
    // MARK: - Import

    func startImport(from text: String) {
        errorMessage = nil
        parsedGroups = []
        showDuplicateAlert = false
        showSuccessAlert = false
        do {
            let groups = try JSONDecoder().decode([ImportGroupDTO].self, from: Data(text.utf8))
            guard !groups.isEmpty else {
                errorMessage = "import_error_empty".localized()
                return
            }
            parsedGroups = try normalized(groups)
            previewMessage = try process(groups: parsedGroups, write: false).message + "\n\n" + "import_merge_rules".localized()
            showDuplicateAlert = true
        } catch let error as DecodingError {
            let context: DecodingError.Context
            switch error {
            case .keyNotFound(let key, let value):
                errorMessage = String(format: "import_error_field".localized(), path(value.codingPath + [key]))
                return
            case .dataCorrupted(let value), .typeMismatch(_, let value), .valueNotFound(_, let value): context = value
            @unknown default:
                errorMessage = "import_error_parse".localized()
                return
            }
            errorMessage = String(format: "import_error_field".localized(), path(context.codingPath))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmImportWithDuplicates() {
        guard !parsedGroups.isEmpty else { return }
        showDuplicateAlert = false
        do {
            // Повторяем расчёт внутри транзакции: база могла измениться после предпросмотра.
            let result = try transaction.perform { try process(groups: parsedGroups, write: true) }
            successMessage = result.message
            showSuccessAlert = true
            parsedGroups = []
            achievementsService?.evaluate()
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct CardKey: Hashable {
        let origin: String
        let translated: String

        init(_ origin: String, _ translated: String) {
            self.origin = origin.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            self.translated = translated.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    private struct Membership: Hashable {
        let group: String
        let card: CardKey
    }

    private struct Summary {
        var groups = 0
        var cards = 0
        var links = 0
        var duplicates = 0

        var message: String {
            String(format: "import_summary".localized(), groups, cards, links, duplicates)
        }
    }

    private func process(groups: [ImportGroupDTO], write: Bool) throws -> Summary {
        let existingGroups = try groupRepository.fetchUserGroups()
        let existingCards = try cardRepository.fetchAll()
        // Старые базы могут содержать совпадающие названия: выбираем первый объект,
        // не удаляя и не объединяя уже существующие пользовательские данные.
        var groupIndex: [String: CardGroup] = [:]
        var cardIndex: [CardKey: Card] = [:]
        for group in existingGroups where groupIndex[group.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] == nil {
            groupIndex[group.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = group
        }
        for card in existingCards where cardIndex[CardKey(card.originWord, card.translatedWord)] == nil {
            cardIndex[CardKey(card.originWord, card.translatedWord)] = card
        }
        var knownGroups = Set(groupIndex.keys)
        var knownCards = Set(cardIndex.keys)
        var memberships = Set<Membership>()
        for (key, card) in cardIndex {
            for group in card.groups {
                memberships.insert(Membership(group: group.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), card: key))
            }
        }
        var summary = Summary()
        for group in groups {
            let groupKey = group.name.lowercased()
            if knownGroups.insert(groupKey).inserted {
                summary.groups += 1
                if write { groupIndex[groupKey] = try groupRepository.create(name: group.name) }
            }
            for dto in group.cards {
                let cardKey = CardKey(dto.origin, dto.translated)
                if knownCards.insert(cardKey).inserted {
                    summary.cards += 1
                    if write {
                        cardIndex[cardKey] = try cardRepository.create(
                            origin: dto.origin, translated: dto.translated,
                            originDescription: dto.originDescription ?? "",
                            translatedDescription: dto.translatedDescription ?? "", groups: []
                        )
                    }
                } else {
                    summary.duplicates += 1
                }
                if memberships.insert(Membership(group: groupKey, card: cardKey)).inserted {
                    summary.links += 1
                    if write, let card = cardIndex[cardKey], let target = groupIndex[groupKey] {
                        try groupRepository.addCard(card, to: target)
                    }
                }
            }
        }
        return summary
    }

    private func normalized(_ groups: [ImportGroupDTO]) throws -> [ImportGroupDTO] {
        try groups.enumerated().map { i, group in
            func required(_ value: String, _ field: String) throws -> String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    throw ImportValidationError(message: String(format: "import_error_field".localized(), field))
                }
                return trimmed
            }
            let name = try required(group.name, "[\(i)].name")
            let cards = try group.cards.enumerated().map { j, card in
                ImportCardDTO(
                    origin: try required(card.origin, "[\(i)].cards[\(j)].origin"),
                    translated: try required(card.translated, "[\(i)].cards[\(j)].translated"),
                    originDescription: card.originDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                    translatedDescription: card.translatedDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            return ImportGroupDTO(name: name, cards: cards)
        }
    }

    private func path(_ keys: [CodingKey]) -> String {
        let result = keys.map { key in key.intValue.map { "[\($0)]" } ?? ".\(key.stringValue)" }.joined()
        return result.isEmpty ? "$" : "$" + result
    }
}

private struct ImportValidationError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
