using Drawing = System.Drawing;
using Drawing2D = System.Drawing.Drawing2D;
using System.IO;
using System.Runtime.InteropServices;

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
        using var source = appIcon.ToBitmap();
        using var trayBitmap = new Drawing.Bitmap(32, 32, Drawing.Imaging.PixelFormat.Format32bppArgb);
        using var graphics = Drawing.Graphics.FromImage(trayBitmap);
        using var clip = new Drawing2D.GraphicsPath();

        graphics.Clear(Drawing.Color.Transparent);
        graphics.InterpolationMode = Drawing2D.InterpolationMode.HighQualityBicubic;
        graphics.PixelOffsetMode = Drawing2D.PixelOffsetMode.HighQuality;
        graphics.CompositingQuality = Drawing2D.CompositingQuality.HighQuality;
        clip.AddEllipse(0, 0, 32, 32);
        graphics.SetClip(clip);
        graphics.DrawImage(source, new Drawing.Rectangle(1, 1, 30, 30), 4, 4, 24, 24, Drawing.GraphicsUnit.Pixel);

        var handle = trayBitmap.GetHicon();
        try
        {
            using var nativeIcon = Drawing.Icon.FromHandle(handle);
            return (Drawing.Icon)nativeIcon.Clone();
        }
        finally
        {
            DestroyIcon(handle);
        }
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(nint hIcon);
}
