import AppKit
import SwiftUI

struct UsageMenuView: View {
    @EnvironmentObject private var store: UsageStore

    private let usageDashboardURL = URL(string: "https://chatgpt.com/codex/settings/usage")!

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if let snapshot = store.snapshot {
                usageContent(snapshot)
            } else if store.isRefreshing {
                loadingContent
            } else {
                unavailableContent
            }

            if let error = store.errorMessage, store.snapshot != nil {
                Divider()
                errorBanner(error)
            }

            Divider()
            footer
        }
        .frame(width: 280)
        .background {
            ZStack {
                ActiveDarkGlassBackground()
                Color.black.opacity(0.58)
            }
        }
        .preferredColorScheme(.dark)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Usage remaining")
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            if store.isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private func usageContent(_ snapshot: CodexUsageSnapshot) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                UsageWindowRow(title: "5h", window: snapshot.codexRateLimits.fiveHourWindow)
                UsageWindowRow(title: "Weekly", window: snapshot.codexRateLimits.weeklyWindow)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            if snapshot.codexRateLimits.rateLimitReachedType != nil {
                statusWarning
            }

            Button(action: openUsageDashboard) {
                HStack(spacing: 6) {
                    Text(manageUsageTitle(snapshot))
                    Image(systemName: "arrow.up.forward.app")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if !snapshot.additionalRateLimits.isEmpty || snapshot.accountUsage != nil {
                Divider()

                VStack(spacing: 8) {
                    if !snapshot.additionalRateLimits.isEmpty {
                        ExpandableSection("Additional limits") {
                            VStack(spacing: 8) {
                                ForEach(snapshot.additionalRateLimits) { limit in
                                    AdditionalLimitView(limit: limit)
                                }
                            }
                        }
                    }

                    if let usage = snapshot.accountUsage {
                        ExpandableSection("Token usage") {
                            VStack(spacing: 7) {
                                DetailRow(title: "Today", value: UsageFormatters.tokenCount(snapshot.todayTokens))
                                DetailRow(title: "Lifetime", value: UsageFormatters.tokenCount(usage.summary.lifetimeTokens))
                                if let streak = usage.summary.currentStreakDays {
                                    DetailRow(title: "Current streak", value: "\(streak) days")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Reading usage from ChatGPT…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Usage unavailable", systemImage: "exclamationmark.triangle")
                .font(.headline)
            Text(store.errorMessage ?? "ChatGPT has not returned usage data yet.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try Again") { store.refresh() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var statusWarning: some View {
        Label("A usage limit has been reached.", systemImage: "exclamationmark.circle.fill")
            .font(.callout)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Showing the last update. \(message)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(action: { store.refresh() }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(store.isRefreshing)

            if let fetchedAt = store.snapshot?.fetchedAt {
                Text(fetchedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func manageUsageTitle(_ snapshot: CodexUsageSnapshot) -> String {
        if let count = snapshot.rateLimitResetCredits?.availableCount, count > 0 {
            return count == 1 ? "1 reset available" : "\(count) resets available"
        }

        let limit = snapshot.codexRateLimits
        guard let credits = limit.credits else { return "Open ChatGPT Usage" }
        if credits.unlimited { return "Unlimited credits" }
        if credits.hasCredits, let balance = credits.balance {
            return "\(balance) credits available"
        }
        return "Manage resets & credits"
    }

    private func openUsageDashboard() {
        NSWorkspace.shared.open(usageDashboardURL)
    }
}

private struct ExpandableSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    @State private var isExpanded = false

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 10)
                    Text(title)
                        .font(.system(size: 13))
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Shows or hides details")

            if isExpanded {
                content()
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ActiveDarkGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: NSVisualEffectView) {
        view.appearance = NSAppearance(named: .darkAqua)
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
    }
}

private struct UsageWindowRow: View {
    let title: String
    let window: RateLimitWindow?

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            if let window {
                Text("\(window.remainingPercent)%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text(UsageFormatters.resetLabel(window.resetsAt))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            } else {
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 15))
    }
}

private struct AdditionalLimitView: View {
    let limit: RateLimitSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(limit.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            UsageWindowRow(title: "5h", window: limit.fiveHourWindow)
            UsageWindowRow(title: "Weekly", window: limit.weeklyWindow)
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.system(size: 13))
    }
}
