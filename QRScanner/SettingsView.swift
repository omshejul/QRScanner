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
    @AppStorage("autoOpenUPI") private var autoOpenUPI = false
    @AppStorage("defaultUPIApp") private var defaultUPIApp = "None"
    @AppStorage("autoOpenPasskey") private var autoOpenPasskey = false
    @AppStorage("isOnboardingRemaining") var isOnboardingRemaining = false
    @AppStorage("showDragDropHint") private var showDragDropHint = true // New state to track hint visibility

    @State private var showResetConfirmation = false
    @State private var showThemeOptions = false
    @State private var showUPIAppOptions = false
    @State private var showOnboarding = false
    
    let themeOptions = ["Device", "Light", "Dark"]
    let upiAppOptions = ["None", "PhonePe", "Google Pay", "Paytm", "CRED", "BHIM", "Amazon Pay", "WhatsApp"]
    
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
                
                // MARK: - UPI Settings
                Section(header: Text("UPI Settings"), footer: Text("Choose your preferred UPI payment app for quick access.")) {
                    Toggle(isOn: $autoOpenUPI) {
                        Label {
                            Text("Auto Open UPI Payments")
                        } icon: {
                            Image(systemName: "indianrupeesign.circle")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Auto Open UPI Payments")
                    .accessibilityHint("Toggle to enable or disable automatic opening of UPI payment links.")
                    
                    if autoOpenUPI {
                        Button {
                            showUPIAppOptions = true
                        } label: {
                            HStack {
                                Label {
                                    Text("Default UPI App")
                                        .foregroundColor(.primary)
                                } icon: {
                                    Image(systemName: "app.badge")
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Text(defaultUPIApp)
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .accessibilityLabel("Default UPI App")
                        .accessibilityHint("Select your preferred UPI payment app.")
                        .accessibilityValue(defaultUPIApp)
                    }
                }
                
                // MARK: - Passkey Settings
                Section(header: Text("Passkey Authentication"), footer: Text("Automatically open passkey and FIDO authentication URLs with compatible apps.")) {
                    Toggle(isOn: $autoOpenPasskey) {
                        Label {
                            Text("Auto Open Passkey URLs")
                        } icon: {
                            Image(systemName: "key.horizontal")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Auto Open Passkey URLs")
                    .accessibilityHint("Toggle to enable or disable automatic opening of passkey authentication URLs.")
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
                
                // MARK: - App Features
                Section(header: Text("App Features")) {
                    Button {
                        // Show onboarding using the local sheet
                        showOnboarding = true
                    } label: {
                        Label {
                            Text("Replay Onboarding")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.primary)
                        }
                    }
                    .accessibilityLabel("Replay Onboarding")
                    .accessibilityHint("Tap to view the app's onboarding tutorial again.")
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
                    VStack(alignment: .leading, spacing: 4) {
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

                    Link(destination: URL(string: "mailto:qrbugreport@omshejul.com?subject=Bug%20Report")!) {
                        Label {
                            Text("Report Bug")
                        } icon: {
                            Image(systemName: "ladybug")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Report Bug")
                    .accessibilityHint("Opens the email client to report a bug.")
                    
                    Link(destination: URL(string: "mailto:qrfeedback@omshejul.com?subject=Feedback")!) {
                        Label {
                            Text("Help & Feedback")
                        } icon: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.primary)
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Help and Feedback")
                    .accessibilityHint("Opens the email client to send feedback.")
                    
//                    Link(destination: URL(string: "https://buymeacoffee.com/omshejul")!) {
//                        Label {
//                            Text("Buy Me a Coffee")
//                        } icon: {
//                            Image(systemName: "cup.and.saucer")
//                                .foregroundStyle(.primary)
//                        }
//                    }
//                    .foregroundStyle(.primary)
//                    .accessibilityLabel("Buy Me a Coffee")
//                    .accessibilityHint("Opens the Buy Me a Coffee page to support the developer.")

                    // Link(destination: URL(string: "https://apps.apple.com/app/id123456789?action=write-review")!) {
                    //     Label {
                    //         Text("Write a Review")
                    //     } icon: {
                    //         Image(systemName: "star")
                    //             .foregroundStyle(.primary)
                    //     }
                    // }
                    // .foregroundStyle(.primary)
                    // .accessibilityLabel("Write a Review")
                    // .accessibilityHint("Opens the App Store to write a review.")
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
            .sheet(isPresented: $showUPIAppOptions) {
                UPIAppSelectionView(selectedApp: $defaultUPIApp)
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isOnboardingRemaining: $isOnboardingRemaining)
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
        autoOpenUPI = false
        defaultUPIApp = "None"
        autoOpenPasskey = false
        isOnboardingRemaining = true // Reset onboarding state
        showDragDropHint = true
        
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

// MARK: - UPI App Selection View
struct UPIAppSelectionView: View {
    @Binding var selectedApp: String
    @Environment(\.dismiss) private var dismiss
    
    let upiAppOptions = ["None", "PhonePe", "Google Pay", "Paytm", "CRED", "BHIM", "Amazon Pay", "WhatsApp"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(upiAppOptions, id: \.self) { app in
                    Button {
                        selectedApp = app
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: app == "None" ? "xmark.circle" : "app.badge")
                                .font(.title3)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading) {
                                Text(app)
                                    .font(.headline)
                                
                                if app == "None" {
                                    Text("Show all payment apps")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedApp == app {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select UPI App")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            
            // Note about authorization and feedback
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note:")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("You will need to authorize Scan to open your selected UPI app only for the first time.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("If your payment app is not listed, please leave feedback so we can add it.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
        }
    }
}
