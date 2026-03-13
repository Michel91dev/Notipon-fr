import SwiftUI
import AppKit
import Combine

/// Gestionnaire des popups de notification personnalisés
final class NotificationPopupController: ObservableObject {
    static let shared = NotificationPopupController()

    private var popupWindow: NSWindow?
    private var hostingView: NSHostingView<AnyView>?
    private var dismissTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var settingsManager: SettingsManager { SettingsManager.shared }
    private var isUpdatingFromSettings = false  // Drapeau de prévention des boucles infinies

    /// Notification actuellement affichée
    @Published var currentNotification: NotificationItem?

    /// File d'attente des notifications (pour les cas où plusieurs arrivent simultanément)
    private var notificationQueue: [NotificationItem] = []

    private init() {
        observeSettings()
        // Précréer la fenêtre (accélère l'affichage initial)
        DispatchQueue.main.async { [weak self] in
            self?.preloadWindow()
        }
    }

    /// Précréer la fenêtre et terminer le rendu
    private func preloadWindow() {
        createWindow()
        // Afficher brièvement pour rendre SwiftUI
        popupWindow?.orderFront(nil)
        popupWindow?.orderOut(nil)
    }

    // MARK: - Observateur des paramètres

    private func observeSettings() {
        // Observer chaque paramètre individuellement (CombineLatest4 peut avoir des problèmes d'ordre)
        settingsManager.$popupX
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyCurrentFrame() }
            .store(in: &cancellables)

        settingsManager.$popupY
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyCurrentFrame() }
            .store(in: &cancellables)

        settingsManager.$popupWidth
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyCurrentFrame() }
            .store(in: &cancellables)

        settingsManager.$popupHeight
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyCurrentFrame() }
            .store(in: &cancellables)

        settingsManager.$popupOpacity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] opacity in
                self?.popupWindow?.alphaValue = opacity
            }
            .store(in: &cancellables)
    }

    private func applyCurrentFrame() {
        let frame = NSRect(
            x: settingsManager.popupX,
            y: settingsManager.popupY,
            width: settingsManager.popupWidth,
            height: settingsManager.popupHeight
        )
        updateWindowFrame(frame)
    }

    // MARK: - Afficher la notification

    /// Afficher une notification en popup
    func show(_ notification: NotificationItem) {
        guard settingsManager.popupEnabled else { return }

        // Si un popup est déjà affiché, ajouter à la file d'attente
        if self.currentNotification != nil {
            self.notificationQueue.append(notification)
            return
        }

        self.currentNotification = notification
        self.showPopupWindow()
        self.startDismissTimer()
    }

    /// Afficher plusieurs notifications à la fois (seule la plus récente est affichée)
    func showMultiple(_ notifications: [NotificationItem]) {
        guard !notifications.isEmpty else { return }

        // Afficher uniquement la notification la plus récente
        if let latest = notifications.first {
            show(latest)
        }
    }

    // MARK: - Gestion de la fenêtre

    private func showPopupWindow() {
        if popupWindow == nil {
            createWindow()
        }
            // Le contenu se met à jour automatiquement via ObservableObject
        popupWindow?.alphaValue = settingsManager.popupOpacity
        popupWindow?.orderFront(nil)
    }

    private func createWindow() {
        let frame = settingsManager.popupFrame

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.alphaValue = 0  // Initialement caché

        // Précréer la vue SwiftUI (mise à jour via ObservableObject)
        let contentView = PopupContentView(controller: self)
            .environmentObject(settingsManager)
        let hosting = NSHostingView(rootView: AnyView(contentView))
        window.contentView = hosting
        hostingView = hosting

        // Sauvegarder la position lors du déplacement
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )

        popupWindow = window
    }

    @objc private func windowDidMove(_ notification: Notification) {
        // Éviter de sauvegarder pendant la mise à jour des paramètres (prévient les boucles infinies)
        guard !isUpdatingFromSettings else { return }
        guard let window = notification.object as? NSWindow else { return }
        settingsManager.setPopupFrame(window.frame)
    }

    private func updateWindowFrame(_ frame: NSRect) {
        isUpdatingFromSettings = true
        popupWindow?.setFrame(frame, display: true, animate: false)
        // Réinitialiser le drapeau après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isUpdatingFromSettings = false
        }
    }

    // MARK: - Fermeture

    private func startDismissTimer() {
        dismissTimer?.invalidate()

        let duration = settingsManager.popupDuration
        guard duration > 0 else { return }  // 0 secondes = ne disparaît pas automatiquement

        dismissTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration), repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        // Animation de fondu
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            popupWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.popupWindow?.orderOut(nil)
            self?.currentNotification = nil

            // Afficher la suivante dans la file si disponible
            if let next = self?.notificationQueue.first {
                self?.notificationQueue.removeFirst()
                self?.show(next)
            }
        })
    }

    /// Fermer manuellement immédiatement
    func dismissImmediately() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        popupWindow?.orderOut(nil)
        currentNotification = nil
        notificationQueue.removeAll()
    }

    // MARK: - Action

    private func handleAction() {
        // Action au clic sur la notification (pour extension future)
        dismiss()
    }

    // MARK: - Mode Aperçu (pour vérifier la position dans les paramètres)

    /// Afficher l'aperçu (depuis les paramètres pour vérifier la position)
    func showPreview() {
        let sampleNotification = NotificationItem(
            appIdentifier: "com.example.preview",
            appName: "Aperçu",
            title: "Titre de notification",
            body: "Ceci est une notification d'aperçu. Vous pouvez déplacer la fenêtre en la traînant.",
            timestamp: Date()
        )

        currentNotification = sampleNotification
        showPopupWindow()

        // L'aperçu disparaît automatiquement après 5 secondes
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
}

// MARK: - PopupContentView (compatible ObservableObject)

private struct PopupContentView: View {
    @ObservedObject var controller: NotificationPopupController
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        Group {
            if let notification = controller.currentNotification {
                NotificationPopupView(
                    notification: notification,
                    onDismiss: { controller.dismiss() },
                    onAction: { controller.dismiss() }
                )
            } else {
                Color.clear
            }
        }
    }
}
