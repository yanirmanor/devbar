import Foundation
import SwiftUI

enum AIAgentType: String, CaseIterable {
    case claudeCode
    case cursor
    case aider
    case codex
    case windsurf

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .cursor:     return "Cursor"
        case .aider:      return "Aider"
        case .codex:      return "Codex CLI"
        case .windsurf:   return "Windsurf"
        }
    }

    var icon: String {
        switch self {
        case .claudeCode: return "brain.head.profile"
        case .cursor:     return "cursorarrow.rays"
        case .aider:      return "person.and.background.dotted"
        case .codex:      return "terminal"
        case .windsurf:   return "wind"
        }
    }

    var color: Color {
        switch self {
        case .claudeCode: return Color(red: 0.85, green: 0.55, blue: 0.30)
        case .cursor:     return Color(red: 0.30, green: 0.54, blue: 1.0)
        case .aider:      return Color(red: 0.18, green: 0.82, blue: 0.50)
        case .codex:      return Color(red: 0.55, green: 0.36, blue: 1.0)
        case .windsurf:   return Color(red: 0.0, green: 0.75, blue: 0.88)
        }
    }
}

struct AIAgent: Identifiable, Equatable {
    let id: Int32  // PID
    let agentType: AIAgentType
    let processName: String
    let directory: String
    let startTime: Date
    var gitBranch: String?
    var childServers: [DevServer] = []

    var hasServers: Bool { !childServers.isEmpty }

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
        return agentType.displayName
    }

    var agentIcon: String { agentType.icon }
    var agentColor: Color { agentType.color }
}
