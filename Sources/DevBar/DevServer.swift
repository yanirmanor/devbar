import Foundation
import SwiftUI

struct DevServer: Identifiable, Equatable {
    let id: Int32  // PID
    let port: UInt16
    let processName: String
    let directory: String
    let startTime: Date
    var detectedFramework: String?

    var uptime: String {
        let interval = Date().timeIntervalSince(startTime)
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

    var displayName: String {
        if !directory.isEmpty {
            return URL(fileURLWithPath: directory).lastPathComponent
        }
        return processName
    }

    var framework: String {
        if let detected = detectedFramework {
            return detected
        }
        switch processName.lowercased() {
        case let name where name.contains("python"):
            return "Python"
        case let name where name.contains("ruby"):
            return "Rails"
        case let name where name.contains("php"):
            return "PHP"
        case let name where name.contains("go"):
            return "Go"
        case let name where name.contains("java"):
            return "Java"
        default:
            return processName
        }
    }

    var frameworkColor: Color {
        switch framework {
        case "Next.js":   return Color(red: 0.20, green: 0.20, blue: 0.22)
        case "Remix":     return Color(red: 0.32, green: 0.45, blue: 1.0)
        case "Vite":      return Color(red: 0.55, green: 0.36, blue: 1.0)
        case "Nuxt":      return Color(red: 0.0, green: 0.75, blue: 0.45)
        case "Astro":     return Color(red: 1.0, green: 0.35, blue: 0.2)
        case "SvelteKit": return Color(red: 1.0, green: 0.24, blue: 0.0)
        case "Python":    return Color(red: 0.26, green: 0.52, blue: 0.96)
        case "Rails":     return Color(red: 0.8, green: 0.0, blue: 0.0)
        case "Go":        return Color(red: 0.0, green: 0.68, blue: 0.84)
        case "PHP":       return Color(red: 0.55, green: 0.55, blue: 0.80)
        case "Java":      return Color(red: 0.90, green: 0.55, blue: 0.25)
        default:          return Color(nsColor: .tertiaryLabelColor)
        }
    }
}
