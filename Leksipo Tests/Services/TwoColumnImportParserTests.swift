import Foundation
import Testing
@testable import English_Words

@Suite("Импорт двух столбцов — разбор текста")
struct TwoColumnImportParserTests {
    @Test("Таблица сохраняет пары, обрезает края и поддерживает окончания строк", arguments: ["\n", "\r\n", "\r"])
    func lineEndings(newline: String) throws {
        let rows = try TwoColumnImportParser.parse("\u{FEFF} cat \t кот " + newline + "dog\tсобака" + newline)
        #expect(rows.count == 2)
        #expect(rows.map(\.origin) == ["cat", "dog"])
        #expect(rows.map(\.translated) == ["кот", "собака"])
        #expect(rows.allSatisfy { $0.issue == nil })
        #expect(rows.map(\.firstLine) == [1, 2])
    }

    @Test("Номера и причины пропуска не сдвигаются из-за пустых ячеек")
    func invalidRows() throws {
        let rows = try TwoColumnImportParser.parse("one\tодин\n\nword\n\tперевод\nword\t\na\tb\tc\nvalid\tда")
        #expect(rows.map(\.firstLine) == Array(1...7))
        #expect(rows.map(\.issue) == [nil, .blank, .columnCount, .emptyOrigin, .emptyTranslation, .columnCount, nil])
        #expect(rows.last?.origin == "valid")
        #expect(try TwoColumnImportParser.parse("").isEmpty)
    }

    @Test("Кавычки таблицы сохраняют переносы, табуляцию и удвоенные кавычки в ячейках")
    func quotedCells() throws {
        let rows = try TwoColumnImportParser.parse("\"a\tb\"\t\"строка 1\r\nстрока 2\"\r\n\"say \"\"hello\"\"\"\tпривет\r\n")
        #expect(rows.count == 2)
        #expect(rows[0].origin == "a\tb")
        #expect(rows[0].translated == "строка 1\nстрока 2")
        #expect(rows[0].firstLine == 1 && rows[0].lastLine == 2)
        #expect(rows[1].firstLine == 3 && rows[1].origin == "say \"hello\"")
        #expect(rows.allSatisfy { $0.issue == nil })
    }

    @Test("Повреждённые кавычки не становятся карточкой")
    func malformedQuotes() throws {
        let malformed = try TwoColumnImportParser.parse("\"cat\"x\tкот\nvalid\tда")
        #expect(malformed[0].issue == .quotes && malformed[1].issue == nil)
        let unclosed = try TwoColumnImportParser.parse("\"cat\tкот\nследующая строка")
        #expect(unclosed.count == 1 && unclosed[0].issue == .quotes)
        #expect(unclosed[0].firstLine == 1 && unclosed[0].lastLine == 2)
    }

    @Test("Обычные кавычки внутри слова и запятые не разделяют столбцы")
    func punctuationIsContent() throws {
        let rows = try TwoColumnImportParser.parse("say \"hi\"\tсказать «привет», поздороваться\na,b")
        #expect(rows[0].origin == "say \"hi\"")
        #expect(rows[0].translated == "сказать «привет», поздороваться")
        #expect(rows[1].issue == .columnCount)
    }

    @Test("Большая таблица не ограничена пятью показанными парами")
    func manyRows() throws {
        let text = (0..<10_000).map { "word\($0)\tперевод\($0)" }.joined(separator: "\n")
        let rows = try TwoColumnImportParser.parse(text)
        #expect(rows.count == 10_000)
        #expect(rows.last?.firstLine == 10_000 && rows.last?.issue == nil)
    }
}
