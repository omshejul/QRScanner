//
//  Utils.swift
//  QRScanner
//
//  Created by Om Shejul on 18/02/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
// MARK: - Haptic Feedback Component
struct Haptic {
    @AppStorage("vibrationEnabled") private static var vibrationEnabled = true
    
    static func soft() {
        guard vibrationEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func medium() {
        guard vibrationEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func strong() {
        guard vibrationEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func success() {
        guard vibrationEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        guard vibrationEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    static func warning() {
        guard vibrationEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}

// Helper function to get current theme mode
func getCurrentThemeMode() -> Bool {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        // Check if app has specific theme override
        if window.overrideUserInterfaceStyle != .unspecified {
            return window.overrideUserInterfaceStyle == .dark
        }
        
        // Use window's trait collection for more accurate results
        return window.traitCollection.userInterfaceStyle == .dark
    }
    
    // Fallback to system-wide trait collection if window isn't available
    return UITraitCollection.current.userInterfaceStyle == .dark
}