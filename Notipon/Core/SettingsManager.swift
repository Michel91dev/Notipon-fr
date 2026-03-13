import Foundation
import Combine
import AppKit

/// Gestionnaire des paramètres
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showUnreadBadge = "showUnreadBadge"
        static let autoDeleteFromNotificationCenter = "autoDeleteFromNotificationCenter"
        static let deleteDelay = "deleteDelay"
        static let hoverPreviewMode = "hoverPreviewMode"
        static let retentionPeriod = "retentionPeriod"
        static let excludedApps = "excludedApps"
        // Paramètres du popup
        static let popupEnabled = "popupEnabled"
        static let popupX = "popupX"
        static let popupY = "popupY"
        static let popupWidth = "popupWidth"
        static let popupHeight = "popupHeight"
        static let popupOpacity = "popupOpacity"
        static let popupDuration = "popupDuration"
        static let popupFontSize = "popupFontSize"
        // Paramètres des raccourcis
        static let shortcutOpenHistory = "shortcutOpenHistory"
        static let shortcutFocusSearch = "shortcutFocusSearch"
        // Paramètres de l'aperçu au survol
        static let hoverPreviewWidth = "hoverPreviewWidth"
        static let hoverPreviewHeight = "hoverPreviewHeight"
        static let hoverPreviewFontSize = "hoverPreviewFontSize"
        // Paramètres du menu déroulant
        static let dropdownWidth = "dropdownWidth"
        static let dropdownHeight = "dropdownHeight"
        static let dropdownFontSize = "dropdownFontSize"
    }

    // MARK: - Published Properties

    /// Lancer à la connexion
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    /// Afficher le badge des non-lus
    @Published var showUnreadBadge: Bool {
        didSet { defaults.set(showUnreadBadge, forKey: Keys.showUnreadBadge) }
    }

    /// Supprimer automatiquement du Centre de notifications après sauvegarde
    @Published var autoDeleteFromNotificationCenter: Bool {
        didSet { defaults.set(autoDeleteFromNotificationCenter, forKey: Keys.autoDeleteFromNotificationCenter) }
    }

    /// Délai de suppression (secondes)
    @Published var deleteDelay: DeleteDelay {
        didSet { defaults.set(deleteDelay.rawValue, forKey: Keys.deleteDelay) }
    }

    /// Mode d'affichage de l'aperçu au survol
    @Published var hoverPreviewMode: HoverPreviewMode {
        didSet { defaults.set(hoverPreviewMode.rawValue, forKey: Keys.hoverPreviewMode) }
    }

    /// Durée de conservation
    @Published var retentionPeriod: RetentionPeriod {
        didSet { defaults.set(retentionPeriod.rawValue, forKey: Keys.retentionPeriod) }
    }

    /// Liste des identifiants de bundle des applications exclues
    @Published var excludedApps: [String] {
        didSet { defaults.set(excludedApps, forKey: Keys.excludedApps) }
    }

    // MARK: - Popup Settings

    /// Activer les notifications popup
    @Published var popupEnabled: Bool {
        didSet { defaults.set(popupEnabled, forKey: Keys.popupEnabled) }
    }

    /// Coordonnée X du popup
    @Published var popupX: CGFloat {
        didSet { defaults.set(popupX, forKey: Keys.popupX) }
    }

    /// Coordonnée Y du popup
    @Published var popupY: CGFloat {
        didSet { defaults.set(popupY, forKey: Keys.popupY) }
    }

    /// Largeur du popup
    @Published var popupWidth: CGFloat {
        didSet { defaults.set(popupWidth, forKey: Keys.popupWidth) }
    }

    /// Hauteur du popup
    @Published var popupHeight: CGFloat {
        didSet { defaults.set(popupHeight, forKey: Keys.popupHeight) }
    }

    /// Opacité du popup (0.0-1.0)
    @Published var popupOpacity: Double {
        didSet { defaults.set(popupOpacity, forKey: Keys.popupOpacity) }
    }

    /// Durée d'affichage du popup (secondes, 0=jamais)
    @Published var popupDuration: Int {
        didSet { defaults.set(popupDuration, forKey: Keys.popupDuration) }
    }

    /// Taille de la police du popup
    @Published var popupFontSize: CGFloat {
        didSet { defaults.set(Double(popupFontSize), forKey: Keys.popupFontSize) }
    }

    // MARK: - Keyboard Shortcuts

    /// Raccourci pour ouvrir la fenêtre d'historique
    @Published var shortcutOpenHistory: KeyboardShortcut {
        didSet {
            if let data = try? JSONEncoder().encode(shortcutOpenHistory) {
                defaults.set(data, forKey: Keys.shortcutOpenHistory)
            }
        }
    }

    /// Raccourci pour focus sur le champ de recherche
    @Published var shortcutFocusSearch: KeyboardShortcut {
        didSet {
            if let data = try? JSONEncoder().encode(shortcutFocusSearch) {
                defaults.set(data, forKey: Keys.shortcutFocusSearch)
            }
        }
    }

    // MARK: - Hover Preview Settings

    /// Largeur de l'aperçu au survol
    @Published var hoverPreviewWidth: CGFloat {
        didSet { defaults.set(hoverPreviewWidth, forKey: Keys.hoverPreviewWidth) }
    }

    /// Hauteur de l'aperçu au survol
    @Published var hoverPreviewHeight: CGFloat {
        didSet { defaults.set(hoverPreviewHeight, forKey: Keys.hoverPreviewHeight) }
    }

    /// Taille de la police de l'aperçu au survol
    @Published var hoverPreviewFontSize: CGFloat {
        didSet { defaults.set(Double(hoverPreviewFontSize), forKey: Keys.hoverPreviewFontSize) }
    }

    // MARK: - Dropdown Settings

    /// Largeur du menu déroulant
    @Published var dropdownWidth: CGFloat {
        didSet { defaults.set(dropdownWidth, forKey: Keys.dropdownWidth) }
    }

    /// Hauteur du menu déroulant
    @Published var dropdownHeight: CGFloat {
        didSet { defaults.set(dropdownHeight, forKey: Keys.dropdownHeight) }
    }

    /// Taille de la police du menu déroulant
    @Published var dropdownFontSize: CGFloat {
        didSet { defaults.set(Double(dropdownFontSize), forKey: Keys.dropdownFontSize) }
    }

    // MARK: - Enums

    enum DeleteDelay: Int, CaseIterable {
        case immediately = 0
        case fiveSeconds = 5
        case oneMinute = 60

        var displayName: String {
            switch self {
            case .immediately: return "Supprimer immédiatement"
            case .fiveSeconds: return "Supprimer après 5 secondes"
            case .oneMinute: return "Supprimer après 1 minute"
            }
        }
    }

    enum HoverPreviewMode: String, CaseIterable {
        case recentFive = "recentFive"
        case unreadOnly = "unreadOnly"

        var displayName: String {
            switch self {
            case .recentFive: return "5 derniers"
            case .unreadOnly: return "Non lus uniquement"
            }
        }
    }

    enum RetentionPeriod: Int, CaseIterable {
        case oneDay = 1
        case oneWeek = 7
        case oneMonth = 30
        case unlimited = 0

        var displayName: String {
            switch self {
            case .oneDay: return "24 heures"
            case .oneWeek: return "7 jours"
            case .oneMonth: return "30 jours"
            case .unlimited: return "Illimité"
            }
        }

        var days: Int? {
            self == .unlimited ? nil : rawValue
        }
    }

    // MARK: - Init

    private init() {
        // Load from UserDefaults or use defaults
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        showUnreadBadge = defaults.object(forKey: Keys.showUnreadBadge) as? Bool ?? true
        autoDeleteFromNotificationCenter = defaults.bool(forKey: Keys.autoDeleteFromNotificationCenter)

        if let delayValue = defaults.object(forKey: Keys.deleteDelay) as? Int,
           let delay = DeleteDelay(rawValue: delayValue) {
            deleteDelay = delay
        } else {
            deleteDelay = .fiveSeconds
        }

        if let modeValue = defaults.string(forKey: Keys.hoverPreviewMode),
           let mode = HoverPreviewMode(rawValue: modeValue) {
            hoverPreviewMode = mode
        } else {
            hoverPreviewMode = .unreadOnly
        }

        if let periodValue = defaults.object(forKey: Keys.retentionPeriod) as? Int,
           let period = RetentionPeriod(rawValue: periodValue) {
            retentionPeriod = period
        } else {
            retentionPeriod = .oneMonth
        }

        excludedApps = defaults.stringArray(forKey: Keys.excludedApps) ?? []

        // Paramètres du popup (défaut: haut-droite, 350x100, opacité 0.95, 5 sec)
        popupEnabled = defaults.object(forKey: Keys.popupEnabled) as? Bool ?? true

        // Calculer la position par défaut en haut à droite de l'écran
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let defaultWidth: CGFloat = 350
        let defaultHeight: CGFloat = 100
        let defaultX = screenFrame.maxX - defaultWidth - 20
        let defaultY = screenFrame.maxY - defaultHeight - 20

        // CGFloat est sauvegardé/lu comme Double
        popupX = CGFloat(defaults.double(forKey: Keys.popupX) != 0 ? defaults.double(forKey: Keys.popupX) : defaultX)
        popupY = CGFloat(defaults.double(forKey: Keys.popupY) != 0 ? defaults.double(forKey: Keys.popupY) : defaultY)
        popupWidth = CGFloat(defaults.double(forKey: Keys.popupWidth) != 0 ? defaults.double(forKey: Keys.popupWidth) : defaultWidth)
        popupHeight = CGFloat(defaults.double(forKey: Keys.popupHeight) != 0 ? defaults.double(forKey: Keys.popupHeight) : defaultHeight)
        popupOpacity = defaults.object(forKey: Keys.popupOpacity) as? Double ?? 0.95
        popupDuration = defaults.object(forKey: Keys.popupDuration) as? Int ?? 5
        popupFontSize = CGFloat(defaults.double(forKey: Keys.popupFontSize) != 0 ? defaults.double(forKey: Keys.popupFontSize) : 14.0)

        // Paramètres des raccourcis
        if let data = defaults.data(forKey: Keys.shortcutOpenHistory),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            shortcutOpenHistory = shortcut
        } else {
            shortcutOpenHistory = .openHistory
        }

        if let data = defaults.data(forKey: Keys.shortcutFocusSearch),
           let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            shortcutFocusSearch = shortcut
        } else {
            shortcutFocusSearch = .focusSearch
        }

        // Paramètres de l'aperçu au survol (défaut: 300x250, 11pt)
        hoverPreviewWidth = CGFloat(defaults.double(forKey: Keys.hoverPreviewWidth) != 0 ? defaults.double(forKey: Keys.hoverPreviewWidth) : 300)
        hoverPreviewHeight = CGFloat(defaults.double(forKey: Keys.hoverPreviewHeight) != 0 ? defaults.double(forKey: Keys.hoverPreviewHeight) : 250)
        hoverPreviewFontSize = CGFloat(defaults.double(forKey: Keys.hoverPreviewFontSize) != 0 ? defaults.double(forKey: Keys.hoverPreviewFontSize) : 11.0)

        // Paramètres du menu déroulant (défaut: 360x500, 13pt)
        dropdownWidth = CGFloat(defaults.double(forKey: Keys.dropdownWidth) != 0 ? defaults.double(forKey: Keys.dropdownWidth) : 360)
        dropdownHeight = CGFloat(defaults.double(forKey: Keys.dropdownHeight) != 0 ? defaults.double(forKey: Keys.dropdownHeight) : 500)
        dropdownFontSize = CGFloat(defaults.double(forKey: Keys.dropdownFontSize) != 0 ? defaults.double(forKey: Keys.dropdownFontSize) : 13.0)
    }

    // MARK: - Methods

    /// Ajouter une application à la liste des exclusions
    func addExcludedApp(_ bundleId: String) {
        if !excludedApps.contains(bundleId) {
            excludedApps.append(bundleId)
        }
    }

    /// Retirer une application de la liste des exclusions
    func removeExcludedApp(_ bundleId: String) {
        excludedApps.removeAll { $0 == bundleId }
    }

    /// Vérifier si une application est exclue
    func isAppExcluded(_ bundleId: String) -> Bool {
        excludedApps.contains(bundleId)
    }

    /// Réinitialiser les paramètres
    func resetToDefaults() {
        launchAtLogin = false
        showUnreadBadge = true
        autoDeleteFromNotificationCenter = false
        deleteDelay = .fiveSeconds
        hoverPreviewMode = .unreadOnly
        retentionPeriod = .oneMonth
        excludedApps = []

        // Réinitialiser les paramètres du popup
        popupEnabled = true
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        popupWidth = 350
        popupHeight = 100
        popupX = screenFrame.maxX - popupWidth - 20
        popupY = screenFrame.maxY - popupHeight - 20
        popupOpacity = 0.95
        popupDuration = 5
        popupFontSize = 14

        // Réinitialiser les paramètres des raccourcis
        shortcutOpenHistory = .openHistory
        shortcutFocusSearch = .focusSearch

        // Réinitialiser les paramètres de l'aperçu au survol
        hoverPreviewWidth = 300
        hoverPreviewHeight = 250
        hoverPreviewFontSize = 11.0

        // Réinitialiser les paramètres du menu déroulant
        dropdownWidth = 360
        dropdownHeight = 500
        dropdownFontSize = 13.0
    }

    /// Obtenir le cadre actuel du popup
    var popupFrame: NSRect {
        NSRect(x: popupX, y: popupY, width: popupWidth, height: popupHeight)
    }

    /// Définir le cadre du popup
    func setPopupFrame(_ frame: NSRect) {
        popupX = frame.origin.x
        popupY = frame.origin.y
        popupWidth = frame.width
        popupHeight = frame.height
    }
}
