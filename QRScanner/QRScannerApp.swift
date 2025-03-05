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
    @AppStorage("isOnboardingRemaining") var isOnboardingRemaining = true
    
    init() {
        applyTheme() // ✅ Apply theme immediately on launch
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabBarView()
                    .onAppear {
                        applyTheme() // ✅ Ensure it updates when the app opens
                    }
            }
            .sheet(isPresented: $isOnboardingRemaining, onDismiss: {
                // Ensure the flag is set to false when the sheet is dismissed
                isOnboardingRemaining = false
            }) {
                OnboardingView(isOnboardingRemaining: $isOnboardingRemaining)
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

struct OnboardingView: View {
    @Binding var isOnboardingRemaining: Bool
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    // Define colors for each page
    private let pageColors: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .blue
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    title: "Welcome to Scan",
                    description: "Scan QR codes and Barcodes faster than the default scanner",
                    imageName: "qrcode.viewfinder",
                    isLastPage: false,
                    iconColor: pageColors[0],
                    currentPage: $currentPage,
                    totalPages: 5
                )
                .tag(0)
                
                OnboardingPage(
                    title: "Your Privacy Matters",
                    description: "All data is processed on your device and nothing leaves your phone without your permission",
                    imageName: "lock.shield",
                    isLastPage: false,
                    iconColor: pageColors[1],
                    currentPage: $currentPage,
                    totalPages: 5
                )
                .tag(1)
                
                OnboardingPage(
                    title: "Completely Free",
                    description: "No ads, no subscriptions, and no hidden costs. This app is completely free to use forever",
                    imageName: "gift",
                    isLastPage: false,
                    iconColor: pageColors[2],
                    currentPage: $currentPage,
                    totalPages: 5
                )
                .tag(2)
                
                OnboardingPage(
                    title: "Powerful Features",
                    description: "Generate QR codes and Barcodes, save history, and more",
                    imageName: "sparkles",
                    isLastPage: false,
                    iconColor: pageColors[3],
                    currentPage: $currentPage,
                    totalPages: 5
                )
                .tag(3)
                
                OnboardingPage(
                    title: "Ready to Start",
                    description: "Tap the button below to begin",
                    imageName: "checkmark.circle",
                    isLastPage: true,
                    iconColor: pageColors[4],
                    currentPage: $currentPage,
                    totalPages: 5,
                    action: {
                        // First dismiss the sheet
                        dismiss()
                        // Then set the flag to false after a slight delay to ensure proper dismissal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isOnboardingRemaining = false
                        }
                    }
                )
                .tag(4)
            }
            .interactiveDismissDisabled()
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

// Helper view for each onboarding page
struct OnboardingPage: View {
    let title: String
    let description: String
    let imageName: String
    let isLastPage: Bool
    let iconColor: Color
    @Binding var currentPage: Int
    let totalPages: Int
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Navigation buttons
            HStack {
                // Previous button
                if currentPage > 0 {
                    Button(action: {
                        Haptic.soft()
                        withAnimation {
                            currentPage -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                            .font(.headline)
                        }
                        .padding()
                        .foregroundColor(iconColor)
                        .background(iconColor.opacity(0.2))
                        .cornerRadius(16)
                    }
                } else {
                    Spacer()
                }
                
                Spacer()
                
                // Next or Get Started button
                if isLastPage {
                    Button(action: {
                        Haptic.soft()
                        action?()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(iconColor)
                            .cornerRadius(16)
                    }
                } else {
                    Button(action: {
                        Haptic.soft()
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        HStack {
                            Text("Next")
                            .font(.headline)
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundColor(iconColor)
                        .background(iconColor.opacity(0.2))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color.clear)
    }
}
