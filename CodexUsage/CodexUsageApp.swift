import AppKit
import Combine
import SwiftUI

@main
struct CodexUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let statusFont = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)

    private var statusItem: NSStatusItem?
    private lazy var statusContentView = StatusContentView(font: Self.statusFont)
    private let popover = NSPopover()
    private var snapshotObserver: AnyCancellable?

#if DEBUG
    private var previewWindow: NSWindow?
#endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("ChatGPT Usage runs in the menu bar")
#if DEBUG
        if ProcessInfo.processInfo.environment["CODEX_USAGE_PREVIEW"] == "1" {
            showPreviewWindow()
        } else {
            NSApp.setActivationPolicy(.accessory)
            configureStatusItem()
        }
#else
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
#endif
        UsageStore.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        UsageStore.shared.stop()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.behavior = []
        item.isVisible = true

        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp])
        button.title = ""
        button.image = nil
        button.imagePosition = .noImage

        statusContentView.setIcon(loadChatGPTMenuBarIcon())
        statusContentView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(statusContentView)
        NSLayoutConstraint.activate([
            statusContentView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            statusContentView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])

        let controller = NSHostingController(
            rootView: UsageMenuView().environmentObject(UsageStore.shared)
        )
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)

        statusItem = item
        updateStatusItem()
        snapshotObserver = UsageStore.shared.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
    }

    private func updateStatusItem() {
        let percentage = UsageStore.shared.menuBarPercentage
        guard let statusItem, let button = statusItem.button else { return }

        statusContentView.percentage = percentage
        button.toolTip = "ChatGPT 5-hour usage: \(percentage) remaining. Double-click to open ChatGPT."
        button.setAccessibilityLabel("ChatGPT 5-hour usage, \(percentage) remaining")

        statusItem.length = ceil(statusContentView.fittingWidth)
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        if (NSApp.currentEvent?.clickCount ?? 1) >= 2 {
            popover.performClose(sender)
            openChatGPT()
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func openChatGPT() {
        let webFallback = URL(string: "https://chatgpt.com")!
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.openai.codex"
        ) else {
            NSWorkspace.shared.open(webFallback)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = false
        NSWorkspace.shared.openApplication(
            at: appURL,
            configuration: configuration
        ) { _, error in
            guard error != nil else { return }
            DispatchQueue.main.async {
                NSWorkspace.shared.open(webFallback)
            }
        }
    }

    private func loadChatGPTMenuBarIcon() -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.openai.codex"
        ) else {
            return NSImage(
                systemSymbolName: "message.fill",
                accessibilityDescription: "ChatGPT"
            )
        }

        let iconURL = appURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("chatgptTemplate@2x.png")

        guard let image = NSImage(contentsOf: iconURL) else {
            return NSImage(
                systemSymbolName: "message.fill",
                accessibilityDescription: "ChatGPT"
            )
        }

        image.size = NSSize(width: 18, height: 18)
        return image
    }

#if DEBUG
    private func showPreviewWindow() {
        NSApp.setActivationPolicy(.regular)
        let rootView = UsageMenuView().environmentObject(UsageStore.shared)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ChatGPT Usage Preview"
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        previewWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
#endif
}

private final class StatusContentView: NSView {
    private static let iconSize: CGFloat = 18
    private static let spacing: CGFloat = 3

    private let iconView = NSImageView()
    private let percentageLabel = NSTextField(labelWithString: "")
    private let stackView = NSStackView()

    var percentage: String {
        get { percentageLabel.stringValue }
        set {
            percentageLabel.stringValue = newValue
            invalidateIntrinsicContentSize()
        }
    }

    var fittingWidth: CGFloat {
        let iconWidth = iconView.isHidden ? 0 : Self.iconSize + Self.spacing
        return iconWidth + percentageLabel.intrinsicContentSize.width
    }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: fittingWidth,
            height: max(Self.iconSize, percentageLabel.intrinsicContentSize.height)
        )
    }

    init(font: NSFont) {
        super.init(frame: .zero)

        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.isHidden = true

        percentageLabel.font = font
        percentageLabel.textColor = .labelColor

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = Self.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(percentageLabel)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setIcon(_ image: NSImage?) {
        let templateImage = image?.copy() as? NSImage
        templateImage?.isTemplate = true
        iconView.image = templateImage
        iconView.isHidden = templateImage == nil
        invalidateIntrinsicContentSize()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
