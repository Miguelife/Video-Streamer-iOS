//
//  TextSenderViewModel.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 12/3/25.
//

import SwiftUI

@Observable
class ClientViewModel {
    // MARK: - Properties
    private var explorer = HttpExplorer(serviceType: Constants.serviceType)
    var services = [NetService]()

    // MARK: - Methods
    func exploreNetwork() {
        explorer.start()

        explorer.didFoundService = { [weak self] service in
            guard let self else { return }
            services.append(service)
        }

        explorer.didLostService = { [weak self] service in
            guard let self else { return }
            services.removeAll { netService in
                netService.name == service.name
            }
        }
    }
}
