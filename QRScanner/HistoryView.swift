//
//  HistoryView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var history: [String] = UserDefaults.standard.stringArray(forKey: "qrHistory") ?? []

    var body: some View {
        NavigationView {
            List {
                ForEach(history, id: \.self) { item in
                    NavigationLink(destination: ScanResultView(scannedText: item) {}) {
                        Text(item)
                            .padding(2)
                    }
                }
                .onDelete(perform: deleteHistoryItem) // ✅ Swipe to delete
            }
            .navigationTitle("Scan History")
        }
        .onAppear {
            loadHistory()
        }
    }

    // MARK: - Load History from UserDefaults
    private func loadHistory() {
        history = UserDefaults.standard.stringArray(forKey: "qrHistory") ?? []
    }

    // MARK: - Delete a History Item
    private func deleteHistoryItem(at offsets: IndexSet) {
        var storedHistory = UserDefaults.standard.stringArray(forKey: "qrHistory") ?? []
        storedHistory.remove(atOffsets: offsets)
        UserDefaults.standard.setValue(storedHistory, forKey: "qrHistory")
        loadHistory() // Refresh list
    }
}
