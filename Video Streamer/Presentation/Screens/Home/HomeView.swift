//
//  HomeView.swift
//  Video Streamer
//
//  Created by Miguel Ángel Soto González on 11/3/25.
//

import SwiftUI

struct HomeView: View {
    @State var path = NavigationPath()

    // MARK: - BODY
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Button("📩 CLIENT") {
                    path.append("client")
                }

                Button("📦 SERVER") {
                    path.append("server")
                }
            }
            .bold()
            .buttonStyle(.borderedProminent)

            // MARK: - NAVIGATION
            .navigationDestination(for: NetService.self, destination: { service in
                ClientBuilder().build(for: service)
            })
            .navigationDestination(for: String.self) { destination in
                switch destination {
                    case "client":
                        BonjourView()
                    case "server":
                        ServerView()
                    default:
                        fatalError("Unsupported destination: \(destination)")
                }
            }
            .onAppear {
                print("On Appear")
            }
            .task {
                print("Task")
            }
        }
    }
}
