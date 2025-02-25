//
//  QRCodeScannerView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    var completion: (String, AVMetadataObject.ObjectType) -> Void
    var selectedDevice: AVCaptureDevice?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        scannerViewController.selectedDevice = selectedDevice
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if uiViewController.selectedDevice?.uniqueID != selectedDevice?.uniqueID {
            uiViewController.switchCamera(to: selectedDevice)
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
    
    private var videoCaptureDevice: AVCaptureDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
        
        // ✅ Listen for Scan Completion to Stop Camera
        NotificationCenter.default.addObserver(self, selector: #selector(stopScanning), name: NSNotification.Name("StopScanning"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startScanning), name: NSNotification.Name("StartScanning"), object: nil)
    }

    func setupScanner() {
        DispatchQueue.global(qos: .userInitiated).async {
            let session = AVCaptureSession()
            
            // Use the selected device or fall back to default
            let videoDevice = self.selectedDevice ?? AVCaptureDevice.default(for: .video)
            guard let device = videoDevice else { return }
            self.videoCaptureDevice = device

            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: device)
            } catch {
                return
            }

            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self.delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
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
                    .upce
                ]
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
