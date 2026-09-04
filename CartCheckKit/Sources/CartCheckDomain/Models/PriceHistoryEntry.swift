import Foundation

/// A confirmed price paid for a product at a store on a date, used to build
/// the shopper's own "expected price" baseline for next time. Only prices
/// from matches the shopper didn't flag as mismatches are recorded, so the
/// baseline never gets poisoned by a price that was itself in dispute.
public struct PriceHistoryEntry: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var itemKey: String
    public var store: String?
    public var price: Decimal
    public var date: Date

    public init(
        id: UUID = UUID(),
        itemKey: String,
        store: String?,
        price: Decimal,
        date: Date = .now
    ) {
        self.id = id
        self.itemKey = itemKey
        self.store = store
        self.price = price
        self.date = date
    }
}
