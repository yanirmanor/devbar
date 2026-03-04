import SwiftUI

struct DockerRowView: View {
    let container: DockerContainer
    let onOpen: () -> Void
    let onStop: () -> Void
    let onOpenServer: (DevServer) -> Void
    let onKillServer: (DevServer) -> Void
    let onOpenPort: (UInt16) -> Void

    @State private var isHovered = false
    @State private var openHovered = false
    @State private var stopHovered = false

    private let bg = Color(red: 0.16, green: 0.17, blue: 0.20)
    private let bgHover = Color(red: 0.19, green: 0.20, blue: 0.24)
    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)
    private let dimColor = Color(red: 0.42, green: 0.45, blue: 0.50)
    private let dockerBlue = DockerContainer.dockerBlue

    private var containerTooltip: String {
        var parts: [String] = []
        parts.append(container.displayName)
        parts.append("Image: \(container.image)")
        parts.append("ID: \(String(container.id.prefix(12)))")
        if !container.ports.isEmpty {
            let portStrs = container.ports.map { "\($0.hostPort)->\($0.containerPort)/\($0.protocol)" }
            parts.append("Ports: \(portStrs.joined(separator: ", "))")
        }
        parts.append("State: \(container.state)")
        parts.append("Up \(container.uptime)")
        return parts.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main container row
            VStack(alignment: .leading, spacing: 0) {
                // Top section: icon + name + actions
                HStack(spacing: 10) {
                    // Docker icon with status dot
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(dockerBlue.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: DockerContainer.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(dockerBlue)
                            )

                        Circle()
                            .fill(container.statusColor)
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.13, green: 0.14, blue: 0.16), lineWidth: 1.5)
                            )
                            .offset(x: 2, y: 2)
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(container.displayName)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(textPrimary)
                            .lineLimit(1)

                        Text(String(container.id.prefix(12)))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(dimColor)
                            .lineLimit(1)
                    }
                    .richTooltip(containerTooltip)

                    Spacer(minLength: 4)

                    // Open button (only if container has port mappings)
                    if container.hasWebPorts {
                        Button(action: onOpen) {
                            Text("Open")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    dockerBlue,
                                                    dockerBlue.opacity(0.85)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(
                                            color: dockerBlue.opacity(openHovered ? 0.35 : 0.0),
                                            radius: 6, y: 2
                                        )
                                )
                                .scaleEffect(openHovered ? 1.03 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { openHovered = h } }
                        .help("Open http://localhost:\(container.ports.first?.hostPort ?? 0)")
                    }

                    // Stop button
                    Button(action: onStop) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(stopHovered ? .red : textSecondary)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(stopHovered ? Color.red.opacity(0.15) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { h in withAnimation(.easeOut(duration: 0.12)) { stopHovered = h } }
                    .help("Stop container")
                }
                .padding(.top, 8)
                .padding(.horizontal, 10)

                // Bottom stats bar: image badge + port badges + uptime
                HStack(spacing: 5) {
                    // Image badge
                    Text(container.shortenedImage)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(dockerBlue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .stroke(dockerBlue.opacity(0.3), lineWidth: 0.75)
                                .background(Capsule().fill(dockerBlue.opacity(0.06)))
                        )
                        .fixedSize()

                    // Port badges
                    ForEach(container.ports, id: \.hostPort) { port in
                        Button(action: { onOpenPort(port.hostPort) }) {
                            Text(":\(port.hostPort)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.18, green: 0.82, blue: 0.50))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.18, green: 0.82, blue: 0.50).opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Open http://localhost:\(port.hostPort)")
                    }

                    Spacer(minLength: 0)

                    // Uptime
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 7))
                        Text(container.uptime)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(dimColor)
                    .fixedSize()
                }
                .padding(.top, 5)
                .padding(.bottom, 8)
                .padding(.horizontal, 10)
            }

            // Child server sub-rows
            if container.hasServers {
                ForEach(container.childServers) { server in
                    DockerChildServerRow(
                        server: server,
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

// MARK: - Docker Child Server Sub-Row

private struct DockerChildServerRow: View {
    let server: DevServer
    let onOpen: () -> Void
    let onKill: () -> Void

    @State private var openHovered = false
    @State private var killHovered = false

    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)
    private let dockerBlue = DockerContainer.dockerBlue

    var body: some View {
        HStack(spacing: 8) {
            // Connector line
            RoundedRectangle(cornerRadius: 1)
                .fill(dockerBlue.opacity(0.3))
                .frame(width: 2, height: 24)
                .padding(.leading, 28)

            // Port badge
            Text(":\(server.port)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(dockerBlue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(dockerBlue.opacity(0.1))
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
