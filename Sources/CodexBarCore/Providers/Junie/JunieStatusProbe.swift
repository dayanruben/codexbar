import Foundation

public enum JunieStatusProbeError: LocalizedError, Sendable {
    case cliNotFound
    case cliFailed(String)
    case notLoggedIn(String?)
    case parseError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            "Junie CLI not found. Install it (e.g. via Homebrew or ensure 'junie' is on PATH)."
        case let .cliFailed(msg):
            msg
        case let .notLoggedIn(msg):
            msg ?? "Not logged in to Junie. Run 'junie login' first."
        case let .parseError(msg):
            "Failed to parse Junie output: \(msg)"
        case .timeout:
            "Junie CLI timed out."
        }
    }
}

public struct JunieStatusProbe: Sendable {
    public init() {}

    private static let logger = CodexBarLog.logger("junie")

    public static func detectVersion() -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = ["junie", "--version"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let out = String(data: data, encoding: .utf8) else { return nil }
            let trimmed = out.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            self.logger.debug("junie version detection failed: \(error.localizedDescription)")
            return nil
        }
    }

    public func fetch(timeout: TimeInterval = 12.0) async throws -> UsageSnapshot {
        // Strategy: try sending "/usage" to junie inside a PTY. If that fails, surface errors cleanly.
        guard let binary = TTYCommandRunner.which("junie") ?? TTYCommandRunner.which("junie-cli") else {
            throw JunieStatusProbeError.cliNotFound
        }

        let runner = TTYCommandRunner()
        let options = TTYCommandRunner.Options(
            rows: 40,
            cols: 160,
            timeout: timeout,
            idleTimeout: 3.0,
            workingDirectory: nil,
            extraArgs: [],
            initialDelay: 0.2,
            sendEnterEvery: nil,
            sendOnSubstrings: [:],
            stopOnURL: false,
            stopOnSubstrings: [],
            settleAfterStop: 0.25)

        do {
            let result = try runner.run(binary: binary, send: "/usage", options: options)
            return try self.parseUsage(text: result.text)
        } catch TTYCommandRunner.Error.binaryNotFound {
            throw JunieStatusProbeError.cliNotFound
        } catch TTYCommandRunner.Error.timedOut {
            throw JunieStatusProbeError.timeout
        } catch {
            // Surface a helpful, actionable error
            throw JunieStatusProbeError.cliFailed(error.localizedDescription)
        }
    }

    // Best-effort parse: accept either Codex/Claude-like lines or a generic percentage pattern.
    func parseUsage(text: String) throws -> UsageSnapshot {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            throw JunieStatusProbeError.parseError("Empty output from Junie CLI.")
        }

        // Detect common login errors early
        let lowered = cleaned.lowercased()
        if lowered.contains("not logged in") || lowered.contains("please login") || lowered.contains("junie login") {
            throw JunieStatusProbeError.notLoggedIn("Not logged in to Junie. Run 'junie login' and retry.")
        }

        // Try to parse a percent remaining like "Session: 72% left" or just "72% left"
        let percentRegex = try! NSRegularExpression(
            pattern: #"(\d{1,3})%\s*(left|remaining)"#,
            options: [.caseInsensitive])
        var primary: RateWindow?
        if let match = percentRegex.firstMatch(
            in: cleaned,
            options: [],
            range: NSRange(cleaned.startIndex..., in: cleaned))
        {
            if let range = Range(match.range(at: 1), in: cleaned) {
                let val = Double(cleaned[range]) ?? 0
                let used = max(0, min(100, 100 - val))
                primary = RateWindow(usedPercent: used, windowMinutes: nil, resetsAt: nil, resetDescription: nil)
            }
        }

        let identity = ProviderIdentitySnapshot(
            providerID: .junie,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: nil)

        return UsageSnapshot(
            primary: primary,
            secondary: nil,
            tertiary: nil,
            providerCost: nil,
            zaiUsage: nil,
            cursorRequests: nil,
            updatedAt: Date(),
            identity: identity)
    }
}
