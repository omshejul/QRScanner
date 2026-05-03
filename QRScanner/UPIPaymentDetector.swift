import Foundation

enum UPIPaymentDetector {
    private static let upiSchemePrefix = "upi://pay"
    private static let npciUPIApplicationIdentifier = "A000000524"
    private static let merchantAccountInfoRange = 2...51
    private static let currencyCodesByNumericCode = [
        "036": "AUD",
        "124": "CAD",
        "156": "CNY",
        "344": "HKD",
        "356": "INR",
        "392": "JPY",
        "458": "MYR",
        "524": "NPR",
        "702": "SGD",
        "764": "THB",
        "784": "AED",
        "826": "GBP",
        "840": "USD",
        "978": "EUR"
    ]
    
    private struct EMVTag {
        let id: String
        let value: String
    }
    
    private struct EMVUPIPayload {
        let tags: [String: String]
        let upiAccountTemplates: [[String: String]]
        
        var payeeAddress: String? {
            upiAccountTemplates.compactMap { template in
                let value = template["01"]
                return value?.contains("@") == true ? value : nil
            }.first
        }
        
        var payeeName: String? {
            tags["59"]
        }
        
        var amount: String? {
            tags["54"]
        }
        
        var merchantCategoryCode: String? {
            tags["52"]
        }
        
        var transactionCurrency: String? {
            guard let currency = tags["53"] else { return nil }
            return UPIPaymentDetector.currencyCodesByNumericCode[currency] ?? currency
        }
        
        var transactionReference: String? {
            upiAccountTemplates.compactMap { template in
                let value = template["01"]
                return value?.contains("@") == true ? nil : value
            }.first ?? parseNestedTags(from: tags["62"])["05"]
        }
    }
    
    static func isUPIPayment(_ text: String) -> Bool {
        isUPIURL(text) || emvUPIPayload(from: text) != nil
    }
    
    static func paymentURLString(from text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isUPIURL(trimmedText) {
            return trimmedText
        }
        
        guard let payload = emvUPIPayload(from: trimmedText),
              let payeeAddress = payload.payeeAddress,
              !payeeAddress.isEmpty else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        
        var queryItems = [URLQueryItem(name: "pa", value: payeeAddress)]
        appendQueryItem("pn", payload.payeeName, to: &queryItems)
        appendQueryItem("mc", payload.merchantCategoryCode, to: &queryItems)
        appendQueryItem("tr", payload.transactionReference, to: &queryItems)
        appendQueryItem("am", payload.amount, to: &queryItems)
        appendQueryItem("cu", payload.transactionCurrency, to: &queryItems)
        components.queryItems = queryItems
        
        return components.string
    }
    
    private static func emvUPIPayload(from text: String) -> EMVUPIPayload? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isUPIURL(trimmedText),
              trimmedText.hasPrefix("000201"),
              let rootTags = parseTLV(trimmedText) else {
            return nil
        }
        
        let tags = dictionary(from: rootTags)
        guard tags["00"] == "01" else {
            return nil
        }
        
        var upiAccountTemplates: [[String: String]] = []
        for tag in rootTags {
            guard let numericID = Int(tag.id),
                  merchantAccountInfoRange.contains(numericID),
                  let merchantTags = parseTLV(tag.value) else {
                continue
            }
            
            let merchantAccountInfo = dictionary(from: merchantTags)
            if merchantAccountInfo["00"] == npciUPIApplicationIdentifier {
                upiAccountTemplates.append(merchantAccountInfo)
            }
        }
        
        guard !upiAccountTemplates.isEmpty else { return nil }
        return EMVUPIPayload(tags: tags, upiAccountTemplates: upiAccountTemplates)
    }
    
    private static func isUPIURL(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .hasPrefix(upiSchemePrefix)
    }
    
    private static func appendQueryItem(_ name: String, _ value: String?, to queryItems: inout [URLQueryItem]) {
        guard let value, !value.isEmpty else { return }
        queryItems.append(URLQueryItem(name: name, value: value))
    }
    
    private static func parseNestedTags(from text: String?) -> [String: String] {
        guard let text, let tags = parseTLV(text) else { return [:] }
        return dictionary(from: tags)
    }
    
    private static func dictionary(from tags: [EMVTag]) -> [String: String] {
        tags.reduce(into: [:]) { result, tag in
            result[tag.id] = tag.value
        }
    }
    
    private static func parseTLV(_ text: String) -> [EMVTag]? {
        var tags: [EMVTag] = []
        var index = text.startIndex
        
        while index < text.endIndex {
            guard let idEndIndex = text.index(index, offsetBy: 2, limitedBy: text.endIndex),
                  let lengthEndIndex = text.index(idEndIndex, offsetBy: 2, limitedBy: text.endIndex) else {
                return nil
            }
            
            let id = String(text[index..<idEndIndex])
            let lengthText = String(text[idEndIndex..<lengthEndIndex])
            guard id.allSatisfy(\.isNumber),
                  lengthText.allSatisfy(\.isNumber),
                  let length = Int(lengthText),
                  let valueEndIndex = text.index(lengthEndIndex, offsetBy: length, limitedBy: text.endIndex) else {
                return nil
            }
            
            tags.append(EMVTag(id: id, value: String(text[lengthEndIndex..<valueEndIndex])))
            index = valueEndIndex
        }
        
        return tags
    }
}

enum QRContentClassifier {
    static func displayType(for text: String) -> String {
        let lowercasedText = text.lowercased()
        
        if UPIPaymentDetector.isUPIPayment(text) {
            return "UPI Payment"
        } else if lowercasedText.hasPrefix("http") {
            return "Web URL"
        } else if lowercasedText.contains("wifi:") {
            return "WiFi"
        } else if lowercasedText.hasPrefix("matmsg:") || lowercasedText.hasPrefix("mailto:") {
            return "Email"
        } else if lowercasedText.hasPrefix("smsto:") || lowercasedText.hasPrefix("sms:") {
            return "SMS"
        } else if lowercasedText.hasPrefix("tel:") {
            return "Phone"
        } else if lowercasedText.hasPrefix("begin:vcard") {
            return "Contact"
        } else if lowercasedText.hasPrefix("geo:") {
            return "Location"
        } else {
            return "QR Code"
        }
    }
    
}
