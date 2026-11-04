import Foundation

/// Текст, скопированный из таблицы: табуляция разделяет ячейки, перевод строки — записи.
/// Кавычки позволяют сохранить табуляцию и переносы строк внутри ячейки.
enum TwoColumnImportParser {
    enum Issue: String, Sendable {
        case blank, columnCount, emptyOrigin, emptyTranslation, quotes
    }

    struct Row: Sendable {
        let firstLine: Int
        let lastLine: Int
        let cells: [String]
        let issue: Issue?

        var origin: String { cells.first ?? "" }
        var translated: String { cells.count > 1 ? cells[1] : "" }
    }

    nonisolated static func parse(_ text: String) throws -> [Row] {
        let text = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        var rows: [Row] = []
        var cells: [String] = []
        var cell = ""
        var quoted = false
        var afterQuote = false
        var malformed = false
        var started = false
        var previousCR = false
        var line = 1
        var firstLine = 1
        var processed = 0

        func finishCell() {
            cells.append(cell.trimmingCharacters(in: .whitespacesAndNewlines))
            cell = ""
            afterQuote = false
        }

        func finishRow() {
            finishCell()
            let issue: Issue?
            if malformed || quoted { issue = .quotes }
            else if cells.count == 1 && cells[0].isEmpty { issue = .blank }
            else if cells.count != 2 { issue = .columnCount }
            else if cells[0].isEmpty { issue = .emptyOrigin }
            else if cells[1].isEmpty { issue = .emptyTranslation }
            else { issue = nil }
            rows.append(Row(firstLine: firstLine, lastLine: line, cells: cells, issue: issue))
            cells = []
            quoted = false
            malformed = false
            started = false
        }

        for scalar in text.unicodeScalars {
            processed += 1
            if processed.isMultiple(of: 1024) { try Task.checkCancellation() }
            if previousCR && scalar == "\n" { previousCR = false; continue }
            previousCR = scalar == "\r"
            let newline = scalar == "\r" || scalar == "\n"
            if quoted {
                if scalar == "\"" { quoted = false; afterQuote = true }
                else if newline { cell.append("\n"); line += 1 }
                else { cell.unicodeScalars.append(scalar) }
            } else if scalar == "\t" {
                finishCell()
                started = true
            } else if newline {
                finishRow()
                line += 1
                firstLine = line
            } else if scalar == "\"" && (cell.isEmpty || afterQuote) {
                if afterQuote { cell.append("\"") }
                quoted = true
                afterQuote = false
                started = true
            } else {
                if afterQuote && scalar != " " { malformed = true }
                cell.unicodeScalars.append(scalar)
                started = true
            }
        }
        try Task.checkCancellation()
        // Конечный перевод строки из буфера не создаёт лишнюю пустую запись.
        if started || !cells.isEmpty || !cell.isEmpty { finishRow() }
        return rows
    }
}
