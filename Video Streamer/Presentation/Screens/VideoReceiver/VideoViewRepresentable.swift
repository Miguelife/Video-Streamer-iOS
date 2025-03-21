//
//  VideoReceiverViewRepresentable.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import WebRTC
import SwiftUI

struct VideoView: UIViewRepresentable {
    var videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView()
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        videoTrack?.add(uiView)
    }
}
