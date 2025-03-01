//
//  QRScannerApp.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

@main
struct QRScannerApp: App {
    @AppStorage("themeMode") private var themeMode = "Device" // Load stored theme
    
    init() {
        applyTheme() // ✅ Apply theme immediately on launch
    }
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .onAppear {
                    applyTheme() // ✅ Ensure it updates when the app opens
                }
        }
    }
    
    // MARK: - Apply Theme Based on Selection
    private func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch themeMode {
            case "Light":
                windowScene.windows.first?.overrideUserInterfaceStyle = .light
            case "Dark":
                windowScene.windows.first?.overrideUserInterfaceStyle = .dark
            default:
                windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified // Follows system
            }
        }
    }
}
