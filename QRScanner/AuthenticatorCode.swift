import Foundation

enum AuthenticatorCode {
    static func url(from scannedText: String) -> URL? {
        let trimmedText = scannedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedText),
              url.scheme?.lowercased() == "otpauth",
              let type = url.host?.lowercased(),
              type == "totp" || type == "hotp" else {
            return nil
        }

        return url
    }

    static func removeFromScanHistory(userDefaults: UserDefaults = .standard) {
        guard let history = userDefaults.array(forKey: "scanHistory") as? [[String: Any]] else {
            return
        }

        let filteredHistory = history.filter { item in
            guard let text = item["text"] as? String else { return true }
            return url(from: text) == nil
        }

        if filteredHistory.count != history.count {
            userDefaults.set(filteredHistory, forKey: "scanHistory")
        }
    }
}
