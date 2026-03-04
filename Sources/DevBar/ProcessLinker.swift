import Foundation

struct LinkResult {
    var linkedAgents: [AIAgent]
    var orphanServers: [DevServer]
}

struct DockerLinkResult {
    var linkedContainers: [DockerContainer]
    var remainingServers: [DevServer]
}

final class ProcessLinker {
    func link(agents: [AIAgent], servers: [DevServer]) -> LinkResult {
        let agentPIDs = Set(agents.map { $0.id })
        var agentMap = Dictionary(uniqueKeysWithValues: agents.map { ($0.id, $0) })
        var orphanServers: [DevServer] = []

        for var server in servers {
            if let parentPID = findAncestorAgent(pid: server.id, agentPIDs: agentPIDs) {
                // Linked via PPID chain
                server.parentAgentPID = parentPID
                agentMap[parentPID]?.childServers.append(server)
            } else if isReparented(pid: server.id),
                      let parentPID = findAgentByDirectory(server: server, agents: agents) {
                // Fallback: match by working directory only for reparented processes (parent is launchd/PID 1)
                server.parentAgentPID = parentPID
                agentMap[parentPID]?.childServers.append(server)
            } else {
                orphanServers.append(server)
            }
        }

        let linkedAgents = agents.map { agentMap[$0.id]! }
        return LinkResult(linkedAgents: linkedAgents, orphanServers: orphanServers)
    }

    private func findAncestorAgent(pid: Int32, agentPIDs: Set<Int32>) -> Int32? {
        var current = pid
        var visited = Set<Int32>()
        // Walk up to 20 levels to avoid infinite loops
        for _ in 0..<20 {
            guard !visited.contains(current) else { return nil }
            visited.insert(current)

            let ppid = getParentPID(of: current)
            guard ppid > 1 else { return nil }

            if agentPIDs.contains(ppid) {
                return ppid
            }
            current = ppid
        }
        return nil
    }

    /// Check if a process has been reparented to launchd (PID 1), indicating its original parent exited.
    private func isReparented(pid: Int32) -> Bool {
        let ppid = getParentPID(of: pid)
        return ppid == 1
    }

    /// Fallback: if a server's working directory is the same as or a subdirectory of an agent's directory, link them.
    private func findAgentByDirectory(server: DevServer, agents: [AIAgent]) -> Int32? {
        let serverDir = server.directory
        guard !serverDir.isEmpty else { return nil }
        for agent in agents {
            guard !agent.directory.isEmpty else { continue }
            if serverDir == agent.directory || serverDir.hasPrefix(agent.directory + "/") {
                return agent.id
            }
        }
        return nil
    }

    /// Link Docker containers to dev servers by matching host port mappings.
    /// Returns updated containers with nested servers, and remaining unmatched servers.
    func linkDocker(containers: [DockerContainer], servers: [DevServer]) -> DockerLinkResult {
        guard !containers.isEmpty else {
            return DockerLinkResult(linkedContainers: containers, remainingServers: servers)
        }

        // Build a map of host port → container index
        var portToContainer: [UInt16: Int] = [:]
        var containerMap = containers
        for (idx, container) in containerMap.enumerated() {
            for portMapping in container.ports {
                portToContainer[portMapping.hostPort] = idx
            }
        }

        var remainingServers: [DevServer] = []
        for server in servers {
            if let idx = portToContainer[server.port] {
                containerMap[idx].childServers.append(server)
            } else {
                remainingServers.append(server)
            }
        }

        return DockerLinkResult(linkedContainers: containerMap, remainingServers: remainingServers)
    }

    private func getParentPID(of pid: Int32) -> Int32 {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["ps", "-o", "ppid=", "-p", "\(pid)"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return 0
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return Int32(output) ?? 0
    }
}
