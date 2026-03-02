import Foundation

final class AgentScanner {
    func scan() -> [AIAgent] {
        // Use lightweight ps format: "pid command" — avoids pipe deadlock from large ps aux output
        let output = shell("ps", "-eo", "pid=,command=")
        var seen = Set<Int32>()
        var agents: [AIAgent] = []

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let spaceIdx = trimmed.firstIndex(of: " ") else { continue }

            guard let pid = Int32(trimmed[..<spaceIdx]) else { continue }
            let command = String(trimmed[trimmed.index(after: spaceIdx)...])

            guard let agentType = detectAgentType(command: command) else { continue }
            guard !seen.contains(pid) else { continue }
            seen.insert(pid)

            var directory = resolveDirectory(pid: pid)

            // Cursor's main process cwd is "/" — resolve from storage.json instead
            if agentType == .cursor && (directory == "/" || directory.isEmpty) {
                directory = resolveCursorActiveProject() ?? ""
            }

            let startTime = resolveStartTime(pid: pid)
            let branch = resolveGitBranch(directory: directory)

            let processName = command.split(separator: " ").first.map(String.init) ?? command
            let memory = resolveMemory(pid: pid)
            let cpu = resolveCPU(pid: pid)

            var sessionId: String?
            if agentType == .claudeCode {
                sessionId = resolveClaudeSessionId(directory: directory)
            }

            agents.append(AIAgent(
                id: pid,
                agentType: agentType,
                processName: processName,
                directory: directory,
                startTime: startTime,
                gitBranch: branch,
                memoryMB: memory,
                cpuPercent: cpu,
                sessionId: sessionId
            ))
        }

        return agents.sorted { $0.agentType.displayName < $1.agentType.displayName }
    }

    // MARK: - Detection

    private func detectAgentType(command: String) -> AIAgentType? {
        // Claude Code: command contains /claude or starts with "claude" (not helper subprocesses)
        if command.contains("/claude") || command.hasPrefix("claude") {
            // Filter out helper/child processes
            if command.contains("--type=") { return nil }
            return .claudeCode
        }

        // Cursor: main app process only (filter out Electron helpers)
        if command.contains("Cursor.app/Contents/MacOS/Cursor") {
            if command.contains("--type=") { return nil }
            return .cursor
        }

        // Aider: command ends with /aider or contains " aider " as standalone word
        if command.hasSuffix("/aider") || command.hasPrefix("aider ") || command.hasPrefix("aider\n") || command == "aider" {
            return .aider
        }
        if command.range(of: "\\baider\\b", options: .regularExpression) != nil &&
           command.contains("python") || command.contains("/aider") {
            return .aider
        }

        // Codex CLI: command contains /codex or starts with "codex"
        if command.contains("/codex") || command.hasPrefix("codex") {
            if command.contains("--type=") { return nil }
            return .codex
        }

        // Windsurf: main app process only
        if command.contains("Windsurf.app/Contents/MacOS/Windsurf") {
            if command.contains("--type=") { return nil }
            return .windsurf
        }

        return nil
    }

    // MARK: - Helpers (mirrored from ServerScanner for independence)

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

    private func resolveMemory(pid: Int32) -> Int {
        let output = shell("ps", "-p", "\(pid)", "-o", "rss=").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let kb = Int(output) else { return 0 }
        return kb / 1024
    }

    private func resolveCPU(pid: Int32) -> Double {
        let output = shell("ps", "-p", "\(pid)", "-o", "%cpu=").trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(output) ?? 0.0
    }

    /// Resolve Cursor's active project from its storage.json (since the main process cwd is "/")
    private func resolveCursorActiveProject() -> String? {
        let home = NSHomeDirectory()
        let storagePath = (home as NSString).appendingPathComponent(
            "Library/Application Support/Cursor/User/globalStorage/storage.json"
        )
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: storagePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let windowsState = json["windowsState"] as? [String: Any]
        else { return nil }

        // Try last active window first, then first opened window
        if let last = windowsState["lastActiveWindow"] as? [String: Any],
           let folder = last["folder"] as? String {
            return cursorFolderURI(folder)
        }
        if let opened = windowsState["openedWindows"] as? [[String: Any]],
           let first = opened.first,
           let folder = first["folder"] as? String {
            return cursorFolderURI(folder)
        }
        return nil
    }

    private func cursorFolderURI(_ uri: String) -> String? {
        // Convert "file:///Users/foo/bar" → "/Users/foo/bar"
        guard uri.hasPrefix("file://") else { return uri }
        return URL(string: uri)?.path
    }

    /// Resolve Claude Code session ID from the most recently modified session file
    private func resolveClaudeSessionId(directory: String) -> String? {
        guard !directory.isEmpty else { return nil }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        // Claude stores sessions in ~/.claude/projects/{encoded-path}/
        let encoded = directory.replacingOccurrences(of: "/", with: "-")
        let projectsDir = "\(home)/.claude/projects/\(encoded)"
        let fm = FileManager.default

        guard fm.fileExists(atPath: projectsDir),
              let contents = try? fm.contentsOfDirectory(atPath: projectsDir)
        else { return nil }

        var newest: (name: String, date: Date)?
        for file in contents where file.hasSuffix(".jsonl") {
            let fullPath = "\(projectsDir)/\(file)"
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let modified = attrs[.modificationDate] as? Date
            else { continue }
            if newest == nil || modified > newest!.date {
                newest = (file, modified)
            }
        }

        guard let found = newest?.name else { return nil }
        // Strip .jsonl extension to get the session UUID
        return String(found.dropLast(6))
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
        return String(contents.prefix(7))
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
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
