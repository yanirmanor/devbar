import Foundation
import SwiftUI

struct PortMapping: Equatable {
    let hostPort: UInt16
    let containerPort: UInt16
    let `protocol`: String
}

struct DockerContainer: Identifiable, Equatable {
    let id: String
    let name: String
    let image: String
    let status: String
    let state: String
    let ports: [PortMapping]
    let startedAt: Date
    var childServers: [DevServer] = []

    var hasServers: Bool { !childServers.isEmpty }

    static let dockerBlue = Color(red: 0.09, green: 0.58, blue: 0.96)
    static let icon = "shippingbox"

    var displayName: String {
        let cleaned = name.hasPrefix("/") ? String(name.dropFirst()) : name
        return cleaned.isEmpty ? String(id.prefix(12)) : cleaned
    }

    var uptime: String {
        let interval = Date().timeIntervalSince(startedAt)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var shortenedImage: String {
        // e.g. "myregistry.io/app:latest" → "app:latest"
        let parts = image.split(separator: "/")
        if parts.count > 1 {
            return String(parts.last!)
        }
        return image
    }

    var isRunning: Bool { state.lowercased() == "running" }
    var isPaused: Bool { state.lowercased() == "paused" }

    var hasWebPorts: Bool { !ports.isEmpty }

    var statusColor: Color {
        if isRunning { return Color(red: 0.18, green: 0.82, blue: 0.50) }
        if isPaused { return Color(red: 1.0, green: 0.78, blue: 0.30) }
        return Color(red: 0.55, green: 0.58, blue: 0.64)
    }
}
