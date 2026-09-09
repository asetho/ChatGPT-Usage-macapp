import Foundation

@MainActor
final class UsageStore: ObservableObject {
    static let shared = UsageStore()

    @Published private(set) var snapshot: CodexUsageSnapshot?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var availableUpdate: AvailableUpdate?

    private var refreshLoop: Task<Void, Never>?
    private var updateCheckLoop: Task<Void, Never>?

    private static let updateCheckIntervalNanoseconds: UInt64 = 12 * 60 * 60 * 1_000_000_000

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
        startUpdateChecks()
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
        updateCheckLoop?.cancel()
        updateCheckLoop = nil
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

    private func startUpdateChecks() {
        guard updateCheckLoop == nil else { return }

        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.0.0"

        updateCheckLoop = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let update = try await UpdateCheckService.fetchAvailableUpdate(
                        currentVersion: currentVersion
                    )
                    guard !Task.isCancelled else { break }
                    self?.availableUpdate = update
                } catch {
                    // Update checks never interfere with usage refreshes.
                }

                do {
                    try await Task.sleep(nanoseconds: Self.updateCheckIntervalNanoseconds)
                } catch {
                    break
                }
            }
        }
    }
}
