import SwiftUI
import ServiceManagement

/// Écran des paramètres
struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var storageManager: StorageManager

    @State private var showingClearConfirmation = false
    @State private var showingAddAppSheet = false
    @State private var showingLoadTestConfirmation = false
    @State private var isLoadTestRunning = false
    @State private var loadTestError: String?
    @State private var loadTestCompleted = false

    // Taille de l'écran (pour le slider de position du popup)
    private var maxScreenX: CGFloat {
        (NSScreen.main?.frame.width ?? 1920) - settingsManager.popupWidth
    }
    private var maxScreenY: CGFloat {
        (NSScreen.main?.frame.height ?? 1080) - settingsManager.popupHeight
    }

    var body: some View {
        Form {
            // Général
            generalSection

            // Raccourcis clavier
            keyboardShortcutsSection

            // Centre de notifications
            notificationCenterSection

            // Aperçu au survol
            hoverPreviewSection

            // Menu déroulant
            dropdownSection

            // Popup personnalisé
            popupSection

            // Durée de conservation
            retentionSection

            // Applications exclues
            excludedAppsSection

            // Données
            dataSection

            // About
            aboutSection
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 800)
        .alert("Effacer l'historique", isPresented: $showingClearConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Effacer", role: .destructive) {
                try? storageManager.deleteAll()
            }
        } message: {
            Text("Supprimer tout l'historique des notifications. Cette action est irréversible.")
        }
        .alert("Test de charge", isPresented: $showingLoadTestConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Exécuter") {
                runLoadTest()
            }
        } message: {
            Text("Générer 1000 notifications de test. La taille de la base de données va augmenter. Continuer ?")
        }
        .alert("Test de charge terminé", isPresented: $loadTestCompleted) {
            Button("OK") {
                loadTestCompleted = false
                loadTestError = nil
            }
        } message: {
            if let error = loadTestError {
                Text("Une erreur s'est produite : \(error)")
            } else {
                Text("1000 notifications de test générées.")
            }
        }
        .sheet(isPresented: $showingAddAppSheet) {
            AddExcludedAppView(settingsManager: settingsManager)
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section("Général") {
            Toggle("Lancer à la connexion", isOn: $settingsManager.launchAtLogin)
                .onChange(of: settingsManager.launchAtLogin) { newValue in
                    updateLoginItem(enabled: newValue)
                }

            Toggle("Afficher le badge des non-lus dans la barre de menus", isOn: $settingsManager.showUnreadBadge)
        }
    }

    // MARK: - Raccourcis clavier

    private var keyboardShortcutsSection: some View {
        Section("Raccourcis clavier") {
            HStack {
                Text("Ouvrir la fenêtre d'historique")
                    .frame(width: 150, alignment: .leading)
                KeyRecorderView(shortcut: $settingsManager.shortcutOpenHistory)
            }

            HStack {
                Text("Focus sur le champ de recherche")
                    .frame(width: 150, alignment: .leading)
                KeyRecorderView(shortcut: $settingsManager.shortcutFocusSearch)
            }

            Text("Cliquez sur le bouton puis appuyez sur les touches pour modifier le raccourci.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Notification Center

    private var notificationCenterSection: some View {
        Section("Centre de notifications") {
            Toggle("Supprimer automatiquement du Centre de notifications après sauvegarde", isOn: $settingsManager.autoDeleteFromNotificationCenter)

            if settingsManager.autoDeleteFromNotificationCenter {
                Picker("Délai de suppression", selection: $settingsManager.deleteDelay) {
                    ForEach(SettingsManager.DeleteDelay.allCases, id: \.self) { delay in
                        Text(delay.displayName).tag(delay)
                    }
                }
                .pickerStyle(.radioGroup)
                .padding(.leading, 20)
            }
        }
    }

    // MARK: - Aperçu au survol

    private var hoverPreviewSection: some View {
        Section("Aperçu au survol") {
            Picker("Contenu affiché", selection: $settingsManager.hoverPreviewMode) {
                ForEach(SettingsManager.HoverPreviewMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            // Configuration de la taille
            VStack(alignment: .leading, spacing: 12) {
                Text("Taille")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Largeur
                HStack {
                    Text("Largeur:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.hoverPreviewWidth,
                        in: 200...1200,
                        step: 10
                    )
                    Text("\(Int(settingsManager.hoverPreviewWidth))px")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                // Hauteur
                HStack {
                    Text("Hauteur:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.hoverPreviewHeight,
                        in: 150...500,
                        step: 10
                    )
                    Text("\(Int(settingsManager.hoverPreviewHeight))px")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                // Taille de police
                HStack {
                    Text("Texte:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.hoverPreviewFontSize,
                        in: 8...30,
                        step: 1
                    )
                    Text("\(Int(settingsManager.hoverPreviewFontSize))pt")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Menu déroulant

    private var dropdownSection: some View {
        Section("Menu déroulant") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Taille")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Largeur
                HStack {
                    Text("Largeur:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.dropdownWidth,
                        in: 300...800,
                        step: 10
                    )
                    Text("\(Int(settingsManager.dropdownWidth))px")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                // Hauteur
                HStack {
                    Text("Hauteur:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.dropdownHeight,
                        in: 400...800,
                        step: 10
                    )
                    Text("\(Int(settingsManager.dropdownHeight))px")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                // Taille de police
                HStack {
                    Text("Texte:")
                        .frame(width: 60, alignment: .leading)
                    Slider(
                        value: $settingsManager.dropdownFontSize,
                        in: 8...30,
                        step: 1
                    )
                    Text("\(Int(settingsManager.dropdownFontSize))pt")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Popup personnalisé

    @ViewBuilder
    private var popupSection: some View {
        Section("Popup personnalisé") {
            Toggle("Afficher les notifications popup", isOn: $settingsManager.popupEnabled)

            if settingsManager.popupEnabled {
                // Durée d'affichage
                HStack {
                    Text("Durée:")
                    Stepper(
                        value: $settingsManager.popupDuration,
                        in: 0...30,
                        step: 1
                    ) {
                        Text(settingsManager.popupDuration == 0 ? "Ne disparaît pas" : "\(settingsManager.popupDuration) sec")
                            .frame(width: 60)
                    }
                }

                // Opacité
                HStack {
                    Text("Opacité:")
                    Slider(value: $settingsManager.popupOpacity, in: 0.3...1.0, step: 0.05)
                    Text("\(Int(settingsManager.popupOpacity * 100))%")
                        .frame(width: 40)
                }

                // Taille de police
                HStack {
                    Text("Taille du texte:")
                    Slider(value: $settingsManager.popupFontSize, in: 10...30, step: 1)
                    Text("\(Int(settingsManager.popupFontSize))pt")
                        .frame(width: 40)
                }

                // Taille (compatible 4K)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Largeur:")
                            .frame(width: 40, alignment: .leading)
                        Slider(value: $settingsManager.popupWidth, in: 200...1200, step: 10)
                        Text("\(Int(settingsManager.popupWidth))")
                            .frame(width: 50)
                    }
                    HStack {
                        Text("Hauteur:")
                            .frame(width: 40, alignment: .leading)
                        Slider(value: $settingsManager.popupHeight, in: 60...400, step: 10)
                        Text("\(Int(settingsManager.popupHeight))")
                            .frame(width: 50)
                    }
                }

                // Position
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("X:")
                            .frame(width: 40, alignment: .leading)
                        Slider(value: $settingsManager.popupX, in: 0...maxScreenX, step: 10)
                        Text("\(Int(settingsManager.popupX))")
                            .frame(width: 50)
                    }
                    HStack {
                        Text("Y:")
                            .frame(width: 40, alignment: .leading)
                        Slider(value: $settingsManager.popupY, in: 0...maxScreenY, step: 10)
                        Text("\(Int(settingsManager.popupY))")
                            .frame(width: 50)
                    }
                }

                // Boutons Test/Prévisualisation
                HStack {
                    Button("Afficher l'aperçu") {
                        NotificationPopupController.shared.showPreview()
                    }

                    Button("Notification de test") {
                        sendTestNotification()
                    }
                }
            }
        }
    }

    // MARK: - Durée de conservation

    private var retentionSection: some View {
        Section("Durée de conservation") {
            Picker("Durée de conservation", selection: $settingsManager.retentionPeriod) {
                ForEach(SettingsManager.RetentionPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }

    // MARK: - Applications exclues

    private var excludedAppsSection: some View {
        Section("Applications exclues") {
            Text("Applications dont les notifications ne sont pas sauvegardées:")
                .font(.caption)
                .foregroundColor(.secondary)

            if settingsManager.excludedApps.isEmpty {
                Text("Aucune")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(settingsManager.excludedApps, id: \.self) { bundleId in
                    HStack {
                        Text(getAppName(for: bundleId))

                        Spacer()

                        Button(action: {
                            settingsManager.removeExcludedApp(bundleId)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(action: { showingAddAppSheet = true }) {
                Label("Ajouter une application", systemImage: "plus")
            }
        }
    }

    // MARK: - Données

    private var dataSection: some View {
        Section("Données") {
            HStack {
                Text("Notifications sauvegardées:")
                Spacer()
                Text("\(storageManager.storageInfo.count) notif.")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Stockage:")
                Spacer()
                Text(storageManager.storageInfo.sizeString)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("Effacer l'historique") {
                    showingClearConfirmation = true
                }

                Spacer()

                Menu("Exporter") {
                    Button("JSON") { exportJSON() }
                    Button("CSV") { exportCSV() }
                }
            }

            Divider()

            // Bouton de test de charge
            HStack {
                Button("Test de charge (1000)") {
                    showingLoadTestConfirmation = true
                }
                .help("Génère 1000 notifications de test")

                Spacer()

                if isLoadTestRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            VStack(spacing: 12) {
                // Nom de l'app et version
                VStack(spacing: 4) {
                    Text("Notipon")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Version \(AppConstants.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                Divider()

                // Lien GitHub
                Button(action: {
                    NSWorkspace.shared.open(AppConstants.githubURL)
                }) {
                    HStack {
                        Image(systemName: "arrow.up.forward.square")
                        Text("Dépôt GitHub")
                    }
                    .frame(maxWidth: .infinity)
                }

                // Buy Me a Coffee
                Button(action: {
                    NSWorkspace.shared.open(AppConstants.buyMeCoffeeURL)
                }) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                        Text("Buy Me a Coffee")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Divider()

                // Informations de licence
                VStack(alignment: .leading, spacing: 4) {
                    Text("Licence")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text(AppConstants.licenseText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Helper Methods

    private func runLoadTest() {
        isLoadTestRunning = true
        loadTestError = nil

        // Exécution en arrière-plan
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try storageManager.generateTestNotifications(count: 1000)

                DispatchQueue.main.async {
                    isLoadTestRunning = false
                    loadTestCompleted = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoadTestRunning = false
                    loadTestError = error.localizedDescription
                    loadTestCompleted = true
                }
            }
        }
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Erreur de l'élément de connexion : \(error)")
        }
    }

    private func getAppName(for bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return bundleId
    }

    private func exportJSON() {
        guard let data = storageManager.exportAsJSON() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "notifications.json"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func exportCSV() {
        let csv = storageManager.exportAsCSV()

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "notifications.csv"

        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func sendTestNotification() {
        let testNotification = NotificationItem(
            appIdentifier: "com.mugendesk.Notipon",
            appName: "Notipon",
            title: "Notification de test",
            body: "Ceci est une notification de test. Vérifiez la position et la taille.",
            timestamp: Date()
        )
        NotificationPopupController.shared.show(testNotification)
    }
}

// MARK: - Vue d'ajout d'application exclue

struct AddExcludedAppView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss

    @State private var runningApps: [(name: String, bundleId: String)] = []

    var body: some View {
        VStack(spacing: 0) {
            Text("Sélectionner une application à exclure")
                .font(.headline)
                .padding()

            Divider()

            List(runningApps, id: \.bundleId) { app in
                Button(action: {
                    settingsManager.addExcludedApp(app.bundleId)
                    dismiss()
                }) {
                    HStack {
                        Text(app.name)
                        Spacer()
                        if settingsManager.isAppExcluded(app.bundleId) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(height: 300)

            Divider()

            HStack {
                Spacer()
                Button("Annuler") {
                    dismiss()
                }
            }
            .padding()
        }
        .frame(width: 350)
        .onAppear {
            loadRunningApps()
        }
    }

    private func loadRunningApps() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (name: String, bundleId: String)? in
                guard let name = app.localizedName,
                      let bundleId = app.bundleIdentifier else { return nil }
                return (name, bundleId)
            }
            .sorted { $0.name < $1.name }

        runningApps = apps
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(StorageManager.shared)
}
