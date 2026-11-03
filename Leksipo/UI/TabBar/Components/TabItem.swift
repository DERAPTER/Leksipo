//
//  TabItem.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import Foundation

struct TabItem: Identifiable, Hashable {
    let screen: AppScreen
    
    var id: AppScreen { screen }
    var title: String { screen.title }
    var iconName: String { screen.iconName }
    
    static var all: [TabItem] {
        AppScreen.allCases.map(TabItem.init(screen:))
    }
}
