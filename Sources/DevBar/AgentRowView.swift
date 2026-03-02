import SwiftUI

struct AgentRowView: View {
    let agent: AIAgent
    let onReveal: () -> Void

    @State private var isHovered = false
    @State private var revealHovered = false

    private let bg = Color(red: 0.16, green: 0.17, blue: 0.20)
    private let bgHover = Color(red: 0.19, green: 0.20, blue: 0.24)
    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)

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
        return parts.joined(separator: "\n")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Agent icon with status dot
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(agent.agentColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: agent.agentIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(agent.agentColor)
                    )

                Circle()
                    .fill(agent.agentColor)
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.13, green: 0.14, blue: 0.16), lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.displayName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .richTooltip(agentTooltip)

                HStack(spacing: 6) {
                    // Agent type badge
                    Text(agent.agentType.displayName)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(agent.agentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .stroke(agent.agentColor.opacity(0.4), lineWidth: 1)
                                .background(Capsule().fill(agent.agentColor.opacity(0.08)))
                        )

                    if let branch = agent.gitBranch {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 8.5, weight: .semibold))
                            Text(branch)
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                        }
                        .foregroundColor(Color(red: 0.65, green: 0.55, blue: 1.0))
                    } else {
                        Text("Running")
                            .font(.system(size: 11))
                            .foregroundColor(textSecondary)
                    }
                }
            }

            Spacer(minLength: 4)

            // Reveal button
            Button(action: onReveal) {
                Text("Reveal")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
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
                                radius: 8, y: 2
                            )
                    )
                    .scaleEffect(revealHovered ? 1.03 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { revealHovered = h } }
            .help("Reveal in Finder")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? bgHover : bg)
        )
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { h in isHovered = h }
    }
}
