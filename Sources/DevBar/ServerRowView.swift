import SwiftUI

struct ServerRowView: View {
    let server: DevServer
    let onOpen: () -> Void
    let onKill: () -> Void

    @State private var isHovered = false
    @State private var openHovered = false
    @State private var killHovered = false
    @Environment(\.colorScheme) private var colorScheme

    private var cardBG: Color {
        if isHovered {
            return colorScheme == .dark
                ? Color.white.opacity(0.055)
                : Color.black.opacity(0.035)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.03)
            : Color.black.opacity(0.018)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Status dot
            ZStack {
                Circle()
                    .fill(Color(red: 0.2, green: 0.84, blue: 0.46))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color(red: 0.2, green: 0.84, blue: 0.46).opacity(0.35))
                    .frame(width: 14, height: 14)
            }
            .frame(width: 14)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(server.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.14))
                        .lineLimit(1)

                    Text(server.framework)
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(0.3)
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(server.frameworkColor.opacity(0.85))
                        )
                }

                HStack(spacing: 5) {
                    Text(":\(server.port)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(colorScheme == .dark
                            ? Color.white.opacity(0.4)
                            : Color.black.opacity(0.38))

                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12))
                        .frame(width: 2.5, height: 2.5)

                    Text(server.uptime)
                        .font(.system(size: 10.5))
                        .foregroundColor(colorScheme == .dark
                            ? Color.white.opacity(0.3)
                            : Color.black.opacity(0.3))
                }
            }

            Spacer(minLength: 4)

            // Actions
            HStack(spacing: 5) {
                Button(action: onOpen) {
                    Text("Open")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.28, green: 0.52, blue: 1.0),
                                            Color(red: 0.22, green: 0.44, blue: 0.95)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color(red: 0.25, green: 0.48, blue: 1.0).opacity(openHovered ? 0.4 : 0.2), radius: openHovered ? 6 : 3, y: 1)
                        )
                        .scaleEffect(openHovered ? 1.04 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeOut(duration: 0.15)) { openHovered = h } }
                .help("Open in browser")

                Button(action: onKill) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(killHovered
                            ? .white
                            : (colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.35)))
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(killHovered
                                    ? Color(red: 0.9, green: 0.25, blue: 0.25)
                                    : (colorScheme == .dark
                                        ? Color.white.opacity(0.06)
                                        : Color.black.opacity(0.04)))
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
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBG)
        )
        .padding(.horizontal, 8)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}
