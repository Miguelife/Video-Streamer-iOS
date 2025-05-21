//
//  VideoReceiverBuilder.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 21/3/25.
//

import Foundation

class ClientBuilder {
    func build(for service: NetService) -> ClientView {
        let viewModel = ClientViewModel(service: service)
        return ClientView(viewModel: viewModel)
    }
}
