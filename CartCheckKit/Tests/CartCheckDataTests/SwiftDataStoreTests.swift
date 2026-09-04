import Foundation
import SwiftData
import Testing
@testable import CartCheckData
@testable import CartCheckDomain

@Suite("SwiftDataStore")
struct SwiftDataStoreTests {
    private func makeStore() throws -> SwiftDataStore {
        let container = try ModelContainer(
            for: Schema(CartCheckSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataStore(modelContainer: container)
    }

    @Test("a saved trip round-trips through fetch(id:) unchanged")
    func savedTripRoundTrips() async throws {
        let store = try makeStore()
        let trip = Trip(
            store: "Kroger",
            cartItems: [CartItem(barcode: "111", name: "Bananas", priceSeen: Decimal(string: "3.49"))],
            receiptLines: [ReceiptLine(rawText: "ORG BANANA 4011  $4.29", parsedName: "ORG BANANA 4011", price: Decimal(string: "4.29"))],
            matches: [
                ProposedMatch(
                    cartItem: CartItem(barcode: "111", name: "Bananas", priceSeen: Decimal(string: "3.49")),
                    outcome: .priceMismatch,
                    confidence: .high,
                    reasoning: "Same product, different price.",
                    decision: .confirmedMismatch
                ),
            ]
        )

        try await store.save(trip)
        let fetched = try await store.fetch(id: trip.id)
        #expect(fetched == trip)
    }

    @Test("fetchAll returns trips newest-first")
    func fetchAllOrdersByDateDescending() async throws {
        let store = try makeStore()
        let older = Trip(date: Date(timeIntervalSince1970: 1000))
        let newer = Trip(date: Date(timeIntervalSince1970: 2000))

        try await store.save(older)
        try await store.save(newer)

        let all = try await store.fetchAll()
        #expect(all.map(\.id) == [newer.id, older.id])
    }

    @Test("saving a trip with the same id again updates it in place, not a duplicate")
    func savingTwiceUpdatesInPlace() async throws {
        let store = try makeStore()
        var trip = Trip(store: "Kroger")
        try await store.save(trip)

        trip.store = "Fred Meyer"
        try await store.save(trip)

        let all = try await store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.store == "Fred Meyer")
    }

    @Test("delete removes a trip")
    func deleteRemovesTrip() async throws {
        let store = try makeStore()
        let trip = Trip()
        try await store.save(trip)
        try await store.delete(id: trip.id)
        #expect(try await store.fetch(id: trip.id) == nil)
    }

    @Test("price history is scoped to item key and store")
    func priceHistoryScopedToStore() async throws {
        let store = try makeStore()
        try await store.record(PriceHistoryEntry(itemKey: "barcode:111", store: "Kroger", price: Decimal(string: "3.49")!))
        try await store.record(PriceHistoryEntry(itemKey: "barcode:111", store: "Fred Meyer", price: Decimal(string: "3.99")!))

        let krogerHistory = try await store.history(forItemKey: "barcode:111", store: "Kroger")
        #expect(krogerHistory.count == 1)
        #expect(krogerHistory.first?.price == Decimal(string: "3.49"))
    }

    @Test("expectedPrice returns the most recent history entry")
    func expectedPriceIsMostRecent() async throws {
        let store = try makeStore()
        try await store.record(PriceHistoryEntry(itemKey: "barcode:111", store: "Kroger", price: Decimal(string: "3.49")!, date: Date(timeIntervalSince1970: 1000)))
        try await store.record(PriceHistoryEntry(itemKey: "barcode:111", store: "Kroger", price: Decimal(string: "3.79")!, date: Date(timeIntervalSince1970: 2000)))

        let expected = try await store.expectedPrice(forItemKey: "barcode:111", store: "Kroger")
        #expect(expected == Decimal(string: "3.79"))
    }
}
