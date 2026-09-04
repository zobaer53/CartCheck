import Foundation

/// Reconciles what was scanned in the cart against what the receipt says,
/// producing a candidate match — with reasoning — for every cart item and
/// every receipt line. Implemented in CartCheckData on top of the on-device
/// Foundation Models language model; nothing in this package depends on
/// that framework.
///
/// A matcher must never claim certainty: its job is to propose, with a
/// confidence and a plain-language reason, never to conclude. Only the
/// shopper's own review turns a proposal into a counted mismatch.
public protocol CartReceiptMatching: Sendable {
    func match(
        cartItems: [CartItem],
        receiptLines: [ReceiptLine],
        priceHistory: [PriceHistoryEntry]
    ) async throws -> [ProposedMatch]
}
