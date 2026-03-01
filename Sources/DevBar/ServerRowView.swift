import SwiftUI
import AppKit

private struct TooltipOverlay: NSViewRepresentable {
    let tooltip: String

    func makeNSView(context: Context) -> NSView {
        let view = TooltipHostView()
        view.toolTip = tooltip
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = tooltip
    }
}

private class TooltipHostView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

extension View {
    func richTooltip(_ text: String) -> some View {
        overlay(TooltipOverlay(tooltip: text).allowsHitTesting(false))
    }
}

struct ServerRowView: View {
    let server: DevServer
    let onOpen: () -> Void
    let onKill: () -> Void

    @State private var isHovered = false
    @State private var openHovered = false
    @State private var killHovered = false

    private let bg = Color(red: 0.16, green: 0.17, blue: 0.20)
    private let bgHover = Color(red: 0.19, green: 0.20, blue: 0.24)
    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)
    private let greenDot = Color(red: 0.18, green: 0.82, blue: 0.50)

    private var serverTooltip: String {
        var parts: [String] = []
        parts.append(server.displayName)
        if !server.directory.isEmpty {
            parts.append(server.directory)
        }
        parts.append("Port \(server.port)  ·  PID \(server.id)  ·  \(server.framework)")
        if let branch = server.gitBranch {
            parts.append("⎇ \(branch)")
        }
        parts.append("Up \(server.uptime)")
        return parts.joined(separator: "\n")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Framework icon with status dot
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(server.frameworkColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: server.frameworkIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(server.frameworkColor)
                    )

                // Green dot
                Circle()
                    .fill(greenDot)
                    .frame(width: 9, height: 9)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.13, green: 0.14, blue: 0.16), lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(server.displayName)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .richTooltip(serverTooltip)

                HStack(spacing: 6) {
                    // Port badge
                    Text("\(server.port)")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(greenDot)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .stroke(greenDot.opacity(0.4), lineWidth: 1)
                                .background(Capsule().fill(greenDot.opacity(0.08)))
                        )

                    if let branch = server.gitBranch {
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

            // Actions
            HStack(spacing: 6) {
                Button(action: onOpen) {
                    Text("Open")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.30, green: 0.54, blue: 1.0),
                                            Color(red: 0.24, green: 0.46, blue: 0.94)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(
                                    color: Color(red: 0.28, green: 0.50, blue: 1.0).opacity(openHovered ? 0.35 : 0.0),
                                    radius: 8, y: 2
                                )
                        )
                        .scaleEffect(openHovered ? 1.03 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeOut(duration: 0.15)) { openHovered = h } }
                .help("Open in browser")

                Button(action: onKill) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(killHovered ? .white : textSecondary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(killHovered
                                    ? Color(red: 0.85, green: 0.22, blue: 0.22)
                                    : Color.white.opacity(0.06))
                        )
                        .scaleEffect(killHovered ? 1.08 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeOut(duration: 0.15)) { killHovered = h } }
                .help("Stop server")
            }
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
