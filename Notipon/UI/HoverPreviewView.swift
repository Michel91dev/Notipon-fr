import SwiftUI

/// Aperçu au survol (affichage léger)
struct HoverPreviewView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var settingsManager: SettingsManager

    private var notifications: [NotificationItem] {
        switch settingsManager.hoverPreviewMode {
        case .recentFive:
            return storageManager.fetchRecent(count: 5)
        case .unreadOnly:
            let unread = storageManager.fetchUnread()
            return Array(unread.prefix(5))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if notifications.isEmpty {
                emptyView
            } else {
                notificationList
            }
        }
        .frame(width: settingsManager.hoverPreviewWidth)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.slash")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(settingsManager.hoverPreviewMode == .unreadOnly ? "Aucune notification non lue" : "Aucune notification")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
    }

    private var notificationList: some View {
        VStack(spacing: 0) {
            ForEach(notifications) { notification in
                HoverPreviewRow(notification: notification)
                    .onTapGesture {
                        try? storageManager.markAsRead(notification.id)
                    }
                    .contextMenu {
                        Button(action: { openApp(notification) }) {
                            Label("Ouvrir l'application", systemImage: "arrow.up.forward.app")
                        }

                        Button(action: { try? storageManager.markAsRead(notification.id) }) {
                            Label("Marquer comme lu", systemImage: "checkmark.circle")
                        }

                        Divider()

                        Button(role: .destructive, action: { try? storageManager.delete(notification.id) }) {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }

                if notification.id != notifications.last?.id {
                    Divider()
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func openApp(_ notification: NotificationItem) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: notification.appIdentifier) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Ligne d'aperçu au survol

struct HoverPreviewRow: View {
    let notification: NotificationItem
    @EnvironmentObject var settingsManager: SettingsManager

    private var iconSize: CGFloat {
        // Ajuster la taille de l'icône selon la taille de police (1.8x)
        settingsManager.hoverPreviewFontSize * 1.8
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Icône de l'application
            AppIconView(bundleIdentifier: notification.appIdentifier, size: iconSize)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    // Nom de l'application
                    Text(notification.appName)
                        .font(.system(size: settingsManager.hoverPreviewFontSize))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Heure
                    Text(notification.timeString)
                        .font(.system(size: settingsManager.hoverPreviewFontSize))
                        .foregroundColor(.secondary)
                }

                // Titre/Contenu
                Text(notification.title.isEmpty ? notification.body : notification.title)
                    .font(.system(size: settingsManager.hoverPreviewFontSize))
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    HoverPreviewView()
        .environmentObject(StorageManager.shared)
        .environmentObject(SettingsManager.shared)
}
