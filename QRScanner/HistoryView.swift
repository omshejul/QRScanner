//
//  HistoryView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var scanHistory: [String] = UserDefaults.standard.stringArray(forKey: "scanHistory") ?? []
    @State private var createHistory: [String] = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []

    var body: some View {
        NavigationView {
            List {
                // MARK: - Scan History Section
                if !scanHistory.isEmpty {
                    Section(header: Text("Scan History").font(.caption).foregroundColor(.gray)) {
                        ForEach(scanHistory, id: \.self) { scannedItem in
                            NavigationLink(destination: ScanResultView(scannedText: scannedItem) {}) {
                                HStack {
                                    Image(systemName: getIcon(for: scannedItem)) // ✅ Show icon
                                        .foregroundColor(.blue)

                                    Text(scannedItem)
                                        .lineLimit(1) // ✅ Prevent wrapping
                                        .truncationMode(.tail) // ✅ Show "..."
                                        .padding(2)
                                }
                            }
                        }
                        .onDelete(perform: deleteScanHistoryItem) // ✅ Swipe to delete scan history
                    }
                }

                // MARK: - Create History Section
                if !createHistory.isEmpty {
                    Section(header: Text("Create History").font(.caption).foregroundColor(.gray)) {
                        ForEach(createHistory, id: \.self) { createdItem in
                            NavigationLink(destination: ScanResultView(scannedText: createdItem) {}) {
                                HStack {
                                    Image(systemName: getIcon(for: createdItem)) // ✅ Show icon
                                        .foregroundColor(.green)

                                    Text(createdItem)
                                        .lineLimit(1) // ✅ Prevent wrapping
                                        .truncationMode(.tail) // ✅ Show "..."
                                        .padding(2)
                                }
                            }
                        }
                        .onDelete(perform: deleteCreateHistoryItem) // ✅ Swipe to delete created QR history
                    }
                }
            }
            .navigationTitle("History")
        }
        .onAppear {
            loadHistory()
        }
    }

    // MARK: - Get Icon Based on QR Code Type
    private func getIcon(for text: String) -> String {
        if text.lowercased().contains("wifi:") {
            return "wifi" // ✅ WiFi Icon
        } else if text.lowercased().hasPrefix("http") {
            return "link" // ✅ URL Icon
        } else if text.lowercased().contains("mailto:") || text.lowercased().contains("matmsg:") {
            return "envelope" // ✅ Email Icon
        } else if text.lowercased().contains("tel:") {
            return "phone" // ✅ Phone Icon
        } else if text.lowercased().contains("smsto:") {
            return "message" // ✅ SMS Icon
        } else if text.lowercased().contains("geo:") {
            return "location" // ✅ Location Icon
        } else if text.lowercased().contains("vcard") || text.lowercased().contains("begin:vcard") {
            return "person.crop.circle" // ✅ Contact Icon
        } else {
            return "qrcode" // ✅ Default QR Code Icon
        }
    }

    // MARK: - Load History from UserDefaults
    private func loadHistory() {
        scanHistory = UserDefaults.standard.stringArray(forKey: "scanHistory") ?? []
        createHistory = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []
    }

    // MARK: - Delete a Scan History Item
    private func deleteScanHistoryItem(at offsets: IndexSet) {
        var storedHistory = UserDefaults.standard.stringArray(forKey: "scanHistory") ?? []
        storedHistory.remove(atOffsets: offsets)
        UserDefaults.standard.setValue(storedHistory, forKey: "scanHistory")
        loadHistory() // Refresh list
    }

    // MARK: - Delete a Create History Item
    private func deleteCreateHistoryItem(at offsets: IndexSet) {
        var storedHistory = UserDefaults.standard.stringArray(forKey: "createHistory") ?? []
        storedHistory.remove(atOffsets: offsets)
        UserDefaults.standard.setValue(storedHistory, forKey: "createHistory")
        loadHistory() // Refresh list
    }
}
