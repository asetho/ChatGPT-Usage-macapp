using System.Diagnostics;
using System.Windows;

namespace ChatGPTUsage.Windows;

public partial class MainWindow : Window
{
    private bool canClose;

    public MainWindow(UsageViewModel usage)
    {
        InitializeComponent();
        DataContext = usage;
    }

    public void ShowNearBottomRight()
    {
        _ = ((UsageViewModel)DataContext).RefreshAsync();
        Left = SystemParameters.WorkArea.Right - Width - 16;
        Top = SystemParameters.WorkArea.Bottom - Height - 16;
        Show();
        Activate();
    }

    public void AllowClose() => canClose = true;

    private void Window_Deactivated(object sender, EventArgs e) => Hide();

    protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
    {
        base.OnClosing(e);
        if (!canClose)
        {
            e.Cancel = true;
            Hide();
        }
    }

    private async void Refresh_Click(object sender, RoutedEventArgs e) => await ((UsageViewModel)DataContext).RefreshAsync();

    private void OpenUsage_Click(object sender, RoutedEventArgs e) => OpenUrl("https://chatgpt.com/codex/settings/usage");

    private void OpenUpdate_Click(object sender, RoutedEventArgs e)
    {
        if (((UsageViewModel)DataContext).UpdateUrl is { } url)
        {
            OpenUrl(url);
        }
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Hide();

    private void Quit_Click(object sender, RoutedEventArgs e) => ((App)System.Windows.Application.Current).ExitApplication();

    private static void OpenUrl(string url) => Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
}
