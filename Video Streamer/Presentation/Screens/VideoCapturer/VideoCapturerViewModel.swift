//
//  VideoCapturerViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import AVFoundation
import SwiftUI

@Observable
class VideoCapturerViewModel {
    enum VideoCapturerStatus { case inProgress, failure, success }
    // MARK: - PUBLIC PROPERTIES
    let server = HTTPServer(port: 8080)
    let captureSession = AVCaptureSession()
    var status: VideoCapturerStatus = .inProgress

    // MARK: - PRIVATE PROPERTIES
    private let videoOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    // MARK: - LIFE CYCLE
    func onAppear() {
        setupSession()
        server.start()
    }

    // MARK: - METHODS
    private func setupSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            status = .failure
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            captureSession.beginConfiguration()

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            }

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            captureSession.commitConfiguration()

            DispatchQueue.global().async { [weak self] in
                self?.captureSession.startRunning()

                DispatchQueue.main.async { [weak self] in
                    self?.status = .success
                }
            }

            startStreaming()
        } catch {
            status = .failure
        }
    }

    private func startStreaming() {
        guard let streamerDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
            status = .failure
            return
        }

        let videoStreamer = VideoStreamer(device: streamerDevice, fps: 30)
        videoStreamer.startCapture()
    }
}
