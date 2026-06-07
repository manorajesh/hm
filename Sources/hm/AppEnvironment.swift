import Foundation

enum AppEnvironment {
    static func load(
        processEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String: String] {
        var environment = loadDotEnvFiles(
            currentDirectory: currentDirectory,
            homeDirectory: homeDirectory
        )

        for (key, value) in processEnvironment {
            environment[key] = value
        }

        return environment
    }

    private static func loadDotEnvFiles(currentDirectory: URL, homeDirectory: URL) -> [String: String] {
        var values: [String: String] = [:]

        for url in [
            homeDirectory.appendingPathComponent(".hm.env"),
            currentDirectory.appendingPathComponent(".env"),
        ] {
            for (key, value) in parseDotEnvFile(at: url) {
                values[key] = value
            }
        }

        return values
    }

    static func parseDotEnv(_ text: String) -> [String: String] {
        var values: [String: String] = [:]

        for rawLine in text.components(separatedBy: .newlines) {
            var line = rawLine.trimmingCharacters(in: .whitespaces)

            guard !line.isEmpty, !line.hasPrefix("#") else {
                continue
            }

            if line.hasPrefix("export ") {
                line = String(line.dropFirst("export ".count))
            }

            guard let equalsIndex = line.firstIndex(of: "=") else {
                continue
            }

            let key = line[..<equalsIndex].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)

            if value.count >= 2 {
                let first = value.first
                let last = value.last

                if (first == "\"" && last == "\"") || (first == "'" && last == "'") {
                    value = String(value.dropFirst().dropLast())
                }
            }

            if !key.isEmpty {
                values[String(key)] = String(value)
            }
        }

        return values
    }

    private static func parseDotEnvFile(at url: URL) -> [String: String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }

        return parseDotEnv(text)
    }
}
