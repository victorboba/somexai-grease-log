import Foundation
import PDFKit
import UIKit

/// The document handed to a FOG inspector.
///
/// Leads with the status, because that is the thing being judged, then the service
/// history with hauler, permit and manifest number for each pump-out. An inspector is
/// checking that the cleanings happened, at the right interval, by a permitted hauler.
enum PDFExporter {
    static func export(_ traps: [Trap], siteName: String = "") throws -> URL {
        let pageWidth: CGFloat = 612, pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppConfig.exportFileStem)-\(ISO8601DateFormatter.day.string(from: .now)).pdf")

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = margin
            ctx.beginPage()

            func line(_ text: String, size: CGFloat = 11, weight: UIFont.Weight = .regular,
                      colour: UIColor = .label, indent: CGFloat = 0, gapAfter: CGFloat = 4) {
                let font = UIFont.systemFont(ofSize: size, weight: weight)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: colour]
                let width = pageWidth - margin * 2 - indent
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                if y + bounding.height > pageHeight - margin { ctx.beginPage(); y = margin }
                (text as NSString).draw(
                    with: CGRect(x: margin + indent, y: y, width: width, height: bounding.height),
                    options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
                y += bounding.height + gapAfter
            }

            func rule(gap: CGFloat = 10) {
                y += gap / 2
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.separator.setStroke(); path.lineWidth = 0.5; path.stroke()
                y += gap / 2
            }

            line("Grease trap service record", size: 22, weight: .semibold)
            if !siteName.isEmpty { line(siteName, size: 12, colour: .secondaryLabel) }
            line("Produced \(Date.now.formatted(date: .long, time: .omitted))",
                 size: 10, colour: .secondaryLabel)
            rule()

            for trap in traps.sorted(by: { $0.name < $1.name }) {
                let status = trap.status
                let colour: UIColor = status.isCitable ? .systemRed
                    : status == .dueSoon ? .systemOrange
                    : status == .current ? .systemGreen : .secondaryLabel

                line(trap.name.isEmpty ? "Unnamed trap" : trap.name, size: 14, weight: .semibold, gapAfter: 2)
                if !trap.location.isEmpty { line(trap.location, size: 10, colour: .secondaryLabel, gapAfter: 2) }
                line(status.headline.uppercased(), size: 11, weight: .bold, colour: colour, gapAfter: 2)
                line(status.detail, size: 10, colour: .secondaryLabel)

                line("\(trap.kind.name)  ·  \(Int(trap.capacityGallons)) gal  ·  cleaned every \(trap.requiredIntervalDays) days",
                     size: 10, colour: .secondaryLabel)
                if let fullness = trap.latestFullness {
                    line(String(format: "Last depth check: %.0f%% of liquid depth (quarter rule is 25%%)", fullness * 100),
                         size: 10, colour: fullness >= 0.25 ? .systemRed : .secondaryLabel)
                }

                y += 4
                if trap.sortedServices.isEmpty {
                    line("No services recorded.", size: 10, colour: .secondaryLabel, indent: 12)
                }
                for s in trap.sortedServices {
                    let gallons = s.gallonsRemoved > 0 ? String(format: "%.0f gal", s.gallonsRemoved) : "—"
                    line("\(ISO8601DateFormatter.day.string(from: s.date))   \(s.haulerName.isEmpty ? "hauler not recorded" : s.haulerName)   \(gallons)",
                         size: 10, indent: 12, gapAfter: 1)
                    var detail: [String] = []
                    if !s.haulerPermit.isEmpty { detail.append("permit \(s.haulerPermit)") }
                    if !s.manifestNumber.isEmpty { detail.append("manifest \(s.manifestNumber)") }
                    if !s.disposalSite.isEmpty { detail.append("to \(s.disposalSite)") }
                    if !detail.isEmpty {
                        line(detail.joined(separator: "  ·  "), size: 9, colour: .secondaryLabel, indent: 12, gapAfter: 5)
                    }
                }
                rule()
            }

            line("Records are kept by the food service establishment as required by the local fats, "
                 + "oils and grease programme. This document lists the services recorded in "
                 + "\(AppConfig.appName); the manifests themselves remain the authoritative record.",
                 size: 9, colour: .secondaryLabel)
        }
        return url
    }
}
