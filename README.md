# Grease Trap Log

A record of every grease trap on a restaurant site, when it was last pumped, and the manifests that prove it. It is for restaurant managers who need the paperwork ready when a city inspector asks.

One of a set of niche iPhone apps built from a shared SwiftUI template. It was never released on the App Store; the code is here for anyone to use. The template is [somexai-ios-template](https://github.com/victorboba/somexai-ios-template) and the collection is [somexai-ios-apps](https://github.com/victorboba/somexai-ios-apps).

## What it does

- Lists every trap on the site, ordered by trouble rather than by name.
- Tracks two independent tests: the required pump-out interval (often 90 days) and the quarter rule, which says clean once grease and solids reach 25% of the liquid depth. A trap can be inside its interval and still over the line, and the rule outranks the calendar.
- Records manifests: date, hauler, hauler permit, manifest number, gallons and disposal site, with a photo of the paper manifest.
- Records depth checks in inches, converted to a percentage only when the trap's liquid depth is known. It does not invent a figure from a guessed depth.
- Exports a PDF per trap or for the whole site, and a CSV with one row per service.
- Includes a Home Screen widget, a Siri App Shortcut and a step-by-step How-to guide.

## The boundary

The app records what was done. It does not certify compliance and does not know any city's ordinance; you enter the interval your program requires. The manifests themselves remain the authoritative record.

## Privacy

Data stays on the device in SwiftData. There is no account, no analytics and no network access, and iCloud sync is off (`iCloudSyncEnabled = false`). Nothing leaves the phone unless you export a PDF or CSV and share it yourself.

## Build and run

- Requirements: Xcode 26 or later, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), iOS 17 or later.
- Run `xcodegen generate`, open `GreaseLog.xcodeproj`, pick the `GreaseLog` scheme and an iPhone simulator, and Run.
- Tests: `xcodebuild -scheme GreaseLog -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test`.
- Paywall: the app has a hard paywall (annual subscription or lifetime purchase). Running from Xcode uses the bundled `Products.storekit` file, so purchases are simulated and free. Debug builds can also skip it with the `-unlock` launch argument or the Debug switch in Settings.
- To run on your own device or ship it: set your team in `project.yml` (`DEVELOPMENT_TEAM`), change the `com.example` bundle ID prefix in `project.yml`, both `.entitlements` files and `Products.storekit`, and update `supportEmail`, `privacyPolicyURL` and `appStoreID` in `Shared/AppConfig.swift`.

## Project layout

- `GreaseLog/App/`, `GreaseLog/Core/`: app entry and root gate, StoreKit entitlement, export, review prompt, App Shortcut, widget sync.
- `GreaseLog/Features/`: the screens.
- `GreaseLog/Models/`: SwiftData models.
- `GreaseLogWidget/`: the Home Screen widget, fed from a snapshot in the App Group.
- `Shared/AppConfig.swift`: everything that changes per app (name, copy, product IDs, links, How-to guide, disclaimer).
- `GreaseLogTests/`, `GreaseLogUITests/`: unit and UI tests.
- `scripts/`, `docs/`: icon and screenshot helpers, capability notes.

## License

MIT. See [LICENSE](LICENSE).
