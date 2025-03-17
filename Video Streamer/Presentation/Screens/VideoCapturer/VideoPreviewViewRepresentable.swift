//
//  ViedeoPreviewViewRepresentable.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import AVFoundation
import SwiftUI
import UIKit

struct VideoPreviewViewRepresentable: UIViewRepresentable {
    let captureSession: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = VideoPreview()
        view.videoPreviewLayer.session = captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class VideoPreview: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
