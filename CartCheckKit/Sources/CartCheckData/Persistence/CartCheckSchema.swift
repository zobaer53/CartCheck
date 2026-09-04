import SwiftData

/// The full set of persisted model types, for building a `ModelContainer`
/// from the app target (or an in-memory one from tests).
public enum CartCheckSchema {
    public static let models: [any PersistentModel.Type] = [
        TripRecord.self,
        PriceHistoryRecord.self,
    ]
}
