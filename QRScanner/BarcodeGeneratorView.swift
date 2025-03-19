import AVFoundation
import RSBarcodes_Swift
import SwiftUI

struct BarcodeGeneratorView: View {
    let type: BarcodeType
    @State private var content: String = ""
    @State private var generatedBarcode: UIImage?
    @State private var isSharingBarcode: Bool = false
    @State private var barcodeShareURL: URL?
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var barcodeScale: CGFloat = QRAnimationConfig.initialScale
    @State private var barcodeOpacity: Double = QRAnimationConfig.initialOpacity
    @State private var barcodeBlur: CGFloat = QRAnimationConfig.initialBlur
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Barcode Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if type == .aztec {
                            Image("aztec")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: getBarcodeIcon(for: type))
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        Text(type.rawValue)
                            .font(.title2)
                            .bold()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text(type.metadata.example)
                                .font(.system(.body, design: .monospaced))
                        } icon: {
                            Text("Example:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Label {
                            Text(type.metadata.usage)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Text("Usage:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.systemGray6), lineWidth: 1)
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter content", text: $content)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button {
                                    hideKeyboard()
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Done")
                                        Image(systemName: "keyboard.chevron.compact.down")
                                    }
                                }
                            }
                        }
                    
                    Text(getInputHint())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
                
                // Generated Barcode Section
                if let barcode = generatedBarcode {
                    VStack(spacing: 16) {
                        Image(uiImage: barcode)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .scaleEffect(barcodeScale)
                            .animation(QRAnimationConfig.scaleAnimation, value: barcodeScale)
                            .opacity(barcodeOpacity)
                            .animation(QRAnimationConfig.opacityAnimation, value: barcodeOpacity)
                            .blur(radius: barcodeBlur)
                            .animation(QRAnimationConfig.blurAnimation, value: barcodeBlur)
                            .onDrag {
                                // Create a high-res version of the barcode for dragging
                                // Determine optimal size based on barcode type
                                let size: CGSize
                                switch type {
                                case .aztec:
                                    size = CGSize(width: 1024, height: 1024)
                                case .pdf417:
                                    size = CGSize(width: 1536, height: 1024)
                                case .ean8, .upce:
                                    size = CGSize(width: 1536, height: 512)
                                case .ean13, .isbn13, .issn13:
                                    size = CGSize(width: 2048, height: 512)
                                case .code128, .code93:
                                    size = CGSize(width: 2048, height: 512)
                                case .code39, .code39Mod43, .extendedCode39:
                                    size = CGSize(width: 2560, height: 512)
                                case .itf14, .interleaved2of5:
                                    size = CGSize(width: 2560, height: 512)
                                default:
                                    size = CGSize(width: 2048, height: 512)
                                }
                                
                                // Create high-res image
                                UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
                                UIColor.white.setFill()
                                UIRectFill(CGRect(origin: .zero, size: size))
                                
                                let originalAspect = barcode.size.width / barcode.size.height
                                let horizontalPadding: CGFloat = 64
                                let targetAspect = (size.width - (2 * horizontalPadding)) / size.height
                                
                                let drawRect: CGRect
                                if originalAspect > targetAspect {
                                    let width = size.width - (2 * horizontalPadding)
                                    let height = width / originalAspect
                                    let y = (size.height - height) / 2
                                    drawRect = CGRect(x: horizontalPadding, y: y, width: width, height: height)
                                } else {
                                    let height = size.height
                                    let width = height * originalAspect
                                    let x = (size.width - width) / 2
                                    drawRect = CGRect(x: x, y: 0, width: width, height: height)
                                }
                                
                                let context = UIGraphicsGetCurrentContext()
                                context?.interpolationQuality = .none
                                context?.setShouldAntialias(false)
                                barcode.draw(in: drawRect)
                                
                                if let highQualityImage = UIGraphicsGetCurrentContext()?.makeImage() {
                                    let highResBarcode = UIImage(cgImage: highQualityImage)
                                    UIGraphicsEndImageContext()
                                    return NSItemProvider(object: highResBarcode)
                                }
                                
                                UIGraphicsEndImageContext()
                                // Fallback to original barcode if high-res creation fails
                                return NSItemProvider(object: barcode)
                            }
                        
                        ActionButtonCenter(
                            icon: "square.and.arrow.up",
                            text: isGenerating ? "Please Wait..." : "Share Barcode"
                        ) {
                            if !isGenerating {
                                isGenerating = true
                                generateBarcodeAndShare()
                            }
                        }
                        .sheet(isPresented: $isSharingBarcode) {
                            if let shareURL = barcodeShareURL {
                                ShareSheet(activityItems: [shareURL])
                            }
                        }
                        .opacity(barcodeOpacity)
                        .animation(QRAnimationConfig.shareButtonAnimation, value: barcodeOpacity)
                    }
                }
                
                // Generate Button
                GenerateBarcodeButton(action: generateBarcode, isDisabled: content.isEmpty)
                    .padding()
                
                Spacer()
            }
            .padding(.vertical)
        }
        .onTapGesture { hideKeyboard() }
        .navigationTitle(type.rawValue)
    }
    
    private func getInputHint() -> String {
        switch type {
        case .code39, .code39Mod43, .extendedCode39:
            return "Accepts A-Z, 0-9, and special characters: -.$/+%"
        case .code93:
            return "Accepts A-Z, 0-9, and special characters"
        case .code128:
            return "Accepts all ASCII characters"
        case .upce, .ean8:
            return "Enter 8 digits"
        case .ean13, .isbn13, .issn13:
            return "Enter 13 digits"
        case .itf14:
            return "Enter 14 digits"
        case .interleaved2of5:
            return "Enter an even number of digits"
        default:
            return "Enter content to generate barcode"
        }
    }
    
    func generateBarcode() {
        hideKeyboard()
        errorMessage = nil
        
        // Reset animation states if regenerating
        if generatedBarcode != nil {
            QRAnimationConfig.resetAnimationStates(
                scale: $barcodeScale,
                opacity: $barcodeOpacity,
                blur: $barcodeBlur
            )
        }
        
        let generator = RSUnifiedCodeGenerator.shared
        let objectType = getBarcodeObjectType()
        
        if let image = generator.generateCode(content, machineReadableCodeObjectType: objectType) {
            generatedBarcode = image
            saveToCreateHistory(content)
            
            // Animate the barcode appearance
            QRAnimationConfig.animateToFinalStates(
                scale: $barcodeScale,
                opacity: $barcodeOpacity,
                blur: $barcodeBlur
            )
        } else {
            errorMessage = "Invalid content for \(type.rawValue)"
        }
    }
    
    func generateBarcodeAndShare() {
        guard let originalImage = generatedBarcode else { return }
        
        // Determine optimal size based on barcode type
        let size: CGSize
        switch type {
        case .aztec:
            // Aztec is always square
            size = CGSize(width: 1024, height: 1024)
        case .pdf417:
            // PDF417 is typically rectangular with 3:4 ratio
            size = CGSize(width: 1536, height: 1024)
        case .ean8, .upce:
            // Shorter retail barcodes
            size = CGSize(width: 1536, height: 512)
        case .ean13, .isbn13, .issn13:
            // Standard retail barcodes - need more width
            size = CGSize(width: 2048, height: 512)
        case .code128, .code93:
            // Variable length codes - wide format
            size = CGSize(width: 2048, height: 512)
        case .code39, .code39Mod43, .extendedCode39:
            // Code 39 variants - need extra width for start/stop chars
            size = CGSize(width: 2560, height: 512)
        case .itf14:
            // ITF-14 is wider for logistics
            size = CGSize(width: 2560, height: 512)
        case .interleaved2of5:
            // Similar to ITF-14
            size = CGSize(width: 2560, height: 512)
            //        case .codabar:
            // Standard width for Codabar
            //            size = CGSize(width: 2048, height: 512)
        case .dataMatrix:
            // Data Matrix is typically square
            size = CGSize(width: 1024, height: 1024)
        }
        
        // Create image context with white background
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)
        
        // Fill white background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Calculate aspect ratio preserving rect
        let horizontalPadding: CGFloat = 64  // Add padding constant
        let originalAspect = originalImage.size.width / originalImage.size.height
        let targetAspect = (size.width - (2 * horizontalPadding)) / size.height
        
        let drawRect: CGRect
        if originalAspect > targetAspect {
            // Image is wider than target - fit to padded width
            let width = size.width - (2 * horizontalPadding)
            let height = width / originalAspect
            let y = (size.height - height) / 2
            drawRect = CGRect(x: horizontalPadding, y: y, width: width, height: height)
        } else {
            // Image is taller than target - fit to height
            let height = size.height
            let width = height * originalAspect
            let x = (size.width - width) / 2
            drawRect = CGRect(x: x, y: 0, width: width, height: height)
        }
        
        // Draw the barcode scaled up with proper aspect ratio
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .none  // Disable interpolation for sharp edges
        context?.setShouldAntialias(false)  // Disable antialiasing for crisp lines
        originalImage.draw(in: drawRect)
        
        // Get the high quality image
        let highQualityImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = highQualityImage else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Barcode.png")
        try? finalImage.pngData()?.write(to: tempURL)  // Save as PNG for lossless quality
        
        DispatchQueue.main.async {
            barcodeShareURL = tempURL
            isSharingBarcode = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isGenerating = false
            }
        }
    }
    
    private func getBarcodeObjectType() -> String {
        switch type {
        case .code39:
            return AVMetadataObject.ObjectType.code39.rawValue
        case .code39Mod43:
            return AVMetadataObject.ObjectType.code39Mod43.rawValue
        case .code93:
            return AVMetadataObject.ObjectType.code93.rawValue
        case .code128:
            return AVMetadataObject.ObjectType.code128.rawValue
        case .upce:
            return AVMetadataObject.ObjectType.upce.rawValue
        case .ean8:
            return AVMetadataObject.ObjectType.ean8.rawValue
        case .ean13, .isbn13, .issn13:
            return AVMetadataObject.ObjectType.ean13.rawValue
        case .itf14, .interleaved2of5:
            return AVMetadataObject.ObjectType.interleaved2of5.rawValue
        case .pdf417:
            return AVMetadataObject.ObjectType.pdf417.rawValue
        case .aztec:
            return AVMetadataObject.ObjectType.aztec.rawValue
        case .dataMatrix:
            return AVMetadataObject.ObjectType.dataMatrix.rawValue
            //        case .codabar:
            //            return AVMetadataObject.ObjectType.codabar.rawValue
        default:
            return AVMetadataObject.ObjectType.code128.rawValue
        }
    }
    
    private func saveToCreateHistory(_ content: String) {
        let createItem: [String: Any] = [
            "text": content,
            "type": getBarcodeObjectType(),
            "displayType": type.rawValue,
            "timestamp": Date(),
        ]
        
        var history = UserDefaults.standard.array(forKey: "createHistory") as? [[String: Any]] ?? []
        
        // Check if item already exists in history
        if let existingIndex = history.firstIndex(where: { ($0["text"] as? String) == content }) {
            // Replace the existing item with the new one
            history[existingIndex] = createItem
        } else {
            // Add as a new item
            history.append(createItem)
        }
        
        // Save the updated history
        UserDefaults.standard.setValue(history, forKey: "createHistory")
    }
}

// MARK: - Helper Function to Get Barcode Icons
private func getBarcodeIcon(for type: BarcodeType) -> String {
    switch type {
    case .code39, .code39Mod43, .extendedCode39:
        return "barcode"
    case .code93:
        return "doc.viewfinder"
    case .code128:
        return "barcode"
    case .upce, .ean8, .ean13:
        return "cart.fill.badge.plus"
    case .isbn13:
        return "book.fill"
    case .issn13:
        return "newspaper.fill"
    case .itf14:
        return "shippingbox.fill"
    case .interleaved2of5:
        return "number.square.fill"
    case .pdf417:
        return "doc.text.fill"
    case .aztec:
        return "doc.text.fill"
    case .dataMatrix:
        return "square.grid.2x2"
        //    case .codabar:
        //        return "creditcard.fill"
    }
}
