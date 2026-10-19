import Foundation
import SwiftData

/// One grease trap or interceptor at one site.
///
/// Shaped around municipal FOG (fats, oils and grease) programmes, which is who actually
/// turns up asking. Almost every one of them requires two things: that the device is
/// cleaned before the accumulated grease and solids reach a quarter of the liquid depth,
/// and that the manifests proving it are kept on site.
@Model
final class Trap {
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    var kindRaw: String = TrapKind.indoorTrap.rawValue
    var capacityGallons: Double = 0
    /// Total liquid depth in inches, which the quarter rule is measured against.
    var liquidDepthInches: Double = 0
    /// What the local programme requires, in days. Ninety is the most common.
    var requiredIntervalDays: Int = 90
    var permitNumber: String = ""
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.trap)
    var services: [ServiceRecord]? = nil

    @Relationship(deleteRule: .cascade, inverse: \DepthCheck.trap)
    var checks: [DepthCheck]? = nil

    var createdAt: Date = Date()

    init(name: String = "", location: String = "") {
        self.id = UUID()
        self.name = name
        self.location = location
        self.createdAt = .now
    }

    var kind: TrapKind {
        get { TrapKind(rawValue: kindRaw) ?? .indoorTrap }
        set { kindRaw = newValue.rawValue }
    }

    var sortedServices: [ServiceRecord] {
        (services ?? []).sorted { $0.date > $1.date }
    }

    var sortedChecks: [DepthCheck] {
        (checks ?? []).sorted { $0.date > $1.date }
    }

    var lastService: ServiceRecord? { sortedServices.first }

    /// When the next pump-out is due, by the interval alone.
    var nextDue: Date? {
        guard let last = lastService else { return nil }
        return Calendar.current.date(byAdding: .day, value: requiredIntervalDays, to: last.date)
    }

    func daysUntilDue(asOf today: Date = .now) -> Int? {
        guard let due = nextDue else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: today),
            to: Calendar.current.startOfDay(for: due)
        ).day
    }

    /// The quarter rule: clean before grease and solids reach 25% of liquid depth.
    /// Reported separately from the interval, because a trap can be well inside its
    /// ninety days and still be over the line — and it is the line an inspector measures.
    var latestFullness: Double? {
        guard liquidDepthInches > 0, let check = sortedChecks.first else { return nil }
        return (check.greaseInches + check.solidsInches) / liquidDepthInches
    }

    var status: TrapStatus {
        if let fullness = latestFullness, fullness >= 0.25 { return .overQuarterRule }
        guard let days = daysUntilDue() else { return .noHistory }
        if days < 0 { return .overdue }
        if days <= 14 { return .dueSoon }
        return .current
    }
}

/// One pump-out, and the manifest that proves it happened.
@Model
final class ServiceRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var haulerName: String = ""
    var haulerPermit: String = ""
    var manifestNumber: String = ""
    var gallonsRemoved: Double = 0
    var disposalSite: String = ""
    var technician: String = ""
    var notes: String = ""
    /// A photograph of the paper manifest, which is what an inspector asks to see.
    @Attribute(.externalStorage) var manifestPhoto: Data? = nil
    var trap: Trap? = nil

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
    }

    var day: Date { Calendar.current.startOfDay(for: date) }
}

/// A measurement taken to answer the quarter rule.
@Model
final class DepthCheck {
    var id: UUID = UUID()
    var date: Date = Date()
    var greaseInches: Double = 0
    var solidsInches: Double = 0
    var checkedBy: String = ""
    var notes: String = ""
    var trap: Trap? = nil

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
    }
}

enum TrapKind: String, CaseIterable, Identifiable {
    case indoorTrap, outdoorInterceptor, automaticUnit
    var id: String { rawValue }

    var name: String {
        switch self {
        case .indoorTrap: return "Indoor grease trap"
        case .outdoorInterceptor: return "Outdoor interceptor"
        case .automaticUnit: return "Automatic grease removal unit"
        }
    }

    var hint: String {
        switch self {
        case .indoorTrap: return "Under a sink or in the floor. Usually small, cleaned often."
        case .outdoorInterceptor: return "In-ground concrete tank, pumped by a hauler."
        case .automaticUnit: return "Skims continuously; still needs servicing and records."
        }
    }
}

enum TrapStatus {
    case noHistory, current, dueSoon, overdue, overQuarterRule

    var headline: String {
        switch self {
        case .noHistory: return "No service recorded"
        case .current: return "Current"
        case .dueSoon: return "Due soon"
        case .overdue: return "Overdue"
        case .overQuarterRule: return "Over the quarter rule"
        }
    }

    var detail: String {
        switch self {
        case .noHistory: return "Add the last pump-out so the next one can be tracked."
        case .current: return "Serviced within the required interval."
        case .dueSoon: return "Book the hauler before the interval runs out."
        case .overdue: return "Past the required interval. This is what a FOG inspection cites."
        case .overQuarterRule:
            return "Grease and solids have reached a quarter of the liquid depth. Most programmes require cleaning at this point regardless of the date."
        }
    }

    var symbol: String {
        switch self {
        case .noHistory: return "questionmark.circle"
        case .current: return "checkmark.seal.fill"
        case .dueSoon: return "clock.badge.exclamationmark"
        case .overdue: return "exclamationmark.triangle.fill"
        case .overQuarterRule: return "exclamationmark.octagon.fill"
        }
    }

    /// Anything an inspector would write up.
    var isCitable: Bool {
        self == .overdue || self == .overQuarterRule
    }
}
