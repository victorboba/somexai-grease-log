import Testing
import Foundation
import PDFKit
@testable import GreaseLog

/// The quarter rule is the thing an inspector measures, and it is independent of the
/// calendar: a trap can be well inside its ninety days and still be citable.
struct QuarterRuleTests {
    private func trap(depth: Double, grease: Double, solids: Double,
                      lastServiceDaysAgo: Int? = 5, interval: Int = 90) -> Trap {
        let t = Trap(name: "Test", location: "Kitchen")
        t.liquidDepthInches = depth
        t.requiredIntervalDays = interval
        if let days = lastServiceDaysAgo {
            let s = ServiceRecord(date: Calendar.current.date(byAdding: .day, value: -days, to: .now)!)
            s.trap = t
            t.services = [s]
        }
        let c = DepthCheck(date: .now)
        c.greaseInches = grease
        c.solidsInches = solids
        c.trap = t
        t.checks = [c]
        return t
    }

    @Test func fullnessAddsGreaseAndSolids() {
        let t = trap(depth: 24, grease: 3, solids: 1.5)
        #expect(t.latestFullness == 4.5 / 24)
    }

    @Test func aTrapInsideItsIntervalCanStillBeOverTheRule() {
        // Serviced five days ago on a ninety day interval, so the calendar says fine.
        let t = trap(depth: 20, grease: 4.5, solids: 1.0)
        #expect((t.daysUntilDue() ?? 0) > 0)
        #expect(t.status == .overQuarterRule, "the rule outranks the calendar")
        #expect(t.status.isCitable)
    }

    @Test func exactlyAQuarterCounts() {
        let t = trap(depth: 20, grease: 5, solids: 0)
        #expect(t.status == .overQuarterRule, "25% is the threshold, not a value to exceed")
    }

    @Test func justUnderAQuarterIsCurrent() {
        let t = trap(depth: 20, grease: 4.9, solids: 0)
        #expect(t.status == .current)
    }

    @Test func withoutALiquidDepthThereIsNoPercentageToReport() {
        let t = trap(depth: 0, grease: 4, solids: 2)
        #expect(t.latestFullness == nil, "guessing a depth would invent a compliance figure")
        #expect(t.status == .current)
    }
}

struct IntervalTests {
    private func trap(lastServiceDaysAgo: Int?, interval: Int) -> Trap {
        let t = Trap(name: "Test")
        t.requiredIntervalDays = interval
        if let days = lastServiceDaysAgo {
            let s = ServiceRecord(date: Calendar.current.date(byAdding: .day, value: -days, to: .now)!)
            s.trap = t
            t.services = [s]
        }
        return t
    }

    @Test func noServiceMeansNoHistoryRatherThanOverdue() {
        #expect(trap(lastServiceDaysAgo: nil, interval: 90).status == .noHistory)
    }

    @Test func pastTheIntervalIsOverdueAndCitable() {
        let t = trap(lastServiceDaysAgo: 95, interval: 90)
        #expect(t.status == .overdue)
        #expect(t.status.isCitable)
        #expect((t.daysUntilDue() ?? 0) < 0)
    }

    @Test func theFinalTwoWeeksReadAsDueSoon() {
        #expect(trap(lastServiceDaysAgo: 80, interval: 90).status == .dueSoon)
        #expect(trap(lastServiceDaysAgo: 70, interval: 90).status == .current)
    }

    @Test func dueSoonIsNotCitable() {
        #expect(trap(lastServiceDaysAgo: 80, interval: 90).status.isCitable == false)
    }
}

struct RecordTests {
    private func loadedTrap() -> Trap {
        let t = Trap(name: "Back lot interceptor", location: "Alley")
        t.kind = .outdoorInterceptor
        t.capacityGallons = 1000
        t.liquidDepthInches = 48
        t.requiredIntervalDays = 90
        let s = ServiceRecord(date: Calendar.current.date(byAdding: .day, value: -100, to: .now)!)
        s.haulerName = "Bayou Grease Services"
        s.haulerPermit = "TX-FOG-4471"
        s.manifestNumber = "BG-87003"
        s.gallonsRemoved = 940
        s.disposalSite = "Cedar Bayou rendering"
        s.trap = t
        t.services = [s]
        return t
    }

    @Test func thePDFLeadsWithTheStatusAndCarriesTheManifest() throws {
        let url = try PDFExporter.export([loadedTrap()], siteName: "Pelican Diner")
        let document = try #require(PDFDocument(url: url))
        let text = (document.string ?? "")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        #expect(text.contains("OVERDUE"))
        #expect(text.contains("Pelican Diner"))
        #expect(text.contains("Bayou Grease Services"))
        #expect(text.contains("BG-87003"), "the manifest number is the point of the record")
        #expect(text.contains("TX-FOG-4471"), "so is the hauler's permit")
        try? FileManager.default.removeItem(at: url)
    }

    @Test func csvIsOneRowPerService() throws {
        let url = try CSVExporter.export([loadedTrap()])
        let text = try String(contentsOf: url, encoding: .utf8)
        let lines = text.split(separator: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].hasPrefix("trap,location,kind"))
        #expect(text.contains("BG-87003"))
        try? FileManager.default.removeItem(at: url)
    }

    @Test func aTrapWithNoServicesStillAppearsInTheCSV() throws {
        let url = try CSVExporter.export([Trap(name: "Never serviced")])
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("Never serviced"), "an empty record is itself the finding")
        try? FileManager.default.removeItem(at: url)
    }
}
