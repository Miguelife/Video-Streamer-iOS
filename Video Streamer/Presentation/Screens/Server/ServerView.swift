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
        VStack(spacing: 16) {
            ProgressView()
            Text("Server running...")
        }
        .navigationTitle("📦 SENDER")
        // MARK: - Life cycle
        .onAppear {
            viewModel.startServer()
        }
        .onDisappear {
            viewModel.stopServer()
        }
    }
}
