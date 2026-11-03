//
//  RepositoryError.swift
//  Leksipo
//
//  Created by Егор Халиков on 24.09.2026.
//

import Foundation

enum RepositoryError: LocalizedError {
    case notFound
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case invalidInput(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Запись не найдена"
        case .saveFailed(let error):
            return "Ошибка сохранения: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Ошибка загрузки: \(error.localizedDescription)"
        case .invalidInput(let reason):
            return reason
        }
    }
}
