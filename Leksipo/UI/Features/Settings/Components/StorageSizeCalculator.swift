//
//  StorageSizeCalculator.swift
//  Leksipo
//
//  Created by Егор Халиков on 27.09.2026.
//

import Foundation

/// Считает примерный логический размер данных приложения.
///
/// **Почему не физический размер файлов:**
/// SQLite-хранилище SwiftData (`.store`) не сжимается после `DELETE` —
/// удалённые строки превращаются в свободные страницы внутри файла, но
/// сам файл не уменьшается без `VACUUM` (недоступен через SwiftData).
/// Плюс при больших транзакциях (например, сброс статистики) SQLite
/// может выделить новые страницы для служебных структур, и физический
/// размер `.store` на короткое время подрастает.
///
/// Поэтому показываем пользователю **логический** объём: считаем количество
/// записей в репозиториях и умножаем на оценочный размер строки. Цифра
/// стабильна и отражает реальный объём данных, а не внутреннее состояние БД.
@MainActor
enum StorageSizeCalculator {
    
    // MARK: - Оценочные размеры строк
    
    private enum RowSize {
        static let card: Int64 = 400       // слово + перевод + 2 описания + SRS + метаданные
        static let group: Int64 = 120      // имя + orderIndex + метаданные
        static let dailyStat: Int64 = 80   // dateKey + date + счётчики + флаг
        static let settings: Int64 = 2_000 // singleton с массивами достижений
    }
    
    /// Фиксированный «пол» — размер самого SwiftData-хранилища «с нуля» (пустая БД).
    /// Чтобы даже на пустой базе показывалось осмысленное число, а не «0 KB».
    private static let baselineBytes: Int64 = 32_000
    
    // MARK: - Public
    
    static func calculate(
        cardRepository: CardRepository,
        groupRepository: GroupRepository,
        statsRepository: StatsRepository
    ) -> String {
        var total: Int64 = baselineBytes
        
        // Карточки
        if let count = try? cardRepository.totalCount() {
            total += Int64(count) * RowSize.card
        }
        
        // Пользовательские группы
        if let count = try? groupRepository.userGroupsCount() {
            total += Int64(count) * RowSize.group
        }
        
        // Дни активности (DailyStat)
        if let stats = try? statsRepository.activityHistory(monthsBack: 24) {
            total += Int64(stats.count) * RowSize.dailyStat
        }
        
        // UserSettings (singleton)
        total += RowSize.settings
        
        return format(total)
    }
    
    // MARK: - Private
    
    private static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}
