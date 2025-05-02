//
//  ViedeoPreviewViewRepresentable.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import AVFoundation
import SwiftUI
import UIKit
import WebRTC

struct VideoPreviewViewRepresentable: UIViewRepresentable {
    let localVideoView: RTCMTLVideoView

    func makeUIView(context: Context) -> UIView {
        return localVideoView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
