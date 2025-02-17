//
//  ContactQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct ContactQRCodeView: View {
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var qrImage: UIImage?
    @State private var isSharing = false // ✅ Share state added

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .autocapitalization(.none)

            TextField("Enter Phone", text: $phone)
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
                    ShareSheet(activityItems: [qrImage]) // ✅ Safe unwrapping
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
            .disabled(name.isEmpty || phone.isEmpty)

            Spacer()
        }
        .padding()
        .navigationTitle("Contact")
    }

    private func generateQRCode() {
        let contactString = "BEGIN:VCARD\nVERSION:3.0\nFN:\(name)\nTEL:\(phone)\nEND:VCARD"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(contactString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
                saveToCreateHistory(contactString)
            }
        }
    }
}
