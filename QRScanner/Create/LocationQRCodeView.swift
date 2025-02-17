//
//  LocationQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct LocationQRCodeView: View {
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var qrImage: UIImage?
    @State private var isSharing = false // ✅ Share state added

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextField("Enter Latitude", text: $latitude)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.decimalPad)
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("Done") {
                                hideKeyboard() // ✅ Manually close keyboard
                            }
                        }
                    }
                
                TextField("Enter Longitude", text: $longitude)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .keyboardType(.decimalPad)
                
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
                .disabled(latitude.isEmpty || longitude.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Location")
        }
        .onTapGesture {
            hideKeyboard() // ✅ Hide keyboard when tapping outside
        }
    }

    // MARK: - Generate QR Code
    private func generateQRCode() {
        hideKeyboard() // ✅ Close keyboard when clicking generate

        let locationString = "geo:\(latitude),\(longitude)"
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(locationString.data(using: .utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let context = CIContext()
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgimg)
                saveToCreateHistory(locationString)
            }
        }
    }
}
