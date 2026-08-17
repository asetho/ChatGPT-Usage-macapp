using Drawing = System.Drawing;

namespace ChatGPTUsage.Windows;

internal static class TrayIcon
{
    public static Drawing.Icon Create()
    {
        var executablePath = Environment.ProcessPath
            ?? throw new InvalidOperationException("The application executable path is unavailable.");

        using var appIcon = Drawing.Icon.ExtractAssociatedIcon(executablePath)
            ?? throw new InvalidOperationException("The application icon is unavailable.");

        return (Drawing.Icon)appIcon.Clone();
    }
}
