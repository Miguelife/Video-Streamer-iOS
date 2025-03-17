import Foundation
import Network

class HTTPServer {
    private let serviceType = Constants.serviceType
    private let serviceName = "VoidStreamer"
    private var listener: NWListener?
    private var service: NetService?
    private var port: UInt16

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
}


//
//    func receiveRequest(_ connection: NWConnection) {
//        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
//            if let data = data, let request = String(data: data, encoding: .utf8) {
//                print("Solicitud recibida:\n\(request)")
//
//                // Construir una respuesta HTTP válida
//                let response =
//                    "HTTP/1.1 200 OK\r\n" +
//                    "Content-Type: text/plain\r\n" +
//                    "Content-Length: 17\r\n" +
//                    "\r\n" +
//                    "¡Hola, cliente!\n"
//
//                let responseData = response.data(using: .utf8)!
//                connection.send(content: responseData, completion: .contentProcessed { _ in
//                    connection.cancel()
//                })
//            }
//
//            if isComplete || error != nil {
//                connection.cancel()
//            }
//        }
//    }
