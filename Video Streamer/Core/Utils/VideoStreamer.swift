//
//  VideoStreamer.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import AVFoundation
import WebRTC

class VideoStreamer {
    let device: AVCaptureDevice
    let fps: Int

    private var peerConnection: RTCPeerConnection?
    private var videoCapturer: RTCCameraVideoCapturer?

    init(device: AVCaptureDevice, fps: Int) {
        self.device = device
        self.fps = fps

        startStreaming()
    }

    func startStreaming() {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.iceServers = []
        peerConnection = factory.peerConnection(with: config, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil)

        let videoSource = factory.videoSource()
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)

        let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        peerConnection?.add(videoTrack, streamIds: ["stream"])
    }

    func startCapture() {
        guard let capturer = videoCapturer else { return }
        let format = device.formats.last
        capturer.startCapture(with: device, format: format!, fps: fps)
    }
}
