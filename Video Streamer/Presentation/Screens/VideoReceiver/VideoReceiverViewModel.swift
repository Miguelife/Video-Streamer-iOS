//
//  VideoReceiverViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import WebRTC

@Observable
class VideoReceiverViewModel: NSObject {
    private var peerConnection: RTCPeerConnection?
    private let factory = RTCPeerConnectionFactory()
    var remoteVideoTrack: RTCVideoTrack?

    private func setupWebRTC() {
        let config = RTCConfiguration()
        config.iceServers = []

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    func startConnection() {
        // Aquí se debe recibir la oferta SDP del emisor
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

// MARK: - WebRTC Delegate
extension VideoReceiverViewModel: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let videoTrack = stream.videoTracks.first {
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
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
