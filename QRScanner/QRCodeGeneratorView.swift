//
//  QRCodeGeneratorView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation
import RSBarcodes_Swift

enum BarcodeType: String, CaseIterable {
    case aztec = "Aztec"
    case code39 = "Code 39"
    case code39Mod43 = "Code 39 Mod 43"
    case extendedCode39 = "Extended Code 39"
    case code93 = "Code 93"
    case code128 = "Code 128"
    case upce = "UPC-E"
    case ean8 = "EAN-8"
    case ean13 = "EAN-13"
    case isbn13 = "ISBN-13"
    case issn13 = "ISSN-13"
    case itf14 = "ITF-14"
    case interleaved2of5 = "Interleaved 2 of 5"
    case pdf417 = "PDF417"
    case dataMatrix = "Data Matrix"
    // case codabar = "Codabar"
    
    var metadata: BarcodeMetadata {
        switch self {
        case .code39:
            return BarcodeMetadata(
                example: "ABC-123",
                usage: "Used in logistics, manufacturing, and military applications. Accepts uppercase letters, numbers, and special characters like dash, dot, dollar sign, slash, plus, and percent."
            )
        case .code39Mod43:
            return BarcodeMetadata(
                example: "CODE39",
                usage: "Similar to Code 39, but with an added check digit for better accuracy. Common in healthcare and defense industries. Accepts uppercase letters, numbers, and special characters like dash, dot, dollar sign, slash, plus, and percent."
            )
        case .extendedCode39:
            return BarcodeMetadata(
                example: "Code-39+",
                usage: "Extended version supporting all 128 ASCII characters. Used in document management and inventory systems. Accepts uppercase letters, numbers, and special characters like dash, dot, dollar sign, slash, plus, and percent."
            )
        case .code93:
            return BarcodeMetadata(
                example: "CODE93",
                usage: "More compact than Code 39, used in logistics and retail. Accepts uppercase letters, numbers, and various special characters."
            )
        case .code128:
            return BarcodeMetadata(
                example: "ABC12345",
                usage: "Versatile barcode for logistics and retail. Accepts all ASCII characters and is very compact."
            )
        case .upce:
            return BarcodeMetadata(
                example: "01234565",
                usage: "Compressed UPC code for small retail items. Used on small product packages where space is limited. Enter 8 digits."
            )
        case .ean8:
            return BarcodeMetadata(
                example: "12345670",
                usage: "Short-form retail barcode used worldwide on small products where EAN-13 won't fit. Enter 8 digits."
            )
        case .ean13:
            return BarcodeMetadata(
                example: "1234567890128",
                usage: "Standard retail barcode used worldwide for product identification. Enter 13 digits."
            )
        case .isbn13:
            return BarcodeMetadata(
                example: "9780123456789",
                usage: "Used for book identification worldwide. Starts with 978 or 979. Enter 13 digits."
            )
        case .issn13:
            return BarcodeMetadata(
                example: "9771234567898",
                usage: "Used for periodical publications. Starts with 977. Enter 13 digits."
            )
        case .itf14:
            return BarcodeMetadata(
                example: "12345678901231",
                usage: "Used on packaging for shipping cartons. Based on Interleaved 2 of 5. Enter 14 digits."
            )
        case .interleaved2of5:
            return BarcodeMetadata(
                example: "1234567890",
                usage: "Used in industrial and warehouse applications. Enter an even number of digits."
            )
        case .pdf417:
            return BarcodeMetadata(
                example: "PDF417TEST",
                usage: "2D barcode used on ID cards, shipping labels, and tickets. Can store up to 1.1 kilobytes of data."
            )
        case .aztec:
            return BarcodeMetadata(
                example: "AZTEC2D",
                usage: "2D barcode used in transport tickets and airline boarding passes. Reads well even if poorly printed or damaged."
            )
        case .dataMatrix:
            return BarcodeMetadata(
                example: "DM2D123",
                usage: "2D barcode used in industrial marking and packaging. Ideal for small items and can encode a large amount of data in a compact space."
            )
            // case .codabar:
            //     return BarcodeMetadata(
            //         example: "A12345B",
            //         usage: "Used in libraries, blood banks, and shipping. Requires start/stop characters (A-D)."
            //     )
        }
    }
}

struct BarcodeMetadata {
    let example: String
    let usage: String
}

struct QRCodeGeneratorView: View {
    var body: some View {
        NavigationStack { // ✅ REPLACED NavigationView with NavigationStack
            List {
                // MARK: - Basic Section
                Section(header: Text("BASIC").font(.caption).foregroundColor(.gray)) {
                    ForEach(QRType.allCases.filter { $0 != .contact }, id: \.rawValue) { type in
                        NavigationLink(destination: BASICQRCodeView(type: type)) {
                            QRCodeOptionRow(icon: getSystemIcon(for: type), title: type.rawValue)
                        }
                    }
                    ForEach(AdvanceQRType.allCases, id: \.rawValue) { type in
                        NavigationLink(destination: AdvanceQRCodeView(type: type)) {
                            QRCodeOptionRow(icon: getAdvancedIcon(for: type), title: type.rawValue)
                        }
                    }
                    
                    NavigationLink(destination: BASICQRCodeView(type: .contact)) {
                        QRCodeOptionRow(icon: "person.crop.circle", title: "Contact")
                    }
                }
                
                // MARK: - Barcode Section
                Section(header: Text("ADVANCED").font(.caption).foregroundColor(.gray)) {
                    ForEach(BarcodeType.allCases.filter { $0 != .dataMatrix }, id: \.rawValue) { type in
                        NavigationLink(destination: BarcodeGeneratorView(type: type)) {
                            QRCodeOptionRow(icon: getBarcodeIcon(for: type), title: type.rawValue)
                        }
                    }
                    // .padding(.vertical, 4)
                    
                    // Data Matrix (Coming Soon)
                    // HStack {
                    //     Image(systemName: "square.grid.2x2")
                    //         .foregroundColor(.gray)
                    //         .frame(width: 25, height: 25)
                    //         .aspectRatio(contentMode: .fit)
                    //         .alignmentGuide(.firstTextBaseline) { d in d[.leading] }
                        
                    //     Text("Data Matrix")
                    //         .foregroundColor(.gray)
                    //     Text("(Coming Soon)")
                    //         .font(.caption)
                    //         .foregroundColor(.gray)
                    //         .padding(.leading, 4)
                    // }
                }
                
                
                // MARK: - Social Section
                Section(header: Text("SOCIAL").font(.caption).foregroundColor(.gray)) {
                    //icons phosphoricons.com
                    NavigationLink(destination: SocialQRCodeView(platform: "Facebook", templateURL: "https://www.facebook.com/", inputPlaceholder: "Enter Facebook Username", exampleInput: "john.doe")) {
                        QRCodeOptionRowSocial(imageName: "facebook", title: "Facebook")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Instagram", templateURL: "https://www.instagram.com/", inputPlaceholder: "Enter Instagram Username", exampleInput: "john_doe")) {
                        QRCodeOptionRowSocial(imageName: "instagram", title: "Instagram")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "WhatsApp", templateURL: "https://wa.me/", inputPlaceholder: "Enter Phone Number", exampleInput: "+1234567890")) {
                        QRCodeOptionRowSocial(imageName: "whatsapp", title: "WhatsApp")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "TikTok", templateURL: "https://www.tiktok.com/@", inputPlaceholder: "Enter TikTok Username", exampleInput: "tiktok_user")) {
                        QRCodeOptionRowSocial(imageName: "tiktok", title: "TikTok")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "X", templateURL: "https://twitter.com/", inputPlaceholder: "Enter X (Twitter) Handle, with @", exampleInput: "@elonmusk")) {
                        QRCodeOptionRowSocial(imageName: "twitter", title: "X")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Snapchat", templateURL: "https://www.snapchat.com/add/", inputPlaceholder: "Enter Snapchat Username", exampleInput: "snap_user")) {
                        QRCodeOptionRowSocial(imageName: "snapchat", title: "Snapchat")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Telegram", templateURL: "https://t.me/", inputPlaceholder: "Enter Telegram Username", exampleInput: "telegram_user")) {
                        QRCodeOptionRowSocial(imageName: "telegram", title: "Telegram")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Spotify", templateURL: "https://open.spotify.com/user/", inputPlaceholder: "Enter Spotify Username", exampleInput: "spotifyuser123")) {
                        QRCodeOptionRowSocial(imageName: "spotify", title: "Spotify")
                    }
                    
                }
            }
            .navigationTitle("Generator")
        }
    }
}

struct QRCodeOptionRowSocial: View {
    let imageName: String // Custom image name from assets
    let title: String
    
    var body: some View {
        HStack {
            Image(imageName) // Loads from Assets
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20) // Adjust logo size
                .clipShape(RoundedRectangle(cornerRadius: 5)) // Optional styling
            
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading) // Aligns text properly
        }
        .padding(.vertical, 4) // Adjusts row height
    }
}

// MARK: - Helper Function to Get Icons
func getSystemIcon(for type: QRType) -> String {
    switch type {
    case .wifi: return "wifi"
    case .web: return "link"
    case .text: return "doc.text"
    case .email: return "envelope"
    case .phone: return "phone"
    case .sms: return "message"
    case .location: return "location"
    case .contact: return "person.crop.circle"
    }
}

// MARK: - Helper Function to Get Advanced Icons
func getAdvancedIcon(for type: AdvanceQRType) -> String {
    switch type {
    case .upi: return "indianrupeesign.circle"
    }
}

// MARK: - QR Code Option Row
struct QRCodeOptionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            if title == "Aztec" {
                Image("aztec")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.blue)
            } else {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 25, height: 25)
                    .aspectRatio(contentMode: .fit)
            }
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading) // Pushes text left
        }
        .padding(.vertical, 4) // Adjusts row height
    }
}


struct SocialQRCodeView: View {
    let platform: String
    let templateURL: String
    let inputPlaceholder: String
    let exampleInput: String
    
    @State private var username: String = ""
    @State private var generatedQRCode: UIImage?
    @State private var isSharingQR = false
    @State private var qrShareURL: URL?
    @State private var isGeneratingQR = false
    @State private var isQRReady = false
    @State private var qrCodeScale: CGFloat = QRAnimationConfig.initialScale
    @State private var qrCodeOpacity: Double = QRAnimationConfig.initialOpacity
    @State private var qrCodeBlur: CGFloat = QRAnimationConfig.initialBlur
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Generate \(platform) QR Code")
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // ✅ Input Field with Placeholder & Example Text
                VStack(alignment: .leading, spacing: 5) {
                    TextField(inputPlaceholder, text: $username)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    hideKeyboard()
                                }
                            }
                        }
                    
                    Text("e.g., \(exampleInput)") // ✅ Example text
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                if let qrImage = generatedQRCode {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .scaleEffect(qrCodeScale)
                        .animation(QRAnimationConfig.scaleAnimation, value: qrCodeScale)
                        .opacity(qrCodeOpacity)
                        .animation(QRAnimationConfig.opacityAnimation, value: qrCodeOpacity)
                        .blur(radius: qrCodeBlur)
                        .animation(QRAnimationConfig.blurAnimation, value: qrCodeBlur)
                    
                    // ✅ Share QR Button
                    ActionButtonCenter(icon: "square.and.arrow.up", text: isGeneratingQR ? "Please Wait..." : "Share QR Code") {
                        if !isGeneratingQR {
                            isGeneratingQR = true
                            generateQRCodeAndShare()
                        }
                    }
                    .sheet(isPresented: $isSharingQR) {
                        if let qrShareURL = qrShareURL {
                            ShareSheet(activityItems: [qrShareURL])
                        }
                    }
                    .opacity(qrCodeOpacity)
                    .animation(QRAnimationConfig.shareButtonAnimation, value: qrCodeOpacity)
                }
                GenerateSocialQRButton(action: generateQRCode)
                    .padding(.vertical)
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Generate QR Code
    func generateQRCode() {
        hideKeyboard()
        let fullURL = templateURL + username
        
        // Reset animation states if regenerating
        if generatedQRCode != nil {
            QRAnimationConfig.resetAnimationStates(
                scale: $qrCodeScale,
                opacity: $qrCodeOpacity,
                blur: $qrCodeBlur
            )
        }
        
        if let image = generateQRCodeImage(from: fullURL, isDarkMode: getCurrentThemeMode()) {
            generatedQRCode = image
            isQRReady = true // ✅ QR is ready for sharing
            saveToCreateHistory(fullURL)
            
            // Animate the QR code appearance
            QRAnimationConfig.animateToFinalStates(
                scale: $qrCodeScale,
                opacity: $qrCodeOpacity,
                blur: $qrCodeBlur
            )
        }
    }
    
    // MARK: - Generate QR Code & Save to File Before Sharing
    func generateQRCodeAndShare() {
        isQRReady = false
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = generateQRCodeImage(from: templateURL + username, isDarkMode: getCurrentThemeMode()) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.png")
                try? image.pngData()?.write(to: tempURL)
                
                DispatchQueue.main.async {
                    qrShareURL = tempURL
                    isSharingQR = true
                    //                    isGeneratingQR = false
                    isQRReady = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isGeneratingQR = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isGeneratingQR = false
                    isQRReady = false
                }
            }
        }
    }
}



struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
// MARK: - Save to Create History
func saveToCreateHistory(_ createdText: String) {
    let displayType: String
    if createdText.starts(with: "upi://pay") {
        displayType = "UPI Payment"
    } else if createdText.starts(with: "http") {
        displayType = "Web URL"
    } else if createdText.starts(with: "WIFI:") {
        displayType = "WiFi"
    } else if createdText.starts(with: "MATMSG:") {
        displayType = "Email"
    } else if createdText.starts(with: "SMSTO:") {
        displayType = "SMS"
    } else if createdText.starts(with: "TEL:") {
        displayType = "Phone"
    } else if createdText.starts(with: "BEGIN:VCARD") {
        displayType = "Contact"
    } else if createdText.starts(with: "geo:") {
        displayType = "Location"
    } else {
        displayType = "QR Code"
    }
    
    let createItem: [String: Any] = [
        "text": createdText,
        "type": AVMetadataObject.ObjectType.qr.rawValue,
        "displayType": displayType,
        "timestamp": Date()
    ]
    
    var history = UserDefaults.standard.array(forKey: "createHistory") as? [[String: Any]] ?? []
    
    // Check if item already exists in history
    if let existingIndex = history.firstIndex(where: { ($0["text"] as? String) == createdText }) {
        // Replace the existing item with the new one
        history[existingIndex] = createItem
    } else {
        // Add as a new item
        history.append(createItem)
    }
    
    // Save the updated history
    UserDefaults.standard.setValue(history, forKey: "createHistory")
}

// MARK: - Helper Function to Get Barcode Icons
private func getBarcodeIcon(for type: BarcodeType) -> String {
    switch type {
    case .code39, .code39Mod43, .extendedCode39:
        return "barcode"
    case .code93:
        return "doc.viewfinder"
    case .code128:
        return "barcode"
    case .upce, .ean8, .ean13:
        return "cart.fill.badge.plus"
    case .isbn13:
        return "book.fill"
    case .issn13:
        return "newspaper.fill"
    case .itf14:
        return "shippingbox.fill"
    case .interleaved2of5:
        return "number.square.fill"
    case .pdf417:
        return "doc.text.fill"
    case .aztec:
        return ""  // Using custom asset in view
        //    case .codabar:
        //        return "creditcard.fill"
    case .dataMatrix:
        return "square.grid.2x2"
    }
}
