//
//  HistoryView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import AVFoundation
import SwiftUI

struct ScanHistoryItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let text: String
    let type: AVMetadataObject.ObjectType
    let timestamp: Date
    
    static func == (lhs: ScanHistoryItem, rhs: ScanHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CreateHistoryItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let text: String
    let type: AVMetadataObject.ObjectType
    let timestamp: Date
    let displayType: String
    
    static func == (lhs: CreateHistoryItem, rhs: CreateHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HistoryView: View {
    @State private var scanHistory: [ScanHistoryItem] = []
    @State private var createHistory: [CreateHistoryItem] = []
    @State private var isScanHistoryExpanded: Bool = true
    @State private var isCreateHistoryExpanded: Bool = true
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Scan History Section
                if !scanHistory.isEmpty {
                    Section {
                        DisclosureGroup(
                            isExpanded: $isScanHistoryExpanded,
                            content: {
                                ForEach(scanHistory.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                                    NavigationLink(
                                        destination: ScanResultView(
                                            scannedText: item.text, 
                                            barcodeType: item.type,
                                            isFromHistory: true,
                                            onDismiss: {}
                                        )
                                    ) {
                                        HStack {
                                            if item.type == .aztec {
                                                Image("aztec")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(.blue)
                                            } else {
                                                Image(systemName: getTypeIcon(for: item.type))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                Text(item.text)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                HStack {
                                                    Text("\(getBarcodeTypeName(item.type)) • \(getRelativeTime(from: item.timestamp))")
                                                }
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteScanHistoryItem)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "qrcode.viewfinder")
                                        .foregroundColor(.blue)
                                    Text("Scan History")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(scanHistory.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        )
                    }
                }
                
                // MARK: - Create History Section
                if !createHistory.isEmpty {
                    Section {
                        DisclosureGroup(
                            isExpanded: $isCreateHistoryExpanded,
                            content: {
                                ForEach(createHistory.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                                    NavigationLink(
                                        destination: ScanResultView(
                                            scannedText: item.text, 
                                            barcodeType: item.type,
                                            isFromHistory: true,
                                            onDismiss: {}
                                        )
                                    ) {
                                        HStack {
                                            if item.type == .aztec {
                                                Image("aztec-green")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(.green)
                                            } else {
                                                Image(systemName: getTypeIcon(for: item.type))
                                                    .foregroundColor(.green)
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                Text(item.text)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                HStack {
                                                    Text(item.displayType)
                                                    Text("•")
                                                    Text(getRelativeTime(from: item.timestamp))
                                                }
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteCreateHistoryItem)
                            },
                            label: {
                                HStack {
                                    Image(systemName: "plus.viewfinder")
                                        .foregroundColor(.green)
                                    Text("Create History")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(createHistory.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        )
                    }
                }
                
                if scanHistory.isEmpty && createHistory.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No History Yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Scan or create QR codes to see them here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("History")
            .onAppear(perform: loadHistory)
            .toolbar {
                if !scanHistory.isEmpty || !createHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Toggle all sections
                            isScanHistoryExpanded.toggle()
                            isCreateHistoryExpanded.toggle()
                        }) {
                            Text(isScanHistoryExpanded && isCreateHistoryExpanded ? "Collapse All" : "Expand All")
                        }
                    }
                }
            }
        }
    }
    
    private func getIcon(for text: String) -> String {
        // First check for special content patterns
        if text.starts(with: "upi://pay") {
            return "indianrupeesign.circle"
        } else if text.lowercased().contains("wifi:") {
            return "wifi"
        } else if text.lowercased().hasPrefix("http") || text.lowercased().hasPrefix("https") {
            return "safari"
        } else if text.lowercased().contains("mailto:") || text.lowercased().contains("matmsg:") {
            return "envelope"
        } else if text.lowercased().contains("tel:") {
            return "phone"
        } else if text.lowercased().contains("smsto:") || text.lowercased().contains("sms:") {
            return "message"
        } else if text.lowercased().contains("geo:") || text.lowercased().contains("maps:") {
            return "location"
        } else if text.lowercased().contains("vcard") || text.lowercased().contains("begin:vcard") {
            return "person.crop.circle"
        } else if text.lowercased().contains("mecard:") {
            return "person.text.rectangle"
        } else if text.lowercased().contains("market:")
                    || text.lowercased().contains("play.google.com")
        {
            return "bag"
        } else if text.lowercased().contains("bitcoin:") {
            return "bitcoinsign.circle"
        } else if text.lowercased().contains("facetime:") {
            return "video"
        } else if text.lowercased().contains("calendar")
                    || text.lowercased().contains("BEGIN:VEVENT")
        {
            return "calendar"
        } else if text.allSatisfy({ $0.isNumber }) {
            // For numeric codes (likely barcodes)
            switch text.count {
            case 8:  // EAN-8, UPC-E
                return "cart.fill.badge.plus"
            case 12:  // UPC-A
                return "cart"
            case 13:  // EAN-13, ISBN-13
                return "book.closed"
            case 14:  // ITF-14
                return "shippingbox"
            default:
                return "barcode"
            }
        } else if text.contains(" ") && text.split(separator: " ").count > 3 {
            // Likely text content
            return "doc.text"
        } else {
            // Default icon based on type
            return "qrcode"
        }
    }
    
    private func getTypeIcon(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr:
            return "qrcode"
        case .aztec:
            return "aztec"
        case .ean8, .upce:
            return "cart.fill.badge.plus"
        case .ean13:
            return "cart"
        case .pdf417:
            return "doc.text.fill"
        case .code128, .code39, .code39Mod43:
            return "barcode"
        case .code93:
            return "barcode"
        case .dataMatrix:
            return "square.grid.2x2"
        case .interleaved2of5:
            return "number.square.fill"
        case .itf14:
            return "shippingbox.fill"
        case .codabar:
            return "creditcard.fill"
        default:
            return "barcode"
        }
    }
    
    private func getBarcodeTypeName(_ type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr:
            return "QR Code"
        case .ean8:
            return "EAN-8"
        case .ean13:
            return "EAN-13"
        case .pdf417:
            return "PDF417"
        case .aztec:
            return "Aztec"
        case .code128:
            return "Code 128"
        case .code39:
            return "Code 39"
        case .code93:
            return "Code 93"
        case .dataMatrix:
            return "Data Matrix"
        case .interleaved2of5:
            return "Interleaved 2 of 5"
        case .itf14:
            return "ITF-14"
        case .upce:
            return "UPC-E"
        default:
            return "Barcode"
        }
    }
    
    // MARK: - Load History from UserDefaults
    private func loadHistory() {
        print("Loading history...")
        
        // Load scan history with type information
        if let savedHistory = UserDefaults.standard.array(forKey: "scanHistory") as? [[String: Any]]
        {
            print("Found \(savedHistory.count) scan history items")
            scanHistory = savedHistory.compactMap { item in
                guard let text = item["text"] as? String,
                      let typeString = item["type"] as? String,
                      let timestamp = item["timestamp"] as? Date
                else {
                    print("Invalid scan history item: \(item)")
                    return nil
                }
                return ScanHistoryItem(
                    text: text, type: AVMetadataObject.ObjectType(rawValue: typeString),
                    timestamp: timestamp)
            }
            print("Loaded \(scanHistory.count) scan history items")
        } else {
            print("No scan history found")
        }
        
        // Load create history with timestamps and display type
        if let savedCreateHistory = UserDefaults.standard.array(forKey: "createHistory")
            as? [[String: Any]]
        {
            print("Found \(savedCreateHistory.count) create history items")
            createHistory = savedCreateHistory.compactMap { item in
                print("Processing item: \(item)")
                guard let text = item["text"] as? String,
                      let typeString = item["type"] as? String,
                      let timestamp = item["timestamp"] as? Date
                else {
                    print("Invalid create history item: \(item)")
                    return nil
                }
                
                // Handle case where displayType might be missing (for older entries)
                let displayType: String
                if let savedDisplayType = item["displayType"] as? String {
                    displayType = savedDisplayType
                } else {
                    // Determine display type from content
                    if text.starts(with: "WIFI:") {
                        displayType = "WiFi"
                    } else if text.starts(with: "http") {
                        displayType = "Web URL"
                    } else if text.starts(with: "MATMSG:") {
                        displayType = "Email"
                    } else if text.starts(with: "SMSTO:") {
                        displayType = "SMS"
                    } else if text.starts(with: "TEL:") {
                        displayType = "Phone"
                    } else if text.starts(with: "BEGIN:VCARD") {
                        displayType = "Contact"
                    } else if text.starts(with: "geo:") {
                        displayType = "Location"
                    } else {
                        displayType = "QR Code"
                    }
                    
                    // Update the item in UserDefaults with the display type
                    var updatedItem = item
                    updatedItem["displayType"] = displayType
                    
                    // Find and update the item in the array
                    if let index = savedCreateHistory.firstIndex(where: { ($0["text"] as? String) == text }) {
                        var updatedHistory = savedCreateHistory
                        updatedHistory[index] = updatedItem
                        UserDefaults.standard.setValue(updatedHistory, forKey: "createHistory")
                    }
                }
                
                return CreateHistoryItem(
                    text: text,
                    type: AVMetadataObject.ObjectType(rawValue: typeString),
                    timestamp: timestamp,
                    displayType: displayType
                )
            }
            print("Loaded \(createHistory.count) create history items")
        } else {
            print("No create history found")
        }
    }
    
    // Helper function to format relative time
    private func getRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Delete History Items
    private func deleteScanHistoryItem(at offsets: IndexSet) {
        // Get the sorted items as they appear in the UI
        let sortedItems = scanHistory.sorted(by: { $0.timestamp > $1.timestamp })
        
        // Get the items to delete based on their IDs
        let itemsToDelete = offsets.map { sortedItems[$0] }
        
        // Remove the items from the local array first
        scanHistory.removeAll(where: { item in
            itemsToDelete.contains(where: { $0.id == item.id })
        })
        
        // Update UserDefaults with the new array
        let updatedHistory = scanHistory.map { item -> [String: Any] in
            return [
                "text": item.text,
                "type": item.type.rawValue,
                "timestamp": item.timestamp
            ]
        }
        
        UserDefaults.standard.setValue(updatedHistory, forKey: "scanHistory")
        
        // Force UI refresh by updating the @State variable
        scanHistory = scanHistory
    }
    
    private func deleteCreateHistoryItem(at offsets: IndexSet) {
        // Get the sorted items as they appear in the UI
        let sortedItems = createHistory.sorted(by: { $0.timestamp > $1.timestamp })
        
        // Get the items to delete based on their IDs
        let itemsToDelete = offsets.map { sortedItems[$0] }
        
        // Remove the items from the local array first
        createHistory.removeAll(where: { item in
            itemsToDelete.contains(where: { $0.id == item.id })
        })
        
        // Update UserDefaults with the new array
        let updatedHistory = createHistory.map { item -> [String: Any] in
            return [
                "text": item.text,
                "type": item.type.rawValue,
                "timestamp": item.timestamp,
                "displayType": item.displayType
            ]
        }
        
        UserDefaults.standard.setValue(updatedHistory, forKey: "createHistory")
        
        // Force UI refresh by updating the @State variable
        createHistory = createHistory
    }
}
