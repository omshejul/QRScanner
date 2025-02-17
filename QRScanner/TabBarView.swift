//
//  TabBarView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct TabBarView: View {
    init() {
        setupTabBarAppearance()
    }

    var body: some View {
        TabView {
            QRCodeScannerContainer()
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }

            QRCodeGeneratorView()
                .tabItem {
                    Label("Create", systemImage: "plus.app")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Apply Blurred Background to Tab Bar
func setupTabBarAppearance() {
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground() // Ensures blur effect
    UITabBar.appearance().standardAppearance = appearance
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
