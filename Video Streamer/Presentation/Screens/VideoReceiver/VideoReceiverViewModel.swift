import SwiftUI
import WebRTC

@Observable
class VideoReceiverViewModel {
    let service: NetService
    let videoManager = WebRtcManager()

    init(service: NetService) {
        self.service = service
    }

    func getStreamConfiguration() {
        videoManager.createOffer { [weak self] session in
            guard let self, let session else { return }
            Task {
                guard let host = self.service.hostName,
                      let url = URL(string: "http://\(host):\(self.service.port)?sdp=\(session.sdp)")
                else {
                    return
                }

                do {
                    _ = try await URLSession.shared.data(from: url)

                    print("SDP SENDED")
                } catch {
                    print("Error sending sdp")
                }
            }
        }
    }
}