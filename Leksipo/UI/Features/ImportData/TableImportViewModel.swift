import Foundation

@MainActor
@Observable
final class TableImportViewModel {
    struct PreviewRow: Identifiable {
        let source: TwoColumnImportParser.Row
        let skipReason: String?
        let reusesCard: Bool
        var id: Int { source.firstLine }
        var shouldImport: Bool { skipReason == nil }
        var lineLabel: String {
            source.firstLine == source.lastLine ? "\(source.firstLine)" : "\(source.firstLine)–\(source.lastLine)"
        }
    }

    var languagePair = StudyLanguagePair.legacy { didSet { refreshPreview() } }
    var groupName = "table_import_group_default".localized() { didSet { refreshPreview() } }
    var firstRowIsHeader = false { didSet { refreshPreview() } }
    private(set) var rows: [PreviewRow] = []
    private(set) var isParsing = false
    private(set) var errorMessage: String?
    var showSuccessAlert = false
    private(set) var successMessage = ""

    var hasInput: Bool { !parsedRows.isEmpty }
    var importableRows: [PreviewRow] { rows.filter(\.shouldImport) }
    var skippedRows: [PreviewRow] { rows.filter { !$0.shouldImport } }
    var canImport: Bool {
        !isParsing && !showSuccessAlert &&
            !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !importableRows.isEmpty
    }

    private var parsedRows: [TwoColumnImportParser.Row] = []
    private var requestID = UUID()
    private let cards: CardRepository
    private let groups: GroupRepository
    private let importGroups: ([ImportGroupDTO]) throws -> String

    init(cards: CardRepository, groups: GroupRepository, importGroups: @escaping ([ImportGroupDTO]) throws -> String) {
        self.cards = cards
        self.groups = groups
        self.importGroups = importGroups
    }

    func prepare(from text: String) async {
        let request = UUID()
        requestID = request
        parsedRows = []
        rows = []
        errorMessage = nil
        showSuccessAlert = false
        isParsing = true
        defer { if requestID == request { isParsing = false } }
        let parsing = Task.detached(priority: .userInitiated) { try TwoColumnImportParser.parse(text) }
        do {
            let result = try await withTaskCancellationHandler {
                try await parsing.value
            } onCancel: {
                parsing.cancel()
            }
            try Task.checkCancellation()
            guard requestID == request else { return }
            parsedRows = result
            if result.isEmpty { errorMessage = "import_error_empty_clipboard".localized() }
            else { refreshPreview() }
        } catch is CancellationError {
            // Отмена или новая вставка не должны возвращать старый предпросмотр.
        } catch {
            if requestID == request { errorMessage = error.localizedDescription }
        }
    }

    func refreshPreview() {
        errorMessage = nil
        guard !parsedRows.isEmpty else { rows = []; return }
        do { try rebuildPreview() }
        catch { rows = []; errorMessage = error.localizedDescription }
    }

    func importTable() {
        guard canImport else { return }
        // База могла измениться в другом окне после вставки.
        refreshPreview()
        guard canImport else { return }
        let ready = importableRows
        let newCount = ready.filter { !$0.reusesCard }.count
        let reusedCount = ready.count - newCount
        let skippedCount = skippedRows.count
        let group = ImportGroupDTO(
            name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
            cards: ready.map { ImportCardDTO(origin: $0.source.origin, translated: $0.source.translated,
                                            originDescription: nil, translatedDescription: nil) },
            learningLanguageCode: languagePair.learning.code, translationLanguageCode: languagePair.translation.code
        )
        do {
            _ = try importGroups([group])
            successMessage = String(format: "table_import_success".localized(), newCount, reusedCount, skippedCount)
            showSuccessAlert = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func rebuildPreview() throws {
        typealias CardKey = ImportDataViewModel.CardKey
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let target = try groups.fetchUserGroups().first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == name
        }
        if let target, target.languagePair != languagePair {
            rows = []
            errorMessage = String(format: "import_language_conflict".localized(), target.name)
            return
        }
        var existing: [CardKey: Card] = [:]
        for card in try cards.fetchAll() {
            let key = CardKey(card.originWord, card.translatedWord, card.languagePair)
            if existing[key] == nil { existing[key] = card }
        }
        var seen = Set<CardKey>()
        rows = parsedRows.enumerated().map { index, row in
            func skipped(_ reason: String) -> PreviewRow {
                PreviewRow(source: row, skipReason: reason, reusesCard: false)
            }
            if firstRowIsHeader && index == 0 { return skipped("table_skip_header") }
            if let issue = row.issue { return skipped("table_skip_\(issue.rawValue)") }
            let key = CardKey(row.origin, row.translated, languagePair)
            guard seen.insert(key).inserted else { return skipped("table_skip_duplicate") }
            if let card = existing[key] {
                if let target, card.groups.contains(where: { $0.id == target.id }) { return skipped("table_skip_present") }
                return PreviewRow(source: row, skipReason: nil, reusesCard: true)
            }
            return PreviewRow(source: row, skipReason: nil, reusesCard: false)
        }
    }
}
