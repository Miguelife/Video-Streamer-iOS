import SwiftUI
import WebRTC

@Observable
class ClientViewModel {
    let service: NetService

    init(service: NetService) {
        self.service = service
    }
}
