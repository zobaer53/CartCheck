import Foundation

/// Persists confirmed prices per product per store, and answers "what did
/// I expect to pay for this?" from that history. Implemented in
/// CartCheckData on top of SwiftData.
public protocol PriceHistoryStore: Sendable {
    func record(_ entry: PriceHistoryEntry) async throws
    func history(forItemKey key: String, store: String?) async throws -> [PriceHistoryEntry]
}

extension PriceHistoryStore {
    /// The most recent confirmed price for this product at this store, if any.
    public func expectedPrice(forItemKey key: String, store: String?) async throws -> Decimal? {
        try await history(forItemKey: key, store: store)
            .sorted { $0.date > $1.date }
            .first?
            .price
    }
}
