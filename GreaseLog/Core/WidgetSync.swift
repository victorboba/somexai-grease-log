import Foundation
import WidgetKit

enum WidgetSync {
    /// The widget answers one question: is anything going to get us cited today.
    static func update(with traps: [Trap]) {
        var snapshot = WidgetSnapshot()
        snapshot.totalEntries = traps.count
        snapshot.unfinished = traps.filter { $0.status.isCitable }.count
        let soonest = traps.compactMap { $0.nextDue }.min()
        snapshot.lastEntryTitle = traps.first(where: { $0.status.isCitable })?.name
        snapshot.lastEntryDate = soonest
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
