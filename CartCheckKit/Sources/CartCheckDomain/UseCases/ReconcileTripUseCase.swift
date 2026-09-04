import Foundation

/// Orchestrates the end-of-trip reconciliation: gathers each scanned item's
/// price history for context, then asks the matcher to propose matches
/// between the cart and the receipt.
public struct ReconcileTripUseCase: Sendable {
    private let matcher: CartReceiptMatching
    private let priceHistoryStore: PriceHistoryStore

    public init(matcher: CartReceiptMatching, priceHistoryStore: PriceHistoryStore) {
        self.matcher = matcher
        self.priceHistoryStore = priceHistoryStore
    }

    public func callAsFunction(
        cartItems: [CartItem],
        receiptLines: [ReceiptLine],
        store: String?
    ) async throws -> [ProposedMatch] {
        var priceHistory: [PriceHistoryEntry] = []
        var seenKeys: Set<String> = []
        for item in cartItems where seenKeys.insert(item.itemKey).inserted {
            priceHistory += try await priceHistoryStore.history(forItemKey: item.itemKey, store: store)
        }

        return try await matcher.match(
            cartItems: cartItems,
            receiptLines: receiptLines,
            priceHistory: priceHistory
        )
    }
}
