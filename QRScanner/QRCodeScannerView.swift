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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        scannerViewController.selectedDevice = selectedDevice
        scannerViewController.shouldInitializeScanner = shouldInitializeScanner
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
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
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var selectedDevice: AVCaptureDevice?
    var shouldInitializeScanner: Bool = true
    
    private var videoCaptureDevice: AVCaptureDevice?
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
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVCaptureSession()
            session.sessionPreset = .high // Higher resolution for better barcode detection
            
            // Use the selected device or fall back to default
            let videoDevice = self.selectedDevice ?? AVCaptureDevice.default(for: .video)
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
            
            DispatchQueue.main.async {
                self.captureSession = session
                self.setupPreviewLayer()
            }
            
            session.startRunning()
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
        DispatchQueue.global(qos: .userInitiated).async {
            if let captureSession = self.captureSession, !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    @objc func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
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
        guard let newDevice = device,
              videoCaptureDevice?.uniqueID != newDevice.uniqueID,
              let session = captureSession else { return }
        
        session.beginConfiguration()
        
        // Remove existing input
        session.inputs.forEach { session.removeInput($0) }
        
        // Add new input for the selected device
        if let newInput = try? AVCaptureDeviceInput(device: newDevice) {
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                self.videoCaptureDevice = newDevice
                self.selectedDevice = newDevice
            }
        }
        
        session.commitConfiguration()
    }
}
