import Foundation
import SwiftData

/// One confirmed price paid for a product at a store, queryable by item
/// key so the app can build an "expected price" baseline per product.
@Model
public final class PriceHistoryRecord {
    @Attribute(.unique) public var id: UUID
    public var itemKey: String
    public var store: String?
    public var price: Decimal
    public var date: Date

    public init(id: UUID, itemKey: String, store: String?, price: Decimal, date: Date) {
        self.id = id
        self.itemKey = itemKey
        self.store = store
        self.price = price
        self.date = date
    }
}
