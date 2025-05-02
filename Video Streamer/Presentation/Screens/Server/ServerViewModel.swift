//
//  TextSenderViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import AVFoundation
import SwiftUI
import WebRTC
@Observable
class ServerViewModel {
    // MARK: - Properties
    var status: VideoCapturerStatus = .inProgress
    enum VideoCapturerStatus { case inProgress, failure, success }

    // MARK: - PRIVATE PROPERTIES
    private var videoStreamer: WebRtcManager!
    private let server = HTTPServer(port: 8080)
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureMovieFileOutput()
    var videoDeviceInput: AVCaptureDeviceInput?

    // MARK: - Methods
    func onAppear() {
        videoStreamer = WebRtcManager()
        startStreaming()
        server.didReceiveConnection = { [weak self] items in
            let sdp = items.first(where: { $0.name == "sdp" })?.value
            print("RECIVED SDP \(sdp ?? "null")")
            // videoStreamer.handleRemoteOffer(sdp)
        }
        server.start()
    }

    func stopServer() {
        server.stop()
    }

    // MARK: - METHODS
    private func startStreaming() {
        guard let streamerDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
            status = .failure
            return
        }

        videoStreamer.startCapture(device: streamerDevice,
                                   format: streamerDevice.formats.last!,
                                   fps: 30)
        status = .success
    }

    func getLocalView() -> RTCMTLVideoView {
        return videoStreamer.getLocalView()
    }
}
