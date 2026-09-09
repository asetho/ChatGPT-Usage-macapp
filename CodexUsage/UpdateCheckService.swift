import Foundation

struct AvailableUpdate: Equatable {
    let version: String
    let releaseURL: URL
}

enum UpdateCheckService {
    private static let latestReleaseURL = URL(
        string: "https://api.github.com/repos/asetho/ChatGPT-Usage/releases/latest"
    )!

    static func fetchAvailableUpdate(
        currentVersion: String,
        session: URLSession = .shared
    ) async throws -> AvailableUpdate? {
        var request = URLRequest(url: latestReleaseURL)
        request.timeoutInterval = 8
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("asetho-ChatGPT-Usage/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return availableUpdate(from: data, currentVersion: currentVersion)
    }

    static func availableUpdate(from data: Data, currentVersion: String) -> AvailableUpdate? {
        guard let release = try? JSONDecoder().decode(GitHubRelease.self, from: data),
              let latestVersion = SemanticVersion(release.tagName),
              let installedVersion = SemanticVersion(currentVersion),
              latestVersion > installedVersion,
              release.htmlURL.scheme == "https",
              release.htmlURL.host == "github.com" else {
            return nil
        }

        return AvailableUpdate(version: latestVersion.description, releaseURL: release.htmlURL)
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

private struct SemanticVersion: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    init?(_ value: String) {
        var normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.first == "v" || normalized.first == "V" {
            normalized.removeFirst()
        }

        let components = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count == 3,
              let major = Int(components[0]), major >= 0,
              let minor = Int(components[1]), minor >= 0,
              let patch = Int(components[2]), patch >= 0 else {
            return nil
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    var description: String { "\(major).\(minor).\(patch)" }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
