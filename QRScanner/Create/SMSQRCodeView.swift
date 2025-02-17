//
//  SMSQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct SMSQRCodeView: View {
    @State private var phoneNumber: String = ""
    @State private var message: String = ""
    @State private var qrImage: UIImage?
    @State private var isSharing = false // ✅ Share state added

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Phone Number", text: $phoneNumber)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.phonePad)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done") {
                                hideKeyboard() // ✅ Manually close keyboard
                            }
                        }
                    }

                TextField("Message", text: $message)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

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
                .disabled(phoneNumber.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("SMS")
        }
        .onTapGesture {
            hideKeyboard() // ✅ Hide keyboard when tapping outside
        }
    }

    // MARK: - Generate QR Code
    private func generateQRCode() {
        hideKeyboard() // ✅ Close keyboard when clicking generate

        let smsString = "SMSTO:\(phoneNumber):\(message)"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(smsString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
                saveToCreateHistory(smsString)
            }
        }
    }
}
