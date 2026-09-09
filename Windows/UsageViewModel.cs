using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;

namespace ChatGPTUsage.Windows;

public sealed class UsageViewModel : INotifyPropertyChanged
{
    private bool isRefreshing;
    private string fiveHourRemaining = "—";
    private string fiveHourReset = "—";
    private string weeklyRemaining = "—";
    private string weeklyReset = "—";
    private string resetTitle = "Open ChatGPT Usage";
    private string errorMessage = "";
    private string refreshStatus = "";
    private string updateDescription = "";
    private string? updateUrl;
    private Visibility additionalLimitsVisibility = Visibility.Collapsed;
    private Visibility tokenUsageVisibility = Visibility.Collapsed;
    private Visibility updateAvailableVisibility = Visibility.Collapsed;
    private bool isCheckingForUpdates;

    public event PropertyChangedEventHandler? PropertyChanged;

    public ObservableCollection<LimitDisplay> AdditionalLimits { get; } = [];
    public ObservableCollection<UsageDetail> TokenUsage { get; } = [];

    public string FiveHourRemaining { get => fiveHourRemaining; private set => Set(ref fiveHourRemaining, value); }
    public string FiveHourReset { get => fiveHourReset; private set => Set(ref fiveHourReset, value); }
    public string WeeklyRemaining { get => weeklyRemaining; private set => Set(ref weeklyRemaining, value); }
    public string WeeklyReset { get => weeklyReset; private set => Set(ref weeklyReset, value); }
    public string ResetTitle { get => resetTitle; private set => Set(ref resetTitle, value); }
    public string ErrorMessage { get => errorMessage; private set => Set(ref errorMessage, value); }
    public string RefreshStatus { get => refreshStatus; private set => Set(ref refreshStatus, value); }
    public string UpdateDescription { get => updateDescription; private set => Set(ref updateDescription, value); }
    public string? UpdateUrl { get => updateUrl; private set => Set(ref updateUrl, value); }
    public Visibility AdditionalLimitsVisibility { get => additionalLimitsVisibility; private set => Set(ref additionalLimitsVisibility, value); }
    public Visibility TokenUsageVisibility { get => tokenUsageVisibility; private set => Set(ref tokenUsageVisibility, value); }
    public Visibility UpdateAvailableVisibility { get => updateAvailableVisibility; private set => Set(ref updateAvailableVisibility, value); }
    public string TrayText => $"ChatGPT Usage: {FiveHourRemaining} remaining";

    public Task RefreshAsync() => RefreshAsync(showErrors: true);

    public Task RefreshInBackgroundAsync() => RefreshAsync(showErrors: false);

    public async Task CheckForUpdatesAsync()
    {
        if (isCheckingForUpdates) return;

        isCheckingForUpdates = true;
        try
        {
            var update = await UpdateCheckService.FetchAvailableUpdateAsync(UpdateCheckService.CurrentVersion);
            if (update is null)
            {
                UpdateAvailableVisibility = Visibility.Collapsed;
                UpdateDescription = "";
                UpdateUrl = null;
                return;
            }

            UpdateDescription = $"Version {update.Version} · View release";
            UpdateUrl = update.ReleaseUrl;
            UpdateAvailableVisibility = Visibility.Visible;
        }
        catch
        {
            // Update checks never interfere with usage refreshes.
        }
        finally
        {
            isCheckingForUpdates = false;
        }
    }

    private async Task RefreshAsync(bool showErrors)
    {
        if (isRefreshing) return;

        isRefreshing = true;
        if (showErrors)
        {
            RefreshStatus = "Refreshing…";
            ErrorMessage = "";
        }
        try
        {
            ApplySnapshot(await CodexUsageService.FetchAsync());
            ErrorMessage = "";
            RefreshStatus = "Updated just now";
        }
        catch (Exception error)
        {
            if (showErrors || FiveHourRemaining == "—")
            {
                ErrorMessage = error is TimeoutException
                    ? "Refresh timed out. It will retry automatically."
                    : error.Message;
                RefreshStatus = "Unavailable";
            }
        }
        finally
        {
            isRefreshing = false;
        }
    }

    private void ApplySnapshot(UsageSnapshot snapshot)
    {
        var limits = snapshot.CodexRateLimits;
        FiveHourRemaining = Remaining(limits.FiveHourWindow);
        FiveHourReset = ResetLabel(limits.FiveHourWindow?.ResetsAt);
        WeeklyRemaining = Remaining(limits.WeeklyWindow);
        WeeklyReset = ResetLabel(limits.WeeklyWindow?.ResetsAt);
        ResetTitle = snapshot.RateLimitResetCredits?.AvailableCount is long count && count > 0
            ? count == 1 ? "1 reset available" : $"{count} resets available"
            : "Open ChatGPT Usage";

        AdditionalLimits.Clear();
        foreach (var limit in snapshot.AdditionalRateLimits)
        {
            AdditionalLimits.Add(new LimitDisplay(
                limit.DisplayName,
                $"5h: {Remaining(limit.FiveHourWindow)} · {ResetLabel(limit.FiveHourWindow?.ResetsAt)}",
                $"Weekly: {Remaining(limit.WeeklyWindow)} · {ResetLabel(limit.WeeklyWindow?.ResetsAt)}"));
        }
        AdditionalLimitsVisibility = AdditionalLimits.Count == 0 ? Visibility.Collapsed : Visibility.Visible;

        TokenUsage.Clear();
        if (snapshot.AccountUsage is { } accountUsage)
        {
            TokenUsage.Add(new UsageDetail("Today", TokenCount(snapshot.TodayTokens)));
            TokenUsage.Add(new UsageDetail("Lifetime", TokenCount(accountUsage.Summary.LifetimeTokens)));
            if (accountUsage.Summary.CurrentStreakDays is long streak)
            {
                TokenUsage.Add(new UsageDetail("Current streak", $"{streak} days"));
            }
        }
        TokenUsageVisibility = TokenUsage.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
    }

    private static string Remaining(RateLimitWindow? window) => window is null ? "—" : $"{Math.Clamp(100 - window.UsedPercent, 0, 100)}%";

    private static string ResetLabel(long? timestamp)
    {
        if (timestamp is null) return "—";
        var reset = DateTimeOffset.FromUnixTimeSeconds(timestamp.Value).ToLocalTime();
        var interval = reset - DateTimeOffset.Now;
        return reset.Date == DateTimeOffset.Now.Date || (interval >= TimeSpan.Zero && interval < TimeSpan.FromDays(1))
            ? reset.ToString("t")
            : reset.ToString("MMM d");
    }

    private static string TokenCount(long? value)
    {
        if (value is null) return "—";
        return Math.Abs(value.Value) switch
        {
            >= 1_000_000_000 => $"{value.Value / 1_000_000_000d:0.#}B",
            >= 1_000_000 => $"{value.Value / 1_000_000d:0.#}M",
            >= 1_000 => $"{value.Value / 1_000d:0.#}K",
            _ => value.Value.ToString("N0")
        };
    }

    private void Set<T>(ref T field, T value, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return;
        field = value;
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        if (propertyName is nameof(FiveHourRemaining))
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(TrayText)));
        }
    }
}

public sealed record LimitDisplay(string Name, string FiveHour, string Weekly);
public sealed record UsageDetail(string Title, string Value);
