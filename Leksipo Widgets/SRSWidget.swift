//
//  SRSWidget.swift
//  Leksipo Widgets
//
//  Created by Егор Халиков on 09.10.2026.
//

import WidgetKit
import SwiftUI

@main
struct SRSWidgetBundle: WidgetBundle {
    var body: some Widget {
        SRSWidget()
    }
}

struct SRSWidget: Widget {
    let kind: String = "SRSWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SRSWidgetProvider()) { entry in
            SRSWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Text(SRSWidgetText.string("widget_display_name")))
        .description(Text(SRSWidgetText.string("widget_description")))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
        ])
        .contentMarginsDisabled()
    }
}
