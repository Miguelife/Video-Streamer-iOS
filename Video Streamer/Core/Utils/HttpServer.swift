import Foundation
import Network

class HTTPServer {
    private let serviceType = Constants.serviceType
    private let serviceName = "VoidStreamer"
    private var listener: NWListener?
    private var service: NetService?
    private var port: UInt16
    var didReceiveConnection: (([URLQueryItem]) -> Void)?

    init(port: UInt16) {
        self.port = port
    }

    func start() {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                guard let self else { return }

                switch state {
                case .ready:
                    print("Servidor HTTP escuchando en el puerto \(self.port)")
                    self.publishBonjourService(port: self.port)
                case .failed(let error):
                    print("Error al iniciar el servidor: \(error)")
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.start(queue: .main)
        } catch {
            print("Error al iniciar NWListener: \(error)")
        }
    }

    func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        receiveRequest(connection)
    }

    func stop() {
        listener?.cancel()
        service?.stop()
    }

    private func publishBonjourService(port: UInt16) {
        service = NetService(domain: "local.", type: serviceType, name: serviceName, port: Int32(port))
        service?.publish()
        print("Servicio Bonjour publicado en: \(serviceType) con puerto: \(port)")
    }

    func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
            guard let self, let data else { return }

            if let requestString = String(data: data, encoding: .utf8),
               let firstLine = requestString.components(separatedBy: "\r\n").first,
               let urlComponents = firstLine.components(separatedBy: " ").dropFirst().first,
               let queryItems = URLComponents(string: urlComponents)?.queryItems
            {
                didReceiveConnection?(queryItems)

                let httpResponse = """
                HTTP/1.1 200 OK\r
                Content-Type: text/plain\r
                Content-Length: 11\r
                \r
                hello world
                """

                let responseData = httpResponse.data(using: .utf8)!
                connection.send(content: responseData, completion: .contentProcessed { _ in
                    connection.cancel()
                })

                return
            }

            connection.cancel()
        }
    }
}
