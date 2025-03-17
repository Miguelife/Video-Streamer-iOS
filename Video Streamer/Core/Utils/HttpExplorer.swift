import Foundation
import Network

class HttpExplorer: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var serviceBrowser = NetServiceBrowser()
    private var netService: NetService?
    let serviceType: String
    var didFoundService: ((NetService) -> Void)?
    var didLostService: ((NetService) -> Void)?

    init(serviceType: String) {
        self.serviceType = serviceType
    }

    func start() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.explore()
            } else {
                print("No hay conexión a la red local")
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }

    func explore() {
        print("Explorer comenzando a buscar servicios...")
        serviceBrowser.delegate = self
        serviceBrowser.searchForServices(ofType: serviceType, inDomain: "local.")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Servicio encontrado: \(service.name)")
        netService = service
        netService!.delegate = self
        netService!.resolve(withTimeout: 5)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Service resolved")
        netService = nil
        didFoundService?(sender)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Service removed")
        didLostService?(service)
    }
}
