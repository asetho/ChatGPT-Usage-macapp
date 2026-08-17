using Drawing = System.Drawing;
using System.IO;

namespace ChatGPTUsage.Windows;

internal static class TrayIcon
{
    public static Drawing.Icon Create()
    {
        var appIconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "ChatGPTUsage.ico");
        if (!File.Exists(appIconPath))
        {
            throw new InvalidOperationException("The app icon asset is unavailable.");
        }

        using var appIcon = new Drawing.Icon(appIconPath, 32, 32);
        return (Drawing.Icon)appIcon.Clone();
    }
}
