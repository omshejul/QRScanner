//
//  SettingsView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @AppStorage("scanSoundEnabled") private var scanSoundEnabled = false
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true

    var body: some View {
        Form {
            Section(header: Text("Scan Settings")) {
                Toggle("Scan Sound", isOn: $scanSoundEnabled)
                Toggle("Scan Vibration", isOn: $vibrationEnabled)
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
