//
//  WebSocketManager.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import Foundation
import SwiftUI

// class WebSocketClient {
//    private var webSocketTask: URLSessionWebSocketTask?
//    var onMessageReceived: (() -> Void)?
//    var receivedMessage: String = "" {
//        didSet {
//            onMessageReceived?()
//        }
//    }
//
//    init(host: String, port: Int) {
//        let url = URL(string: "ws://\(host):\(port)")!
//        self.webSocketTask = URLSession.shared.webSocketTask(with: url)
//    }
//
//    func connect() {
//        print("WebSocketClient connected")
//        webSocketTask?.resume()
//        listenForMessages()
//    }
//
//    func disconnect() {
//        webSocketTask?.cancel(with: .normalClosure, reason: nil)
//    }
//
//    private func listenForMessages() {
//        Task {
//            while webSocketTask?.state == .running {
//                let result = try? await webSocketTask!.receive()
//
//                switch result {
//                case .string(let text):
//                    print("Recibido: \(text)")
//                    self.receivedMessage = text
//                default:
//                    break
//                }
//            }
//        }
//    }
//
//    func send(_ message: String) {
//        let message = URLSessionWebSocketTask.Message.string(message)
//        webSocketTask?.send(message) { error in
//            if let error = error {
//                print("Error al enviar el mensaje: \(error)")
//            }
//        }
//    }
// }
