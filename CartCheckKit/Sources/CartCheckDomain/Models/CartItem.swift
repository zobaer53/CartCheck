import Foundation

/// An item logged while shopping — from a barcode scan, optionally paired
/// with the shelf price the shopper pointed the camera at.
public struct CartItem: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var barcode: String?
    public var name: String
    public var priceSeen: Decimal?
    public var scannedAt: Date

    public init(
        id: UUID = UUID(),
        barcode: String? = nil,
        name: String,
        priceSeen: Decimal? = nil,
        scannedAt: Date = .now
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.priceSeen = priceSeen
        self.scannedAt = scannedAt
    }

    public var itemKey: String { ItemKey.make(barcode: barcode, name: name) }
}
