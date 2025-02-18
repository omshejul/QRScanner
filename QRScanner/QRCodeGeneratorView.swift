//
//  QRCodeGeneratorView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct QRCodeGeneratorView: View {
    var body: some View {
        NavigationStack { // ✅ REPLACED NavigationView with NavigationStack
            List {
                // MARK: - Basic Section
                Section(header: Text("SIMPLE").font(.caption).foregroundColor(.gray)) {
                    ForEach(QRType.allCases.filter { $0 != .contact }, id: \.rawValue) { type in
                        NavigationLink(destination: BASICQRCodeView(type: type)) {
                            QRCodeOptionRow(icon: getSystemIcon(for: type), title: type.rawValue)
                        }
                    }
                    
                    NavigationLink(destination: BASICQRCodeView(type: .contact)) {
                        QRCodeOptionRow(icon: "person.crop.circle", title: "Contact")
                    }
                }

                // MARK: - Social Section
                Section(header: Text("SOCIAL").font(.caption).foregroundColor(.gray)) {
                    NavigationLink(destination: SocialQRCodeView(platform: "Facebook", templateURL: "https://www.facebook.com/")) {
                        QRCodeOptionRowSocial(imageName: "facebook", title: "Facebook")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Instagram", templateURL: "https://www.instagram.com/")) {
                        QRCodeOptionRowSocial(imageName: "instagram", title: "Instagram")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "WhatsApp", templateURL: "https://wa.me/")) {
                        QRCodeOptionRowSocial(imageName: "whatsapp", title: "WhatsApp")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "TikTok", templateURL: "https://www.tiktok.com/@")) {
                        QRCodeOptionRowSocial(imageName: "tiktok", title: "TikTok")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "X", templateURL: "https://twitter.com/")) {
                        QRCodeOptionRowSocial(imageName: "twitter", title: "X")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Snapchat", templateURL: "https://www.snapchat.com/add/")) {
                        QRCodeOptionRowSocial(imageName: "snapchat", title: "Snapchat")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Telegram", templateURL: "https://t.me/")) {
                        QRCodeOptionRowSocial(imageName: "telegram", title: "Telegram")
                    }
                    NavigationLink(destination: SocialQRCodeView(platform: "Spotify", templateURL: "https://open.spotify.com/user/")) {
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


// MARK: - QR Code Option Row
struct QRCodeOptionRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25, height: 25) // Ensures consistent height
                .aspectRatio(contentMode: .fit) // Maintains aspect ratio
                .alignmentGuide(.firstTextBaseline) { d in d[.leading] } // Aligns properly

            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading) // Pushes text left
        }
        .padding(.vertical, 4) // Adjusts row height
    }
}


struct SocialQRCodeView: View {
    let platform: String
    let templateURL: String
    
    @State private var username: String = ""
    @State private var generatedQRCode: UIImage?
    @State private var isSharing = false // ✅ State for sharing

    var body: some View {
        ScrollView { // ✅ Prevents gesture conflicts
            VStack {
                Text("Generate \(platform) QR Code")
                    .font(.title)
                    .bold()

                TextField("Enter Username or ID", text: $username)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done") {
                                hideKeyboard() // ✅ Manually close keyboard
                            }
                        }
                    }

                Button(action: generateQRCode) {
                    Text("Generate QR Code")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if let qrImage = generatedQRCode {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()

                    // ✅ Share Button Below QR Code
                    Button(action: { isSharing = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share QR Code")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $isSharing) {
                        if let qrImage = generatedQRCode {
                            ShareSheet(activityItems: [qrImage])
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard() // ✅ Hide keyboard when tapping outside
        }
    }

    // MARK: - Generate QR Code
    func generateQRCode() {
        hideKeyboard() // ✅ Close keyboard when clicking generate

        let fullURL = templateURL + username
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(fullURL.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            generatedQRCode = UIImage(cgImage: cgImage)
            // ✅ Save generated QR code to Create History
            saveToCreateHistory(fullURL)
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
    var history = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []
    if !history.contains(createdText) {
        history.append(createdText)
        UserDefaults.standard.setValue(history, forKey: "createHistory")
    }
}
