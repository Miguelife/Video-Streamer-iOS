//
//  ServerViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import AVFoundation
import SwiftUI

@Observable
class ServerViewModel {
    // MARK: - Properties
    var status: VideoCapturerStatus = .inProgress
    enum VideoCapturerStatus { case inProgress, failure, success }

    // MARK: - PRIVATE PROPERTIES
    private let server = HTTPServer(port: 8080)
    private let videoOutput = VideoOutputManager()

    // MARK: - Methods
    func onAppear() {
        do {
            try videoOutput.startStreaming()
            videoOutput.onFrameAvailable = { [weak self] frame in
                // Pasar el frame de vídeo al servidor HTTP para su distribución
                self?.server.broadcastVideoFrame(frame)
            }

            server.start()
            status = .success
        } catch {
            status = .failure
        }
    }

    func stopServer() {
        server.stop()
        videoOutput.stopStreaming()
    }
}
