import Foundation
import GRDB

/// Modèle de données de notification
struct NotificationItem: Identifiable, Hashable {
    var id: String
    var appIdentifier: String
    var appName: String
    var title: String
    var body: String
    var subtitle: String?
    var timestamp: Date
    var isRead: Bool
    var threadIdentifier: String?
    var categoryIdentifier: String?
    var imageData: Data?  // Image de pochette, etc.

    init(
        id: String = UUID().uuidString,
        appIdentifier: String,
        appName: String,
        title: String,
        body: String,
        subtitle: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false,
        threadIdentifier: String? = nil,
        categoryIdentifier: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.appIdentifier = appIdentifier
        self.appName = appName
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.isRead = isRead
        self.threadIdentifier = threadIdentifier
        self.categoryIdentifier = categoryIdentifier
        self.imageData = imageData
    }
}

// MARK: - Codable with snake_case mapping

extension NotificationItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case appIdentifier = "app_identifier"
        case appName = "app_name"
        case title
        case body
        case subtitle
        case timestamp
        case isRead = "is_read"
        case threadIdentifier = "thread_identifier"
        case categoryIdentifier = "category_identifier"
        case imageData = "image_data"
    }
}

// MARK: - GRDB TableRecord & FetchableRecord

extension NotificationItem: TableRecord, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "notifications" }

    enum Columns: String, ColumnExpression {
        case id
        case appIdentifier = "app_identifier"
        case appName = "app_name"
        case title
        case body
        case subtitle
        case timestamp
        case isRead = "is_read"
        case threadIdentifier = "thread_identifier"
        case categoryIdentifier = "category_identifier"
        case imageData = "image_data"
    }
}

// MARK: - Convenience Properties

extension NotificationItem {
    /// Nom de l'icône d'application (SF Symbols)
    var appIconName: String {
        switch appIdentifier.lowercased() {
        case let id where id.contains("slack"):
            return "bubble.left.and.bubble.right.fill"
        case let id where id.contains("mail"):
            return "envelope.fill"
        case let id where id.contains("discord"):
            return "bubble.left.fill"
        case let id where id.contains("calendar"):
            return "calendar"
        case let id where id.contains("messages"):
            return "message.fill"
        case let id where id.contains("safari"):
            return "safari.fill"
        case let id where id.contains("finder"):
            return "folder.fill"
        default:
            return "app.fill"
        }
    }

    /// Couleur de l'application
    var appColor: String {
        switch appIdentifier.lowercased() {
        case let id where id.contains("slack"):
            return "purple"
        case let id where id.contains("mail"):
            return "blue"
        case let id where id.contains("discord"):
            return "indigo"
        case let id where id.contains("calendar"):
            return "red"
        case let id where id.contains("messages"):
            return "green"
        default:
            return "gray"
        }
    }

    /// Affichage de l'heure relative
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Affichage de l'heure (format HH:mm)
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    /// Affichage de la date
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")

        if Calendar.current.isDateInToday(timestamp) {
            return "Aujourd'hui"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Hier"
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: timestamp)
        }
    }

    /// Affichage de la date et heure (date + heure)
    var dateTimeString: String {
        return "\(dateString) \(timeString)"
    }
}

// MARK: - Sample Data

extension NotificationItem {
    static let samples: [NotificationItem] = [
        NotificationItem(
            appIdentifier: "com.tinyspeck.slackmacgap",
            appName: "Slack",
            title: "Jean Dupont",
            body: "Concernant la réunion, demain à 14h en salle B pour en discuter.",
            timestamp: Date().addingTimeInterval(-300)
        ),
        NotificationItem(
            appIdentifier: "com.apple.mail",
            appName: "Mail",
            title: "Amazon.fr",
            body: "Votre commande a été expédiée. Date de livraison prévue : 5 janvier",
            timestamp: Date().addingTimeInterval(-1200)
        ),
        NotificationItem(
            appIdentifier: "com.hnc.Discord",
            appName: "Discord",
            title: "#dev - Vibe Coding Server",
            body: "@user Merci de vérifier svp",
            timestamp: Date().addingTimeInterval(-2400)
        ),
        NotificationItem(
            appIdentifier: "com.apple.iCal",
            appName: "Calendar",
            title: "15:00 Réunion",
            body: "Lien Zoom : https://zoom.us/j/...",
            timestamp: Date().addingTimeInterval(-3600),
            isRead: true
        ),
        NotificationItem(
            appIdentifier: "com.tinyspeck.slackmacgap",
            appName: "Slack",
            title: "#general",
            body: "Vous avez un nouveau message",
            timestamp: Date().addingTimeInterval(-7200),
            isRead: true
        )
    ]
}
