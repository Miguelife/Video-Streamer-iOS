//
//  TextSenderView.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import SwiftUI

struct ServerView: View {
    // MARK: - Properties
    @State private var viewModel = ServerViewModel()

    // MARK: - BODY
    var body: some View {
        buildByStatus()
            .navigationTitle("📦 SERVER")
            // MARK: - Life cycle
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.stopServer()
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
        ZStack(alignment: .bottom) {
            VideoPreviewViewRepresentable(captureSession: viewModel.captureSession)
                .ignoresSafeArea(edges: [.horizontal, .bottom])

            serverRunningLabel()
        }
    }

    @ViewBuilder
    func serverRunningLabel() -> some View {
        HStack(spacing: 16) {
            ProgressView()
            Text("Server running...")
        }
        .padding(.all, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.25), radius: 8)
    }

    @ViewBuilder
    func loadingBody() -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading...")
        }
    }

    @ViewBuilder
    func failureBody() -> some View {
        Text("Something went wrong. Try again.")
    }
}
