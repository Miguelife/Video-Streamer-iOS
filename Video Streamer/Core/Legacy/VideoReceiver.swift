//
//  VideoReceiver.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import WebRTC

class VideoReceiver: UIViewController {
    private var peerConnection: RTCPeerConnection?
    private var remoteVideoView: RTCMTLVideoView!

    private func setupWebRTC() {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.iceServers = []

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    func receiveOffer(_ offer: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(offer, completionHandler: { [weak self] error in
            guard error == nil else { return }
            self?.sendAnswer()
        })
    }

    private func sendAnswer() {
        peerConnection?.answer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { [weak self] answer, error in
            guard let answer = answer, error == nil else { return }
            self?.peerConnection?.setLocalDescription(answer, completionHandler: { _ in })
        }
    }
}

extension VideoReceiver: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let videoTrack = stream.videoTracks.first {
            DispatchQueue.main.async {
                videoTrack.add(self.remoteVideoView)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {}
}
