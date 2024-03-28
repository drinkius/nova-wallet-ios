import Foundation

extension CloudBackup {
    struct Available: Equatable {
        static func == (lhs: CloudBackup.Available, rhs: CloudBackup.Available) -> Bool {
            lhs.cloudId.equals(to: rhs.cloudId) && (lhs.hasStorage == rhs.hasStorage)
        }

        let cloudId: CloudIdentifiable
        let hasStorage: Bool
    }

    enum Availability: Equatable {
        case notDetermined
        case unavailable
        case available(Available)
    }
}
