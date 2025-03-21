//
//  VideoReceiverBuilder.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 21/3/25.
//

import Foundation

class VideoReceiverBuilder {
    func build(for service: NetService) -> VideoReceiverView {
        let viewModel = VideoReceiverViewModel(service: service)
        return VideoReceiverView(viewModel: viewModel)
    }
}
