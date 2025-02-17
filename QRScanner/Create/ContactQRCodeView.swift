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

    var body: some View {
        ScrollView { // ✅ Prevents keyboard blocking input
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
                    .keyboardType(.phonePad)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done") {
                                hideKeyboard() // ✅ Manually close keyboard
                            }
                        }
                    }

                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(10)
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
        }
        .onTapGesture {
            hideKeyboard() // ✅ Hide keyboard when tapping outside
        }
        .navigationTitle("Contact")
    }

    private func generateQRCode() {
        hideKeyboard() // ✅ Close keyboard when clicking generate

        let contactString = "BEGIN:VCARD\nVERSION:3.0\nFN:\(name)\nTEL:\(phone)\nEND:VCARD"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(contactString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
            }
        }
    }
}
