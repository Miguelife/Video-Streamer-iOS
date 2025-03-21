import SwiftUI
import WebRTC

@Observable
class VideoReceiverViewModel {
    let service: NetService
    let videoManager = WebRtcManager()

    init(service: NetService) {
        self.service = service
    }

    func getStreamConfiguration() {
        videoManager.createOffer { [weak self] session in
            guard let self, let session else { return }
            Task {
                guard let host = self.service.hostName,
                      let url = URL(string: "http://\(host):\(self.service.port)?sdp=\(session.sdp)")
                else {
                    return
                }

                do {
                    _ = try await URLSession.shared.data(from: url)

                    print("SDP SENDED")
                } catch {
                    print("Error sending sdp")
                }
            }
        }
    }
}

import AVFoundation
import Foundation
import WebRTC

class WebRtcManager: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var videoCapturer: RTCCameraVideoCapturer?
    private let factory = RTCPeerConnectionFactory()
    private let localVideoTrack: RTCVideoTrack
    private let remoteVideoTrack: RTCVideoTrack

    override init() {
        let videoSource = factory.videoSource()
        self.localVideoTrack = factory.videoTrack(with: videoSource, trackId: "localVideo")
        self.remoteVideoTrack = factory.videoTrack(with: videoSource, trackId: "remoteVideo")
        super.init()
        setupPeerConnection()
    }

    private func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)

        let capturer = RTCCameraVideoCapturer(delegate: localVideoTrack.source)
        videoCapturer = capturer
    }

    func startCapture(device: AVCaptureDevice, format: AVCaptureDevice.Format, fps: Int) {
        videoCapturer?.startCapture(with: device, format: format, fps: 30)
    }

    func createOffer(completion: @escaping (RTCSessionDescription?) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.offer(for: constraints) { [weak self] sdp, error in
            guard let sdp = sdp, error == nil else {
                completion(nil)
                return
            }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { _ in })
            completion(sdp)
        }
    }

    func handleRemoteOffer(_ sdp: RTCSessionDescription) {
        peerConnection?.setRemoteDescription(sdp) { [weak self] error in
            if error == nil {
                self?.createAnswer()
            }
        }
    }

    private func createAnswer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection?.answer(for: constraints) { [weak self] sdp, error in
            guard let sdp = sdp, error == nil else { return }
            self?.peerConnection?.setLocalDescription(sdp, completionHandler: { _ in })
        }
    }
}

extension WebRtcManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange state: RTCIceGatheringState) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
