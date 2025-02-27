//
//  QRCodeScannerContainer.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation
import Vision
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRCodeScannerContainer: View {
    @State private var scannedCode: String? = nil
    @State private var scannedType: AVMetadataObject.ObjectType? = nil
    @State private var isShowingResult = false
    @State private var flashlightEnabled = false
    @State private var overlayScale: CGFloat = 1.0
    @State private var showCameraSelector = false
    @State private var backCameras: [AVCaptureDevice] = []
    @State private var frontCameras: [AVCaptureDevice] = []
    @State private var selectedLens: AVCaptureDevice? = nil {
        didSet {
            // When camera lens changes, update the flashlight state
            if oldValue?.uniqueID != selectedLens?.uniqueID {
                // Turn off flashlight when switching cameras
                turnOffFlashlight()
                // Update UI state to match actual device state
                updateFlashlightState()
            }
        }
    }
    @State private var isShowingPhotoPicker = false
    @State private var isScanning = false
    @State private var showNoCodeFound = false
    @AppStorage("scanSoundEnabled") private var scanSoundEnabled = false
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("autoOpenLinks") private var autoOpenLinks = false

    let scanBoxSize: CGFloat = 250 // Square size for scanning
    
    // Add initialization of available cameras
    init() {
        // Get back cameras
        let backSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .back
        )
        self._backCameras = State(initialValue: backSession.devices)
        
        // Get front cameras
        let frontSession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .front
        )
        self._frontCameras = State(initialValue: frontSession.devices)
        
        // Set default camera
        if let defaultCamera = backSession.devices.first {
            self._selectedLens = State(initialValue: defaultCamera)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if !isShowingResult {
                    QRCodeScannerView(completion:  { code, type in
                        scannedCode = code
                        scannedType = type
                        isShowingResult = true
                        playScanSound()
                        turnOffFlashlight()
                        saveToScanHistory(code, type: type)
                        
                        // Auto-open HTTPS links if enabled
                        if autoOpenLinks,
                           let url = URL(string: code),
                           url.scheme?.lowercased() == "https",
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }, selectedDevice: selectedLens)
                    .edgesIgnoringSafeArea(.all)

                    // ✅ Scanner Overlay with L-Shaped Corners
                    GeometryReader { proxy in
                        ZStack {
                            ScannerCorner(rotation: 0, position: getCornerPosition(.topLeading, proxy: proxy))
                            ScannerCorner(rotation: 90, position: getCornerPosition(.topTrailing, proxy: proxy))
                            ScannerCorner(rotation: 180, position: getCornerPosition(.bottomTrailing, proxy: proxy))
                            ScannerCorner(rotation: 270, position: getCornerPosition(.bottomLeading, proxy: proxy))

                            // ✅ Center Pulsing Overlay (Fixed)
                            Image("blank")
                                .resizable()
                                .scaledToFit()
                                .opacity(0.1)
                                .frame(width: 100, height: 100)
                                .scaleEffect(overlayScale)
                                .onAppear {
                                    overlayScale = 1.05 // ✅ Ensure stable scale
                                    withAnimation(
                                        Animation.easeInOut(duration: 1.2)
                                            .repeatForever(autoreverses: true)
                                    ) {
                                        overlayScale = 1.1
                                    }
                                }
                        }
                        .frame(width: scanBoxSize, height: scanBoxSize)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 3)
                    }
                    .frame(width: scanBoxSize, height: scanBoxSize)

                    // Camera Controls
                    GeometryReader { proxy in
                        VStack(spacing: 20) {
                            // Camera Lens Selector
                            CameraLensSelector(
                                backCameras: backCameras,
                                frontCameras: frontCameras,
                                selectedLens: selectedLens,
                                onSelect: { selectedLens = $0 },
                                getMagnificationText: getMagnificationText2
                            )
                            .frame(maxWidth: .infinity)
                            // .padding(.bottom, 20)

                            // Bottom Controls
                            BottomControls(
                                selectedLens: selectedLens,
                                flashlightEnabled: flashlightEnabled,
                                onCameraSelect: { showCameraSelector = true },
                                onFlashlight: toggleFlashlight,
                                onPhotoSelect: { isShowingPhotoPicker = true },
                                getMagnificationText: getMagnificationText
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingResult) {
                if let code = scannedCode, let type = scannedType {
                    ScanResultView(scannedText: code, barcodeType: type) {
                        isShowingResult = false
                        scannedCode = nil
                        scannedType = nil
                        turnOffFlashlight()
                    }
                }
            }
            .sheet(isPresented: $showCameraSelector) {
                CameraSelectorSheet(
                    selectedLens: $selectedLens,
                    backCameras: backCameras,
                    frontCameras: frontCameras,
                    isPresented: $showCameraSelector
                )
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                ImagePicker { image in
                    if let image = image {
                        processPickedImage(image)
                    }
                }
            }
            .overlay {
                if isScanning {
                    ScanningOverlay()
                } else if showNoCodeFound {
                    NoCodeFoundOverlay {
                        showNoCodeFound = false
                    }
                }
            }
            .onAppear {
                // Check and update flashlight state when view appears
                updateFlashlightState()
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Get Corner Positions Using GeometryReader
    private func getCornerPosition(_ alignment: Alignment, proxy: GeometryProxy) -> CGPoint {
        let centerX = proxy.size.width / 2
        let centerY = proxy.size.height / 2
        let halfSize = scanBoxSize / 2 - 20

        switch alignment {
        case .topLeading:
            return CGPoint(x: centerX - halfSize, y: centerY - halfSize)
        case .topTrailing:
            return CGPoint(x: centerX + halfSize, y: centerY - halfSize)
        case .bottomTrailing:
            return CGPoint(x: centerX + halfSize, y: centerY + halfSize)
        case .bottomLeading:
            return CGPoint(x: centerX - halfSize, y: centerY + halfSize)
        default:
            return CGPoint(x: centerX, y: centerY)
        }
    }

    // MARK: - Toggle Flashlight
    private func toggleFlashlight() {
        Haptic.medium()
        
        guard let device = selectedLens,
              device.hasTorch,
              device.position == .back else {
            flashlightEnabled = false
            return
        }

        do {
            try device.lockForConfiguration()
            
            // Toggle the torch mode
            if device.torchMode == .on {
                device.torchMode = .off
                flashlightEnabled = false
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                flashlightEnabled = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be used: \(error)")
            // Make sure UI state reflects actual state
            updateFlashlightState()
        }
    }

    // MARK: - Turn Off Flashlight When Leaving Scanner
    private func turnOffFlashlight() {
        // Update UI state first
        flashlightEnabled = false
        
        guard let device = selectedLens,
              device.hasTorch,
              device.position == .back else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be turned off: \(error)")
            // Even if there's an error, keep UI state as off
            flashlightEnabled = false
        }
    }

    // MARK: - Helper Functions
    private func getCameraDescription() -> String {
        guard let device = selectedLens else { return "Select Camera" }
        let position = device.position == .front ? "Front" : "Back"
        return "\(position) - \(getLensName(for: device))"
    }

    private func getLensName(for camera: AVCaptureDevice) -> String {
        let magnification: String
        if camera.deviceType == .builtInUltraWideCamera {
            magnification = ".5×"
        } else if camera.deviceType == .builtInTelephotoCamera {
            // Get approximate zoom level based on field of view comparison
            let fov = camera.activeFormat.videoFieldOfView
            if fov <= 18 {
                magnification = "5×"
            } else if fov <= 30 {
                magnification = "3×"
            } else {
                magnification = "2×"
            }
        } else {
            magnification = "1×"
        }
        
        if camera.deviceType == .builtInUltraWideCamera {
            return "Ultra Wide \(magnification)"
        } else if camera.deviceType == .builtInTelephotoCamera {
            return "Telephoto \(magnification)"
        } else {
            return "Main \(magnification)"
        }
    }

    private func getMagnificationText() -> String {
        guard let device = selectedLens else { return "1×" }
        
        if device.deviceType == .builtInUltraWideCamera {
            return ".5×"
        } else if device.deviceType == .builtInTelephotoCamera {
            let fov = device.activeFormat.videoFieldOfView
            if fov <= 18 {
                return "5×"
            } else if fov <= 30 {
                return "3×"
            } else {
                return "2×"
            }
        } else {
            return "1×"
        }
    }

    private func getMagnificationText2(for camera: AVCaptureDevice) -> String {
        if camera.deviceType == .builtInUltraWideCamera {
            return ".5×"
        } else if camera.deviceType == .builtInTelephotoCamera {
            let fov = camera.activeFormat.videoFieldOfView
            if fov <= 18 {
                return "5×"
            } else if fov <= 30 {
                return "3×"
            } else {
                return "2×"
            }
        } else {
            return "1×"
        }
    }

    // MARK: - Play Scan Sound
    private func playScanSound() {
        if scanSoundEnabled {
            AudioServicesPlaySystemSound(1057) // Default QR scan beep
        }

        if vibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare() // Prepare the generator for better response
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Process Picked Image
    private func processPickedImage(_ image: UIImage) {
        isScanning = true
        showNoCodeFound = false
        
        // Simulate a minimum scanning time for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    isScanning = false
                    showNoCodeFound = true
                    Haptic.error()
                }
                return
            }
            
            // Create Vision barcode detection request
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    print("Vision error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        isScanning = false
                        showNoCodeFound = true
                        Haptic.error()
                    }
                    return
                }
                
                guard let results = request.results as? [VNBarcodeObservation], !results.isEmpty else {
                    DispatchQueue.main.async {
                        isScanning = false
                        showNoCodeFound = true
                        Haptic.error()
                    }
                    return
                }
                
                // Process the first detected barcode
                if let barcode = results.first, let payloadString = barcode.payloadStringValue {
                    DispatchQueue.main.async {
                        scannedCode = payloadString
                        scannedType = convertToAVMetadataType(from: barcode.symbology)
                        isShowingResult = true
                        playScanSound()
                        saveToScanHistory(payloadString, type: convertToAVMetadataType(from: barcode.symbology))
                        
                        // Auto-open links if enabled and the scanned code is a URL
                        if autoOpenLinks,
                           let url = URL(string: payloadString),
                           url.scheme?.lowercased() == "https",
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                        
                        isScanning = false
                    }
                } else {
                    DispatchQueue.main.async {
                        Haptic.error()
                        isScanning = false
                        showNoCodeFound = true
                    }
                }
            }
            
            // Process the image with Vision
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
                DispatchQueue.main.async {
                    isScanning = false
                    showNoCodeFound = true
                    Haptic.error()
                }
            }
        }
    }

    // Convert Vision barcode symbology to AVMetadataObject.ObjectType
    private func convertToAVMetadataType(from symbology: VNBarcodeSymbology) -> AVMetadataObject.ObjectType {
        switch symbology {
        case .qr: return .qr
        case .aztec: return .aztec
        case .code39: return .code39
        case .code93: return .code93
        case .code128: return .code128
        case .dataMatrix: return .dataMatrix
        case .ean8: return .ean8
        case .ean13: return .ean13
        case .itf14: return .itf14
        case .pdf417: return .pdf417
        case .upce: return .upce
        default: return .qr // Default to QR if no direct mapping
        }
    }

    // MARK: - Update Flashlight State
    private func updateFlashlightState() {
        guard let device = selectedLens,
              device.hasTorch,
              device.position == .back else {
            // If no valid torch device, ensure flashlight is shown as off
            flashlightEnabled = false
            return
        }
        
        // Check the actual torch mode and update the UI state to match
        do {
            try device.lockForConfiguration()
            flashlightEnabled = (device.torchMode == .on)
            device.unlockForConfiguration()
        } catch {
            print("Could not check flashlight state: \(error)")
            flashlightEnabled = false
        }
    }
}

struct ScannerCorner: View {
    let rotation: Double
    let position: CGPoint

    @State private var scaleEffect: CGFloat = 1.0

    var body: some View {
        Image("scanner-overlay") // Ensure this asset is in Assets.xcassets
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: rotation))
            .position(position)
            .scaleEffect(scaleEffect)
            .animation(
                Animation.bouncy(duration: 1.2, extraBounce: 1)
                    .repeatForever(autoreverses: true),
                value: scaleEffect
            )
            .onAppear {
                scaleEffect = 1.05
            }
    }
}


// MARK: - Save to Scan History
func saveToScanHistory(_ scannedText: String, type: AVMetadataObject.ObjectType) {
    let scanItem: [String: Any] = [
        "text": scannedText,
        "type": type.rawValue,
        "timestamp": Date()
    ]
    
    var history = UserDefaults.standard.array(forKey: "scanHistory") as? [[String: Any]] ?? []
    if !history.contains(where: { ($0["text"] as? String) == scannedText }) {
        history.append(scanItem)
        UserDefaults.standard.setValue(history, forKey: "scanHistory")
    }
}

// MARK: - Camera Selector Sheet
struct CameraSelectorSheet: View {
    @Binding var selectedLens: AVCaptureDevice?
    let backCameras: [AVCaptureDevice]
    let frontCameras: [AVCaptureDevice]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                if !backCameras.isEmpty {
                    Section("Back Cameras") {
                        ForEach(backCameras, id: \.uniqueID) { camera in
                            CameraRow(camera: camera, isSelected: selectedLens?.uniqueID == camera.uniqueID)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedLens = camera
                                    isPresented = false
                                }
                        }
                    }
                }
                
                if !frontCameras.isEmpty {
                    Section("Front Cameras") {
                        ForEach(frontCameras, id: \.uniqueID) { camera in
                            CameraRow(camera: camera, isSelected: selectedLens?.uniqueID == camera.uniqueID)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedLens = camera
                                    isPresented = false
                                }
                        }
                    }
                }
            }
            .navigationTitle("Select Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CameraRow: View {
    let camera: AVCaptureDevice
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(getLensName(for: camera))
                    .font(.headline)
                Text(getDeviceDetails(for: camera))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getLensName(for camera: AVCaptureDevice) -> String {
        let magnification: String
        if camera.deviceType == .builtInUltraWideCamera {
            magnification = ".5×"
        } else if camera.deviceType == .builtInTelephotoCamera {
            // Get approximate zoom level based on field of view comparison
            let fov = camera.activeFormat.videoFieldOfView
            if fov <= 18 {
                magnification = "5×"
            } else if fov <= 30 {
                magnification = "3×"
            } else {
                magnification = "2×"
            }
        } else {
            magnification = "1×"
        }
        
        if camera.deviceType == .builtInUltraWideCamera {
            return "Ultra Wide \(magnification)"
        } else if camera.deviceType == .builtInTelephotoCamera {
            return "Telephoto \(magnification)"
        } else {
            return "Main \(magnification)"
        }
    }
    
    private func getDeviceDetails(for camera: AVCaptureDevice) -> String {
        let position = camera.position == .front ? "Front" : "Back"
        let focal = String(format: "%.1f", camera.activeFormat.videoFieldOfView)
        return "\(position) Camera - \(focal)°"
    }
}

// MARK: - Camera Lens Button View
private struct CameraLensButton: View {
    let camera: AVCaptureDevice
    let isSelected: Bool
    let action: () -> Void
    let magnificationText: String
    
    var body: some View {
        Button(action: action) {
            Group {
                if camera.position == .front {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? Color("customYellow") : .secondary)
                } else {
                    Text(magnificationText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? Color("customYellow") : .secondary)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color.gray.opacity(0.3) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.2 : 1.0)
        }
    }
}

// MARK: - Camera Lens Selector View
private struct CameraLensSelector: View {
    let backCameras: [AVCaptureDevice]
    let frontCameras: [AVCaptureDevice]
    let selectedLens: AVCaptureDevice?
    let onSelect: (AVCaptureDevice) -> Void
    let getMagnificationText: (AVCaptureDevice) -> String
    
    private func sortedBackCameras() -> [AVCaptureDevice] {
        return backCameras.sorted { camera1, camera2 in
            let mag1 = getMagnificationValue(camera1)
            let mag2 = getMagnificationValue(camera2)
            return mag1 < mag2
        }
    }
    
    private func getMagnificationValue(_ camera: AVCaptureDevice) -> Double {
        if camera.deviceType == .builtInUltraWideCamera {
            return 0.5
        } else if camera.deviceType == .builtInTelephotoCamera {
            let fov = camera.activeFormat.videoFieldOfView
            if fov <= 18 {
                return 5.0
            } else if fov <= 30 {
                return 3.0
            } else {
                return 2.0
            }
        } else {
            return 1.0
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 10) {
                // Spacer()
                ForEach(frontCameras, id: \.uniqueID) { camera in
                    CameraLensButton(
                        camera: camera,
                        isSelected: selectedLens?.uniqueID == camera.uniqueID,
                        action: { 
                            Haptic.soft()
                            onSelect(camera)
                        },
                        magnificationText: getMagnificationText(camera)
                    )
                }
                ForEach(sortedBackCameras(), id: \.uniqueID) { camera in
                    CameraLensButton(
                        camera: camera,
                        isSelected: selectedLens?.uniqueID == camera.uniqueID,
                        action: { 
                            Haptic.soft()
                            onSelect(camera)
                        },
                        magnificationText: getMagnificationText(camera)
                    )
                }
                // Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 0)
            )
            .frame(height: 60)
            Spacer()
        }
        .scaleEffect(0.75)
    }
}

// MARK: - Bottom Controls View
private struct BottomControls: View {
    let selectedLens: AVCaptureDevice?
    let flashlightEnabled: Bool
    let onCameraSelect: () -> Void
    let onFlashlight: () -> Void
    let onPhotoSelect: () -> Void
    let getMagnificationText: () -> String
    
    var body: some View {
        HStack(spacing: 20) {
            // Photo Library Button
            Button(action: onPhotoSelect) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(.thickMaterial)
                    .clipShape(Circle())
            }
            
            // Flashlight Button
            if selectedLens?.position == .back {
                Button(action: onFlashlight) {
                    Image(systemName: flashlightEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 24))
                        .foregroundColor(flashlightEnabled ? Color("customYellow") : .secondary)
                        .frame(width: 50, height: 50)
                        .background(.thickMaterial)
                        .clipShape(Circle())
                }
            } else {
                Button(action: {}) {
                    Image(systemName: "flashlight.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                        .background(.ultraThickMaterial)
                        .clipShape(Circle())
                }
                .disabled(true)
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        // Exclude location and caption data by default
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
            super.init()
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                completion(nil)
                return
            }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self = self, let image = image as? UIImage else {
                        DispatchQueue.main.async {
                            self?.completion(nil)
                        }
                        return
                    }
                    
                    // Strip metadata to ensure no location data is included
                    let strippedImage = self.stripMetadata(from: image)
                    
                    DispatchQueue.main.async {
                        self.completion(strippedImage)
                    }
                }
            }
        }
        
        // Strip metadata from image to ensure no location or caption data
        private func stripMetadata(from image: UIImage) -> UIImage {
            guard let cgImage = image.cgImage else { return image }
            
            // Create a new image without metadata
            let newImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            return newImage
        }
    }
}

// MARK: - Scanning Overlay
private struct ScanningOverlay: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primary)
                
                Text("Scanning for Code...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please wait while we analyze the image")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(30)
            .background(.thinMaterial)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .transition(.opacity)
    }
}

// MARK: - No Code Found Overlay
private struct NoCodeFoundOverlay: View {
    let dismissAction: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissAction()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.primary)
                
                Text("No Code Found")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Button("Try Again") {
                    dismissAction()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(.secondary)
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .padding(30)
            .background(.thinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.red, lineWidth: 1)
                    .opacity(0.5)
            )
        }
        .transition(.opacity)
    }
}
