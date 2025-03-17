//
//  TextSenderViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import SwiftUI

@Observable
class ServerViewModel {
    // MARK: - Properties
    private var server = HTTPServer(port: 8080)

    // MARK: - Methods
    func startServer() {
        server.start()
    }

    func stopServer() {
        server.stop()
    }
}
