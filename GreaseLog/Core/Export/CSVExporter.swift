import Foundation

/// One row per service, because that is what a FOG inspector counts.
enum CSVExporter {
    static func export(_ traps: [Trap]) throws -> URL {
        var rows = ["trap,location,kind,capacity_gallons,required_interval_days,service_date,hauler,hauler_permit,manifest,gallons_removed,disposal_site,notes"]
        for trap in traps.sorted(by: { $0.name < $1.name }) {
            let head = [trap.name, trap.location, trap.kind.name,
                        String(trap.capacityGallons), String(trap.requiredIntervalDays)]
            if trap.sortedServices.isEmpty {
                rows.append((head + Array(repeating: "", count: 7)).map(escape).joined(separator: ","))
            }
            for s in trap.sortedServices {
                rows.append((head + [
                    ISO8601DateFormatter.day.string(from: s.date),
                    s.haulerName, s.haulerPermit, s.manifestNumber,
                    String(s.gallonsRemoved), s.disposalSite, s.notes,
                ]).map(escape).joined(separator: ","))
            }
        }
        let text = rows.joined(separator: "\n") + "\n"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(ISO8601DateFormatter.day.string(from: .now)).csv")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ value: String) -> String {
        value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" })
            ? "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
            : value
    }
}

extension ISO8601DateFormatter {
    static let day: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
