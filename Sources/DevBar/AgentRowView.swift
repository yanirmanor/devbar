import SwiftUI

struct AgentRowView: View {
    let agent: AIAgent
    let onReveal: () -> Void
    let onKillAgent: () -> Void
    let onKillServer: (DevServer) -> Void
    let onOpenServer: (DevServer) -> Void

    @State private var isHovered = false
    @State private var revealHovered = false
    @State private var killHovered = false

    private let bg = Color(red: 0.16, green: 0.17, blue: 0.20)
    private let bgHover = Color(red: 0.19, green: 0.20, blue: 0.24)
    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)
    private let dimColor = Color(red: 0.42, green: 0.45, blue: 0.50)

    private func cpuColor(_ percent: Double) -> Color {
        if percent >= 50 { return Color(red: 1.0, green: 0.35, blue: 0.35) }
        if percent >= 25 { return Color(red: 1.0, green: 0.78, blue: 0.30) }
        return Color(red: 0.30, green: 0.85, blue: 0.45)
    }

    private var agentTooltip: String {
        var parts: [String] = []
        parts.append(agent.agentType.displayName)
        if !agent.directory.isEmpty {
            parts.append(agent.directory)
        }
        parts.append("PID \(agent.id)")
        if let branch = agent.gitBranch {
            parts.append("⎇ \(branch)")
        }
        parts.append("Up \(agent.uptime)")
        if agent.memoryMB > 0 {
            parts.append("Memory: \(agent.memoryMB) MB")
        }
        if agent.cpuPercent > 0 {
            parts.append(String(format: "CPU: %.1f%%", agent.cpuPercent))
        }
        if let sid = agent.sessionId {
            parts.append("Session: \(sid)")
        }
        if agent.hasServers {
            parts.append("\(agent.childServers.count) server\(agent.childServers.count == 1 ? "" : "s")")
        }
        return parts.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main agent row
            VStack(alignment: .leading, spacing: 0) {
                // Top section: icon + name + actions
                HStack(spacing: 10) {
                    // Agent icon with status dot
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(agent.agentColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: agent.agentIcon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(agent.agentColor)
                            )

                        Circle()
                            .fill(agent.agentColor)
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.13, green: 0.14, blue: 0.16), lineWidth: 1.5)
                            )
                            .offset(x: 2, y: 2)
                    }

                    // Name + path
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(agent.displayName)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(textPrimary)
                                .lineLimit(1)

                            if let sid = agent.shortSessionId {
                                Text(sid)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(dimColor)
                            }
                        }

                        if let path = agent.shortenedPath {
                            Text(path)
                                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                                .foregroundColor(dimColor)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .richTooltip(agentTooltip)

                    Spacer(minLength: 4)

                    // Reveal button
                    Button(action: onReveal) {
                        Text("Reveal")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                agent.agentColor,
                                                agent.agentColor.opacity(0.85)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(
                                        color: agent.agentColor.opacity(revealHovered ? 0.35 : 0.0),
                                        radius: 6, y: 2
                                    )
                            )
                            .scaleEffect(revealHovered ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { h in withAnimation(.easeOut(duration: 0.15)) { revealHovered = h } }
                    .help("Reveal in Finder")

                    // Stop button
                    Button(action: onKillAgent) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(killHovered ? .red : textSecondary)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(killHovered ? Color.red.opacity(0.15) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { h in withAnimation(.easeOut(duration: 0.12)) { killHovered = h } }
                    .help("Stop agent and its servers")
                }
                .padding(.top, 8)
                .padding(.horizontal, 10)

                // Bottom stats bar: type badge + branch + stats — separate row, full width
                HStack(spacing: 5) {
                    Text(agent.agentType.displayName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(agent.agentColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .stroke(agent.agentColor.opacity(0.3), lineWidth: 0.75)
                                .background(Capsule().fill(agent.agentColor.opacity(0.06)))
                        )
                        .fixedSize()

                    if let branch = agent.gitBranch {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 7, weight: .semibold))
                            Text(branch)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .foregroundColor(Color(red: 0.65, green: 0.55, blue: 1.0))
                    }

                    Spacer(minLength: 0)

                    // Right-aligned stats
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 7))
                            Text(agent.uptime)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(dimColor)

                        if agent.showsResourceStats && agent.memoryMB > 0 {
                            Text("\(agent.memoryMB) MB")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(dimColor)
                        }

                        if agent.showsResourceStats && agent.cpuPercent > 0 {
                            Text(String(format: "%.0f%%", agent.cpuPercent))
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(cpuColor(agent.cpuPercent))
                        }

                        if agent.hasServers {
                            HStack(spacing: 2) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 7))
                                Text("\(agent.childServers.count)")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(agent.agentColor.opacity(0.7))
                        }
                    }
                    .fixedSize()
                }
                .padding(.top, 5)
                .padding(.bottom, 8)
                .padding(.horizontal, 10)
            }

            // Child server sub-rows
            if agent.hasServers {
                ForEach(agent.childServers) { server in
                    ChildServerRow(
                        server: server,
                        agentColor: agent.agentColor,
                        onOpen: { onOpenServer(server) },
                        onKill: { onKillServer(server) }
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? bgHover : bg)
        )
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { h in isHovered = h }
    }
}

// MARK: - Child Server Sub-Row

private struct ChildServerRow: View {
    let server: DevServer
    let agentColor: Color
    let onOpen: () -> Void
    let onKill: () -> Void

    @State private var openHovered = false
    @State private var killHovered = false

    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)

    var body: some View {
        HStack(spacing: 8) {
            // Connector line
            RoundedRectangle(cornerRadius: 1)
                .fill(agentColor.opacity(0.3))
                .frame(width: 2, height: 24)
                .padding(.leading, 28)

            // Port badge
            Text(":\(server.port)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(agentColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(agentColor.opacity(0.1))
                )

            // Process name / framework
            Text(server.framework)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textSecondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Open button
            Button(action: onOpen) {
                Text("Open")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(openHovered ? textPrimary : textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(openHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { openHovered = h } }
            .help("Open http://localhost:\(server.port)")

            // Kill button
            Button(action: onKill) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(killHovered ? .red : textSecondary)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(killHovered ? Color.red.opacity(0.15) : Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { killHovered = h } }
            .help("Stop server")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
