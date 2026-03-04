import Foundation

final class DockerScanner {
    func scan() -> [DockerContainer] {
        let output = shell("docker", "ps", "--format", "{{json .}}", "--no-trunc")
        guard !output.isEmpty else { return [] }

        var containers: [DockerContainer] = []
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = DateFormatter()
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        for line in output.split(separator: "\n") {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }

            let id = json["ID"] as? String ?? ""
            let names = json["Names"] as? String ?? ""
            let image = json["Image"] as? String ?? ""
            let status = json["Status"] as? String ?? ""
            let state = json["State"] as? String ?? ""
            let portsStr = json["Ports"] as? String ?? ""
            let createdAt = json["CreatedAt"] as? String ?? ""

            let portMappings = parsePorts(portsStr)

            var startDate = Date()
            if let date = dateFormatter.date(from: createdAt) {
                startDate = date
            } else if let date = fallbackFormatter.date(from: createdAt) {
                startDate = date
            }

            containers.append(DockerContainer(
                id: id,
                name: names,
                image: image,
                status: status,
                state: state,
                ports: portMappings,
                startedAt: startDate
            ))
        }

        return containers.sorted { $0.name < $1.name }
    }

    func stopContainer(id: String) {
        shell("docker", "stop", id)
    }

    func openInBrowser(port: UInt16) {
        shell("/usr/bin/open", "http://localhost:\(port)")
    }

    // MARK: - Private

    /// Parse Docker ports string like "0.0.0.0:3000->3000/tcp, 0.0.0.0:5432->5432/tcp"
    func parsePorts(_ portsString: String) -> [PortMapping] {
        guard !portsString.isEmpty else { return [] }
        var mappings: [PortMapping] = []

        for segment in portsString.split(separator: ",") {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            // Match pattern: <host>:<hostPort>-><containerPort>/<protocol>
            guard let arrowRange = trimmed.range(of: "->") else { continue }

            let left = trimmed[..<arrowRange.lowerBound]
            let right = trimmed[arrowRange.upperBound...]

            // Parse host port (last component after ":")
            guard let colonIdx = left.lastIndex(of: ":") else { continue }
            let hostPortStr = left[left.index(after: colonIdx)...]
            guard let hostPort = UInt16(hostPortStr) else { continue }

            // Parse container port and protocol (e.g. "3000/tcp")
            let rightParts = right.split(separator: "/")
            guard let containerPort = UInt16(rightParts.first ?? "") else { continue }
            let proto = rightParts.count > 1 ? String(rightParts[1]) : "tcp"

            mappings.append(PortMapping(
                hostPort: hostPort,
                containerPort: containerPort,
                protocol: proto
            ))
        }

        return mappings
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
