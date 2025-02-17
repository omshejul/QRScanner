//
//  ScanResultView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ScanResultView: View {
    let scannedText: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            // Use dynamic theme for QR code
            generateQRCode(from: scannedText, isDarkMode: UITraitCollection.current.userInterfaceStyle == .dark)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 200, height: 200) // Increased QR size
                .padding(20) // Extra padding around QR code

            // Data Section
            SectionView(title: "DATA", content: scannedText)

            // Type Section
            SectionView(title: "TYPE", content: determineQRType(from: scannedText))

            // Action Buttons
            ActionButtonsView(scannedText: scannedText)

            Spacer()
        }
        .padding(0.5)
        .navigationTitle("Scan Result")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Dark background for modern look
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
            let bgColor = CIColor.clear // No background

            colorFilter.setValue(qrColor, forKey: "inputColor0")
            colorFilter.setValue(bgColor, forKey: "inputColor1")

            if let cgimg = context.createCGImage(colorFilter.outputImage!, from: outputImage.extent) {
                return Image(uiImage: UIImage(cgImage: cgimg))
            }
        }

        return Image(systemName: "xmark.circle") // Fallback in case of error
    }

    // MARK: - Determine QR Code Type
    func determineQRType(from text: String) -> String {
        if text.starts(with: "http") {
            return "QRCode (URL)"
        } else if text.contains("@") {
            return "QRCode (Email)"
        } else if text.allSatisfy({ $0.isNumber }) {
            return "QRCode (Number)"
        } else {
            return "QRCode (Text)"
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
    @State private var isCopied = false // ✅ Track copy state

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
                        if scannedText.starts(with: "MATMSG:") {
                            openMATMSGEmail(scannedText)
                        } else if let url = URL(string: scannedText) {
                            UIApplication.shared.open(url)
                        }
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
                    ActionButton(icon: "wifi", text: "Connect to WiFi") {
                        connectToWiFi(scannedText)
                    }
                    Divider()
                }

                if scannedText.contains("BEGIN:VCARD") {
                    ActionButton(icon: "person.crop.circle", text: "Save Contact") {
                        saveContact(scannedText)
                    }
                    Divider()
                }

                ActionButton(icon: "doc.on.doc", text: isCopied ? "Copied" : "Copy") {
                    UIPasteboard.general.string = scannedText
                    isCopied = true

                    // ✅ Reset back to "Copy" after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                    }
                }
                Divider()

                ActionButton(icon: "square.and.arrow.up", text: "Share") {
                    shareScannedText()
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.top, 10)
    }

    // MARK: - Share Function
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

// MARK: - Action Button View
struct ActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)

                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 16))

                Spacer()
            }
            .padding()
        }
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
