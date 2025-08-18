//
//  QRScannerApp.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import StoreKit

// MARK: - Review Manager
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    @AppStorage("appLaunchCount") private var appLaunchCount = 0
    @AppStorage("totalScanCount") private var totalScanCount = 0
    @AppStorage("totalUsageTimeMinutes") private var totalUsageTimeMinutes = 0
    @AppStorage("lastReviewRequestDate") private var lastReviewRequestDate = Date.distantPast
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    private var sessionStartTime = Date()
    
    init() {
        // Track app launch
        appLaunchCount += 1
        sessionStartTime = Date()
        
        print("📱 App Launch #\(appLaunchCount)")
        
        // Check if we should request a review
        checkForReviewRequest()
    }
    
    func trackQRScan() {
        totalScanCount += 1
        print("📷 QR Scan #\(totalScanCount)")
        
        // Check for review after significant scan activity
        checkForReviewRequest()
    }
    
    func trackSessionEnd() {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let sessionMinutes = Int(sessionDuration / 60)
        totalUsageTimeMinutes += sessionMinutes
        
        print("⏱️ Session: \(sessionMinutes) min, Total: \(totalUsageTimeMinutes) min")
    }
    
    private func checkForReviewRequest() {
        // Don't spam users - wait at least 60 days between requests
        let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastReviewRequestDate, to: Date()).day ?? 0
        
        // Conditions for requesting review:
        // 1. At least 3 scans OR 30 minutes of usage
        // 2. At least 5 app launches
        // 3. At least 5 days since last request (or never requested)
        // 4. User has completed onboarding
        
        let hasSignificantUsage = totalScanCount >= 3 || totalUsageTimeMinutes >= 30
        let hasMultipleLaunches = appLaunchCount >= 5
        let enoughTimePassed = daysSinceLastRequest >= 5 || !hasRequestedReview
        let completedOnboarding = !UserDefaults.standard.bool(forKey: "isOnboardingRemaining")
        
        if hasSignificantUsage && hasMultipleLaunches && enoughTimePassed && completedOnboarding {
            Task { @MainActor in
                requestReview()
            }
        }
    }
    
        @MainActor
    private func requestReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        print("⭐ Requesting App Store review...")
        
        AppStore.requestReview(in: windowScene)
        
        // Update tracking
        hasRequestedReview = true
        lastReviewRequestDate = Date()
    }
}

@main
struct QRScannerApp: App {
    @AppStorage("themeMode") private var themeMode = "Device" // Load stored theme
    @AppStorage("isOnboardingRemaining") var isOnboardingRemaining = true
	@Environment(\.scenePhase) private var scenePhase
	@State private var obfuscateSnapshot = false
    
    // Initialize review manager
    private let reviewManager = ReviewManager.shared
    
    init() {
        applyTheme() // ✅ Apply theme immediately on launch
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabBarView(obfuscateSnapshot: obfuscateSnapshot)
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
			.onChange(of: scenePhase) { _, newPhase in
				obfuscateSnapshot = newPhase != .active
				
				// Track session end when app goes to background
				if newPhase == .background {
					reviewManager.trackSessionEnd()
				}
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
