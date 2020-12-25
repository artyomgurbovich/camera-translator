//
//  CameraManager.swift
//  Camera Translator
//
//  Created by Artyom Gurbovich on 11/2/20.
//

import UIKit
import AVFoundation

final class CameraManager: NSObject {
    var onReceive: ((CVPixelBuffer) -> Void)?
    var onMove: (() -> Void)?
    private(set) var isRunning = true
    private(set) var isReceiving = true
    private let mainQueue = DispatchQueue.main
    private let queue = DispatchQueue(label: "CameraManager", qos: .background)
    private let outputView: UIView
    private let captureSession: AVCaptureSession
    private let captureDeviceVideo: AVCaptureDevice
    private let captureVideoPreviewLayer: AVCaptureVideoPreviewLayer
    private var previousPixelBuffer: CVPixelBuffer?
    private var counter = Int.zero
    var isTorchOn: Bool {
        return captureDeviceVideo.torchMode == .on
    }
    
    init?(outputView: UIView) {
        self.outputView = outputView
        guard let captureDeviceVideo = AVCaptureDevice.default(for: .video) else { return nil }
        self.captureDeviceVideo = captureDeviceVideo
        guard let captureDeviceVideoInput = try? AVCaptureDeviceInput(device: captureDeviceVideo) else { return nil }
        captureSession = AVCaptureSession()
        let captureVideoDataOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddInput(captureDeviceVideoInput) else { return nil }
        guard captureSession.canAddOutput(captureVideoDataOutput) else { return nil }
        captureSession.addInput(captureDeviceVideoInput)
        captureSession.addOutput(captureVideoDataOutput)
        captureVideoDataOutput.connection(with: .video)?.isEnabled = true
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        captureVideoPreviewLayer.frame = self.outputView.bounds
        self.outputView.layer.insertSublayer(captureVideoPreviewLayer, at: .zero)
        captureSession.startRunning()
        super.init()
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    func setRunning(_ state: Bool) {
        mainQueue.async {
            self.isRunning = state
            if state && !self.captureSession.isRunning {
                self.captureSession.startRunning()
            } else if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func setReceiving(_ state: Bool) {
        mainQueue.async {
            self.isReceiving = state
        }
    }
    
    func toggleTorch() {
        guard captureDeviceVideo.hasTorch else { return }
        do {
            try captureDeviceVideo.lockForConfiguration()
            if (captureDeviceVideo.torchMode == .on) {
                captureDeviceVideo.torchMode = .off
            } else {
                do {
                    try captureDeviceVideo.setTorchModeOn(level: 1)
                } catch {
                    print(error)
                }
            }
            captureDeviceVideo.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func draw(layers: [CATextLayer]) {
        mainQueue.async {
            self.captureVideoPreviewLayer.sublayers?.removeSubrange(1...)
            layers.forEach{self.captureVideoPreviewLayer.addSublayer($0)}
        }
    }
    
    func clearPreviewLayer() {
        mainQueue.async {
            self.captureVideoPreviewLayer.sublayers?.removeSubrange(1...)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if counter % 20 == .zero {
            if let previousPixelBuffer = previousPixelBuffer, getMotionPercentage(previousPixelBuffer, pixelBuffer) > 11 {
                mainQueue.async {
                    self.onMove?()
                }
            }
            previousPixelBuffer = pixelBuffer
        } else if counter % 10 == .zero {
            mainQueue.async {
                guard self.isReceiving else { return }
                self.onReceive?(pixelBuffer)
            }
        }
        counter += 1
        if counter == 60 {
            counter = .zero
        }
    }
}

extension CameraManager {
    func getMotionPercentage(_ previousPixelBuffer: CVPixelBuffer, _ currentPixelBuffer: CVPixelBuffer) -> Int {
        CVPixelBufferLockBaseAddress(previousPixelBuffer, [])
        CVPixelBufferLockBaseAddress(currentPixelBuffer, [])
        defer {
            CVPixelBufferUnlockBaseAddress(previousPixelBuffer,[])
            CVPixelBufferUnlockBaseAddress(currentPixelBuffer,[])
        }
        var differences = Int.zero
        let width = CVPixelBufferGetWidth(currentPixelBuffer)
        let height = CVPixelBufferGetHeight(currentPixelBuffer)
        let bytesPerRowC = CVPixelBufferGetBytesPerRow(currentPixelBuffer)
        let bytesPerRowP = CVPixelBufferGetBytesPerRow(previousPixelBuffer)
        let bufferC = CVPixelBufferGetBaseAddress(currentPixelBuffer)!.assumingMemoryBound(to: UInt8.self)
        let bufferP = CVPixelBufferGetBaseAddress(previousPixelBuffer)!.assumingMemoryBound(to: UInt8.self)
        for x in 0..<height / 8 {
            for y in 0..<width / 8 {
                let p0 = Int(bufferP[x * 8 * bytesPerRowP + y * 8 + 0])
                let p1 = Int(bufferP[x * 8 * bytesPerRowP + y * 8 + 1])
                let p2 = Int(bufferP[x * 8 * bytesPerRowP + y * 8 + 2])
                let c0 = Int(bufferC[x * 8 * bytesPerRowC + y * 8 + 0])
                let c1 = Int(bufferC[x * 8 * bytesPerRowC + y * 8 + 1])
                let c2 = Int(bufferC[x * 8 * bytesPerRowC + y * 8 + 2])
                if ((abs(p0 - c0) > 8) && (abs(p1 - c1) > 8) && (abs(p2 - c2) > 8)) {
                    differences += 1
                }
            }
        }
        return differences * 100 / (width * height / 64)
    }
}
