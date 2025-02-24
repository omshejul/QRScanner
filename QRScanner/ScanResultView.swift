//
//  ScanResultView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

struct ScanResultView: View {
    let scannedText: String
    let barcodeType: AVMetadataObject.ObjectType
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Show QR Code Image only for QR codes
                if barcodeType == .qr {
                    generateQRCode(from: scannedText, isDarkMode: UITraitCollection.current.userInterfaceStyle == .dark)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(20)
                } else {
                    // Show appropriate barcode icon for other types
                    Image(systemName: getBarcodeIcon(for: barcodeType))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 100)
                        .foregroundColor(.primary)
                        .padding(20)
                }

                // Data Section
                SectionView(title: "DATA", content: scannedText)

                // Type Section
                SectionView(title: "TYPE", content: determineQRType(from: scannedText, type: barcodeType))

                // Action Buttons
                ActionButtonsView(scannedText: scannedText, barcodeType: barcodeType)

                Spacer()
            }
            .padding(4)
        }
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
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
        if text.starts(with: "http") {
            return "\(baseType) (URL)"
        } else if text.contains("@") {
            return "\(baseType) (Email)"
        } else if text.contains("WIFI:") {
            return "\(baseType) (WiFi)"
        } else if text.starts(with: "BEGIN:VCARD") {
            return "\(baseType) (Contact)"
        } else if text.starts(with: "tel:") {
            return "\(baseType) (Phone)"
        } else if text.starts(with: "smsto:") {
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


// MARK: - Action Buttons with Additional Actions
struct ActionButtonsView: View {
    let scannedText: String
    let barcodeType: AVMetadataObject.ObjectType
    @State private var isCopied = false
    @State private var isSharingData = false
    @State private var isSharingQR = false
    @State private var qrImage: UIImage?
    @State private var isGeneratingQR = false
    @State private var qrShareURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ACTION")
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.horizontal)

            VStack(spacing: 0) {
                
                if let url = URL(string: scannedText), scannedText.starts(with: "http") {
                    ActionButton(icon: "safari", text: "Open in Safari") {
                        UIApplication.shared.open(url)
                    }
                    Divider()
                }

                if scannedText.starts(with: "mailto:") || scannedText.starts(with: "MATMSG:") {
                    ActionButton(icon: "envelope", text: "Send Email") {
                        openMATMSGEmail(scannedText)
                    }
                    Divider()
                }

                if scannedText.starts(with: "tel:") {
                    ActionButton(icon: "phone", text: "Call") {
                        if let url = URL(string: scannedText) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Divider()
                }

                if scannedText.starts(with: "smsto:") {
                    ActionButton(icon: "message", text: "Send SMS") {
                        if let url = URL(string: scannedText) {
                            UIApplication.shared.open(url)
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

                    ActionButton(icon: "doc.on.doc", text: "Copy WiFi Password") {
                        UIPasteboard.general.string = wifiPassword
                    }
                    Divider()
                }

                if scannedText.contains("BEGIN:VCARD") {
                    ActionButton(icon: "person.crop.circle", text: "Save Contact") {
                        saveContact(scannedText)
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
                if barcodeType == .qr {
                    // ✅ Only allow tap when NOT generating QR
                    ActionButton(icon: "qrcode", text: isGeneratingQR ? "Please Wait..." : "Share QR Code") {
                        if !isGeneratingQR {
                            isGeneratingQR = true
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                // ✅ Correctly determine dark mode
                                let isDark: Bool
                                if window.overrideUserInterfaceStyle == .unspecified {
                                    isDark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
                                } else {
                                    isDark = window.overrideUserInterfaceStyle == .dark
                                }

                                // ✅ Generate QR Code with correct theme
                                if let image = generateQRCodeImage(from: scannedText, isDarkMode: isDark) {
                                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.png")
                                    try? image.pngData()?.write(to: tempURL) // ✅ Ensure file is written before sharing
                                    qrShareURL = tempURL
                                    isSharingQR = true
                                }
                            }
                            // ✅ Ensure `isGeneratingQR` resets even if `windowScene` is nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isGeneratingQR = false
                            }
                        }
                    }
                    .sheet(isPresented: $isSharingQR) {
                        if let qrShareURL = qrShareURL {
                            ShareSheet(activityItems: [qrShareURL]) // ✅ Share Image
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.top, 10)
    }    // MARK: - Share Function
    func shareScannedText() {
        let activityItems: [Any] = scannedText.starts(with: "http") ? [URL(string: scannedText)!] : [scannedText]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let topController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
            .first {
            topController.present(activityVC, animated: true, completion: nil)
        }
    }

    // MARK: - Connect to WiFi
    func connectToWiFi(_ text: String) {
        print("WiFi QR detected: \(text)")

    }

    // MARK: - Save Contact (vCard)
    func saveContact(_ vCard: String) {
        print("Saving vCard: \(vCard)")
        // vCard import functionality requires Contacts API (not included here)
    }
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

// ✅ Prevents double taps while generating
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
                    .foregroundColor(.blue)

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
                    .foregroundColor(.blue)

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
