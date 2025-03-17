//
//  WebSocketServer.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 14/3/25.
//

// class WebSocketServer {
//    let host: String
//    let port: Int
//    let eventLoopGroup: MultiThreadedEventLoopGroup
//    private var listener: NWListener?
//    private var service: NetService?
//    private let serviceType = "_websocket._tcp"
//    private let serviceName = "WebSocketServer"
//
//    enum UpgradeResult {
//        case websocket(NIOAsyncChannel<WebSocketFrame, WebSocketFrame>)
//        case notUpgraded(NIOAsyncChannel<HTTPServerRequestPart, HTTPPart<HTTPResponseHead, ByteBuffer>>)
//    }
//
//    init(host: String, port: Int, eventLoopGroup: MultiThreadedEventLoopGroup) {
//        self.host = host
//        self.port = port
//        self.eventLoopGroup = eventLoopGroup
//    }
//
//    func run() async throws {
//        print("WebSocketServer start running on \(host):\(port)...")
//        let channel: NIOAsyncChannel<EventLoopFuture<UpgradeResult>, Never> = try await ServerBootstrap(
//            group: eventLoopGroup
//        )
//        .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
//        .bind(
//            host: host,
//            port: port
//        ) { channel in
//            channel.eventLoop.makeCompletedFuture {
//                let upgrader = NIOTypedWebSocketServerUpgrader<UpgradeResult>(
//                    shouldUpgrade: { channel, _ in
//                        channel.eventLoop.makeSucceededFuture(HTTPHeaders())
//                    },
//                    upgradePipelineHandler: { channel, _ in
//                        channel.eventLoop.makeCompletedFuture {
//                            let asyncChannel = try NIOAsyncChannel<WebSocketFrame, WebSocketFrame>(
//                                wrappingChannelSynchronously: channel
//                            )
//                            return UpgradeResult.websocket(asyncChannel)
//                        }
//                    }
//                )
//
//                let serverUpgradeConfiguration = NIOTypedHTTPServerUpgradeConfiguration(
//                    upgraders: [upgrader],
//                    notUpgradingCompletionHandler: { channel in
//                        channel.eventLoop.makeCompletedFuture {
//                            try channel.pipeline.syncOperations.addHandler(HTTPByteBufferResponsePartHandler())
//                            let asyncChannel = try NIOAsyncChannel<
//                                HTTPServerRequestPart, HTTPPart<HTTPResponseHead, ByteBuffer>
//                            >(wrappingChannelSynchronously: channel)
//                            return UpgradeResult.notUpgraded(asyncChannel)
//                        }
//                    }
//                )
//
//                let negotiationResultFuture = try channel.pipeline.syncOperations.configureUpgradableHTTPServerPipeline(
//                    configuration: .init(upgradeConfiguration: serverUpgradeConfiguration)
//                )
//
//                return negotiationResultFuture
//            }
//        }
//
//        becomeVisible()
//
//        try await withThrowingDiscardingTaskGroup { group in
//            try await channel.executeThenClose { inbound in
//                for try await upgradeResult in inbound {
//                    group.addTask {
//                        await self.handleUpgradeResult(upgradeResult)
//                    }
//                }
//            }
//        }
//    }
//
//    private func handleUpgradeResult(_ upgradeResult: EventLoopFuture<UpgradeResult>) async {
//        do {
//            switch try await upgradeResult.get() {
//            case .websocket(let websocketChannel):
//                try await handleWebsocketChannel(websocketChannel)
//            default:
//                break
//            }
//        } catch {
//            print("Hit error: \(error)")
//        }
//    }
//
//    private func handleWebsocketChannel(_ channel: NIOAsyncChannel<WebSocketFrame, WebSocketFrame>) async throws {
//        try await channel.executeThenClose { inbound, outbound in
//            try await withThrowingTaskGroup(of: Void.self) { group in
//                group.addTask {
//                    for try await frame in inbound {
//                        switch frame.opcode {
//                        case .connectionClose:
//                            print("Received close")
//                            var data = frame.unmaskedData
//                            let closeDataCode = data.readSlice(length: 2) ?? ByteBuffer()
//                            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
//                            try await outbound.write(closeFrame)
//                            return
//                        case .binary, .continuation, .pong, .ping:
//                            break
//                        case .text:
//                            var frameData = frame.data
//                            if let maskingKey = frame.maskKey {
//                                frameData.webSocketUnmask(maskingKey)
//                            }
//
//                            var responseFrame = WebSocketFrame(fin: true, opcode: .text, data: frameData)
//                            let message = responseFrame.data.readString(length: responseFrame.data.readableBytes) ?? "-"
//
//                            print("Received text: " + message)
//
//                            var buffer = channel.channel.allocator.buffer(capacity: 12)
//                            buffer.writeString(message)
//
//                            let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
//
//                            try await outbound.write(frame)
//                        default:
//                            // Unknown frames are errors.
//                            return
//                        }
//                    }
//                }
//
//                try await group.next()
//                group.cancelAll()
//            }
//        }
//    }
//
//    func becomeVisible() {
//        do {
//            listener = try NWListener(using: .tcp, on: 8083)
//            listener?.stateUpdateHandler = { state in
//                switch state {
//                case .ready:
//                    if let port = self.listener?.port {
//                        print("Servidor WebSocket en puerto: \(port)")
//                        self.publishBonjourService(port: port.rawValue)
//                    }
//                case .failed(let error):
//                    print("WebSocketServer Error al iniciar servidor: \(error)")
//                default:
//                    break
//                }
//            }
//            listener?.newConnectionHandler = { connection in
//                connection.start(queue: .main)
//                self.handleNewConnection(connection)
//                print("Nueva conexión WebSocket")
//            }
//            listener?.start(queue: .main)
//        } catch {
//            print("Error al iniciar NWListener: \(error)")
//        }
//    }
//
//    func handleNewConnection(_ connection: NWConnection) {
//        connection.start(queue: .main)
//
//        // Enviar un mensaje personalizado al cliente
//        let welcomeMessage = "Bienvenido al servidor WebSocket!\n"
//        let data = welcomeMessage.data(using: .utf8)!
//
//        connection.send(content: data, completion: .contentProcessed { error in
//            if let error = error {
//                print("Error al enviar mensaje: \(error)")
//            } else {
//                print("Mensaje enviado al cliente")
//            }
//        })
//    }
//
//    private func publishBonjourService(port: UInt16) {
//        service = NetService(domain: "local.", type: serviceType, name: serviceName, port: Int32(port))
//        service?.publish()
//        print("Servicio Bonjour publicado en: \(serviceType) con puerto: \(port)")
//    }
// }
//
// final class HTTPByteBufferResponsePartHandler: ChannelOutboundHandler {
//    typealias OutboundIn = HTTPPart<HTTPResponseHead, ByteBuffer>
//    typealias OutboundOut = HTTPServerResponsePart
//
//    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
//        let part = Self.unwrapOutboundIn(data)
//        switch part {
//        case .head(let head):
//            context.write(Self.wrapOutboundOut(.head(head)), promise: promise)
//        case .body(let buffer):
//            context.write(Self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: promise)
//        case .end(let trailers):
//            context.write(Self.wrapOutboundOut(.end(trailers)), promise: promise)
//        }
//    }
// }
