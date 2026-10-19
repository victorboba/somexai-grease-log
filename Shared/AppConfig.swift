import Foundation

/// The one file to edit when starting a new app from this template.
/// Everything user-facing that changes per app (name, copy, product IDs, links) lives here.
/// Compiled into both the app and the widget, so keep it free of UIKit/SwiftUI imports.
enum AppConfig {
    // MARK: Identity
    static let appName = "Grease Trap Log"
    static let bundleID = "com.example.grease-log"
    static let appGroupID = "group.com.example.grease-log"
    /// Your App Store ID once the app is live. The Rate button stays hidden while it is empty.(the number in the App Store URL).
    static let appStoreID = ""

    // MARK: Sync
    /// Set to true only after enabling iCloud + CloudKit on the App ID (see docs/capabilities.md).
    /// With false, SwiftData stores locally and the app works with no Apple capabilities at all.
    static let iCloudSyncEnabled = false

    // MARK: StoreKit (must match App Store Connect and StoreKit/Products.storekit)
    /// Apple allows only letters, digits, underscores and periods in product IDs, so hyphens in the bundle ID are dropped.
    static let productPrefix = bundleID.replacingOccurrences(of: "-", with: "")
    static let annualProductID = "\(productPrefix).pro.annual"
    static let lifetimeProductID = "\(productPrefix).pro.lifetime"

    // MARK: Links
    static let supportEmail = "support@somexai.com"
    /// Hosted copy of PrivacyPolicyView, one page per app under somexai.com/privacy (somexai_corp repo, scripts/privacy.py).
    static let privacyPolicyURL = URL(string: "https://somexai.com/privacy/grease-log/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // MARK: Copy
    /// What the app calls one record. "Entry" for a generic log; "Dose", "Visit", "Inspection" in real apps.
    static let entryNoun = "Service"
    static let entryNounPlural = "Services"
    /// File name stem for exports: "grease-log-2026-09-11.csv".
    static let exportFileStem = "grease-log"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "drop.triangle", title: "Every trap, one list",
                       body: "Add each trap and interceptor once. The app tracks when the next pump-out is due against your local interval."),
        OnboardingPage(symbol: "ruler", title: "The quarter rule, not just the calendar",
                       body: "Record a depth check and the app works out whether grease and solids have reached a quarter of the liquid depth — the line an inspector actually measures."),
        OnboardingPage(symbol: "doc.text.magnifyingglass", title: "Ready when they walk in",
                       body: "Manifests, haulers and gallons in one PDF. Hand it over instead of hunting through a drawer."),
    ]

    static let paywallSymbol = "checkmark.seal.fill"
    static let paywallHeadline = "Unlock \(appName)"
    static let paywallBenefits = [
        "Unlimited traps, sites and service records",
        "Manifest photos kept with each pump-out",
        "Inspection-ready PDF and CSV",
        "No ads, no account, no tracking",
    ]

    // MARK: How-to guide (Settings → How do I use this app; also the ? button on the home screen)
    static let howToIntro = "Set up once, then a minute per pump-out. The point is that the record is already there when an inspector asks."
    static let howTo: [HowToStep] = [
        HowToStep(symbol: "plus.circle", title: "Add each trap",
                  body: "Name it the way your staff refer to it — Dish pit trap, Back lot interceptor. Set the capacity, the liquid depth in inches, and the interval your city requires. Ninety days is the most common."),
        HowToStep(symbol: "doc.on.clipboard", title: "Record every pump-out",
                  body: "After the hauler leaves, tap the trap and add a service: date, hauler, permit number, manifest number and gallons. Photograph the paper manifest — that is what an inspector asks to see."),
        HowToStep(symbol: "ruler", title: "Check the depth between visits",
                  body: "Measure grease and solids in inches and add a depth check. If the two together reach a quarter of the liquid depth, the app says so, because most programmes require cleaning at that point whatever the calendar says."),
        HowToStep(symbol: "square.and.arrow.up", title: "Hand over the record",
                  body: "Export a PDF for one trap or CSV for everything. It lists each service with its hauler, manifest number and gallons, and states the required interval."),
    ]

    /// Display prices used only by DEBUG screenshot runs (`-mockPrices`). Keep in sync with StoreKit/Products.storekit.
    static let mockPrices = (annual: "$19.99", lifetime: "$49.99")

    // MARK: Behaviour
    /// Ask for an App Store review after this many successful saves (once per app version).
    static let reviewAfterSuccesses = 3
}

struct HowToStep: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
    var tip: String? = nil
}

struct OnboardingPage: Identifiable, Hashable {
    var id: String { title }
    let symbol: String
    let title: String
    let body: String
}
