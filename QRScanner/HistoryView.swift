//
//  HistoryView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation

struct ScanHistoryItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: AVMetadataObject.ObjectType
    
    static func == (lhs: ScanHistoryItem, rhs: ScanHistoryItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HistoryView: View {
    @State private var scanHistory: [ScanHistoryItem] = []
    @State private var createHistory: [String] = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []

    var body: some View {
        NavigationView {
            List {
                // MARK: - Scan History Section
                if !scanHistory.isEmpty {
                    Section(header: Text("Scan History").font(.caption).foregroundColor(.gray)) {
                        ForEach(scanHistory) { item in
                            NavigationLink(destination: ScanResultView(scannedText: item.text, barcodeType: item.type) {}) {
                                HStack {
                                    // Show content-specific icon if available, otherwise show type icon
                                    Image(systemName: item.text.allSatisfy({ $0.isNumber }) ? getTypeIcon(for: item.type) : getIcon(for: item.text))
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading) {
                                        Text(item.text)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Text(getBarcodeTypeName(item.type))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .onDelete(perform: deleteScanHistoryItem)
                    }
                }

                // MARK: - Create History Section
                if !createHistory.isEmpty {
                    Section(header: Text("Create History").font(.caption).foregroundColor(.gray)) {
                        ForEach(createHistory, id: \.self) { createdItem in
                            NavigationLink(destination: ScanResultView(scannedText: createdItem, barcodeType: .qr) {}) {
                                HStack {
                                    Image(systemName: getIcon(for: createdItem))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text(createdItem)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Text("QR Code")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .onDelete(perform: deleteCreateHistoryItem)
                    }
                }

                if scanHistory.isEmpty && createHistory.isEmpty {
                    Text("No history yet")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("History")
            .onAppear(perform: loadHistory)
        }
    }

    private func getIcon(for text: String) -> String {
        // First check for special content patterns
        if text.lowercased().contains("wifi:") {
            return "wifi"
        } else if text.lowercased().hasPrefix("http") {
            return "safari"
        } else if text.lowercased().contains("mailto:") || text.lowercased().contains("matmsg:") {
            return "envelope"
        } else if text.lowercased().contains("tel:") {
            return "phone"
        } else if text.lowercased().contains("smsto:") {
            return "message"
        } else if text.lowercased().contains("geo:") {
            return "location"
        } else if text.lowercased().contains("vcard") || text.lowercased().contains("begin:vcard") {
            return "person.crop.circle"
        } else if text.allSatisfy({ $0.isNumber }) {
            // For numeric codes (likely barcodes), use barcode icon
            return "barcode.viewfinder"
        } else {
            // Default icon based on type
            return "qrcode"
        }
    }

    private func getTypeIcon(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .ean8, .ean13, .upce:
            return "barcode.viewfinder"
        case .pdf417:
            return "doc.viewfinder"
        case .aztec:
            return "square.grid.3x3.square"
        case .dataMatrix:
            return "square.grid.2x2"
        case .code128, .code39, .code93, .interleaved2of5, .itf14:
            return "barcode"
        case .qr:
            return "qrcode"
        default:
            return "viewfinder"
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
        // Load scan history with type information
        if let savedHistory = UserDefaults.standard.array(forKey: "scanHistory") as? [[String: String]] {
            scanHistory = savedHistory.compactMap { item in
                guard let text = item["text"],
                      let typeString = item["type"] else {
                    return nil
                }
                return ScanHistoryItem(text: text, type: AVMetadataObject.ObjectType(rawValue: typeString))
            }
        }
        
        // Load create history
        createHistory = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []
    }

    // MARK: - Delete a Scan History Item
    private func deleteScanHistoryItem(at offsets: IndexSet) {
        var savedHistory = UserDefaults.standard.array(forKey: "scanHistory") as? [[String: String]] ?? []
        offsets.forEach { index in
            if index < savedHistory.count {
                savedHistory.remove(at: index)
            }
        }
        UserDefaults.standard.setValue(savedHistory, forKey: "scanHistory")
        loadHistory()
    }

    // MARK: - Delete a Create History Item
    private func deleteCreateHistoryItem(at offsets: IndexSet) {
        var storedHistory = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []
        storedHistory.remove(atOffsets: offsets)
        UserDefaults.standard.setValue(storedHistory, forKey: "createHistory")
        loadHistory()
    }
}

