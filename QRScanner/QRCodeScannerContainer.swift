//
//  QRCodeScannerContainer.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerContainer: View {
    @State private var scannedCode: String? = nil
    @State private var scannedType: AVMetadataObject.ObjectType? = nil
    @State private var isShowingResult = false
    @State private var flashlightEnabled = false
    @State private var overlayScale: CGFloat = 1.0
    @State private var showCameraSelector = false
    @State private var backCameras: [AVCaptureDevice] = []
    @State private var frontCameras: [AVCaptureDevice] = []
    @State private var selectedLens: AVCaptureDevice? = nil

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
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }
                    .frame(width: scanBoxSize, height: scanBoxSize)

                    // Add Camera Controls
                    GeometryReader { proxy in
                        // Bottom Controls
                        HStack(spacing: 20) {
                            // Camera Selection Button
                            Button(action: { showCameraSelector = true }) {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .frame(width: 64, height: 64)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            // Flashlight Button
                            if selectedLens?.position == .back {
                                Button(action: toggleFlashlight) {
                                    Image(systemName: flashlightEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(flashlightEnabled ? .blue : .white)
                                        .frame(width: 64, height: 64)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .position(x: proxy.size.width / 2, y: proxy.size.height - 50)
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
        flashlightEnabled.toggle()

        guard let device = selectedLens,
              device.hasTorch,
              device.position == .back else {
            flashlightEnabled = false
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = flashlightEnabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be used")
            flashlightEnabled = false
        }
    }

    // MARK: - Turn Off Flashlight When Leaving Scanner
    private func turnOffFlashlight() {
        flashlightEnabled = false
        guard let device = selectedLens,
              device.hasTorch,
              device.position == .back else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be turned off")
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
            magnification = "0.5×"
        } else if camera.deviceType == .builtInTelephotoCamera {
            // Get approximate zoom level based on field of view comparison
            let fov = camera.activeFormat.videoFieldOfView
            if fov <= 13 {
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


// MARK: - Play Scan Sound
func playScanSound() {
    let scanSoundEnabled = UserDefaults.standard.bool(forKey: "scanSoundEnabled")
    let vibrationEnabled = UserDefaults.standard.bool(forKey: "vibrationEnabled")

    if scanSoundEnabled {
        AudioServicesPlaySystemSound(1057) // Default QR scan beep
    }

    if vibrationEnabled {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
            magnification = "0.5×"
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
