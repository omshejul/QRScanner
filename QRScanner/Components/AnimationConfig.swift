import SwiftUI

// MARK: - Animation Configuration
struct QRAnimationConfig {
    // Animation state values
    static let initialScale: CGFloat = 0.5
    static let finalScale: CGFloat = 1.0
    static let initialOpacity: Double = 0.5
    static let finalOpacity: Double = 1.0
    static let initialBlur: CGFloat = 50 // range 0-100
    static let finalBlur: CGFloat = 0
    
    // Animation timing
    // static let scaleAnimation = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
    // static let opacityAnimation = Animation.easeIn(duration: 0.3)
    // static let blurAnimation = Animation.easeOut(duration: 0.6)
    // static let shareButtonAnimation = Animation.easeIn(duration: 0.3).delay(0.1)

    static let scaleAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)
    static let opacityAnimation = Animation.easeIn(duration: 0.2)
    static let blurAnimation = Animation.easeOut(duration: 0.3)
    static let shareButtonAnimation = Animation.easeIn(duration: 0.2)
    
    // Notification name for resetting animations
    static let resetAnimationNotification = NSNotification.Name("ResetQRAnimation")
    
    // Helper method to reset animation states
    static func resetAnimationStates(scale: Binding<CGFloat>, opacity: Binding<Double>, blur: Binding<CGFloat>) {
        scale.wrappedValue = initialScale
        opacity.wrappedValue = initialOpacity
        blur.wrappedValue = initialBlur
    }
    
    // Helper method to animate to final states
    static func animateToFinalStates(scale: Binding<CGFloat>, opacity: Binding<Double>, blur: Binding<CGFloat>) {
        withAnimation {
            scale.wrappedValue = finalScale
            opacity.wrappedValue = finalOpacity
            blur.wrappedValue = finalBlur
        }
    }
}

// MARK: - App-wide Animation Configuration
struct AppAnimations {
    // Button animations
    static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)
    static let buttonAction = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // Transition animations
    static let viewTransition = Animation.spring(response: 0.3)
    static let contentTransition = Animation.easeInOut(duration: 0.3)
    
    // Repeating animations
    static let scannerPulse = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
    static let scannerBounce = Animation.bouncy(duration: 1.2, extraBounce: 1).repeatForever(autoreverses: true)
    
    // Digit animations
    static let digitRoll = Animation.easeInOut(duration: 0.8)
} 