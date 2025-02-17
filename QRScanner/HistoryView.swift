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
                                Text(scannedItem)
                                    .padding(2)
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
                                Text(createdItem)
                                    .padding(2)
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
