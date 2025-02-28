//
//  Buttons.swift
//  QRScanner
//
//  Created by Om Shejul on 28/02/25.
//

import SwiftUI

// MARK: - Generate Barcode Button
// MARK: - Common Generate Button
struct GenerateButton: View {
    let action: () -> Void
    let title: String
    let icon: String?
    let isDisabled: Bool
    let cornerRadius: CGFloat
    @State private var isAnimating = false
    @State private var isLoading = false
    
    init(
        action: @escaping () -> Void,
        title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        cornerRadius: CGFloat = 10
    ) {
        self.action = action
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Button(action: {
            Haptic.medium()
            self.isAnimating = true
            self.isLoading = true
            
            // Delay resetting the animation state to allow full animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.isAnimating = false
                    self.isLoading = false
                }
            }
            
            action()
        }) {
            HStack {
                if isLoading {
                    // Show spinner when loading
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.0)
                } else {
                    // Show normal content when not loading
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(EnhancedButtonStyle(isAnimating: $isAnimating))
        .disabled(isDisabled || isLoading)
        .padding(.horizontal)
    }
}

// MARK: - Enhanced Button Style
struct EnhancedButtonStyle: ButtonStyle {
    @Binding var isAnimating: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed || isAnimating ? 0.96 : 1)
            .brightness(configuration.isPressed || isAnimating ? -0.05 : 0)
            .rotationEffect(Angle(degrees: configuration.isPressed || isAnimating ? -0.2 : 0))
            .shadow(color: Color.black.opacity(configuration.isPressed || isAnimating ? 0.1 : 0.2), 
                   radius: configuration.isPressed || isAnimating ? 1 : 3, 
                   x: 0, 
                   y: configuration.isPressed || isAnimating ? 1 : 2)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed || isAnimating)
    }
}

// MARK: - Generate Barcode Button
struct GenerateBarcodeButton: View {
    let action: () -> Void
    let isDisabled: Bool

    var body: some View {
        GenerateButton(
            action: action,
            title: "Generate Barcode",
            icon: "barcode.viewfinder",
            isDisabled: isDisabled,
            cornerRadius: 12
        )
    }
}

// MARK: - Generate QR Code Button
struct GenerateQRButton: View {
    let action: () -> Void
    let isDisabled: Bool

    var body: some View {
        GenerateButton(
            action: action,
            title: "Generate QR Code",
            icon: "qrcode.viewfinder",
            isDisabled: isDisabled
        )
    }
}

// MARK: - Generate Social QR Button
struct GenerateSocialQRButton: View {
    let action: () -> Void
    
    var body: some View {
        GenerateButton(
            action: action,
            title: "Generate Social QR Code",
            icon: "qrcode.viewfinder"
        )
    }
}