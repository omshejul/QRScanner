//
//  ScanResultView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation
import RSBarcodes_Swift
import LinkPresentation
import Contacts
import ContactsUI
import NetworkExtension
import EventKit
import EventKitUI
//import URLDetectorUtility

struct ScanResultView: View {
    let scannedText: String
    let barcodeType: AVMetadataObject.ObjectType
    let onDismiss: () -> Void
    let isFromHistory: Bool
    
    init(scannedText: String, barcodeType: AVMetadataObject.ObjectType, isFromHistory: Bool = false, onDismiss: @escaping () -> Void) {
        self.scannedText = scannedText
        self.barcodeType = barcodeType
        self.isFromHistory = isFromHistory
        self.onDismiss = onDismiss
    }
    
    @State private var generatedBarcode: UIImage?
    @State private var isGeneratingQR = false
    @State private var isSharingQR = false
    @State private var qrShareURL: URL?
    @State private var isURL = false
    @State private var formattedURLString: String = ""
    @State private var extractedURLs: [URL] = []
    

    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Display the barcode/QR code image
                if barcodeType == .qr {
                    generateQRCode(from: scannedText, isDarkMode: getCurrentThemeMode())
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .padding()
                        .onDrag {
                            // Generate a high-quality QR code for dragging (same as for sharing)
                            let isDark = getCurrentThemeMode()
                            if let image = generateQRCodeImage(from: scannedText, isDarkMode: isDark, size: 1024) {
                                // Create a provider with the high-res image
                                return NSItemProvider(object: image)
                            }
                            // Fallback to empty provider if image generation fails
                            return NSItemProvider()
                        }
                } else if let barcode = generatedBarcode {
                    Image(uiImage: barcode)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .onDrag {
                            // Create a high-res version of the barcode for dragging
                            // Determine optimal size based on barcode type
                            let size: CGSize
                            switch barcodeType {
                            case .aztec:
                                size = CGSize(width: 1024, height: 1024)
                            case .pdf417:
                                size = CGSize(width: 1536, height: 1024)
                            case .ean8, .upce:
                                size = CGSize(width: 1536, height: 512)
                            case .ean13:
                                size = CGSize(width: 2048, height: 512)
                            case .code128, .code93:
                                size = CGSize(width: 2048, height: 512)
                            case .code39, .code39Mod43:
                                size = CGSize(width: 2560, height: 512)
                            case .itf14, .interleaved2of5:
                                size = CGSize(width: 2560, height: 512)
                            default:
                                size = CGSize(width: 2048, height: 512)
                            }
                            
                            // Create high-res image
                            UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
                            UIColor.white.setFill()
                            UIRectFill(CGRect(origin: .zero, size: size))
                            
                            let originalAspect = barcode.size.width / barcode.size.height
                            let horizontalPadding: CGFloat = 64
                            let targetAspect = (size.width - (2 * horizontalPadding)) / size.height
                            
                            let drawRect: CGRect
                            if originalAspect > targetAspect {
                                let width = size.width - (2 * horizontalPadding)
                                let height = width / originalAspect
                                let y = (size.height - height) / 2
                                drawRect = CGRect(x: horizontalPadding, y: y, width: width, height: height)
                            } else {
                                let height = size.height
                                let width = height * originalAspect
                                let x = (size.width - width) / 2
                                drawRect = CGRect(x: x, y: 0, width: width, height: height)
                            }
                            
                            let context = UIGraphicsGetCurrentContext()
                            context?.interpolationQuality = .none
                            context?.setShouldAntialias(false)
                            barcode.draw(in: drawRect)
                            
                            if let highQualityImage = UIGraphicsGetCurrentContext()?.makeImage() {
                                let highResBarcode = UIImage(cgImage: highQualityImage)
                                UIGraphicsEndImageContext()
                                return NSItemProvider(object: highResBarcode)
                            }
                            
                            UIGraphicsEndImageContext()
                            // Fallback to original barcode if high-res creation fails
                            return NSItemProvider(object: barcode)
                        }
                }
                
                // Link Preview for URLs
                if isURL && URLDetectorUtility.shared.isValidWebLink(formattedURLString) {
                    VStack(alignment: .leading) {
                        Text("LINK PREVIEW")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                        
                        RichLinkPreview(urlString: formattedURLString)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                    }
                    // Data Section
                    SectionView(title: "DATA", content: scannedText)
                    
                    // Type Section for URLs
                    SectionView(title: "TYPE", content: determineQRType(from: scannedText, type: barcodeType))
                } else if !extractedURLs.isEmpty, let firstURL = extractedURLs.first, URLDetectorUtility.shared.isValidWebLink(firstURL.absoluteString) {
                    // Show link preview for extracted URLs
                    VStack(alignment: .leading) {
                        Text("LINK PREVIEW")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                        
                        RichLinkPreview(urlString: firstURL.absoluteString)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Data Section
                    SectionView(title: "DATA", content: scannedText)
                    
                    // Type Section
                    SectionView(title: "TYPE", content: determineQRType(from: scannedText, type: barcodeType))
                } else {
                    // Data Section (only shown for non-URLs)
                    SectionView(title: "DATA", content: scannedText)
                    
                    // Type Section
                    SectionView(title: "TYPE", content: determineQRType(from: scannedText, type: barcodeType))
                }
                
                // UPI Details Expandable View
                if scannedText.lowercased().starts(with: "upi://pay") {
                    UPIDetailView(upiString: scannedText)
                }
                
                // Action Buttons
                ActionButtonsView(
                    scannedText: scannedText, 
                    barcodeType: barcodeType, 
                    generatedBarcode: generatedBarcode,
                    extractedURLs: extractedURLs,
                    formattedURLString: formattedURLString,
                    isURL: isURL,
                    onDismiss: onDismiss,
                    isFromHistory: isFromHistory
                )
                
                Spacer()
            }
            .padding(4)
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if barcodeType != .qr {
                generateBarcode()
            }
            
            // Enhanced URL detection
            checkForURLs()
        }
    }
    
    private func checkForURLs() {
        // First check if it's a direct URL
        isURL = URLDetectorUtility.shared.isValidWebLink(scannedText)
        
        if isURL {
            formattedURLString = URLDetectorUtility.shared.formatURLString(scannedText)
            // Double check that the formatted URL is valid
            isURL = URLDetectorUtility.shared.isValidWebLink(formattedURLString)
        } else {
            // Try to extract URLs from text
            extractedURLs = URLDetectorUtility.shared.extractURLs(from: scannedText)
        }
    }
    
    private func generateBarcode() {
        let generator = RSUnifiedCodeGenerator.shared
        let objectType = barcodeType.rawValue
        
        if let image = generator.generateCode(scannedText, machineReadableCodeObjectType: objectType) {
            generatedBarcode = image
        }
    }
    
    // MARK: - Generate QR Code Based on Theme
    func generateQRCode(from string: String, isDarkMode: Bool) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(string.data(using: .utf8), forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let colorFilter = CIFilter.falseColor()
            colorFilter.setValue(outputImage, forKey: "inputImage")
            
            // ✅ Set QR color based on theme
            let qrColor = isDarkMode ? CIColor.white : CIColor.black
            let bgColor = !isDarkMode ? CIColor.white : CIColor.black
            
            colorFilter.setValue(qrColor, forKey: "inputColor0")
            colorFilter.setValue(bgColor, forKey: "inputColor1")
            
            if let cgimg = context.createCGImage(colorFilter.outputImage!, from: outputImage.extent) {
                return Image(uiImage: UIImage(cgImage: cgimg))
            }
        }
        
        return Image(systemName: "xmark.circle") // Fallback in case of error
    }
    
    // MARK: - Determine QR Code Type
    func determineQRType(from text: String, type: AVMetadataObject.ObjectType) -> String {
        // First check the actual barcode type
        let baseType = getBarcodeTypeName(type)
        
        // Then check for specific content patterns
        if text.starts(with: "upi://pay") {
            return "\(baseType) (UPI Payment)"
        } else if text.starts(with: "http") {
            return "\(baseType) (URL)"
        } else if text.contains("@") {
            return "\(baseType) (Email)"
        } else if text.contains("WIFI:") {
            return "\(baseType) (WiFi)"
        } else if text.starts(with: "BEGIN:VCARD") {
            return "\(baseType) (Contact)"
        } else if text.starts(with: "tel:") {
            return "\(baseType) (Phone)"
        } else if text.starts(with: "smsto:") || text.starts(with: "sms:") {
            return "\(baseType) (SMS)"
        } else if text.starts(with: "geo:") {
            return "\(baseType) (Location)"
        } else if text.allSatisfy({ $0.isNumber }) {
            return baseType
        } else {
            return "\(baseType) (Text)"
        }
    }
    
    private func getBarcodeTypeName(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr:
            return "QR Code"
        case .ean8:
            return "EAN-8"
        case .ean13:
            return "EAN-13"
        case .pdf417:
            return "PDF417"
        case .aztec:
            return "Aztec"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .code93:
            return "Code 93"
        case .dataMatrix:
            return "Data Matrix"
        case .interleaved2of5:
            return "Interleaved 2 of 5"
        case .itf14:
            return "ITF-14"
        case .upce:
            return "UPC-E"
        default:
            return "Barcode"
        }
    }
    
    private func getBarcodeIcon(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .ean8, .ean13, .upce:
            return "barcode.viewfinder"
        case .pdf417:
            return "doc.viewfinder"
        case .aztec:
            return "square.grid.3x3.square"
        case .dataMatrix:
            return "square.grid.2x2"
        case .code128, .code39, .code93, .interleaved2of5, .itf14:
            return "barcode"
        default:
            return "viewfinder"
        }
    }
}

// MARK: - Reusable Section View
struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(content)
                .font(.system(size: 16, weight: .medium))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}

// MARK: - UPI Details Expandable View
struct UPIDetailView: View {
    let upiString: String
    @State private var isExpanded = false
    @State private var copiedParam: String? = nil
    @State private var stableOrderedParams: [(key: String, value: String)] = []
    
    // Parse UPI parameters
    private var upiParams: [String: String] {
        guard upiString.hasPrefix("upi://pay?") else { return [:] }
        
        // Extract query parameters
        let queryString = upiString.replacingOccurrences(of: "upi://pay?", with: "")
        let pairs = queryString.components(separatedBy: "&")
        
        // Build dictionary
        var params = [String: String]()
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0]
                let value = components[1].removingPercentEncoding ?? components[1]
                params[key] = value
            }
        }
        
        return params
    }
    
    private var parameterLabels: [String: String] {
        return [
            "pa": "UPI ID",
            "pn": "Payee Name",
            "am": "Amount",
            "cu": "Currency",
            "tn": "Note",
            "tr": "Transaction Ref",
            "mc": "Merchant Code",
            "tid": "Transaction ID",
            "url": "URL",
            "refUrl": "Reference URL"
        ]
    }
    
    private var parameterIcons: [String: String] {
        return [
            "pa": "person.crop.circle",
            "pn": "person.text.rectangle",
            "am": "indianrupeesign",
            "cu": "dollarsign.circle",
            "tn": "text.bubble",
            "tr": "number",
            "mc": "bag.circle",
            "tid": "number.square",
            "url": "link",
            "refUrl": "arrow.up.right.square"
        ]
    }
    
    // Color scheme for the parameters
    private func colorForParam(_ key: String) -> Color {
        switch key {
        case "pa":
            return Color.blue
        case "pn":
            return Color.purple
        case "am":
            return Color.green
        case "cu":
            return Color.orange
        case "tn":
            return Color.teal
        case "tr":
            return Color.pink
        case "mc":
            return Color.indigo
        case "tid":
            return Color.gray
        case "url", "refUrl":
            return Color.blue
        default:
            return Color.secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            UPIHeaderButton(
                isExpanded: $isExpanded
            )
            
            if isExpanded {
                UPIDetailsContent(
                    upiString: upiString,
                    stableOrderedParams: stableOrderedParams,
                    parameterIcons: parameterIcons,
                    parameterLabels: parameterLabels,
                    colorForParam: colorForParam,
                    copiedParam: $copiedParam,
                    formatValue: formatValue
                )
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 5)
                .padding(.bottom, 10)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3)),
                    removal: .opacity.animation(.easeOut(duration: 0.25))
                ))
                // Add blur animation
                .blur(radius: isExpanded ? 0 : 10)
                .animation(.easeOut(duration: 0.3), value: isExpanded)
            }
        }
        .onAppear {
            // Sort parameters once on appear and store in stable order
            stableOrderedParams = upiParams.sorted { paramOrder($0.key) < paramOrder($1.key) }
        }
    }
    
    // Format values for display
    private func formatValue(key: String, value: String) -> String {
        switch key {
        case "am":
            if let amount = Double(value) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                return formatter.string(from: NSNumber(value: amount)) ?? value
            }
            return value
        case "cu":
            // Format currency code
            if value == "INR" {
                return "₹ (Indian Rupee)"
            }
            return value
        default:
            return value
        }
    }
    
    // Helper to sort parameters in a logical order
    private func paramOrder(_ key: String) -> Int {
        let orderMap = [
            "pa": 1,   // UPI ID first
            "pn": 2,   // Name second
            "am": 3,   // Amount third
            "cu": 4,   // Currency fourth
            "tn": 5,   // Note
            "tr": 6,   // Transaction reference
            "mc": 7,   // Merchant code
            "tid": 8,  // Transaction ID
            "url": 9,
            "refUrl": 10
        ]
        
        return orderMap[key] ?? 100 // Unknown keys at the end
    }
}

// Header button for UPI Details
struct UPIHeaderButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("UPI PAYMENT DETAILS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                Text(isExpanded ? "Hide Details" : "View Details")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// Content view for UPI details when expanded
struct UPIDetailsContent: View {
    let upiString: String
    let stableOrderedParams: [(key: String, value: String)]
    let parameterIcons: [String: String]
    let parameterLabels: [String: String]
    let colorForParam: (String) -> Color
    @Binding var copiedParam: String?
    let formatValue: (String, String) -> String
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Payment Information")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            Divider()
                .padding(.horizontal, 15)
            
            // Parameter rows
            UPIParameterList(
                stableOrderedParams: stableOrderedParams,
                parameterIcons: parameterIcons,
                parameterLabels: parameterLabels,
                colorForParam: colorForParam,
                copiedParam: $copiedParam,
                formatValue: formatValue
            )
            
            // Footer with schema info
            UPIDetailsFooter(
                upiString: upiString,
                copiedParam: $copiedParam
            )
        }
    }
}

// Parameter list view
struct UPIParameterList: View {
    let stableOrderedParams: [(key: String, value: String)]
    let parameterIcons: [String: String]
    let parameterLabels: [String: String]
    let colorForParam: (String) -> Color
    @Binding var copiedParam: String?
    let formatValue: (String, String) -> String
    
    var body: some View {
        ForEach(Array(stableOrderedParams.enumerated()), id: \.element.key) { index, param in
            let key = param.key
            let value = param.value
            
            UPIParameterRow(
                key: key,
                value: value,
                icon: parameterIcons[key] ?? "circle",
                label: parameterLabels[key] ?? key.uppercased(),
                color: colorForParam(key),
                copiedParam: $copiedParam,
                formatValue: formatValue
            )
            
            // Only show divider if not the last item
            if index < stableOrderedParams.count - 1 {
                Divider()
                    .padding(.leading, 45)
                    .padding(.trailing, 15)
            }
        }
    }
}

// Single parameter row
struct UPIParameterRow: View {
    let key: String
    let value: String
    let icon: String
    let label: String
    let color: Color
    @Binding var copiedParam: String?
    let formatValue: (String, String) -> String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 26, height: 26)
                    .background(
                        color.opacity(0.2)
                    )
                    .cornerRadius(6)
                
                // Label
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Tappable value area
                Button(action: {
                    UIPasteboard.general.string = value
                    copiedParam = key
                    
                    // Show haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // Reset copied status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if copiedParam == key {
                            copiedParam = nil
                        }
                    }
                }) {
                    HStack {
                        Text(formatValue(key, value))
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            
                        // Always show copy icon (for clarity that it's clickable)
                        Image(systemName: copiedParam == key ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 8))
                            .foregroundColor(copiedParam == key ? .green : .secondary)
                            .opacity(0.8)
                            .rotationEffect(copiedParam == key ? .degrees(360) : .degrees(0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: copiedParam)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(copiedParam == key ? 
                                  Color.green.opacity(0.15) : 
                                  Color(UIColor.systemGray5).opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(copiedParam == key ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }
}

// Footer view for UPI details
struct UPIDetailsFooter: View {
    let upiString: String
    @Binding var copiedParam: String?
    @State private var isUpiCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.horizontal, 15)
            
            HStack {
                Text("UPI Schema")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = upiString
                    
                    // Show haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // Set copied state to true
                    isUpiCopied = true
                    
                    // Reset copied status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isUpiCopied = false
                    }
                }) {
                    HStack {
                        Text(isUpiCopied ? "UPI URL Copied!" : "Copy Full UPI URL")
                            .font(.caption)
                            .foregroundColor(isUpiCopied ? .green : .blue)
                        
                        Image(systemName: isUpiCopied ? "checkmark.circle" : "link.circle")
                            .font(.system(size: 12))
                            .foregroundColor(isUpiCopied ? .green : .blue)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isUpiCopied ? 
                                  Color.green.opacity(0.15) : 
                                  Color.blue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isUpiCopied ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isUpiCopied)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .background(Color.blue.opacity(0.05))
    }
}

// MARK: - Action Buttons with Additional Actions
struct ActionButtonsView: View {
    let scannedText: String
    let barcodeType: AVMetadataObject.ObjectType
    let generatedBarcode: UIImage?
    let extractedURLs: [URL]
    let formattedURLString: String
    let isURL: Bool
    let onDismiss: () -> Void
    let isFromHistory: Bool
    @State private var isCopied = false
    @State private var isSharingData = false
    @State private var isSharingQR = false
    @State private var qrImage: UIImage?
    @State private var isGeneratingQR = false
    @State private var qrShareURL: URL?
    @State private var detectedURL: URL?
    
    // MARK: - Get Region-Specific Amazon URL
    private func getAmazonDomain() -> String {
        let countryCode = Locale.current.region?.identifier ?? "US"
        
        let amazonDomains: [String: String] = [
            "US": "amazon.com",
            "IN": "amazon.in",
            "UK": "amazon.co.uk",
            "CA": "amazon.ca",
            "DE": "amazon.de",
            "FR": "amazon.fr",
            "IT": "amazon.it",
            "ES": "amazon.es",
            "JP": "amazon.co.jp",
            "AU": "amazon.com.au",
            "AE": "amazon.ae",
            "BR": "amazon.com.br"
        ]
        
        return amazonDomains[countryCode] ?? "amazon.com"
    }
    
    private func getAmazonSearchURL(for query: String) -> URL? {
        let domain = getAmazonDomain()
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.\(domain)/s?k=\(encodedQuery)")
    }
    
    // MARK: - Extract Coordinates from geo: URL
    private func extractCoordinates(from geoString: String) -> (latitude: Double, longitude: Double)? {
        // Remove the "geo:" prefix and any additional parameters
        let coordinateString = geoString
            .replacingOccurrences(of: "geo:", with: "")
            .components(separatedBy: ";").first ?? ""
        
        // Split by comma to get latitude and longitude
        let components = coordinateString.components(separatedBy: ",")
        guard components.count >= 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            return nil
        }
        
        return (latitude, longitude)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ACTION")
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                
                // Check for URLs using URLDetectorUtility
                Group {
                    if let url = URL(string: scannedText), scannedText.lowercased().starts(with: "http") {
                        // Direct HTTP URL
                        ActionButton(icon: "safari", text: "Open in Safari") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                    } else if isURL, let url = URL(string: formattedURLString), URLDetectorUtility.shared.isValidWebLink(formattedURLString) {
                        // Valid web link detected by URLDetectorUtility
                        ActionButton(icon: "safari", text: "Open in Safari") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                    } else if !extractedURLs.isEmpty, let firstURL = extractedURLs.first, URLDetectorUtility.shared.isValidWebLink(firstURL.absoluteString) {
                        // URL extracted from text
                        ActionButton(icon: "safari", text: "Open URL in Safari") {
                            UIApplication.shared.open(firstURL)
                            onDismiss()
                        }
                        Divider()
                        
                        // Add a search option specifically for the extracted URL domain
                        if let host = firstURL.host {
                            ActionButton(icon: "magnifyingglass", text: "Search for more about \(host)") {
                                if let encodedQuery = host.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                   let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
                                    UIApplication.shared.open(url)
                                    onDismiss()
                                }
                            }
                            Divider()
                        }
                    }
                }
                
                // Location QR Code Handling
                if scannedText.lowercased().starts(with: "geo:") {
                    if let coordinates = extractCoordinates(from: scannedText) {
                        let lat = coordinates.latitude
                        let lon = coordinates.longitude
                        
                        // Apple Maps
                        ActionButton(icon: "apple.logo", text: "Open in Apple Maps") {
                            let url = URL(string: "https://maps.apple.com/?q=\(lat),\(lon)")!
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                        
                        // Google Maps
                        ActionButton(icon: "map", text: "Open in Google Maps") {
                            let url = URL(string: "https://www.google.com/maps?q=\(lat),\(lon)")!
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                        
                        // Waze
                        ActionButton(icon: "car", text: "Open in Waze") {
                            let url = URL(string: "https://waze.com/ul?ll=\(lat),\(lon)")!
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                        
                        // Open in Safari (generic map link)
                        ActionButton(icon: "safari", text: "Open in Safari") {
                            let url = URL(string: "https://www.google.com/search?q=\(lat),\(lon)")!
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                        Divider()
                    }
                }
                
                // Plain text handling - Add search option for text content
                // Only show this for plain text that doesn't match other formats
                // AND doesn't have extracted URLs
                if barcodeType == .qr && 
                    !scannedText.lowercased().starts(with: "http") &&
                    !scannedText.lowercased().starts(with: "geo:") &&
                    !scannedText.lowercased().starts(with: "mailto:") &&
                    !scannedText.lowercased().starts(with: "matmsg:") &&
                    !scannedText.lowercased().starts(with: "tel:") &&
                    !scannedText.lowercased().starts(with: "smsto:") &&
                    !scannedText.lowercased().starts(with: "sms:") &&
                    !scannedText.lowercased().starts(with: "upi://") &&
                    !scannedText.lowercased().starts(with: "fido:/") && // Passkey URLs
                    !scannedText.lowercased().contains("wifi:") &&
                    !scannedText.lowercased().contains("begin:vcard") &&
                    !scannedText.lowercased().contains("begin:vevent") && // Calendar events
                    extractedURLs.isEmpty && // Don't show search if we already have URLs
                    !isURL { // Don't show search if the text itself is a URL
                    
                    // Search in Safari
                    ActionButton(icon: "safari", text: "Search in Safari") {
                        if let encodedQuery = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                }
                
                if scannedText.lowercased().starts(with: "fido:/") {
                    ActionButton(icon: "key.horizontal", text: "Open Passkey Authentication") {
                        if let url = URL(string: scannedText) {
                            UIApplication.shared.open(url) { success in
                                if success {
                                    onDismiss()
                                } else {
                                    // Handle case where no app can handle passkey URLs
                                    print("No app available to handle passkey URL: \(scannedText)")
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Only auto-open passkey URLs if not viewing from history
                        if !isFromHistory,
                           let autoOpenPasskey = UserDefaults.standard.value(forKey: "autoOpenPasskey") as? Bool,
                           autoOpenPasskey {
                            // Auto-open passkey URL
                            if let url = URL(string: scannedText) {
                                UIApplication.shared.open(url) { success in
                                    if success {
                                        onDismiss()
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                }
                
                if scannedText.lowercased().starts(with: "upi://pay") {
                    ActionButton(icon: "indianrupeesign.circle", text: "Pay with UPI") {
                        showUPIAppSelection(for: scannedText)
                        onDismiss()
                    }
                    .onAppear {
                        // Only auto-open UPI apps if not viewing from history
                        if !isFromHistory,
                           let autoOpenUPI = UserDefaults.standard.value(forKey: "autoOpenUPI") as? Bool,
                           autoOpenUPI,
                           let defaultApp = UserDefaults.standard.string(forKey: "defaultUPIApp"),
                           defaultApp != "None" {
                            // Open directly with the default app
                            openUPILink(scannedText, with: defaultApp)
                            onDismiss()
                        }
                    }
                    Divider()
                }
                
                if scannedText.lowercased().starts(with: "mailto:") || scannedText.starts(with: "MATMSG:") {
                    ActionButton(icon: "envelope", text: "Send Email") {
                        openMATMSGEmail(scannedText)
                        onDismiss()
                    }
                    Divider()
                }
                
                if scannedText.lowercased().starts(with: "tel:") {
                    ActionButton(icon: "phone", text: "Call") {
                        if let url = URL(string: scannedText) {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                }
                
                if scannedText.lowercased().starts(with: "smsto:") || scannedText.lowercased().starts(with: "sms:") {
                    ActionButton(icon: "message", text: "Send SMS") {
                        // Handle both SMSTO: and sms: formats
                        let formattedSMS: String
                        
                        if scannedText.lowercased().starts(with: "smsto:") {
                            // SMSTO:number:message format
                            let content = scannedText.replacingOccurrences(of: "SMSTO:", with: "").replacingOccurrences(of: "smsto:", with: "")
                            let components = content.components(separatedBy: ":")
                            
                            if components.count >= 2 {
                                let phoneNumber = components[0]
                                let message = components[1].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                formattedSMS = "sms:\(phoneNumber)?body=\(message)"
                            } else {
                                // Just the phone number
                                formattedSMS = "sms:\(content)"
                            }
                        } else {
                            // Already in sms: format
                            formattedSMS = scannedText
                        }
                        
                        if let url = URL(string: formattedSMS) {
                            UIApplication.shared.open(url)
                            onDismiss()
                        } else {
                            // Fallback for compatibility
                            if let url = URL(string: scannedText) {
                                UIApplication.shared.open(url)
                                onDismiss()
                            }
                        }
                    }
                    Divider()
                }
                
                if scannedText.lowercased().contains("wifi:") {
                    let components = scannedText
                        .replacingOccurrences(of: "WIFI:", with: "")
                        .components(separatedBy: ";")
                        .reduce(into: [String: String]()) { dict, pair in
                            let parts = pair.components(separatedBy: ":")
                            if parts.count == 2 {
                                dict[parts[0]] = parts[1]
                            }
                        }
                    
                    let wifiPassword = components["P"] ?? "No Password Found"
                    let wifiSSID = components["S"] ?? "Unknown Network"
                    
                    ActionButton(icon: "wifi", text: "Connect to Wi-Fi") {
                        connectToWiFi(ssid: wifiSSID, passphrase: wifiPassword)
                        onDismiss()
                    }
                    Divider()
                    
                    ActionButton(icon: "doc.on.doc", text: "Copy WiFi Password") {
                        UIPasteboard.general.string = wifiPassword
                    }
                    Divider()
                }
                
                if scannedText.lowercased().contains("begin:vcard") {
                    ActionButton(icon: "person.crop.circle", text: "Save Contact") {
                        saveContact(scannedText)
                    }
                    Divider()
                }
                
                if scannedText.lowercased().contains("begin:vevent") {
                    ActionButton(icon: "calendar.badge.plus", text: "Add to Calendar") {
                        showEventEditController(scannedText)
                    }
                    Divider()
                }
                
                // Product Search Options for Barcodes
                if [.ean8, .ean13, .upce, .code128].contains(barcodeType) && scannedText.allSatisfy({ $0.isNumber }) {
                    ActionButton(icon: "cart", text: "Search on Amazon.\(getAmazonDomain().split(separator: ".").last ?? "com")") {
                        if let url = getAmazonSearchURL(for: scannedText) {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                    
                    ActionButton(icon: "magnifyingglass", text: "Search on Google") {
                        if let encodedQuery = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://www.google.com/search?q=\(encodedQuery)") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                    
                    ActionButton(icon: "magnifyingglass.circle.fill", text: "Search on BarcodeLookup") {
                        if let encodedQuery = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://www.barcodelookup.com/\(encodedQuery)") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                    ActionButton(icon: "cart.circle.fill", text: "Search on Go-UPC") {
                        if let encodedQuery = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://go-upc.com/search?q=/\(encodedQuery)") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                    ActionButton(icon: "checkmark.seal.fill", text: "Search on GS1 (Official)") {
                        if let encodedQuery = scannedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://www.gs1.org/services/verified-by-gs1/results?gtin=\(encodedQuery)") {
                            UIApplication.shared.open(url)
                            onDismiss()
                        }
                    }
                    Divider()
                }
                
                ActionButton(icon: "doc.on.doc", text: isCopied ? "Copied" : "Copy Data") {
                    UIPasteboard.general.string = scannedText
                    isCopied = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }
                Divider()
                
                // ✅ Added Two Share Options: Data & QR Code
                ActionButton(icon: "square.and.arrow.up", text: "Share Data") {
                    isSharingData = true
                }
                .sheet(isPresented: $isSharingData) {
                    ShareSheet(activityItems: [scannedText])
                }
                Divider()
                
                // Only show QR Code sharing for QR codes
                Group {
                    if barcodeType == .qr {
                        // QR Code sharing
                        ActionButton(icon: "qrcode", text: isGeneratingQR ? "Please Wait..." : "Share QR Code") {
                            if !isGeneratingQR {
                                isGeneratingQR = true
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                                    let isDark = window.overrideUserInterfaceStyle == .unspecified ?
                                    UIScreen.main.traitCollection.userInterfaceStyle == .dark :
                                    window.overrideUserInterfaceStyle == .dark
                                    
                                    if let image = generateQRCodeImage(from: scannedText, isDarkMode: isDark) {
                                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.png")
                                        try? image.pngData()?.write(to: tempURL)
                                        qrShareURL = tempURL
                                        isSharingQR = true
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isGeneratingQR = false
                                }
                            }
                        }
                    } else {
                        // Barcode sharing
                        ActionButton(icon: "square.and.arrow.up", text: isGeneratingQR ? "Please Wait..." : "Share Barcode") {
                            if !isGeneratingQR {
                                isGeneratingQR = true
                                
                                // Determine optimal size based on barcode type
                                let size: CGSize
                                switch barcodeType {
                                case .aztec:
                                    size = CGSize(width: 1024, height: 1024)
                                case .pdf417:
                                    size = CGSize(width: 1536, height: 1024)
                                case .ean8, .upce:
                                    size = CGSize(width: 1536, height: 512)
                                case .ean13:
                                    size = CGSize(width: 2048, height: 512)
                                case .code128, .code93:
                                    size = CGSize(width: 2048, height: 512)
                                case .code39, .code39Mod43:
                                    size = CGSize(width: 2560, height: 512)
                                case .itf14, .interleaved2of5:
                                    size = CGSize(width: 2560, height: 512)
                                    // case .codabar:
                                    // size = CGSize(width: 2048, height: 512)
                                default:
                                    size = CGSize(width: 2048, height: 512)
                                }
                                
                                if let barcode = generatedBarcode {
                                    // Create image context with white background
                                    UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
                                    
                                    // Fill white background
                                    UIColor.white.setFill()
                                    UIRectFill(CGRect(origin: .zero, size: size))
                                    
                                    // Calculate aspect ratio preserving rect with horizontal padding
                                    let horizontalPadding: CGFloat = 64  // Add padding constant
                                    let originalAspect = barcode.size.width / barcode.size.height
                                    let targetAspect = (size.width - (2 * horizontalPadding)) / size.height
                                    
                                    let drawRect: CGRect
                                    if originalAspect > targetAspect {
                                        // Image is wider than target - fit to padded width
                                        let width = size.width - (2 * horizontalPadding)
                                        let height = width / originalAspect
                                        let y = (size.height - height) / 2
                                        drawRect = CGRect(x: horizontalPadding, y: y, width: width, height: height)
                                    } else {
                                        // Image is taller than target - fit to height
                                        let height = size.height
                                        let width = height * originalAspect
                                        let x = (size.width - width) / 2
                                        drawRect = CGRect(x: x, y: 0, width: width, height: height)
                                    }
                                    
                                    // Draw the barcode scaled up with proper aspect ratio
                                    let context = UIGraphicsGetCurrentContext()
                                    context?.interpolationQuality = .none  // Disable interpolation for sharp edges
                                    context?.setShouldAntialias(false)  // Disable antialiasing for crisp lines
                                    barcode.draw(in: drawRect)
                                    
                                    // Get the high quality image
                                    if let highQualityImage = UIGraphicsGetCurrentContext()?.makeImage() {
                                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Barcode.png")
                                        try? UIImage(cgImage: highQualityImage).pngData()?.write(to: tempURL)  // Save as PNG for lossless quality
                                        qrShareURL = tempURL
                                        isSharingQR = true
                                    }
                                    UIGraphicsEndImageContext()
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isGeneratingQR = false
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .sheet(isPresented: $isSharingQR) {
                if let qrShareURL = qrShareURL {
                    ShareSheet(activityItems: [qrShareURL])
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Save Contact (vCard)
    func saveContact(_ vCard: String) {
        print("Saving vCard: \(vCard)")
        
        // Normalize vCard data
        let normalizedVCard = normalizeVCardData(vCard)
        
        // Create a CNContact from vCard data
        let data = normalizedVCard.data(using: .utf8)
        if let data = data {
            do {
                let contacts = try CNContactVCardSerialization.contacts(with: data)
                if let contact = contacts.first {
                    // Present the contact view controller using the ContactPresenter class
                    ContactPresenter.shared.presentContact(contact)
                } else {
                    showErrorAlert(message: "No valid contact information found in the QR code.")
                    print("No contacts found in vCard data")
                }
            } catch {
                showErrorAlert(message: "Could not parse contact information: \(error.localizedDescription)")
                print("Error parsing vCard data: \(error)")
            }
        } else {
            showErrorAlert(message: "Invalid contact data format.")
        }
    }
    
    // Show error alert to user
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Contact Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default))
        
        // Present the alert
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = window.rootViewController {
                
                var currentVC = rootVC
                while let presentedVC = currentVC.presentedViewController {
                    currentVC = presentedVC
                }
                
                currentVC.present(alert, animated: true)
            }
        } else {
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                var currentVC = rootVC
                while let presentedVC = currentVC.presentedViewController {
                    currentVC = presentedVC
                }
                
                currentVC.present(alert, animated: true)
            }
        }
    }
    
    // Helper method to normalize vCard data
    private func normalizeVCardData(_ vCardString: String) -> String {
        var vCard = vCardString
        
        // Ensure vCard starts with BEGIN:VCARD
        if !vCard.hasPrefix("BEGIN:VCARD") {
            vCard = "BEGIN:VCARD\n" + vCard
        }
        
        // Ensure vCard ends with END:VCARD
        if !vCard.hasSuffix("END:VCARD") {
            vCard = vCard + "\nEND:VCARD"
        }
        
        // Replace any double line breaks with single line breaks
        vCard = vCard.replacingOccurrences(of: "\n\n", with: "\n")
        
        // Ensure version is specified
        if !vCard.contains("VERSION:") {
            vCard = vCard.replacingOccurrences(of: "BEGIN:VCARD\n", with: "BEGIN:VCARD\nVERSION:3.0\n")
        }
        
        return vCard
    }
}

// MARK: - Contact View Controller Delegate
class ContactViewControllerDelegate: NSObject, CNContactViewControllerDelegate {
    static let shared = ContactViewControllerDelegate()
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Calendar Event Management (EventKitUI)

// SwiftUI wrapper for EKEventEditViewController - no permissions needed!
struct EventEditView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let editController = EKEventEditViewController()
        editController.eventStore = eventStore
        editController.event = event
        editController.editViewDelegate = context.coordinator
        return editController
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true) {
                switch action {
                case .saved:
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    print("Calendar event saved successfully")
                case .canceled:
                    print("Calendar event creation canceled")
                case .deleted:
                    print("Calendar event deleted")
                @unknown default:
                    break
                }
            }
        }
    }
}

// Show event edit controller - no permissions required!
func showEventEditController(_ eventString: String) {
    let eventStore = EKEventStore()
    
    // Parse the VEVENT and create the event
    guard let event = parseVEventSimple(eventString, eventStore: eventStore) else {
        print("Failed to parse calendar event")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        return
    }
    
    // Present using SwiftUI
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        
        let eventEditView = EventEditView(event: event, eventStore: eventStore)
        let hostingController = UIHostingController(rootView: eventEditView)
        
        // Find the topmost presented view controller
        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        
        topController?.present(hostingController, animated: true)
    }
}

// Simple VEVENT parser - extracts key fields to prefill the event
func parseVEventSimple(_ eventString: String, eventStore: EKEventStore) -> EKEvent? {
    let event = EKEvent(eventStore: eventStore)
    let lines = eventString.components(separatedBy: .newlines)
    
    // Date formatters for different VEVENT formats
    let utcFormatter = DateFormatter()
    utcFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
    let localFormatter = DateFormatter()
    localFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
    localFormatter.timeZone = TimeZone.current
    
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateFormat = "yyyyMMdd"
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedLine.hasPrefix("SUMMARY:") {
            event.title = String(trimmedLine.dropFirst(8))
        } else if trimmedLine.hasPrefix("DESCRIPTION:") {
            event.notes = String(trimmedLine.dropFirst(12))
        } else if trimmedLine.hasPrefix("LOCATION:") {
            event.location = String(trimmedLine.dropFirst(9))
        } else if trimmedLine.hasPrefix("DTSTART") {
            let dateString = extractDateValue(from: trimmedLine)
            if let date = utcFormatter.date(from: dateString) ?? 
                         localFormatter.date(from: dateString) ?? 
                         dateOnlyFormatter.date(from: dateString) {
                event.startDate = date
            }
        } else if trimmedLine.hasPrefix("DTEND") {
            let dateString = extractDateValue(from: trimmedLine)
            if let date = utcFormatter.date(from: dateString) ?? 
                         localFormatter.date(from: dateString) ?? 
                         dateOnlyFormatter.date(from: dateString) {
                event.endDate = date
            }
        }
    }
    
    // Validation - need at least a title
    if event.title?.isEmpty != false {
        event.title = "Calendar Event" // Default title
    }
    
    // If no dates, set to current time + 1 hour
    if event.startDate == nil {
        event.startDate = Date()
        event.endDate = Date().addingTimeInterval(3600)
    } else if event.endDate == nil {
        event.endDate = event.startDate?.addingTimeInterval(3600)
    }
    
    return event
}

// Helper to extract date value from VEVENT property line
func extractDateValue(from property: String) -> String {
    // Handle formats like "DTSTART:20231225T120000Z" or "DTSTART;TZID=America/New_York:20231225T120000"
    if let colonIndex = property.lastIndex(of: ":") {
        return String(property[property.index(after: colonIndex)...])
    }
    return ""
}

// MARK: - Open Email (MATMSG Format)
func openMATMSGEmail(_ text: String) {
    let components = text.replacingOccurrences(of: "MATMSG:", with: "")
        .components(separatedBy: ";")
        .reduce(into: [String: String]()) { dict, pair in
            let parts = pair.components(separatedBy: ":")
            if parts.count == 2 {
                dict[parts[0]] = parts[1]
            }
        }
    
    if let to = components["TO"], let subject = components["SUB"], let body = components["BODY"] {
        let mailtoString = "mailto:\(to)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: mailtoString) {
            UIApplication.shared.open(url)
        }
    }
}
// ✅ Ensures image is ready BEFORE sharing
func generateQRCodeImage(from string: String, isDarkMode: Bool, size: CGFloat = 1024) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(string.data(using: .utf8), forKey: "inputMessage")
    
    guard let outputImage = filter.outputImage else { return nil }
    
    // Define colors
    let qrColor = isDarkMode ? CIColor.white : CIColor.black
    let bgColor = !isDarkMode ? CIColor.white : CIColor.black
    
    // Apply false color filter
    let colorFilter = CIFilter.falseColor()
    colorFilter.setValue(outputImage, forKey: "inputImage")
    colorFilter.setValue(qrColor, forKey: "inputColor0")
    colorFilter.setValue(bgColor, forKey: "inputColor1")
    
    // Apply proper scaling
    let transform = CGAffineTransform(scaleX: size / outputImage.extent.width, y: size / outputImage.extent.height)
    let scaledImage = colorFilter.outputImage!.transformed(by: transform)
    
    // Convert to UIImage
    if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
        return UIImage(cgImage: cgimg)
    }
    
    return nil
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                //                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(text)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding()
        }
        .disabled(text == "Generating QR...")
    }
}


struct ActionButtonCenter: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(text)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding()
        }
        .disabled(text == "Generating QR...")
    }
}

// MARK: - UPI App Selection
func showUPIAppSelection(for upiLink: String) {
    let alert = UIAlertController(title: "Choose Payment App", message: nil, preferredStyle: .actionSheet)
    
    // Add all UPI apps
    alert.addAction(UIAlertAction(title: "PhonePe", style: .default, handler: { _ in
        openUPILink(upiLink, with: "PhonePe")
    }))
    
    alert.addAction(UIAlertAction(title: "Google Pay", style: .default, handler: { _ in
        openUPILink(upiLink, with: "Google Pay")
    }))
    
    alert.addAction(UIAlertAction(title: "Paytm", style: .default, handler: { _ in
        openUPILink(upiLink, with: "Paytm")
    }))
    
    alert.addAction(UIAlertAction(title: "CRED", style: .default, handler: { _ in
        openUPILink(upiLink, with: "CRED")
    }))
    
    alert.addAction(UIAlertAction(title: "BHIM", style: .default, handler: { _ in
        openUPILink(upiLink, with: "BHIM")
    }))
    
    alert.addAction(UIAlertAction(title: "Amazon Pay", style: .default, handler: { _ in
        openUPILink(upiLink, with: "Amazon Pay")
    }))
    
    alert.addAction(UIAlertAction(title: "WhatsApp", style: .default, handler: { _ in
        openUPILink(upiLink, with: "WhatsApp")
    }))
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
    if let topController = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
        .first {
        topController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Link Preview View
struct LinkPreviewView: UIViewRepresentable {
    let metadata: LPLinkMetadata
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(metadata: metadata)
        linkView.sizeToFit()
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
        uiView.metadata = metadata
    }
}

// MARK: - Enhanced Link Preview View
struct EnhancedLinkPreviewView: View {
    let metadata: LPLinkMetadata
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Standard link preview
            LinkPreviewView(metadata: metadata)
                .frame(height: 150)
                .cornerRadius(12)
            
            // Overlapping title with domain
            VStack(alignment: .leading, spacing: 2) {
                if let title = metadata.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                }
                
                if let url = metadata.url, let host = url.host {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(host)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.3)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .allowsHitTesting(false) 
            )
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            
            // Hold to preview hint positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                        Text("Hold to open preview")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
                    .transition(.opacity)
                    .allowsHitTesting(false) // Make the hint non-interactive
                }
            }
            .allowsHitTesting(false) 
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
    }
}

// Extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Link Preview ViewModel
class LinkPreviewViewModel: ObservableObject {
    @Published var metadata: LPLinkMetadata?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var additionalMetadata: [String: String] = [:]
    
    func fetchMetadata(for urlString: String) {
        // Reset state
        metadata = nil
        error = nil
        additionalMetadata = [:]
        
        // Check if the string is a valid URL
        guard let url = URL(string: urlString) else {
            return
        }
        
        isLoading = true
        
        // Extract basic URL information
        if let host = url.host {
            additionalMetadata["Domain"] = host
        }
        
        additionalMetadata["Protocol"] = url.scheme ?? "Unknown"
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { [weak self] metadata, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    print("Error fetching metadata: \(error.localizedDescription)")
                } else if let metadata = metadata {
                    self?.metadata = metadata
                    
                    // Extract additional metadata
                    if let title = metadata.title {
                        self?.additionalMetadata["Title"] = title
                    }
                }
            }
        }
    }
    
    private func getDomainTypeDescription(for tld: String) -> String {
        switch tld.lowercased() {
        case "com":
            return "Commercial website"
        case "org":
            return "Organization (typically non-profit)"
        case "net":
            return "Network service provider"
        case "edu":
            return "Educational institution"
        case "gov":
            return "Government entity"
        case "mil":
            return "Military organization"
        case "io":
            return "Technology/startup company"
        case "co":
            return "Company or commercial entity"
        case "app":
            return "Application-related website"
        case "dev":
            return "Developer-focused website"
        case "ai":
            return "Artificial Intelligence related"
        default:
            // Check if it's a country code
            if tld.count == 2 {
                return "Country-specific domain (.\(tld))"
            }
            return "Domain extension (.\(tld))"
        }
    }
}

// MARK: - Rich Link Preview Component
struct RichLinkPreview: View {
    let urlString: String
    @StateObject private var viewModel = LinkPreviewViewModel()
    @State private var isLink = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(height: 100)
            } else if let metadata = viewModel.metadata, isLink {
                // Enhanced link preview with overlapping title
                ZStack(alignment: .bottomTrailing) {
                    EnhancedLinkPreviewView(metadata: metadata)
                        .frame(height: 150) // Slightly taller for better visibility
                }
            } else {
                // Fallback for non-link content or failed preview
                HStack {
                    Image(systemName: "link.badge.xmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("Not a valid web link")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        
        .onAppear {
            isLink = isValidLink(urlString)
            if isLink {
                viewModel.fetchMetadata(for: urlString)
            }
        }
    }
    
    // Helper to check if the string is a valid link
    private func isValidLink(_ string: String) -> Bool {
        return URLDetectorUtility.shared.isValidWebLink(string)
    }
}

// MARK: - Contact Presenter
class ContactPresenter: NSObject {
    static let shared = ContactPresenter()
    
    func presentContact(_ contact: CNContact) {
        let contactViewController = CNContactViewController(forUnknownContact: contact)
        contactViewController.contactStore = CNContactStore()
        contactViewController.allowsActions = true
        contactViewController.allowsEditing = false
        contactViewController.delegate = ContactViewControllerDelegate.shared
        
        // Create a navigation controller
        let navigationController = UINavigationController(rootViewController: contactViewController)
        
        // Add a cancel button to the navigation bar
        contactViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissContactVC)
        )
        
        // Get the current UIViewController - iOS 15+ compatible approach
        var currentVC: UIViewController?
        
        if #available(iOS 15.0, *) {
            // Get the active window scene
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                currentVC = window.rootViewController
            }
        } else {
            // Fallback for iOS 14 and earlier
            currentVC = UIApplication.shared.windows.first?.rootViewController
        }
        
        // Find the topmost presented view controller
        if let rootVC = currentVC {
            var topmostVC = rootVC
            while let presentedVC = topmostVC.presentedViewController {
                topmostVC = presentedVC
            }
            
            // Present the navigation controller
            topmostVC.present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func dismissContactVC() {
        // Dismiss the presented view controller
        if #available(iOS 15.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = window.rootViewController {
                
                var currentVC = rootVC
                while let presentedVC = currentVC.presentedViewController {
                    currentVC = presentedVC
                }
                
                currentVC.dismiss(animated: true, completion: nil)
            }
        } else {
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                var currentVC = rootVC
                while let presentedVC = currentVC.presentedViewController {
                    currentVC = presentedVC
                }
                
                currentVC.dismiss(animated: true, completion: nil)
            }
        }
    }
}
// Helper function to open UPI link with specific app
func openUPILink(_ upiLink: String, with app: String) {
    let urlString: String
    switch app {
    case "PhonePe":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "phonepe://upi/pay")
    case "Google Pay":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "gpay://upi/pay")
    case "Paytm":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "paytmmp://upi/pay")
    case "CRED":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "credpay://upi/pay")
    case "BHIM":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "bhim://upi/pay")
    case "Amazon Pay":
        urlString = upiLink.replacingOccurrences(of: "upi://pay", with: "amazonpay://upi/pay")
    case "WhatsApp":
        urlString = upiLink // WhatsApp uses the default UPI scheme
    default:
        urlString = upiLink
    }
    
    if let url = URL(string: urlString) {
        UIApplication.shared.open(url, options: [:]) { _ in }
    }
}

// Helper function to connect to Wi-Fi
func connectToWiFi(ssid: String, passphrase: String) {
    // Check if running on simulator
    #if targetEnvironment(simulator)
    showToast(message: "Wi-Fi connection not available in simulator")
    return
    #endif
    
    let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
    configuration.joinOnce = false // Allow persistent connection

    showToast(message: "Attempting to connect to \(ssid)...")
    
    NEHotspotConfigurationManager.shared.apply(configuration) { error in
        if let error = error {
            if error.localizedDescription.contains("already associated") {
                print("Already connected to \(ssid).")
                showToast(message: "Already connected to \(ssid)")
            } else if error.localizedDescription.contains("missing entitlement") {
                print("Missing Hotspot Configuration entitlement")
                showToast(message: "Missing required app permissions. Please enable Hotspot Configuration capability in Xcode.")
            } else {
                // For all other errors
                print("Error connecting to Wi-Fi: \(error.localizedDescription)")
                
                let errorMessage: String
                if error.localizedDescription.contains("internal error") {
                    errorMessage = "Could not connect to Wi-Fi. Please verify the Hotspot Configuration capability is enabled."
                } else if passphrase.isEmpty {
                    errorMessage = "Could not connect: Password required"
                } else if passphrase.count < 8 {
                    errorMessage = "Could not connect: Password too short"
                } else {
                    errorMessage = "Could not connect to Wi-Fi: \(error.localizedDescription)"
                }
                
                showToast(message: errorMessage)
            }
        } else {
            // Connection attempt completed - check if we can verify the connection
            // Note: iOS doesn't provide a reliable programmatic way to check the current Wi-Fi SSID
            // due to privacy restrictions, so we'll just be more cautious in our messaging
            print("Connection attempt to \(ssid) completed without errors")
            showToast(message: "Connection request sent to \(ssid)")
            
            // Display a follow-up message after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showToast(message: "Please check your Wi-Fi settings to confirm connection")
            }
        }
    }
}

// Helper function to show toast message
func showToast(message: String) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
    else { return }
    
    let toastContainer = UIView(frame: CGRect(x: 0, y: 0, width: 280, height: 50))
    
    // Create blur effect background like system toast
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = toastContainer.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.layer.cornerRadius = 10
    blurView.clipsToBounds = true
    toastContainer.addSubview(blurView)
    
    // Add a subtle border
    toastContainer.layer.cornerRadius = 10
    toastContainer.layer.borderWidth = 0.5
    toastContainer.layer.borderColor = UIColor.gray.withAlphaComponent(0.2).cgColor
    
    // Configure message label
    let messageLabel = UILabel()
    messageLabel.textColor = .label
    messageLabel.textAlignment = .center
    messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    messageLabel.text = message
    messageLabel.numberOfLines = 0
    
    // Add label to vibrancy effect for better readability
    let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
    let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
    vibrancyView.frame = blurView.bounds
    vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.contentView.addSubview(vibrancyView)
    
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    vibrancyView.contentView.addSubview(messageLabel)
    
    NSLayoutConstraint.activate([
        messageLabel.leadingAnchor.constraint(equalTo: vibrancyView.leadingAnchor, constant: 10),
        messageLabel.trailingAnchor.constraint(equalTo: vibrancyView.trailingAnchor, constant: -10),
        messageLabel.topAnchor.constraint(equalTo: vibrancyView.topAnchor, constant: 10),
        messageLabel.bottomAnchor.constraint(equalTo: vibrancyView.bottomAnchor, constant: -10)
    ])
    
    window.addSubview(toastContainer)
    
    // Position at bottom like system toast
    toastContainer.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        toastContainer.centerXAnchor.constraint(equalTo: window.centerXAnchor),
        toastContainer.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -50),
        toastContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
    ])
    
    toastContainer.alpha = 0
    
    // Animate like system toast
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
        toastContainer.alpha = 1.0
        toastContainer.transform = CGAffineTransform(translationX: 0, y: -10)
    }, completion: { _ in
        UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseIn, animations: {
            toastContainer.alpha = 0
            toastContainer.transform = CGAffineTransform(translationX: 0, y: 10)
        }, completion: { _ in
            toastContainer.removeFromSuperview()
        })
    })
}