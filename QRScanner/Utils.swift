//
//  Utils.swift
//  QRScanner
//
//  Created by Om Shejul on 18/02/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
