import Foundation
@testable import CartCheckDomain

actor InMemoryPriceHistoryStore: PriceHistoryStore {
    private var entries: [PriceHistoryEntry] = []

    func record(_ entry: PriceHistoryEntry) async throws {
        entries.append(entry)
    }

    func history(forItemKey key: String, store: String?) async throws -> [PriceHistoryEntry] {
        entries.filter { $0.itemKey == key && $0.store == store }
    }
}

actor InMemoryTripStore: TripStore {
    private var trips: [UUID: Trip] = [:]

    func save(_ trip: Trip) async throws {
        trips[trip.id] = trip
    }

    func fetchAll() async throws -> [Trip] {
        Array(trips.values)
    }

    func fetch(id: UUID) async throws -> Trip? {
        trips[id]
    }

    func delete(id: UUID) async throws {
        trips.removeValue(forKey: id)
    }
}

struct StubMatcher: CartReceiptMatching {
    let result: [ProposedMatch]

    func match(
        cartItems: [CartItem],
        receiptLines: [ReceiptLine],
        priceHistory: [PriceHistoryEntry]
    ) async throws -> [ProposedMatch] {
        result
    }
}
