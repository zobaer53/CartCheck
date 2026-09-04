import Foundation
import SwiftData

/// A trip is stored as a JSON-encoded snapshot of the Domain `Trip` value
/// type, keyed by a few scalar columns for querying/sorting. A trip's
/// cart items, receipt lines, and matches always travel together as one
/// unit — there's no cross-trip query that needs them broken into
/// relationships, so a blob keeps the mapping code trivial and correct by
/// construction instead of hand-maintaining a relational graph.
@Model
public final class TripRecord {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var store: String?
    public var payload: Data

    public init(id: UUID, date: Date, store: String?, payload: Data) {
        self.id = id
        self.date = date
        self.store = store
        self.payload = payload
    }
}
