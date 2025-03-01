//
//  BASICQRCodeView.swift
//  QRScanner
//
//  Created by Om Shejul on 18/02/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation
import ContactsUI
import MapKit
import CoreLocation

enum QRType: String, CaseIterable {
    case wifi = "WiFi"
    case web = "Web URL"
    case text = "Text"
    case email = "Email"
    case phone = "Phone"
    case sms = "SMS"
    case location = "Location"
    case contact = "Contact"
}

// MARK: - BASIC QR Code View
struct BASICQRCodeView: View {
    let type: QRType
    @State private var primaryInput: String = ""
    @State private var secondaryInput: String = ""
    @State private var optionalFields: [String: String] = [:]
    @State private var selectedEncryption = "WPA"
    @State private var isHiddenNetwork = false
    @State private var qrImage: UIImage?
    @State private var isSharingQR = false
    @State private var qrShareURL: URL?
    @State private var isGeneratingQR = false
    @State private var isQRReady = false
    @State private var errorMessage: String?
    @State private var showContactPicker = false
    @State private var contactPickerField: String? = nil
    @State private var showLocationPicker = false
    
    let encryptionOptions = ["WPA", "WEP", "None"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if type == .email {
                    ZStack(alignment: .trailingFirstTextBaseline) {
                        InputField(title: "Enter Recipient Email",
                                   info: "Enter the email address where the message will be sent.",
                                   text: $primaryInput,
                                   keyboardType: .emailAddress)
                        
                        Button(action: {
                            contactPickerField = "email"
                            showContactPicker = true
                            errorMessage = nil
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                        .padding(.trailing, 30)
                    }
                    
                    InputField(title: "Enter Subject (Optional)",
                               info: "You can add a subject for the email.",
                               text: Binding(
                                get: { optionalFields["subject"] ?? "" },
                                set: { optionalFields["subject"] = $0 }
                               ))
                    
                    InputField(title: "Enter Body (Optional)",
                               info: "Write the content of the email.",
                               text: Binding(
                                get: { optionalFields["body"] ?? "" },
                                set: { optionalFields["body"] = $0 }
                               ))
                }
                
                else if type == .sms {
                    ZStack(alignment: .trailingFirstTextBaseline) {
                        InputField(title: "Enter Phone Number",
                                   info: "Enter the phone number to send the SMS message to.",
                                   text: $primaryInput,
                                   keyboardType: .phonePad)
                        
                        Button(action: {
                            contactPickerField = "phone"
                            showContactPicker = true
                            errorMessage = nil
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                        .padding(.trailing, 30)
                    }
                    
                    InputField(title: "Enter Message (Optional)",
                               info: "",
                               text: Binding(
                                get: { optionalFields["message"] ?? "" },
                                set: { optionalFields["message"] = $0 }
                               ))
                }
                
                else if type == .wifi {
                    InputField(title: "Enter SSID",
                               info: "Enter network name as it appears in Wi-Fi setting.",
                               text: $primaryInput)
                    
                    InputField(title: "Enter Wifi Password",
                               info: "Leave empty if it's an open network.",
                               text: $secondaryInput)
                    
                    // Encryption Type Picker
                    Picker("Encryption Type", selection: $selectedEncryption) {
                        ForEach(encryptionOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    Text("If you don't know, its probably WPA")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    // Hidden Network Toggle
                    Toggle("Hidden Network", isOn: $isHiddenNetwork)
                        .padding(.horizontal)
                }
                
                else if type == .location {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Location Options")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manual Coordinates Entry")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            InputField(title: "Enter Latitude",
                                       info: "Must be between -90 and 90.",
                                       text: $primaryInput,
                                       keyboardType: .decimalPad)
                            
                            InputField(title: "Enter Longitude",
                                       info: "Must be between -180 and 180.",
                                       text: $secondaryInput,
                                       keyboardType: .decimalPad)
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        Button(action: {
                            self.hideKeyboard()
                            showLocationPicker = true
                        }) {
                            HStack {
                                Image(systemName: "map")
                                    .font(.system(size: 20))
                                Text("Select Location on Map")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        if !primaryInput.isEmpty && !secondaryInput.isEmpty,
                           let lat = Double(primaryInput), let lon = Double(secondaryInput),
                           (-90...90).contains(lat), (-180...180).contains(lon) {
                            Text("Selected: \(lat), \(lon)")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal)
                        }
                    }
                    .sheet(isPresented: $showLocationPicker) {
                        LocationMapView(latitude: $primaryInput, longitude: $secondaryInput)
                    }
                }
                
                else if type == .contact {
                    VStack {
                        HStack {
                            Text("Select from Contacts")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                contactPickerField = "fullcontact"
                                showContactPicker = true
                                errorMessage = nil
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("Select Contact")
                                }
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Or enter details manually:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    ContactFields(optionalFields: $optionalFields)
                }
                else if type == .web {
                    InputField(title: getPlaceholder(),
                               info: "Enter the link in format http:// or https:// or ://",
                               text: $primaryInput)
                }
                else if type == .phone {
                    ZStack(alignment: .trailingFirstTextBaseline) {
                        InputField(title: getPlaceholder(),
                                   info: "Enter the phone number with or without a country code",
                                   text: $primaryInput,
                                   keyboardType: .phonePad)
                        
                        Button(action: {
                            contactPickerField = "phone"
                            showContactPicker = true
                            errorMessage = nil
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                        .padding(.trailing, 30)
                    }
                }
                
                else {
                    InputField(title: getPlaceholder(),
                               info: "",
                               text: $primaryInput)
                }
                
                
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                if let qrImage = qrImage {
                    QRCodeImageView(qrImage: qrImage)
                    // Share QR Button
                    
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
                    
                    Button(action: { hideKeyboard() }) {
                        HStack() {
                            Text("Done")
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                    }
                    
                    .padding(.horizontal)
                }
            }
        }
        .onTapGesture { hideKeyboard() }
        .navigationTitle(type.rawValue)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(selectedField: contactPickerField ?? "", onContactSelected: handleContactSelection)
        }
    }
    
    private func handleContactSelection(contact: CNContact) {
        switch contactPickerField {
        case "email":
            if let email = contact.emailAddresses.first?.value as String? {
                primaryInput = email
            } else {
                errorMessage = "No email found in the selected contact."
            }
        case "phone":
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                primaryInput = phone
            } else {
                errorMessage = "No phone number found in the selected contact."
            }
        case "fullcontact":
            // Fill in all contact fields
            if let name = [contact.givenName, contact.familyName].filter({ !$0.isEmpty }).joined(separator: " ").nilIfEmpty() {
                optionalFields["name"] = name
            }
            
            if let email = contact.emailAddresses.first?.value as String? {
                optionalFields["email"] = email
            }
            
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                optionalFields["phone"] = phone
            }
            
            if let company = contact.organizationName.nilIfEmpty() {
                optionalFields["company"] = company
            }
            
            if let jobTitle = contact.jobTitle.nilIfEmpty() {
                optionalFields["jobTitle"] = jobTitle
            }
            
            if let url = contact.urlAddresses.first?.value as String? {
                optionalFields["website"] = url
            }
            
            if let address = contact.postalAddresses.first {
                let addressComponents = [
                    address.value.street,
                    address.value.city,
                    address.value.state,
                    address.value.postalCode,
                    address.value.country
                ].filter { !$0.isEmpty }
                
                optionalFields["address"] = addressComponents.joined(separator: ", ")
            }
            
            if let note = contact.note.nilIfEmpty() {
                optionalFields["notes"] = note
            }
        default:
            break
        }
    }
    
    private func generateQRCode() {
        hideKeyboard()
        errorMessage = nil
        let qrString = generateQRString()
        
        print("Generated QR String: \(qrString)")
        
        guard !qrString.isEmpty else {
            errorMessage = "Invalid input. Please check your values."
            return
        }
        
        if let image = generateQRCodeImage(from: qrString, isDarkMode: getCurrentThemeMode()) {
            qrImage = image
            print("Saving to history: \(qrString)")
            saveToCreateHistory(qrString)
        }
    }
    
    // MARK: - Generate QR Code & Save to File Before Sharing
    func generateQRCodeAndShare() {
        isQRReady = false // ✅ Prevent sharing until ready
        isGeneratingQR = true // ✅ Ensure UI updates immediately
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let _ = windowScene.windows.first else {
                isGeneratingQR = false
                return
            }
            
            // Use getCurrentThemeMode() instead of manual calculation
            let isDark = getCurrentThemeMode()
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let image = generateQRCodeImage(from: generateQRString(), isDarkMode: isDark) {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("QRCode.png")
                    try? image.pngData()?.write(to: tempURL) // ✅ Save image before sharing
                    
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
        case .wifi:
            return "WIFI:S:\(primaryInput);T:\(selectedEncryption);P:\(secondaryInput);H:\(isHiddenNetwork ? "true" : "false");;"
        case .web, .text:
            return primaryInput
        case .email:
            return "MATMSG:TO:\(primaryInput);SUB:\(optionalFields["subject"] ?? "");BODY:\(optionalFields["body"] ?? "");;"
        case .sms:
            return "SMSTO:\(primaryInput):\(optionalFields["message"] ?? "")"
        case .phone:
            return "TEL:\(primaryInput)"
        case .location:
            guard let lat = Double(primaryInput), let long = Double(secondaryInput),
                  (-90...90).contains(lat), (-180...180).contains(long) else {
                errorMessage = "Invalid coordinates. Ensure lat is between -90 and 90, and long between -180 and 180."
                return ""
            }
            return "geo:\(lat),\(long)"
        case .contact:
            return generateVCard()
        }
    }
    
    private func generateVCard() -> String {
        var vCard = "BEGIN:VCARD\nVERSION:3.0\n"
        
        if let name = optionalFields["name"], !name.isEmpty {
            vCard += "FN:\(name)\n"
        }
        if let email = optionalFields["email"], !email.isEmpty {
            vCard += "EMAIL:\(email)\n"
        }
        if let phone = optionalFields["phone"], !phone.isEmpty {
            vCard += "TEL:\(phone)\n"
        }
        if let company = optionalFields["company"], !company.isEmpty {
            vCard += "ORG:\(company)\n"
        }
        if let jobTitle = optionalFields["jobTitle"], !jobTitle.isEmpty {
            vCard += "TITLE:\(jobTitle)\n"
        }
        if let website = optionalFields["website"], !website.isEmpty {
            vCard += "URL:\(website)\n"
        }
        if let address = optionalFields["address"], !address.isEmpty {
            vCard += "ADR:;;\(address);;;;\n"
        }
        if let notes = optionalFields["notes"], !notes.isEmpty {
            vCard += "NOTE:\(notes)\n"
        }
        
        vCard += "END:VCARD"
        return vCard
    }
    
    private func isInputInvalid() -> Bool {
        switch type {
        case .wifi:
            return primaryInput.isEmpty // WiFi requires SSID
        case .web, .text, .email, .phone, .sms:
            return primaryInput.isEmpty // Requires at least primary input
        case .location:
            return primaryInput.isEmpty || secondaryInput.isEmpty // Requires latitude & longitude
        case .contact:
            return optionalFields.values.allSatisfy { $0.isEmpty } // Requires at least 1 field
        }
    }
    
    private func getPlaceholder() -> String {
        switch type {
        case .wifi: return "Enter SSID"
        case .web: return "https://omshejul.com"
        case .text: return "Enter Text"
        case .email: return "Enter Email"
        case .phone: return "Enter Phone Number"
        case .sms: return "Enter Phone Number"
        case .contact: return "Enter Name"
        default: return ""
        }
    }
    
    // MARK: - Save to Create History
    func saveToCreateHistory(_ createdText: String) {
        let displayType: String
        if createdText.starts(with: "WIFI:") {
            displayType = "WiFi"
        } else if createdText.starts(with: "http") {
            displayType = "Web URL"
        } else if createdText.starts(with: "MATMSG:") {
            displayType = "Email"
            print("Detected Email QR Code")
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
        
        print("History item to save: \(createItem)")
        
        var history = UserDefaults.standard.array(forKey: "createHistory") as? [[String: Any]] ?? []
        print("Current history count: \(history.count)")
        
        // Check if item already exists in history
        if let existingIndex = history.firstIndex(where: { ($0["text"] as? String) == createdText }) {
            // Replace the existing item with the new one
            history[existingIndex] = createItem
            print("Replaced existing item in history")
        } else {
            // Add as a new item
            history.append(createItem)
            print("Added new item to history")
        }
        
        // Save the updated history
        UserDefaults.standard.setValue(history, forKey: "createHistory")
        print("Saved to history. New count: \(history.count)")
    }
}

// MARK: - Input Field
struct InputField: View {
    let title: String
    let info: String?
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { // ✅ Ensures text and info align properly
            TextField(title, text: $text)
                .padding() // ✅ Adds padding inside the field
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .keyboardType(keyboardType)
            
            if let info = info {
                Text(info)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal) // ✅ Adds padding outside the entire component
    }
}

// MARK: - Contact Fields
struct ContactFields: View {
    @Binding var optionalFields: [String: String]
    
    var body: some View {
        VStack {
            InputField(title: "Name (optional)", info: "", text: Binding(
                get: { optionalFields["name"] ?? "" },
                set: { optionalFields["name"] = $0 }
            ))
            InputField(title: "Enter Email (optional)", info: "", text: Binding(
                get: { optionalFields["email"] ?? "" },
                set: { optionalFields["email"] = $0 }
            ))
            InputField(title: "Enter Phone (optional)", info: "", text: Binding(
                get: { optionalFields["phone"] ?? "" },
                set: { optionalFields["phone"] = $0 }
            ), keyboardType: .phonePad)
            InputField(title: "Enter Company (optional)", info: "", text: Binding(
                get: { optionalFields["company"] ?? "" },
                set: { optionalFields["company"] = $0 }
            ))
            InputField(title: "Enter Job Title (optional)", info: "", text: Binding(
                get: { optionalFields["jobTitle"] ?? "" },
                set: { optionalFields["jobTitle"] = $0 }
            ))
            InputField(title: "Enter Website (optional)", info: "", text: Binding(
                get: { optionalFields["website"] ?? "" },
                set: { optionalFields["website"] = $0 }
            ), keyboardType: .URL)
            InputField(title: "Enter Address (optional)", info: "", text: Binding(
                get: { optionalFields["address"] ?? "" },
                set: { optionalFields["address"] = $0 }
            ))
            InputField(title: "Enter Notes (optional)", info: "", text: Binding(
                get: { optionalFields["notes"] ?? "" },
                set: { optionalFields["notes"] = $0 }
            ))
        }
    }
}

// MARK: - QR Code Image View
struct QRCodeImageView: View {
    let qrImage: UIImage
    @State private var isSharing = false
    
    var body: some View {
        VStack {
            Image(uiImage: qrImage)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(10)
            
                .padding(.horizontal)
                .sheet(isPresented: $isSharing) {
                    ShareSheet(activityItems: [qrImage])
                }
        }
    }
}

// MARK: - Helper Extensions    

// Extension to help with optional strings
extension String {
    func nilIfEmpty() -> String? {
        return self.isEmpty ? nil : self
    }
}

// Contact Picker View using UIViewControllerRepresentable
struct ContactPickerView: UIViewControllerRepresentable {
    let selectedField: String
    let onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onContactSelected(contact)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Handle cancel if needed
        }
    }
}

// MARK: - Preview
struct BASICQRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for WiFi QR code
            BASICQRCodeView(type: .wifi)
                .previewDisplayName("WiFi QR Code")
            
            // Preview for Web URL QR code
            BASICQRCodeView(type: .web)
                .previewDisplayName("Web URL QR Code")
            
            // Preview for Text QR code
            BASICQRCodeView(type: .text)
                .previewDisplayName("Text QR Code")
            
            // Preview for Email QR code
            BASICQRCodeView(type: .email)
                .previewDisplayName("Email QR Code")
            
            // Preview for Phone QR code
            BASICQRCodeView(type: .phone)
                .previewDisplayName("Phone QR Code")
            
            // Preview for SMS QR code
            BASICQRCodeView(type: .sms)
                .previewDisplayName("SMS QR Code")
            
            // Preview for Location QR code
            BASICQRCodeView(type: .location)
                .previewDisplayName("Location QR Code")
            
            // Preview for Contact QR code
            BASICQRCodeView(type: .contact)
                .previewDisplayName("Contact QR Code")
        }
    }
}
