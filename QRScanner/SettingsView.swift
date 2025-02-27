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
    @AppStorage("autoOpenLinks") private var autoOpenLinks = false
    
    @State private var showResetConfirmation = false
    @State private var showThemeOptions = false
    
    let themeOptions = ["Device", "Light", "Dark"]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Scan Settings
                Section(header: Text("Scan Settings")) {
                    Toggle(isOn: $scanSoundEnabled) {
                        Label {
                            Text("Scan Sound")
                        } icon: {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Enable Scan Sound")
                    .accessibilityHint("Toggle to enable or disable sound during scanning.")
                    
                    Toggle(isOn: $vibrationEnabled) {
                        Label {
                            Text("Scan Vibration")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Enable Scan Vibration")
                    .accessibilityHint("Toggle to enable or disable vibration during scanning.")
                }
                
                // MARK: - Link Settings
                Section(header: Text("Link Handling"), footer: Text("Only secure HTTPS links will be opened automatically.")) {
                    Toggle(isOn: $autoOpenLinks) {
                        Label {
                            Text("Auto Open Links")
                        } icon: {
                            Image(systemName: "link")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Auto Open Links")
                    .accessibilityHint("Toggle to enable or disable automatic opening of secure links.")
                }
                
                // MARK: - Appearance Settings
                Section(header: Text("Appearance"), footer: Text("Theme affects the app interface and QR code appearance.")) {
                    Button {
                        showThemeOptions = true
                    } label: {
                        HStack {
                            Label {
                                Text("Theme")
                                    .foregroundColor(.primary)

                            } icon: {
                                Image(systemName: "circle.lefthalf.filled")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text(themeMode)
                                .foregroundColor(.gray)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .accessibilityLabel("App Theme")
                    .accessibilityHint("Select the desired theme for the app.")
                    .accessibilityValue(themeMode)
                }
                
                // MARK: - Data Management
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label {
                            Text("Reset All Settings")
                                .foregroundStyle(.red)
                        } icon: {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(.red)
                        }
                    }
                    .accessibilityLabel("Reset All Settings")
                    .accessibilityHint("Tap to reset all settings to their default values.")
                }
                
                // MARK: - About
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QR Scanner & Generator")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Developed by Om Shejul")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("QR Scanner & Generator, Version 1.0.0, Developed by Om Shejul")
                    
                    Link(destination: URL(string: "https://omshejul.com")!) {
                        Label {
                            Text("Visit Website")
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Visit Website")
                    .accessibilityHint("Opens the developer's website.")
                    
                    Link(destination: URL(string: "mailto:qr@omshejul.com")!) {
                        Label {
                            Text("Email Me")
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Email Developer")
                    .accessibilityHint("Opens the email client to contact the developer.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Settings", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
            .sheet(isPresented: $showThemeOptions) {
                ThemeSelectionView(selectedTheme: $themeMode)
            }
        }
        .onAppear { applyTheme() }
        .onChange(of: themeMode) {
            applyTheme()
        }
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
                windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    // MARK: - Reset Settings
    private func resetAllSettings() {
        // Reset all settings to their default values
        scanSoundEnabled = false
        vibrationEnabled = true
        themeMode = "Device"
        autoOpenLinks = false
        
        // Apply theme after reset
        applyTheme()
        
        // Provide haptic feedback for the reset action
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @Binding var selectedTheme: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                themeOption(title: "Device", icon: "iphone", description: "Follow system appearance")
                themeOption(title: "Light", icon: "sun.max.fill", description: "Always use light appearance")
                themeOption(title: "Dark", icon: "moon.fill", description: "Always use dark appearance")
            }
            .navigationTitle("Select Theme")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func themeOption(title: String, icon: String, description: String) -> some View {
        Button {
            selectedTheme = title
            dismiss()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if selectedTheme == title {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
