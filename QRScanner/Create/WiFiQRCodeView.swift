//
//  WiFiQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct WiFiQRCodeView: View {
    @State private var ssid: String = ""
    @State private var password: String = ""
    @State private var encryption: String = "WPA" // Default encryption type
    @State private var qrImage: UIImage?
    @State private var isSharing = false // ✅ Share state added

    let encryptionTypes = ["WPA", "WEP", "None"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Enter SSID", text: $ssid)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done") {
                                hideKeyboard() // ✅ Manually close keyboard
                            }
                        }
                    }

                SecureField("Enter Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                Picker("Encryption Type", selection: $encryption) {
                    ForEach(encryptionTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(10)

                    // ✅ Share Button (Only if QR code exists)
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
                        ShareSheet(activityItems: [qrImage]) // ✅ Share QR
                    }
                }

                Button(action: generateQRCode) {
                    Text("Generate QR Code")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(ssid.isEmpty)
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard() // ✅ Hide keyboard when tapping outside
        }
        .navigationTitle("WiFi")
    }

    // MARK: - Generate QR Code
    private func generateQRCode() {
        hideKeyboard() // ✅ Close keyboard when clicking generate

        let wifiString = "WIFI:S:\(ssid);T:\(encryption);P:\(password);H:false;;"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(wifiString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
                // ✅ Save to Create History
                saveToCreateHistory(wifiString)
            }
        }
    }
}
