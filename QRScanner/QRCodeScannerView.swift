//
//  QRCodeScannerView.swift
//  QRScanner
//
//  Created by Om Shejul on 17/02/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let scannerViewController = ScannerViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView

        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  readableObject.type == .qr,
                  let stringValue = readableObject.stringValue else { return }

            DispatchQueue.main.async {
                self.parent.completion(stringValue)
            }
        }
    }
}

// MARK: - ScannerViewController
class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
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
            guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
            self.videoCaptureDevice = videoDevice

            let videoInput: AVCaptureDeviceInput
            do {
                videoInput = try AVCaptureDeviceInput(device: videoDevice)
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
                metadataOutput.metadataObjectTypes = [.qr]
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
}
