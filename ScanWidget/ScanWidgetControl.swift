//
//  ScanWidgetControl.swift
//  ScanWidget
//
//  Created by Om Shejul on 05/03/25.
//

import AppIntents
import SwiftUI
import WidgetKit

struct ScanWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.omshejul.ControlCenterWidget.CCWidget"
        ) {
            ControlWidgetButton(
                "Launch App",
                action: OpenAppIntent()
            ) { isRunning in
                Label("Scan", systemImage: "qrcode.viewfinder")
            }
        }
        .displayName("Open Scan")
        .description("Quickly open the Scan app from Control Center.")
    }
}


struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open the App"

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Start / stop the timer based on `value`.
        return .result()
    }
}
