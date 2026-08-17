using System.Windows;
using System.Windows.Input;

namespace ChatGPTUsage.Windows;

public partial class UsageWidget : Window
{
    private readonly Action openUsage;

    public UsageWidget(UsageViewModel usage, Action openUsage)
    {
        InitializeComponent();
        DataContext = usage;
        this.openUsage = openUsage;
    }

    public void ShowNearClock()
    {
        Show();
        Left = SystemParameters.WorkArea.Right - ActualWidth - 12;
        Top = SystemParameters.WorkArea.Bottom - ActualHeight - 12;
    }

    private void Widget_Click(object sender, MouseButtonEventArgs e) => openUsage();
}
