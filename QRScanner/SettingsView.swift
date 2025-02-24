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
    @AppStorage("themeMode") private var themeMode = "Device"

    let themeOptions = ["Device", "Light", "Dark"]

    var body: some View {
        NavigationView { // ✅ Wrap in NavigationView
            Form {
                // MARK: - Scan Settings
                Section(header: Text("Scan Settings")) {
                    Toggle("Scan Sound", isOn: $scanSoundEnabled)
                    Toggle("Scan Vibration", isOn: $vibrationEnabled)
                }
                
                // MARK: - Appearance Settings
                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading, spacing: 5) {
                        Picker("Theme", selection: $themeMode) {
                            ForEach(themeOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        HStack(spacing: 5) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)

                            Text("Theme affects QR code's appearance.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - About Me
                Section(header: Text("About").font(.caption).foregroundColor(.gray)) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("QR Scanner & Generator").font(.headline)
                        Text("Version 1.0.0").font(.subheadline).foregroundColor(.gray)
                        Text("Developed by Om Shejul").font(.subheadline).foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                    
                    // MARK: - Links
                    Link(destination: URL(string: "https://omshejul.com")!) {
                        Label("Visit Website", systemImage: "globe")
                    }
                    
                    Link(destination: URL(string: "mailto:qr@omshejul.com")!) {
                        Label("Email Me", systemImage: "envelope.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { applyTheme() }
        .onChange(of: themeMode) { applyTheme() }
    }

    // MARK: - Apply Theme
    private func applyTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch themeMode {
            case "Light":
                windowScene.windows.first?.overrideUserInterfaceStyle = .light
            case "Dark":
                windowScene.windows.first?.overrideUserInterfaceStyle = .dark
            default:
                windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified // System Default
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
