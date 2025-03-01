//
//  Buttons.swift
//  QRScanner
//
//  Created by Om Shejul on 28/02/25.
//

import SwiftUI

// MARK: - Generate QR Code Button
struct GenerateQRButton: View {
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        AppButton(
            action: action,
            title: "Generate QR Code",
            icon: "qrcode.viewfinder",
            isDisabled: isDisabled
        )
    }
}

// MARK: - Generate Barcode Button
struct GenerateBarcodeButton: View {
    let action: () -> Void
    let isDisabled: Bool
    
    var body: some View {
        AppButton(
            action: action,
            title: "Generate Barcode",
            icon: "barcode.viewfinder",
            isDisabled: isDisabled,
            cornerRadius: 12
        )
    }
}

// MARK: - Generate Social QR Button
struct GenerateSocialQRButton: View {
    let action: () -> Void
    
    var body: some View {
        AppButton(
            action: action,
            title: "Generate Social QR Code",
            icon: "qrcode.viewfinder"
        )
    }
}

// CUSTOM BUTTON

// MARK: - Generic App Button
struct AppButton: View {
    // MARK: - Button Style Enum
    enum AppButtonStyle: Equatable {
        case primary
        case secondary
        case destructive
        case outline
        case plain
        case custom(backgroundColor: Color, foregroundColor: Color)
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.blue
            case .secondary:
                return Color.gray.opacity(0.2)
            case .destructive:
                return Color.red
            case .outline, .plain:
                return Color.clear
            case .custom(let backgroundColor, _):
                return backgroundColor
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return Color.white
            case .secondary:
                return Color.primary
            case .outline:
                return Color.blue
            case .plain:
                return Color.blue
            case .custom(_, let foregroundColor):
                return foregroundColor
            }
        }
        
        var hasBorder: Bool {
            switch self {
            case .outline:
                return true
            default:
                return false
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return Color.blue
            default:
                return Color.clear
            }
        }
    }
    
    // MARK: - Button Size Enum
    enum ButtonSize {
        case small
        case medium
        case large
        case custom(height: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat)
        
        var height: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 44
            case .large:
                return 56
            case .custom(let height, _, _):
                return height
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small:
                return 12
            case .medium:
                return 16
            case .large:
                return 20
            case .custom(_, let horizontalPadding, _):
                return horizontalPadding
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small:
                return 6
            case .medium:
                return 10
            case .large:
                return 14
            case .custom(_, _, let verticalPadding):
                return verticalPadding
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:
                return 14
            case .medium:
                return 16
            case .large:
                return 20
            case .custom:
                return 16
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .small:
                return .medium
            case .medium, .large, .custom:
                return .semibold
            }
        }
    }
    
    // MARK: - Properties
    let action: () -> Void
    let title: String
    let icon: String?
    let trailingIcon: String?
    let style: AppButtonStyle
    let size: ButtonSize
    let isDisabled: Bool
    let cornerRadius: CGFloat
    let isFullWidth: Bool
    var showLoadingIndicator: Bool
    var hapticFeedback: Bool
    
    @State private var isAnimating = false
    @State private var isLoading = false
    
    // MARK: - Initializer
    init(
        action: @escaping () -> Void,
        title: String,
        icon: String? = nil,
        trailingIcon: String? = nil,
        style: AppButtonStyle = .primary,
        size: ButtonSize = .medium,
        isDisabled: Bool = false,
        cornerRadius: CGFloat = 10,
        isFullWidth: Bool = true,
        showLoadingIndicator: Bool = true,
        hapticFeedback: Bool = true
    ) {
        self.action = action
        self.title = title
        self.icon = icon
        self.trailingIcon = trailingIcon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.cornerRadius = cornerRadius
        self.isFullWidth = isFullWidth
        self.showLoadingIndicator = showLoadingIndicator
        self.hapticFeedback = hapticFeedback
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if hapticFeedback {
                Haptic.medium()
            }
            
            if showLoadingIndicator {
                self.isAnimating = true
                self.isLoading = true
                
                // Delay resetting the animation state to allow full animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        self.isAnimating = false
                        self.isLoading = false
                    }
                }
            }
            
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading && showLoadingIndicator {
                    // Show spinner when loading
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    // Show normal content when not loading
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: size.fontWeight))
                    }
                    
                    Text(title)
                        .font(.system(size: size.iconSize + 2, weight: size.fontWeight))
                    
                    if let trailingIcon = trailingIcon {
                        Spacer()
                        Image(systemName: trailingIcon)
                            .font(.system(size: size.iconSize, weight: size.fontWeight))
                    }
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil, minHeight: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(isDisabled ? Color.gray.opacity(0.3) : style.backgroundColor)
            .foregroundColor(isDisabled ? Color.gray : style.foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(style.hasBorder ? (isDisabled ? Color.gray : style.borderColor) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: (style == .plain || style == .outline || isDisabled) ? Color.clear : Color.black.opacity(0.1), 
                    radius: 2, x: 0, y: 1)
        }
        .buttonStyle(EnhancedButtonStyle(isAnimating: $isAnimating))
        .disabled(isDisabled || isLoading)
        .padding(.horizontal, isFullWidth ? 16 : 0)
    }
    
    // MARK: - Modifier Methods
    func withoutAnimation() -> some View {
        let button = self
        button.isAnimating = false
        return button
    }
    
    func withoutHaptic() -> some View {
        var button = self
        button.hapticFeedback = false
        return button
    }
    
    func withoutLoading() -> some View {
        var button = self
        button.showLoadingIndicator = false
        return button
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


// MARK: - Button Extensions
extension AppButton {
    // Preset button styles
    static func primary(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> AppButton {
        AppButton(
            action: action,
            title: title,
            icon: icon,
            style: .primary,
            isDisabled: isDisabled
        )
    }
    
    static func secondary(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> AppButton {
        AppButton(
            action: action,
            title: title,
            icon: icon,
            style: .secondary,
            isDisabled: isDisabled
        )
    }
    
    static func destructive(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> AppButton {
        AppButton(
            action: action,
            title: title,
            icon: icon,
            style: .destructive,
            isDisabled: isDisabled
        )
    }
    
    static func outline(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> AppButton {
        AppButton(
            action: action,
            title: title,
            icon: icon,
            style: .outline,
            isDisabled: isDisabled
        )
    }
    
    static func plain(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> AppButton {
        AppButton(
            action: action,
            title: title,
            icon: icon,
            style: .plain,
            isDisabled: isDisabled,
            isFullWidth: false,
            showLoadingIndicator: false
        )
    }
    
    static func icon(
        icon: String,
        action: @escaping () -> Void,
        style: AppButtonStyle = .primary,
        size: ButtonSize = .medium,
        isDisabled: Bool = false
    ) -> some View {
        AppButton(
            action: action,
            title: "",
            icon: icon,
            style: style,
            size: size,
            isDisabled: isDisabled,
            isFullWidth: false
        )
        .frame(width: size.height, height: size.height)
    }
}
