//
//  AdvanceQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

enum AdvanceQRType: String, CaseIterable {
    case upi = "UPI Payment"
}

struct AdvanceQRCodeView: View {
    let type: AdvanceQRType
    @State private var vpa: String = ""
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var message: String = ""
    @State private var qrImage: UIImage?
    @State private var isSharingQR = false
    @State private var qrShareURL: URL?
    @State private var isGeneratingQR = false
    @State private var isQRReady = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if type == .upi {
                    InputField(title: "Enter UPI ID",
                               info: "Enter your UPI ID (e.g., username@upi)",
                               text: $vpa)
                    
                    InputField(title: "Enter Name",
                               info: "Enter recipient's name",
                               text: $name)
                    
                    InputField(title: "Enter Amount (Optional)",
                               info: "Leave empty for user to enter amount",
                               text: $amount,
                               keyboardType: .decimalPad)
                    
                    InputField(title: "Enter Message (Optional)",
                               info: "Add a note for the payment",
                               text: $message)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                if let qrImage = qrImage {
                    QRCodeImageView(qrImage: qrImage)
                    
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
                }
                
                GenerateQRButton(action: generateQRCode, isDisabled: isInputInvalid())
                    .padding()
                
                Spacer()
            }
            .padding(4)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { hideKeyboard() }
                }
            }
        }
        .onTapGesture { hideKeyboard() }
        .navigationTitle(type.rawValue)
    }
    
    private func generateQRCode() {
        hideKeyboard()
        errorMessage = nil
        let qrString = generateQRString()
        
        guard !qrString.isEmpty else {
            errorMessage = "Invalid input. Please check your values."
            return
        }
        
        if let image = generateQRCodeImage(from: qrString, isDarkMode: getCurrentThemeMode()) {
            qrImage = image
            saveToCreateHistory(qrString)
        }
    }
    
    private func generateQRCodeAndShare() {
        isQRReady = false
        isGeneratingQR = true
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let _ = windowScene.windows.first else {
                isGeneratingQR = false
                return
            }
            
            let isDark = getCurrentThemeMode()
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let image = generateQRCodeImage(from: generateQRString(), isDarkMode: isDark) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.png")
                    try? image.pngData()?.write(to: tempURL)
                    
                    DispatchQueue.main.async {
                        qrShareURL = tempURL
                        isSharingQR = true
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
    
    private func generateQRString() -> String {
        switch type {
        case .upi:
            var upiString = "upi://pay?pa=\(vpa)&pn=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if !amount.isEmpty {
                if let amountValue = Double(amount), amountValue > 0 {
                    upiString += "&am=\(amountValue)"
                }
            }
            
            if !message.isEmpty {
                upiString += "&tn=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }
            
            return upiString
        }
    }
    
    private func isInputInvalid() -> Bool {
        switch type {
        case .upi:
            // Basic validation for UPI ID format
            let isValidVPA = vpa.contains("@") && vpa.split(separator: "@").count == 2
            return vpa.isEmpty || name.isEmpty || !isValidVPA
        }
    }
} 
