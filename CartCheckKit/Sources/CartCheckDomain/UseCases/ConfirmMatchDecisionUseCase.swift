import Foundation

/// Applies the shopper's decision to a proposed match. A decision other
/// than "confirmed mismatch" — including "not a mismatch" — means the
/// receipt's price for that item was accepted, so it becomes part of the
/// shopper's own price history for next time. A confirmed mismatch is, by
/// definition, a price still in dispute, so it is never recorded as history.
public struct ConfirmMatchDecisionUseCase: Sendable {
    private let priceHistoryStore: PriceHistoryStore

    public init(priceHistoryStore: PriceHistoryStore) {
        self.priceHistoryStore = priceHistoryStore
    }

    @discardableResult
    public func callAsFunction(
        match: ProposedMatch,
        decision: ReviewDecision,
        store: String?
    ) async throws -> ProposedMatch {
        var updated = match
        updated.decision = decision

        if decision == .notAMismatch,
           let line = updated.receiptLine, let price = line.price {
            let key = updated.cartItem?.itemKey ?? ItemKey.make(barcode: nil, name: line.parsedName)
            try await priceHistoryStore.record(
                PriceHistoryEntry(itemKey: key, store: store, price: price)
            )
        }

        return updated
    }
}
