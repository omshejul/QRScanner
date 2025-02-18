//
//  SettingsView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("scanSoundEnabled") private var scanSoundEnabled = false
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("themeMode") private var themeMode = "Device" // ✅ New setting

    let themeOptions = ["Device", "Light", "Dark"]

    var body: some View {
        Form {
            // MARK: - Scan Settings
            Section(header: Text("Scan Settings")) {
                Toggle("Scan Sound", isOn: $scanSoundEnabled)
                Toggle("Scan Vibration", isOn: $vibrationEnabled)
            }

            // MARK: - Appearance Settings
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $themeMode) {
                    ForEach(themeOptions, id: \.self) { option in
                        Text(option)
                    }
                }
            }

            // MARK: - About Me
            Section(header: Text("About").font(.caption).foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("QR Scanner & Generator")
                            .font(.headline)
                    }

                    HStack {
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Developed by Om Shejul")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)

                // MARK: - Links
                Link(destination: URL(string: "https://omshejul.com")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Visit Website")
                    }
                }

                Link(destination: URL(string: "mailto:qr@omshejul.com")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Email Me")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            applyTheme()
        }
        .onChange(of: themeMode) {
            applyTheme()
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
