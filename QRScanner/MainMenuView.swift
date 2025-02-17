//
//  MainMenuView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink("Scan QR Code", destination: Text("Scanner Screen (Coming Soon)"))
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("Generate QR Code", destination: Text("Generator Screen (Coming Soon)"))
                    .buttonStyle(.borderedProminent)
                
                NavigationLink("View History", destination: Text("History Screen (Coming Soon)"))
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("QR Code App")
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
