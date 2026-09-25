//
//  QRCodeScannerView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation
import Vision

struct QRCodeScannerView: UIViewControllerRepresentable {
    var completion: (String, AVMetadataObject.ObjectType) -> Void
    var selectedDevice: AVCaptureDevice?
    var shouldInitializeScanner: Bool = true
    var onCameraChanged: ((AVCaptureDevice) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.onCameraChanged = onCameraChanged
        scannerViewController.delegate = context.coordinator
        scannerViewController.selectedDevice = selectedDevice
        scannerViewController.shouldInitializeScanner = shouldInitializeScanner
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        context.coordinator.parent = self
        if uiViewController.selectedDevice?.uniqueID != selectedDevice?.uniqueID {
            uiViewController.switchCamera(to: selectedDevice)
        }
        
        if uiViewController.shouldInitializeScanner != shouldInitializeScanner {
            uiViewController.shouldInitializeScanner = shouldInitializeScanner
            
            if shouldInitializeScanner && uiViewController.captureSession == nil {
                uiViewController.setupScanner()
            }
        }
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        
        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }
            
            DispatchQueue.main.async {
                self.parent.completion(stringValue, readableObject.type)
            }
        }
    }
}

// MARK: - ScannerViewController
class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var selectedDevice: AVCaptureDevice?
    var shouldInitializeScanner: Bool = true
    
    private var videoCaptureDevice: AVCaptureDevice?
    var onCameraChanged: ((AVCaptureDevice) -> Void)?
    private let sessionQueue = DispatchQueue(label: "scanner.capture", qos: .userInitiated)
    private var recovery = ScannerRecovery()
    private var lastSampleTime = -Double.infinity
    private var lastVisionTime = -Double.infinity
    private var lastUndecodedQR = -Double.infinity
    private var wantsRunning = true
    private var originalFrameDurations: (minimum: CMTime, maximum: CMTime)?
    private var lastTorchMode: AVCaptureDevice.TorchMode = .off
    private var longPressGesture: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if shouldInitializeScanner {
            setupScanner()
        }
        
        // Add long press gesture for pasting images
        setupLongPressGesture()
        
        // ✅ Listen for Scan Completion to Stop Camera
        NotificationCenter.default.addObserver(self, selector: #selector(stopScanning), name: NSNotification.Name("StopScanning"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startScanning), name: NSNotification.Name("StartScanning"), object: nil)
        
        // Listen for return to scanner notification
        NotificationCenter.default.addObserver(self, selector: #selector(startScanning), name: NSNotification.Name("ReturnToScanner"), object: nil)
    }
    
    private func setupLongPressGesture() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            showPasteImageAlert()
        }
    }
    
    private func showPasteImageAlert() {
        let alertController = UIAlertController(
            title: "Paste Image",
            message: "Paste an image to scan for codes",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Paste from Clipboard", style: .default) { [weak self] _ in
            self?.pasteImageFromClipboard()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func pasteImageFromClipboard() {
        guard UIPasteboard.general.hasImages, let image = UIPasteboard.general.image else {
            let alert = UIAlertController(
                title: "No Image",
                message: "No image found in clipboard",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Stop the camera temporarily
        stopScanning()
        
        // Process the image to find codes
        processImageForCodes(image)
    }
    
    private func processImageForCodes(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            showAlert(title: "Error", message: "Could not process the image")
            resumeScanning()
            return
        }
        
        // Try QR codes first with CIDetector
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = qrDetector?.features(in: ciImage) as? [CIQRCodeFeature]
        
        // Process QR code features if found
        if let features = features, !features.isEmpty, let feature = features.first, let messageString = feature.messageString {
            // Call the delegate with the scanned data
            DispatchQueue.main.async {
                // Create a mock AVMetadataMachineReadableCodeObject type
                let objectType = AVMetadataObject.ObjectType.qr
                
                // Call the parent completion handler
                if let coordinator = self.delegate as? QRCodeScannerView.Coordinator {
                    coordinator.parent.completion(messageString, objectType)
                }
            }
            return
        }
        
        // If no QR code found, try barcode detection with Vision framework
        detectBarcodesWithVision(in: image)
    }
    
    private func detectBarcodesWithVision(in image: UIImage) {
        // Convert to CG image
        guard let cgImage = image.cgImage else {
            resumeScanning()
            return
        }
        
        // Create Vision barcode detection request
        let barcodeRequest = VNDetectBarcodesRequest()
        
        // Process the image
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            // Perform the barcode detection request
            try handler.perform([barcodeRequest])
            
            // Process results
            if let results = barcodeRequest.results, !results.isEmpty {
                // Get all detected barcodes
                let barcodes = results.compactMap { result -> (String, String)? in
                    let barcode = result 
                    guard let payload = barcode.payloadStringValue else { return nil }
                    return (payload, barcode.symbology.rawValue)
                }
                
                // Use the first detected barcode
                if let firstBarcode = barcodes.first {
                    let barcodeValue = firstBarcode.0
                    let barcodeType = mapVisionBarcodeTypeToAVType(firstBarcode.1)
                    
                    DispatchQueue.main.async {
                        // Call the parent completion handler
                        if let coordinator = self.delegate as? QRCodeScannerView.Coordinator {
                            coordinator.parent.completion(barcodeValue, barcodeType)
                        }
                    }
                    return
                }
            }
            
            // If we get here, no codes were found
            DispatchQueue.main.async {
                self.showAlert(title: "No Codes Found", message: "No QR or barcodes were detected in the image")
                self.resumeScanning()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Failed to process the image: \(error.localizedDescription)")
                self.resumeScanning()
            }
        }
    }
    
    // Helper method to map Vision barcode types to AVMetadataObject types
    private func mapVisionBarcodeTypeToAVType(_ visionType: String) -> AVMetadataObject.ObjectType {
        switch visionType {
        case "VNBarcodeSymbologyQR":
            return .qr
        case "VNBarcodeSymbologyEAN13":
            return .ean13
        case "VNBarcodeSymbologyEAN8":
            return .ean8
        case "VNBarcodeSymbologyPDF417":
            return .pdf417
        case "VNBarcodeSymbologyAztec":
            return .aztec
        case "VNBarcodeSymbologyCode128":
            return .code128
        case "VNBarcodeSymbologyCode39":
            return .code39
        case "VNBarcodeSymbologyCode93":
            return .code93
        case "VNBarcodeSymbologyDataMatrix":
            return .dataMatrix
        case "VNBarcodeSymbologyITF14":
            return .itf14
        case "VNBarcodeSymbologyUPCE":
            return .upce
        default:
            return .qr
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resumeScanning()
        })
        present(alert, animated: true)
    }
    
    private func resumeScanning() {
        // Resume camera scanning
        startScanning()
    }
    
    func setupScanner() {
        let requestedDevice = selectedDevice
        sessionQueue.async {
            guard self.captureSession == nil else { return }
            let session = AVCaptureSession()
            session.sessionPreset = session.canSetSessionPreset(.hd1920x1080) ? .hd1920x1080 : .high
            
            // Use the selected device or fall back to default
            let videoDevice = requestedDevice ?? AVCaptureDevice.default(for: .video)
            guard let device = videoDevice else { return }
            self.videoCaptureDevice = device
            
            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: device)
            } catch {
                print("Error creating AVCaptureDeviceInput: \(error.localizedDescription)")
                return
            }
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                print("Could not add video input to session")
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                
                // The order here is important - add output to session first, then set metadata types
                metadataOutput.setMetadataObjectsDelegate(self.delegate, queue: DispatchQueue.main)
                
                // Get all available metadata object types
                let availableMetadataTypes = metadataOutput.availableMetadataObjectTypes
                
                // Set all available barcode types
                metadataOutput.metadataObjectTypes = availableMetadataTypes.filter { type in
                    return [
                        .qr,
                        .ean13,
                        .ean8,
                        .pdf417,
                        .aztec,
                        .code128,
                        .code39,
                        .code93,
                        .dataMatrix,
                        .interleaved2of5,
                        .itf14,
                        .upce,
                        .codabar,
                        .code39Mod43,
                        .microQR
                    ].contains(type)
                }
                
                print("Enabled metadata types: \(metadataOutput.metadataObjectTypes.map { $0.rawValue })")
            } else {
                print("Could not add metadata output to session")
                return
            }
            
            let frames = AVCaptureVideoDataOutput()
            frames.alwaysDiscardsLateVideoFrames = true
            frames.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            if session.canAddOutput(frames) {
                session.addOutput(frames)
                frames.setSampleBufferDelegate(self, queue: self.sessionQueue)
            }
            self.configureCamera(device)
            self.captureSession = session
            DispatchQueue.main.async { self.setupPreviewLayer() }
            if self.wantsRunning { session.startRunning() }
        }
    }
    
    func setupPreviewLayer() {
        guard let captureSession = captureSession else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
    }
    
    @objc func startScanning() {
        sessionQueue.async {
            self.wantsRunning = true
            if let captureSession = self.captureSession, !captureSession.isRunning {
                self.recovery = ScannerRecovery()
                self.lastUndecodedQR = -Double.infinity
                if let device = self.videoCaptureDevice { self.configureCamera(device) }
                captureSession.startRunning()
            }
        }
    }
    
    @objc func stopScanning() {
        sessionQueue.async {
            self.wantsRunning = false
            if let device = self.videoCaptureDevice { self.restoreExposure(device) }
            if let captureSession = self.captureSession, captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    func switchCamera(to device: AVCaptureDevice?) {
        guard let device else { return }
        selectedDevice = device
        sessionQueue.async {
            self.recovery = ScannerRecovery()
            self.replaceCamera(with: device)
        }
    }

    private func replaceCamera(with device: AVCaptureDevice) {
        guard let session = captureSession,
              videoCaptureDevice?.uniqueID != device.uniqueID,
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if let old = videoCaptureDevice { restoreExposure(old) }
        let previous = session.inputs
        session.beginConfiguration()
        previous.forEach { session.removeInput($0) }
        if session.canAddInput(input) {
            session.addInput(input)
            videoCaptureDevice = device
            configureCamera(device)
            lastSampleTime = -Double.infinity
            lastVisionTime = -Double.infinity
            lastUndecodedQR = -Double.infinity
            DispatchQueue.main.async {
                self.selectedDevice = device
                self.onCameraChanged?(device)
            }
        } else {
            previous.filter { session.canAddInput($0) }.forEach { session.addInput($0) }
        }
        session.commitConfiguration()
    }

    private func configureCamera(_ device: AVCaptureDevice) {
        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
        lastTorchMode = device.torchMode
    }

    private func restoreExposure(_ device: AVCaptureDevice) {
        guard (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
        if let original = originalFrameDurations {
            device.activeVideoMinFrameDuration = original.minimum
            device.activeVideoMaxFrameDuration = original.maximum
            originalFrameDurations = nil
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let time = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        guard wantsRunning, let device = videoCaptureDevice,
              time - lastSampleTime >= 0.025,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastSampleTime = time
        if time - lastVisionTime >= 0.5 {
            lastVisionTime = time
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr, .microQR]
            if (try? VNImageRequestHandler(cvPixelBuffer: buffer, options: [:]).perform([request])) != nil {
                if let code = request.results?.first(where: { $0.payloadStringValue != nil }), let value = code.payloadStringValue {
                    DispatchQueue.main.async { [weak self] in
                        guard let coordinator = self?.delegate as? QRCodeScannerView.Coordinator else { return }
                        coordinator.parent.completion(value, code.symbology == .microQR ? .microQR : .qr)
                    }
                    return
                }
                if request.results?.isEmpty == false { lastUndecodedQR = time }
            }
        }
        if device.torchMode != lastTorchMode {
            lastTorchMode = device.torchMode
            recovery.resetExposure(at: time)
            restoreExposure(device)
        }
        guard device.torchMode == .off, CVPixelBufferGetPlaneCount(buffer) > 0 else { return }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            return
        }
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        let width = CVPixelBufferGetWidthOfPlane(buffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(buffer, 0)
        let stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        var patches: [Double] = []
        for row in 0..<4 {
            for col in 0..<4 {
                var sum = 0.0
                for y in 0..<4 {
                    for x in 0..<4 {
                        let px = (col * 4 + x) * width / 16
                        let py = (row * 4 + y) * height / 16
                        sum += Double(bytes[py * stride + px]) / 255
                    }
                }
                patches.append(sum / 16)
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        guard let action = recovery.observe(patches, at: time, undecodedQR: time - lastUndecodedQR < 0.8) else { return }
        switch action {
        case .automatic:
            restoreExposure(device)
        case .ultraWide:
            restoreExposure(device)
            if device.position == .back, device.deviceType == .builtInWideAngleCamera,
               let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                replaceCamera(with: ultraWide)
            }
        case .exposure(let duration):
            guard device.isExposureModeSupported(.custom),
                  duration >= CMTimeGetSeconds(device.activeFormat.minExposureDuration),
                  duration <= CMTimeGetSeconds(device.activeFormat.maxExposureDuration),
                  let iso = ScannerRecovery.compensatedISO(currentISO: Double(device.iso), currentDuration: CMTimeGetSeconds(device.exposureDuration), duration: duration, minimum: Double(device.activeFormat.minISO), maximum: Double(device.activeFormat.maxISO)),
                  (try? device.lockForConfiguration()) != nil else {
                recovery.resetExposure(at: time)
                restoreExposure(device)
                return
            }
            if originalFrameDurations == nil {
                originalFrameDurations = (device.activeVideoMinFrameDuration, device.activeVideoMaxFrameDuration)
            }
            device.setExposureModeCustom(duration: CMTime(seconds: duration, preferredTimescale: 1_000_000), iso: Float(iso), completionHandler: nil)
            device.unlockForConfiguration()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}
