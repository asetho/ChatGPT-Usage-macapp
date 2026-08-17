import Foundation

@MainActor
final class UsageStore: ObservableObject {
    static let shared = UsageStore()

    @Published private(set) var snapshot: CodexUsageSnapshot?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    private var refreshLoop: Task<Void, Never>?

    var remainingFiveHourPercent: Int? {
        snapshot?.codexRateLimits.fiveHourWindow?.remainingPercent
    }

    var menuBarPercentage: String {
        guard let remainingFiveHourPercent else { return "--%" }
        return "\(remainingFiveHourPercent)%"
    }

    func start() {
        guard refreshLoop == nil else { return }
        refresh()
        refreshLoop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { break }
                self?.refresh()
            }
        }
    }

    func stop() {
        refreshLoop?.cancel()
        refreshLoop = nil
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task { [weak self] in
            do {
                let snapshot = try await CodexUsageService.fetch()
                guard let self else { return }
                self.snapshot = snapshot
                self.errorMessage = nil
                self.isRefreshing = false
            } catch {
                guard let self else { return }
                self.errorMessage = error.localizedDescription
                self.isRefreshing = false
            }
        }
    }
}
