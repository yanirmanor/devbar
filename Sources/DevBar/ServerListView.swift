import SwiftUI
import Combine
import AppKit

final class ServerViewModel: ObservableObject {
    @Published var servers: [DevServer] = []
    @Published var agents: [AIAgent] = []
    private let scanner = ServerScanner()
    private let agentScanner = AgentScanner()
    private var timer: Timer?

    var totalCount: Int { servers.count + agents.count }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let serverResults = self.scanner.scan()
            let agentResults = self.agentScanner.scan()
            DispatchQueue.main.async {
                self.servers = serverResults
                self.agents = agentResults
            }
        }
    }

    func open(_ server: DevServer) {
        scanner.openInBrowser(port: server.port)
    }

    func kill(_ server: DevServer) {
        scanner.kill(pid: server.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refresh()
        }
    }

    func revealInFinder(_ agent: AIAgent) {
        guard !agent.directory.isEmpty else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: agent.directory)
    }
}

struct ServerListView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var refreshHovered = false
    @State private var quitHovered = false

    private let panelBG = Color(red: 0.13, green: 0.14, blue: 0.16)
    private let textPrimary = Color(red: 0.92, green: 0.93, blue: 0.95)
    private let textSecondary = Color(red: 0.55, green: 0.58, blue: 0.64)
    private let textTertiary = Color(red: 0.40, green: 0.42, blue: 0.48)
    private let dividerColor = Color.white.opacity(0.06)
    private let greenDot = Color(red: 0.18, green: 0.82, blue: 0.50)

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.30, green: 0.54, blue: 1.0),
                                        Color(red: 0.22, green: 0.40, blue: 0.90)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 30, height: 30)
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("DevBar")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(textPrimary)
                        Text("Local Environment")
                            .font(.system(size: 10.5))
                            .foregroundColor(textTertiary)
                    }
                }

                Spacer()

                // Count badge
                if viewModel.totalCount > 0 {
                    Text("\(viewModel.totalCount)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(textSecondary)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle().fill(Color.white.opacity(0.07))
                        )
                }

                // Refresh
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(refreshHovered ? textPrimary : textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(refreshHovered ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeOut(duration: 0.12)) { refreshHovered = h } }
                .help("Refresh")
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Divider
            Rectangle().fill(dividerColor).frame(height: 1)
                .padding(.horizontal, 12)

            // ── Content ──
            if viewModel.servers.isEmpty && viewModel.agents.isEmpty {
                emptyState
            } else {
                mainContent
            }

            // Divider
            Rectangle().fill(dividerColor).frame(height: 1)
                .padding(.horizontal, 12)

            // ── Footer ──
            // Quit
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                        .font(.system(size: 9, weight: .semibold))
                    Text("Quit DevBar")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(quitHovered ? textSecondary : textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { quitHovered = h } }
            .padding(.bottom, 4)
        }
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
        .background(panelBG)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 56, height: 56)
                Image(systemName: "server.rack")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textTertiary)
            }
            VStack(spacing: 4) {
                Text("No dev servers or AI agents running")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textSecondary)
                Text("Scanning ports 3000 – 9000 and processes")
                    .font(.system(size: 11))
                    .foregroundColor(textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 4) {
                if !viewModel.servers.isEmpty {
                    sectionHeader("DEV SERVERS", count: viewModel.servers.count)
                    ForEach(viewModel.servers) { server in
                        ServerRowView(
                            server: server,
                            onOpen: { viewModel.open(server) },
                            onKill: { viewModel.kill(server) }
                        )
                    }
                }

                if !viewModel.servers.isEmpty && !viewModel.agents.isEmpty {
                    Rectangle().fill(dividerColor).frame(height: 1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                }

                if !viewModel.agents.isEmpty {
                    sectionHeader("AI AGENTS", count: viewModel.agents.count)
                    ForEach(viewModel.agents) { agent in
                        AgentRowView(
                            agent: agent,
                            onReveal: { viewModel.revealInFinder(agent) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxHeight: 600)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(textTertiary)
                .tracking(0.8)
            Spacer()
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }
}
