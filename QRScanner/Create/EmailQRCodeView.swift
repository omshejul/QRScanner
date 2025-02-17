//
//  EmailQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct EmailQRCodeView: View {
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var ebody: String = ""
    @State private var qrImage: UIImage?
    @State private var isSharing = false // ✅ Share state added

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)

            TextField("Enter Subject", text: $subject)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            TextField("Body", text: $ebody)
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
                    ShareSheet(activityItems: [qrImage]) 
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
            .disabled(email.isEmpty)

            Spacer()
        }
        .padding()
        .navigationTitle("Email")
    }

    // MARK: - Generate QR Code
    private func generateQRCode() {
        let emailString = "MATMSG:TO:\(email);SUB:\(subject);BODY:\(ebody);;"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(emailString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
                saveToCreateHistory(emailString)
            }
        }
    }
}
