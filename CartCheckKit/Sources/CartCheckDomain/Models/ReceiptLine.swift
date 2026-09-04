import Foundation

/// One line item extracted from a photographed receipt. `rawText` preserves
/// exactly what OCR read (often abbreviated, all-caps register printing);
/// `parsedName` is a best-effort cleanup used for display and matching.
public struct ReceiptLine: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var rawText: String
    public var parsedName: String
    public var price: Decimal?
    public var quantity: Int

    public init(
        id: UUID = UUID(),
        rawText: String,
        parsedName: String,
        price: Decimal? = nil,
        quantity: Int = 1
    ) {
        self.id = id
        self.rawText = rawText
        self.parsedName = parsedName
        self.price = price
        self.quantity = quantity
    }
}
