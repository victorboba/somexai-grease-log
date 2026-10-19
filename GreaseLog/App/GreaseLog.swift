import SwiftUI
import SwiftData

@main
struct GreaseLog: App {
    @State private var entitlements = EntitlementStore()
    private let container: ModelContainer

    init() {
        let schema = Schema([Trap.self, ServiceRecord.self, DepthCheck.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: AppConfig.iCloudSyncEnabled ? .automatic : .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetData") {
            try? container.mainContext.delete(model: ServiceRecord.self)
            try? container.mainContext.delete(model: DepthCheck.self)
            try? container.mainContext.delete(model: Trap.self)
            try? container.mainContext.save()
        }
        if ProcessInfo.processInfo.arguments.contains("-sampleData"),
           (try? container.mainContext.fetchCount(FetchDescriptor<Trap>())) == 0 {
            SampleData.insert(into: container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlements)
        }
        .modelContainer(container)
    }
}
