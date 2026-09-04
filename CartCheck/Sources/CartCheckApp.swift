import SwiftUI
import SwiftData
import CartCheckData

@main
struct CartCheckApp: App {
    private let dependencies: AppDependencies

    init() {
        let container = Self.makeModelContainer()
        let store = SwiftDataStore(modelContainer: container)
        dependencies = AppDependencies(
            tripStore: store,
            priceHistoryStore: store,
            receiptTextExtractor: VisionReceiptTextExtractor(),
            matcher: FoundationModelsCartMatcher()
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Schema(CartCheckSchema.models))
        } catch {
            // Persistence is core to the app, not an optional feature — if
            // the on-disk store can't be opened there's nothing usable to
            // fall back to.
            fatalError("Failed to create CartCheck's persistent store: \(error)")
        }
    }
}
