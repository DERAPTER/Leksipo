import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// Снимок содержимого одной группы. Живые SwiftData-модели не передаются в экспорт.
struct SharedGroupDocument: Transferable, Sendable {
    let name: String
    let fileName: String
    let groups: [ImportGroupDTO]

    @MainActor
    init(group: CardGroup) {
        name = group.name
        fileName = Self.safeFileName(group.name)
        let cards = group.cards.sorted {
            if $0.originWord != $1.originWord { return $0.originWord < $1.originWord }
            if $0.translatedWord != $1.translatedWord { return $0.translatedWord < $1.translatedWord }
            return $0.id.uuidString < $1.id.uuidString
        }.map {
            ImportCardDTO(origin: $0.originWord, translated: $0.translatedWord,
                          originDescription: $0.originDescription, translatedDescription: $0.translatedDescription)
        }
        groups = [ImportGroupDTO(name: group.name, cards: cards,
                                 learningLanguageCode: group.languagePair.learning.code,
                                 translationLanguageCode: group.languagePair.translation.code)]
    }

    func encodedData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(groups)
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { document in
            try document.encodedData()
        }
        .suggestedFileName { $0.fileName }
    }

    private static func safeFileName(_ name: String) -> String {
        let invalid = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:?%*|\"<>"))
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        var base = ""
        for character in cleaned {
            guard base.utf8.count + String(character).utf8.count <= 120 else { break }
            base.append(character)
        }
        return (base.isEmpty ? "Leksipo-group" : base) + ".json"
    }
}
