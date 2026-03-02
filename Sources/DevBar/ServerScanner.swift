import Foundation

final class ServerScanner {
    func scan() -> [DevServer] {
        let output = shell("lsof", "-iTCP", "-sTCP:LISTEN", "-n", "-P")
        var seen = Set<Int32>()
        var servers: [DevServer] = []

        for line in output.split(separator: "\n").dropFirst() {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true)
            guard cols.count >= 9 else { continue }

            guard let pid = Int32(cols[1]) else { continue }

            let nameField = String(cols[8])
            guard let colonIdx = nameField.lastIndex(of: ":") else { continue }
            let portStr = nameField[nameField.index(after: colonIdx)...]
            guard let port = UInt16(portStr), (1024...65535).contains(port) else { continue }

            guard !seen.contains(pid) else { continue }
            seen.insert(pid)

            let processName = String(cols[0])
            let directory = resolveDirectory(pid: pid)
            let startTime = resolveStartTime(pid: pid)
            let framework = detectFramework(processName: processName, directory: directory)
            let branch = resolveGitBranch(directory: directory)

            servers.append(DevServer(
                id: pid,
                port: port,
                processName: processName,
                directory: directory,
                startTime: startTime,
                detectedFramework: framework,
                gitBranch: branch
            ))
        }

        return servers.sorted { $0.port < $1.port }
    }

    func kill(pid: Int32) {
        Foundation.kill(pid, SIGTERM)
    }

    func openInBrowser(port: UInt16) {
        let url = "http://localhost:\(port)"
        shell("/usr/bin/open", url)
    }

    // MARK: - Private

    private func detectFramework(processName: String, directory: String) -> String? {
        let isNode = processName.lowercased().contains("node")
        guard isNode, !directory.isEmpty else { return nil }

        let packageJsonPath = (directory as NSString).appendingPathComponent("package.json")
        guard FileManager.default.fileExists(atPath: packageJsonPath),
              let contents = try? String(contentsOfFile: packageJsonPath, encoding: .utf8).lowercased()
        else { return nil }

        if contents.contains("\"next\"") || contents.contains("\"next/") {
            return "Next.js"
        } else if contents.contains("\"@remix-run/") || contents.contains("\"remix\"") {
            return "Remix"
        } else if contents.contains("\"vite\"") || contents.contains("\"@vitejs/") {
            return "Vite"
        } else if contents.contains("\"nuxt\"") || contents.contains("\"@nuxt/") {
            return "Nuxt"
        } else if contents.contains("\"astro\"") {
            return "Astro"
        } else if contents.contains("\"svelte\"") || contents.contains("\"@sveltejs/") {
            return "SvelteKit"
        }

        return nil
    }

    private func resolveGitBranch(directory: String) -> String? {
        guard !directory.isEmpty else { return nil }
        let headPath = (directory as NSString).appendingPathComponent(".git/HEAD")
        guard let contents = try? String(contentsOfFile: headPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        else { return nil }
        let prefix = "ref: refs/heads/"
        if contents.hasPrefix(prefix) {
            return String(contents.dropFirst(prefix.count))
        }
        // Detached HEAD — return short hash
        return String(contents.prefix(7))
    }

    private func resolveDirectory(pid: Int32) -> String {
        let output = shell("lsof", "-a", "-p", "\(pid)", "-d", "cwd", "-F", "n")
        for line in output.split(separator: "\n") {
            if line.hasPrefix("n") && line.count > 1 {
                return String(line.dropFirst())
            }
        }
        return ""
    }

    private func resolveStartTime(pid: Int32) -> Date {
        let output = shell("ps", "-p", "\(pid)", "-o", "lstart=").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return Date() }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        if let date = formatter.date(from: output) {
            return date
        }
        formatter.dateFormat = "EEE MMM  d HH:mm:ss yyyy"
        return formatter.date(from: output) ?? Date()
    }

    @discardableResult
    private func shell(_ args: String...) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
