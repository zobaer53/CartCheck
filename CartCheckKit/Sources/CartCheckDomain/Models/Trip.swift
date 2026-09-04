import Foundation

/// One shopping trip: what was scanned, what the receipt said, and the
/// reconciliation between them.
public struct Trip: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var store: String?
    public var date: Date
    public var cartItems: [CartItem]
    public var receiptLines: [ReceiptLine]
    public var matches: [ProposedMatch]

    public init(
        id: UUID = UUID(),
        store: String? = nil,
        date: Date = .now,
        cartItems: [CartItem] = [],
        receiptLines: [ReceiptLine] = [],
        matches: [ProposedMatch] = []
    ) {
        self.id = id
        self.store = store
        self.date = date
        self.cartItems = cartItems
        self.receiptLines = receiptLines
        self.matches = matches
    }

    /// Sum of confirmed overcharges only. A pending, skipped, or
    /// dismissed-as-not-a-mismatch match never contributes — CartCheck would
    /// rather under-count than hand back a number the shopper can't stand
    /// behind at customer service.
    public var confirmedOverchargeTotal: Decimal {
        matches
            .filter { $0.decision == .confirmedMismatch }
            .compactMap(\.priceDelta)
            .filter { $0 > 0 }
            .reduce(0, +)
    }

    public var pendingReviewCount: Int {
        matches.filter { $0.needsReview && $0.decision == .pending }.count
    }
}
