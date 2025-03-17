//
//  TextSenderView.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import SwiftUI

struct ClientView: View {
    // MARK: - Properties
    @State private var viewModel = ClientViewModel()

    // MARK: - BODY
    var body: some View {
        makeBody()
            .navigationTitle("📩 RECEIVER")
            // MARK: - Life cycle
            .onAppear {
                viewModel.exploreNetwork()
            }
    }

    @ViewBuilder
    func makeBody() -> some View {
        if viewModel.services.isEmpty {
            emptyView()
        } else {
            successView()
        }
    }

    @ViewBuilder
    func emptyView() -> some View {
        VStack {
            ProgressView()
            Text("Searching for servers...")
        }
    }

    @ViewBuilder
    func successView() -> some View {
        List {
            ForEach(viewModel.services, id: \.self) { service in
                NavigationLink(value: service) {
                    serviceTile(service)
                }
            }
        }
    }

    @ViewBuilder
    func serviceTile(_ service: NetService) -> some View {
        let subtitle = (service.hostName ?? "") + ":" +  "\(service.port)"

        VStack(alignment: .leading, spacing: 0) {
            Text(service.name)
                .bold()
            Text(subtitle)
                .font(.subheadline)
        }
    }
}
