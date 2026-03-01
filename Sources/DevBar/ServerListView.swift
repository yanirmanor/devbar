import SwiftUI
import Combine

final class ServerViewModel: ObservableObject {
    @Published var servers: [DevServer] = []
    private let scanner = ServerScanner()
    private var timer: Timer?

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
            let results = self.scanner.scan()
            DispatchQueue.main.async {
                self.servers = results
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
}

struct ServerListView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var refreshHovered = false
    @State private var quitHovered = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack(alignment: .center) {
                HStack(spacing: 7) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.35, green: 0.55, blue: 1.0),
                                        Color(red: 0.28, green: 0.44, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("DevBar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12))
                }

                Spacer()

                // Server count badge
                if !viewModel.servers.isEmpty {
                    Text("\(viewModel.servers.count)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        )
                }

                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(refreshHovered
                            ? (colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12))
                            : (colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.35)))
                        .frame(width: 26, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(refreshHovered
                                    ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                                    : (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)))
                        )
                        .scaleEffect(refreshHovered ? 1.05 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { h in withAnimation(.easeOut(duration: 0.15)) { refreshHovered = h } }
                .help("Refresh")
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Thin separator
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            // ── Content ──
            if viewModel.servers.isEmpty {
                emptyState
            } else {
                serverList
            }

            // Thin separator
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            // ── Footer ──
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text("Quit DevBar")
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundColor(quitHovered
                    ? (colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
                    : (colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.3)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { quitHovered = h } }
        }
        .frame(width: 330)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                    .frame(width: 56, height: 56)
                Image(systemName: "server.rack")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.18))
            }
            VStack(spacing: 4) {
                Text("No dev servers running")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.45))
                Text("Scanning ports 3000 – 9000")
                    .font(.system(size: 11))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.22))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(.vertical, 8)
    }

    // MARK: - Server List

    private var serverList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(viewModel.servers) { server in
                    ServerRowView(
                        server: server,
                        onOpen: { viewModel.open(server) },
                        onKill: { viewModel.kill(server) }
                    )
                }
            }
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 350)
    }
}
