//
//  VideoReceiverView.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import SwiftUI

struct VideoReceiverView: View {
    // MARK: - Properties
    @State var viewModel: VideoReceiverViewModel

    // MARK: - BODY
    var body: some View {
        VideoView()
            .onAppear() {
                viewModel.getStreamConfiguration()
            }
    }
}
