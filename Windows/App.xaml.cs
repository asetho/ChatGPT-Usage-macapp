using Forms = System.Windows.Forms;
using System.Windows;

namespace ChatGPTUsage.Windows;

public partial class App : System.Windows.Application
{
    private Forms.NotifyIcon? notifyIcon;
    private MainWindow? mainWindow;
    private UsageWidget? usageWidget;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var usage = new UsageViewModel();
        mainWindow = new MainWindow(usage);
        mainWindow.Show();
        mainWindow.Hide();
        usageWidget = new UsageWidget(usage, mainWindow.ShowNearBottomRight);
        usageWidget.ShowNearClock();

        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Show usage", null, (_, _) => Dispatcher.Invoke(mainWindow.ShowNearBottomRight));
        menu.Items.Add("Refresh", null, async (_, _) => await Dispatcher.InvokeAsync(usage.RefreshAsync));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Quit", null, (_, _) => Dispatcher.Invoke(ExitApplication));

        notifyIcon = new Forms.NotifyIcon
        {
            Icon = TrayIcon.Create(),
            Text = "ChatGPT Usage",
            Visible = true,
            ContextMenuStrip = menu
        };
        notifyIcon.MouseClick += (_, args) =>
        {
            if (args.Button == Forms.MouseButtons.Left)
            {
                Dispatcher.Invoke(mainWindow.ShowNearBottomRight);
            }
        };

        usage.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName == nameof(UsageViewModel.TrayText) && notifyIcon is not null)
            {
                notifyIcon.Text = usage.TrayText;
            }
        };

        _ = usage.RefreshAsync();
    }

    public void ExitApplication()
    {
        mainWindow?.AllowClose();
        usageWidget?.Close();
        Shutdown();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        notifyIcon?.Dispose();
        base.OnExit(e);
    }
}
