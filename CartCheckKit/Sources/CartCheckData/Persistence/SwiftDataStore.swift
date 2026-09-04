import Foundation
import SwiftData
import CartCheckDomain

/// The concrete, on-device persistence layer. Backed by SwiftData, running
/// off the main actor so trip saves and price-history lookups never block
/// the UI.
@ModelActor
public actor SwiftDataStore {}

extension SwiftDataStore: TripStore {
    public func save(_ trip: Trip) async throws {
        let payload = try JSONEncoder().encode(trip)
        let tripID = trip.id
        let descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == tripID })

        if let existing = try modelContext.fetch(descriptor).first {
            existing.date = trip.date
            existing.store = trip.store
            existing.payload = payload
        } else {
            modelContext.insert(TripRecord(id: trip.id, date: trip.date, store: trip.store, payload: payload))
        }
        try modelContext.save()
    }

    public func fetchAll() async throws -> [Trip] {
        let descriptor = FetchDescriptor<TripRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(descriptor).map { try JSONDecoder().decode(Trip.self, from: $0.payload) }
    }

    public func fetch(id: UUID) async throws -> Trip? {
        let descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try modelContext.fetch(descriptor).first else { return nil }
        return try JSONDecoder().decode(Trip.self, from: record.payload)
    }

    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<TripRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(record)
        try modelContext.save()
    }
}

extension SwiftDataStore: PriceHistoryStore {
    public func record(_ entry: PriceHistoryEntry) async throws {
        modelContext.insert(
            PriceHistoryRecord(id: entry.id, itemKey: entry.itemKey, store: entry.store, price: entry.price, date: entry.date)
        )
        try modelContext.save()
    }

    public func history(forItemKey key: String, store: String?) async throws -> [PriceHistoryEntry] {
        let descriptor = FetchDescriptor<PriceHistoryRecord>(
            predicate: #Predicate { $0.itemKey == key && $0.store == store }
        )
        return try modelContext.fetch(descriptor).map {
            PriceHistoryEntry(id: $0.id, itemKey: $0.itemKey, store: $0.store, price: $0.price, date: $0.date)
        }
    }
}
