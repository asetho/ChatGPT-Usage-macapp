import Darwin
import Foundation

enum CodexUsageError: LocalizedError {
    case codexNotFound
    case launchFailed(String)
    case timedOut
    case invalidResponse
    case server(String)
    case processExited(Int32, String)

    var errorDescription: String? {
        switch self {
        case .codexNotFound:
            return "Codex CLI was not found. Install or sign in to Codex, then refresh."
        case .launchFailed(let message):
            return "Could not start Codex: \(message)"
        case .timedOut:
            return "Codex took too long to return usage data."
        case .invalidResponse:
            return "Codex returned usage data in an unexpected format."
        case .server(let message):
            return message
        case .processExited(let status, let detail):
            let suffix = detail.isEmpty ? "" : ": \(detail)"
            return "Codex stopped unexpectedly (\(status))\(suffix)"
        }
    }
}

struct CodexUsageService {
    static func fetch(
        timeout: TimeInterval = 15,
        executablePath: String? = nil
    ) async throws -> CodexUsageSnapshot {
        try await Task.detached(priority: .utility) {
            try CodexUsageProbe(timeout: timeout, executablePath: executablePath).fetch()
        }.value
    }
}

private struct CodexExecutableLocator {
    static func find() -> String? {
        let environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            environment["CODEX_EXECUTABLE"],
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "\(home)/.local/bin/codex"
        ].compactMap { $0 }

        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }
}

private final class CodexUsageProbe: @unchecked Sendable {
    private static let ignoreBrokenPipeSignal: Void = {
        signal(SIGPIPE, SIG_IGN)
    }()

    private let timeout: TimeInterval
    private let executablePath: String?
    private let decoder = JSONDecoder()
    private let process = Process()
    private let standardInput = Pipe()
    private let standardOutput = Pipe()
    private let standardError = Pipe()
    private let queue = DispatchQueue(label: "com.aaronwhippo.CodexUsage.probe")
    private let finished = DispatchSemaphore(value: 0)

    // Access to the following state is serialized by queue.
    private var outputBuffer = Data()
    private var errorBuffer = Data()
    private var limitsResponse: RateLimitsResponse?
    private var usageResponse: AccountUsageResponse?
    private var usageFinished = false
    private var resultError: Error?
    private var didFinish = false

    init(timeout: TimeInterval, executablePath: String?) {
        self.timeout = timeout
        self.executablePath = executablePath
    }

    func fetch() throws -> CodexUsageSnapshot {
        _ = Self.ignoreBrokenPipeSignal

        guard let executable = executablePath ?? CodexExecutableLocator.find() else {
            throw CodexUsageError.codexNotFound
        }

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["app-server", "--stdio"]
        process.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError

        var environment = ProcessInfo.processInfo.environment
        let requiredPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let existing = environment["PATH"], !existing.isEmpty {
            environment["PATH"] = requiredPath + ":" + existing
        } else {
            environment["PATH"] = requiredPath
        }
        process.environment = environment

        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self.queue.async {
                self.outputBuffer.append(data)
                self.consumeOutput()
            }
        }

        standardError.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self.queue.async {
                if self.errorBuffer.count < 8_192 {
                    self.errorBuffer.append(data.prefix(8_192 - self.errorBuffer.count))
                }
            }
        }

        process.terminationHandler = { terminated in
            self.queue.async {
                guard !self.didFinish else { return }
                let detail = String(data: self.errorBuffer, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.complete(CodexUsageError.processExited(terminated.terminationStatus, detail))
            }
        }

        do {
            try process.run()
        } catch {
            stopProcess()
            throw CodexUsageError.launchFailed(error.localizedDescription)
        }

        queue.async {
            self.send([
                "id": 1,
                "method": "initialize",
                "params": [
                    "clientInfo": [
                        "name": "codex_usage_menu",
                        "title": "Codex Usage",
                        "version": "1.0.0"
                    ],
                    "capabilities": ["experimentalApi": true]
                ]
            ])
        }

        if finished.wait(timeout: .now() + timeout) == .timedOut {
            queue.sync {
                if !self.didFinish {
                    self.didFinish = true
                    self.resultError = CodexUsageError.timedOut
                }
            }
        }

        stopProcess()
        let result = queue.sync {
            (resultError, limitsResponse, usageResponse)
        }

        if let resultError = result.0 {
            throw resultError
        }
        guard let limitsResponse = result.1 else {
            throw CodexUsageError.invalidResponse
        }

        var buckets = limitsResponse.rateLimitsByLimitId ?? [:]
        if buckets.isEmpty {
            buckets[limitsResponse.rateLimits.limitId ?? "codex"] = limitsResponse.rateLimits
        }

        return CodexUsageSnapshot(
            defaultRateLimits: limitsResponse.rateLimits,
            rateLimitsById: buckets,
            rateLimitResetCredits: limitsResponse.rateLimitResetCredits,
            accountUsage: result.2,
            fetchedAt: Date()
        )
    }

    private func complete(_ error: Error? = nil) {
        guard !didFinish else { return }
        didFinish = true
        resultError = error
        finished.signal()
    }

    private func send(_ object: [String: Any]) {
        do {
            var data = try JSONSerialization.data(withJSONObject: object)
            data.append(0x0A)
            try standardInput.fileHandleForWriting.write(contentsOf: data)
        } catch {
            complete(error)
        }
    }

    private func maybeComplete() {
        if limitsResponse != nil && usageFinished {
            complete()
        }
    }

    private func handleResponse(_ object: [String: Any]) {
        guard let id = (object["id"] as? NSNumber)?.intValue else { return }

        if let error = object["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Codex could not read usage data."
            if id == 4 {
                usageFinished = true
                maybeComplete()
            } else {
                complete(CodexUsageError.server(message))
            }
            return
        }

        guard let result = object["result"] else { return }

        if id == 1 {
            send(["method": "initialized"])
            send(["id": 3, "method": "account/rateLimits/read"])
            send(["id": 4, "method": "account/usage/read"])
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: result)
            switch id {
            case 3:
                limitsResponse = try decoder.decode(RateLimitsResponse.self, from: data)
            case 4:
                usageResponse = try decoder.decode(AccountUsageResponse.self, from: data)
                usageFinished = true
            default:
                break
            }
            maybeComplete()
        } catch {
            if id == 4 {
                usageFinished = true
                maybeComplete()
            } else {
                complete(CodexUsageError.invalidResponse)
            }
        }
    }

    private func consumeOutput() {
        while let newline = outputBuffer.firstIndex(of: 0x0A) {
            let line = outputBuffer[..<newline]
            outputBuffer.removeSubrange(...newline)
            guard !line.isEmpty,
                  let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] else {
                continue
            }
            handleResponse(object)
        }
    }

    private func stopProcess() {
        standardOutput.fileHandleForReading.readabilityHandler = nil
        standardError.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        try? standardInput.fileHandleForWriting.close()

        if process.isRunning {
            process.terminate()
        }
    }
}
