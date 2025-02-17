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
    @State private var isShowingResult = false
    @State private var flashlightEnabled = false // ✅ Flash toggle state

    let scanBoxSize: CGFloat = 250 // Square size for scanning
    var body: some View {
        NavigationStack {
            ZStack {
                if !isShowingResult {
                    QRCodeScannerView { code in
                        scannedCode = code
                        isShowingResult = true
                        playScanSound()
                        turnOffFlashlight()
                        saveToHistory(code)
                    }
                    .edgesIgnoringSafeArea(.all)

                    // Scanner Overlay with Four L-Shaped Corners
                    GeometryReader { proxy in
                        ZStack {
                            ScannerCorner(rotation: 0, position: getCornerPosition(.topLeading, proxy: proxy))
                            ScannerCorner(rotation: 90, position: getCornerPosition(.topTrailing, proxy: proxy))
                            ScannerCorner(rotation: 180, position: getCornerPosition(.bottomTrailing, proxy: proxy))
                            ScannerCorner(rotation: 270, position: getCornerPosition(.bottomLeading, proxy: proxy))
                        }
                        .frame(width: scanBoxSize, height: scanBoxSize)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }
                    .frame(width: scanBoxSize, height: scanBoxSize)

                    // ✅ Flashlight Toggle Button
                    VStack {
                        Spacer()
                        Button(action: toggleFlashlight) {
                            Image(systemName: flashlightEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 32))
                                .foregroundColor(flashlightEnabled ? .blue : .white)
                                .padding(24)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.bottom, 40) // Adjust position near bottom
                    }
                }
            }
            .navigationDestination(isPresented: $isShowingResult) {
                ScanResultView(scannedText: scannedCode ?? "") {
                    isShowingResult = false
                    scannedCode = nil
                    turnOffFlashlight() // Ensure flash turns off when exiting scanner
                }
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

        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = flashlightEnabled ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be used")
        }
    }

    // MARK: - Turn Off Flashlight When Leaving Scanner
    private func turnOffFlashlight() {
        flashlightEnabled = false
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
        } catch {
            print("Flashlight could not be turned off")
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

// MARK: - Save QR Code to History
private func saveToHistory(_ scannedText: String) {
    var history = UserDefaults.standard.stringArray(forKey: "qrHistory") ?? []
    
    // Avoid duplicates
    if !history.contains(scannedText) {
        history.append(scannedText)
        UserDefaults.standard.setValue(history, forKey: "qrHistory")
    }
}
