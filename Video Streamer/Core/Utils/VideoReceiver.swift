//
//  VideoReceiver.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 17/3/25.
//

import UIKit
import WebRTC

class VideoReceiver: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var videoRenderer: RTCMTLVideoView

    init(videoView: RTCMTLVideoView) {
        self.videoRenderer = videoView
        super.init()
        setupPeerConnection()
    }

    private func setupPeerConnection() {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.iceServers = []
        config.sdpSemantics = .unifiedPlan

        peerConnection = factory.peerConnection(with: config, constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil)

        let videoSource = factory.videoSource()
        let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
        videoTrack.add(videoRenderer)

        peerConnection?.add(videoTrack, streamIds: ["stream"])
    }

    func setRemoteDescription(_ sdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        peerConnection?.setRemoteDescription(sdp) { error in
            print("Hola Mundo")
            completion(error)
        }
    }

    func addIceCandidate(_ candidate: RTCIceCandidate) {
        peerConnection?.add(candidate, completionHandler: { _ in
            // Manage error
        })
    }
}
