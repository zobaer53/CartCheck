#if DEBUG
import Foundation
import CartCheckDomain

/// In-memory stand-ins for SwiftUI previews, so canvas rendering never
/// touches a real SwiftData container or the on-device language model.

final class PreviewTripStore: TripStore, @unchecked Sendable {
    private var trips: [UUID: Trip] = [:]
    func save(_ trip: Trip) async throws { trips[trip.id] = trip }
    func fetchAll() async throws -> [Trip] { Array(trips.values) }
    func fetch(id: UUID) async throws -> Trip? { trips[id] }
    func delete(id: UUID) async throws { trips.removeValue(forKey: id) }
}

final class PreviewPriceHistoryStore: PriceHistoryStore, @unchecked Sendable {
    private var entries: [PriceHistoryEntry] = []
    func record(_ entry: PriceHistoryEntry) async throws { entries.append(entry) }
    func history(forItemKey key: String, store: String?) async throws -> [PriceHistoryEntry] {
        entries.filter { $0.itemKey == key && $0.store == store }
    }
}

struct PreviewReceiptTextExtractor: ReceiptTextExtracting {
    func extractLines(fromReceiptImageData data: Data) async throws -> [ReceiptLine] { [] }
}

struct PreviewCartReceiptMatcher: CartReceiptMatching {
    func match(cartItems: [CartItem], receiptLines: [ReceiptLine], priceHistory: [PriceHistoryEntry]) async throws -> [ProposedMatch] {
        []
    }
}
#endif
