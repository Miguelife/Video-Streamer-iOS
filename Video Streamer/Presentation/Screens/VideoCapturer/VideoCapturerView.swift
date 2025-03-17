//
//  Videpo.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import AVFoundation
import SwiftUI

struct VideoCapturerView: View {
    @State var viewModel = VideoCapturerViewModel()

    // MARK: - BODY
    var body: some View {
        buildByStatus()
            .onAppear {
                viewModel.onAppear()
            }
    }

    @ViewBuilder
    func buildByStatus() -> some View {
        switch viewModel.status {
        case .success:
            successBody()
        case .inProgress:
            loadingBody()
        case .failure:
            failureBody()
        }
    }

    @ViewBuilder
    func successBody() -> some View {
        VideoPreviewViewRepresentable(captureSession: viewModel.captureSession)
            .ignoresSafeArea(.all)
    }

    @ViewBuilder
    func loadingBody() -> some View {
        ProgressView()
    }

    @ViewBuilder
    func failureBody() -> some View {
        Text("Failed to initialize camera")
    }
}
