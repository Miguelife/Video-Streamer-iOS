//
//  VideoOutput.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 17/5/25.
//

import AVFoundation
import Foundation
import UIKit

class VideoOutputError: Error {}

class VideoOutputManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    var onFrameAvailable: ((Data) -> Void)?

    init(onFrameAvailable: ((Data) -> Void)? = nil) {
        self.onFrameAvailable = onFrameAvailable
    }

    func startStreaming() throws {
        captureSession.sessionPreset = .hd4K3840x2160
        guard let streamerDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back),
              let inputDevice = try? AVCaptureDeviceInput(device: streamerDevice)
        else {
            throw VideoOutputError()
        }

        captureSession.addInput(inputDevice)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        captureSession.addOutput(output)

        DispatchQueue.global().async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopStreaming() {
        captureSession.stopRunning()
    }

    // Para streaming de video
    private let frameRateLimit: Double = 60.0 // Frames por segundo máximos
    private var lastFrameTime = Date()
    private(set) var latestFrameTimestamp: Date = .init()
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Control de frecuencia de frames para no saturar la red
        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastFrameTime)
        let targetInterval = 1.0 / frameRateLimit

        guard elapsedTime >= targetInterval else { return }
        lastFrameTime = now

        // Procesar frame de video
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)

        // Convertir a JPEG con calidad 0.7 (buena calidad/tamaño)
        if let jpegData = context.jpegRepresentation(of: ciImage,
                                                     colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                     options: [:])
        {
            // Almacenar el último frame para streaming HTTP
            latestFrameTimestamp = now

            // Notificar que hay un nuevo frame disponible
            onFrameAvailable?(jpegData)
        }
    }
}
