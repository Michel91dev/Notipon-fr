import SwiftUI
import AppKit
import Combine

/// Contrôleur de la barre de menus (avec support survol)
final class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem!
    private var hoverPopover: NSPopover!
    private var dropdownPopover: NSPopover!
    private var historyWindow: NSWindow?
    private var hoverTimer: Timer?
    private var hoverHandler: HoverHandler?

    private var storageManager: StorageManager { StorageManager.shared }
    private var settingsManager: SettingsManager { SettingsManager.shared }
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var isHoverPreviewShown = false

    override init() {
        super.init()
        setupStatusItem()
        setupPopovers()
        observeUnreadCount()
        setupGlobalHotkeys()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem.button else { return }

        updateIcon()

        // Configuration de l'icône
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Configuration du gestionnaire de survol
        hoverHandler = HoverHandler(
            onMouseEntered: { [weak self] in self?.handleMouseEntered() },
            onMouseExited: { [weak self] in self?.handleMouseExited() }
        )

        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: hoverHandler,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }

        // Fermer l'aperçu au survol
        hideHoverPreview()

        if event.type == .rightMouseUp {
            openHistoryWindow()
        } else {
            toggleDropdown()
        }
    }

    private func setupPopovers() {
        // Aperçu au survol
        hoverPopover = NSPopover()
        hoverPopover.contentSize = NSSize(
            width: settingsManager.hoverPreviewWidth,
            height: settingsManager.hoverPreviewHeight
        )
        hoverPopover.behavior = .semitransient
        hoverPopover.animates = true

        // Créer le hosting controller sans closure capturant self
        let hoverView = HoverPreviewView()
            .environmentObject(StorageManager.shared)
            .environmentObject(SettingsManager.shared)
        hoverPopover.contentViewController = NSHostingController(rootView: hoverView)

        // Menu déroulant
        dropdownPopover = NSPopover()
        dropdownPopover.contentSize = NSSize(
            width: settingsManager.dropdownWidth,
            height: settingsManager.dropdownHeight
        )
        dropdownPopover.behavior = .transient
        dropdownPopover.animates = true

        // Créer le hosting controller avec weak self
        let dropdownView = DropdownView(
            onOpenHistory: { [weak self] in self?.openHistoryWindow() },
            onOpenSettings: { [weak self] in self?.openSettings() }
        )
        .environmentObject(StorageManager.shared)
        .environmentObject(SettingsManager.shared)
        dropdownPopover.contentViewController = NSHostingController(rootView: dropdownView)
    }

    // MARK: - Mise à jour de l'icône

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let unreadCount = storageManager.unreadCount
        let showBadge = settingsManager.showUnreadBadge && unreadCount > 0

        // Icône de base (blanche fixe)
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        guard let symbolImage = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Notipon")?.withSymbolConfiguration(config) else { return }

        let whiteIcon = createWhiteIcon(from: symbolImage)

        if showBadge {
            // Icône avec badge
            let badgeImage = createBadgeImage(base: whiteIcon, count: unreadCount)
            button.image = badgeImage
        } else {
            button.image = whiteIcon
        }
    }

    private func createWhiteIcon(from symbol: NSImage) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()

        // Dessiner un rectangle blanc
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Dessiner le symbole en masquant la partie blanche
        symbol.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .destinationIn, fraction: 1.0)

        image.unlockFocus()

        return image
    }

    private func createBadgeImage(base: NSImage, count: Int) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size)

        image.lockFocus()

        // Dessiner l'icône blanche
        base.draw(
            in: NSRect(x: 0, y: 0, width: 18, height: 18),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )

        // Dessiner le badge (cercle rouge)
        let badgeRect = NSRect(x: 12, y: 10, width: 10, height: 10)
        NSColor.systemRed.setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        // Dessiner le numéro du badge (jusqu'à 9)
        if count <= 9 {
            let text = "\(count)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 7, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = NSRect(
                x: badgeRect.midX - textSize.width / 2,
                y: badgeRect.midY - textSize.height / 2 + 0.5,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }

        image.unlockFocus()

        return image
    }

    private func observeUnreadCount() {
        storageManager.$unreadCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        settingsManager.$showUnreadBadge
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)

        // Surveillance des changements de taille de l'aperçu au survol
        settingsManager.$hoverPreviewWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] width in
                self?.hoverPopover.contentSize.width = width
            }
            .store(in: &cancellables)

        settingsManager.$hoverPreviewHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.hoverPopover.contentSize.height = height
            }
            .store(in: &cancellables)

        // Surveillance des changements de taille du menu déroulant
        settingsManager.$dropdownWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] width in
                self?.dropdownPopover.contentSize.width = width
            }
            .store(in: &cancellables)

        settingsManager.$dropdownHeight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.dropdownPopover.contentSize.height = height
            }
            .store(in: &cancellables)
    }

    // MARK: - Événements souris

    private func handleMouseEntered() {
        // Affichage différé de l'aperçu au survol
        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.showHoverPreview()
        }
    }

    private func handleMouseExited() {
        hoverTimer?.invalidate()
        hoverTimer = nil

        // Fermer le popup si le menu déroulant n'est pas affiché
        if !dropdownPopover.isShown {
            hideHoverPreview()
        }
    }

    // MARK: - Contrôle des popups

    private func showHoverPreview() {
        guard let button = statusItem.button,
              !dropdownPopover.isShown,
              !hoverPopover.isShown else { return }

        hoverPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        isHoverPreviewShown = true
    }

    private func hideHoverPreview() {
        if hoverPopover.isShown {
            hoverPopover.performClose(nil)
        }
        isHoverPreviewShown = false
    }

    private func toggleDropdown() {
        guard let button = statusItem.button else { return }

        if dropdownPopover.isShown {
            dropdownPopover.performClose(nil)
        } else {
            dropdownPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Fenêtre d'historique

    func openHistoryWindow() {
        dropdownPopover.performClose(nil)

        // Si une fenêtre existe et est visible, la fermer
        if let window = historyWindow, window.isVisible {
            window.close()
            return
        }

        // Si la fenêtre existe mais est cachée, l'afficher
        if let window = historyWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Créer une nouvelle fenêtre si elle n'existe pas
        let contentView = HistoryWindowView()
            .environmentObject(storageManager)
            .environmentObject(settingsManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Notipon"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.setFrameAutosaveName("NotiponHistoryWindow")
        window.isReleasedWhenClosed = false

        historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Paramètres

    func openSettings() {
        dropdownPopover.performClose(nil)

        // Paramètres window
        let contentView = SettingsView()
            .environmentObject(settingsManager)
            .environmentObject(storageManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Paramètres"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Raccourcis clavier globaux

    private var keyDownMonitor: Any?

    private func setupGlobalHotkeys() {
        // Raccourci pour ouvrir la fenêtre d'historique (depuis les paramètres)
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            let shortcut = self.settingsManager.shortcutOpenHistory

            // Vérifier si le raccourci correspond à l'événement
            if !shortcut.isDisabled && shortcut.matches(event: event) {
                self.openHistoryWindow()
                return nil  // Consommer l'événement
            }

            return event
        }

        // Surveillance des changements de raccourci (redémarrage nécessaire)
        settingsManager.$shortcutOpenHistory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Traitement lors du changement de paramètre
                // Note: redémarrage requis pour appliquer les nouveaux raccourcis
            }
            .store(in: &cancellables)
    }

    deinit {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hoverTimer?.invalidate()
        pollingTimer?.invalidate()
    }
}

// MARK: - Hover Handler

/// Classe helper utilisée comme owner de NSTrackingArea
final class HoverHandler: NSResponder {
    private let onMouseEntered: () -> Void
    private let onMouseExited: () -> Void

    init(onMouseEntered: @escaping () -> Void, onMouseExited: @escaping () -> Void) {
        self.onMouseEntered = onMouseEntered
        self.onMouseExited = onMouseExited
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited()
    }
}
