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


struct AnimatedNumberView: View {
    let value: Double
    let precision: Int
    @State private var animatedValue: Double
    @State private var hasInitialized: Bool = false
    
    init(value: Double, precision: Int) {
        self.value = value
        self.precision = precision
        self._animatedValue = State(initialValue: value)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Convert the number to a formatted string with specified precision
            ForEach(0..<formattedString.count, id: \.self) { index in
                let char = Array(formattedString)[index]
                if char.isNumber {
                    // For numeric characters, create a scrolling digit column
                    DigitScrollView(
                        targetDigit: Int(String(char)) ?? 0,
                        previousDigit: hasInitialized ? nil : Int(String(char)) ?? 0,
                        animationDuration: 0.8 // This value is not used anymore since we're using AppAnimations.digitRoll
                    )
                    .frame(width: 8) // Adjust width as needed
                } else {
                    // For non-numeric characters (like decimal point), just display them
                    Text(String(char))
                        .monospacedDigit()
                        .frame(height: 20)
                }
            }
        }
        .onAppear {
            // Slight delay to ensure view is fully rendered before animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasInitialized = true
                animatedValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            animatedValue = newValue
        }
    }
    
    // Helper to get the formatted string representation of the value
    private var formattedString: String {
        return String(format: "%.\(precision)f", animatedValue)
    }
}

struct DigitScrollView: View {
    let targetDigit: Int
    let previousDigit: Int?
    let animationDuration: Double
    @State private var animatingDigit: Int
    @State private var shouldAnimate: Bool = false
    
    init(targetDigit: Int, previousDigit: Int? = nil, animationDuration: Double) {
        self.targetDigit = targetDigit
        self.previousDigit = previousDigit
        self.animationDuration = animationDuration
        // Initialize with the target digit (no animation on first render)
        self._animatingDigit = State(initialValue: previousDigit ?? targetDigit)
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Create a scrolling column of digits
            VStack(spacing: 0) {
                ForEach(0...9, id: \.self) { digit in
                    Text("\(digit)")
                        .monospacedDigit()
                        .fontWeight(.medium)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .offset(y: -CGFloat(animatingDigit) * geometry.size.height)
            .animation(shouldAnimate ? AppAnimations.digitRoll : nil, value: animatingDigit)
        }
        .frame(height: 20) // Adjust height as needed
        .clipped() // Clip to show only the current digit
        .onAppear {
            // If previousDigit is nil, we're in the initial state and should animate
            if previousDigit == nil {
                // Slight delay to ensure view is fully rendered
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    shouldAnimate = true
                    animatingDigit = targetDigit
                }
            }
        }
        .onChange(of: targetDigit) { oldValue, newValue in
            shouldAnimate = true
            animatingDigit = targetDigit
        }
    }
}