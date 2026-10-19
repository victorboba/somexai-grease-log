import Foundation
import SwiftData

/// Debug fixtures. One trap current, one due soon, one over the quarter rule — because
/// a screenshot of three green ticks says nothing about what the app is for.
enum SampleData {
    static func insert(into context: ModelContext) {
        func trap(_ name: String, _ location: String, _ kind: TrapKind,
                  capacity: Double, depth: Double, interval: Int) -> Trap {
            let t = Trap(name: name, location: location)
            t.kind = kind; t.capacityGallons = capacity
            t.liquidDepthInches = depth; t.requiredIntervalDays = interval
            context.insert(t)
            return t
        }
        func service(_ t: Trap, daysAgo: Int, hauler: String, gallons: Double, manifest: String) {
            let s = ServiceRecord(date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now)
            s.haulerName = hauler; s.gallonsRemoved = gallons; s.manifestNumber = manifest
            s.haulerPermit = "TX-FOG-4471"; s.disposalSite = "Cedar Bayou rendering"
            s.trap = t
            context.insert(s)
        }
        func check(_ t: Trap, daysAgo: Int, grease: Double, solids: Double) {
            let c = DepthCheck(date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now)
            c.greaseInches = grease; c.solidsInches = solids; c.checkedBy = "M. Alvarez"
            c.trap = t
            context.insert(c)
        }

        let dish = trap("Dish pit trap", "Kitchen, under the three-bay", .indoorTrap,
                        capacity: 50, depth: 24, interval: 30)
        service(dish, daysAgo: 8, hauler: "Bayou Grease Services", gallons: 45, manifest: "BG-88214")
        check(dish, daysAgo: 2, grease: 3.0, solids: 1.5)

        let lot = trap("Back lot interceptor", "Alley, behind the walk-in", .outdoorInterceptor,
                       capacity: 1000, depth: 48, interval: 90)
        service(lot, daysAgo: 82, hauler: "Bayou Grease Services", gallons: 940, manifest: "BG-87003")
        check(lot, daysAgo: 5, grease: 7.5, solids: 3.0)

        let prep = trap("Prep line trap", "Prep kitchen", .indoorTrap,
                        capacity: 35, depth: 20, interval: 30)
        service(prep, daysAgo: 46, hauler: "Gulf Coast Pumping", gallons: 30, manifest: "GC-1192")
        check(prep, daysAgo: 1, grease: 4.5, solids: 1.0)

        try? context.save()
    }
}
