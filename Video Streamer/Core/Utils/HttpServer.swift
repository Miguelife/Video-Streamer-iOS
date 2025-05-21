import Foundation
import Network

class HTTPServer {
    private let serviceType = Constants.serviceType
    private let serviceName = "VoidStreamer"
    private var listener: NWListener?
    private var service: NetService?
    private var port: UInt16
    var didReceiveConnection: (([URLQueryItem]) -> Void)?
    private var mjpegClients: [NWConnection] = []
    private var currentVideoFrame: Data?
    private var lastFrameTimestamp = Date.distantPast

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
        // Cerrar todas las conexiones de streaming activas
        for connection in mjpegClients {
            connection.cancel()
        }
        mjpegClients.removeAll()
        
        // Detener Bonjour y el listener
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
            
            if let requestString = String(data: data, encoding: .utf8) {
                // Parsear la solicitud HTTP
                let requestLines = requestString.components(separatedBy: "\r\n")
                guard let firstLine = requestLines.first,
                      let _ = firstLine.components(separatedBy: " ").first
                else {
                    self.sendError(connection: connection, status: 400, message: "Solicitud incorrecta")
                    return
                }
                
                // Obtener la URL solicitada
                let urlComponents = firstLine.components(separatedBy: " ").dropFirst().first
                
                // Verificar qué tipo de solicitud es
                if let urlPath = urlComponents {
                    if urlPath.contains("/stream") {
                        // Streaming de video MJPEG
                        self.handleMJPEGRequest(connection: connection)
                        return
                    } else if urlPath.contains("/snapshot") {
                        // Captura de imagen estática
                        self.handleSnapshotRequest(connection: connection)
                        return
                    } else if urlPath.contains("/info") {
                        // Información sobre el servidor
                        self.handleInfoRequest(connection: connection)
                        return
                    } else if let queryItems = URLComponents(string: urlPath)?.queryItems {
                        // Endpoint por defecto con parámetros
                        self.didReceiveConnection?(queryItems)
                        self.sendDefaultResponse(connection: connection)
                        return
                    }
                }
                
                // Por defecto, enviar página HTML principal
                self.sendMainPage(connection: connection)
                return
            }
            
            connection.cancel()
        }
    }
    
    // MARK: - Métodos de respuesta HTTP
    
    private func sendError(connection: NWConnection, status: Int, message: String) {
        let httpResponse = "HTTP/1.1 \(status) Error\r\nContent-Type: text/plain\r\nContent-Length: \(message.count)\r\n\r\n\(message)"
        
        let responseData = httpResponse.data(using: .utf8)!
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func sendDefaultResponse(connection: NWConnection) {
        let message = "OK"
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: \(message.count)\r\n\r\n\(message)"
        
        let responseData = httpResponse.data(using: .utf8)!
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func handleInfoRequest(connection: NWConnection) {
        let info = "{\"name\": \"VoidStreamer\", \"version\": \"1.0\", \"endpoints\": {\"/stream\": \"MJPEG video stream\", \"/snapshot\": \"Single JPEG image\", \"/info\": \"Server information\"}}"
        
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(info.count)\r\n\r\n\(info)"
        
        let responseData = httpResponse.data(using: .utf8)!
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func handleSnapshotRequest(connection: NWConnection) {
        guard let jpegData = currentVideoFrame else {
            sendError(connection: connection, status: 503, message: "No video frame available")
            return
        }
        
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpegData.count)\r\nCache-Control: no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0\r\nPragma: no-cache\r\nConnection: close\r\n\r\n"
        
        let headerData = httpResponse.data(using: .utf8)!
        
        // Enviar encabezado y luego los datos JPEG
        connection.send(content: headerData, completion: .contentProcessed { _ in
            connection.send(content: jpegData, completion: .contentProcessed { _ in
                connection.cancel()
            })
        })
    }
    
    private func handleMJPEGRequest(connection: NWConnection) {
        // Enviar cabeceras MJPEG
        let httpHeader = "HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=frameboundary\r\nCache-Control: no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0\r\nPragma: no-cache\r\nConnection: close\r\n\r\n"
        
        let headerData = httpHeader.data(using: .utf8)!
        connection.send(content: headerData, completion: .contentProcessed { [weak self] _ in
            guard let self = self else { return }
            // Añadir a la lista de clientes MJPEG para enviar frames
            self.mjpegClients.append(connection)
            
            // Si hay un frame disponible, enviarlo inmediatamente
            if let currentFrame = self.currentVideoFrame {
                self.sendFrameToClient(connection: connection, jpegData: currentFrame)
            }
        })
    }
    
    // Método para que ServerViewModel pueda enviar frames de vídeo
    func broadcastVideoFrame(_ jpegData: Data) {
        // Guardar el frame actual
        currentVideoFrame = jpegData
        lastFrameTimestamp = Date()
        
        // Filtrar clientes inactivos
        mjpegClients = mjpegClients.filter { connection in
            return connection.state == .ready || connection.state == .preparing
        }
        
        // Enviar a todos los clientes conectados
        for connection in mjpegClients {
            sendFrameToClient(connection: connection, jpegData: jpegData)
        }
    }
    
    private func sendFrameToClient(connection: NWConnection, jpegData: Data) {
        // Preparar el frame MJPEG con el boundary
        let frameHeader = "--frameboundary\r\nContent-Type: image/jpeg\r\nContent-Length: \(jpegData.count)\r\n\r\n"
        let frameHeaderData = frameHeader.data(using: .utf8)!
        
        // Enviar encabezado y luego el frame
        connection.send(content: frameHeaderData, completion: .contentProcessed { [weak self] _ in
            guard let _ = self else { return }
            connection.send(content: jpegData, completion: .contentProcessed { _ in
                // El frame se ha enviado correctamente
            })
        })
    }
    
    private func sendMainPage(connection: NWConnection) {
        let html = "<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>VoidStreamer</title>\n    <style>\n        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; text-align: center; }\n        h1 { color: #333; }\n        .container { max-width: 800px; margin: 0 auto; }\n        .stream-container { margin-top: 20px; }\n        img { max-width: 100%; border: 1px solid #ddd; }\n        .controls { margin-top: 20px; }\n        button { padding: 10px 15px; margin: 0 5px; cursor: pointer; }\n    </style>\n</head>\n<body>\n    <div class=\"container\">\n        <h1>VoidStreamer - Transmisor de Video</h1>\n        <div class=\"stream-container\">\n            <img id=\"streamImage\" src=\"/stream\" alt=\"Stream de video\" width=\"640\">\n        </div>\n        <div class=\"controls\">\n            <button onclick=\"location.href='/snapshot';\">Capturar Imagen</button>\n            <button onclick=\"location.href='/info';\">Información</button>\n        </div>\n    </div>\n</body>\n</html>"
        
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=UTF-8\r\nContent-Length: \(html.count)\r\n\r\n\(html)"
        
        let responseData = httpResponse.data(using: .utf8)!
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
