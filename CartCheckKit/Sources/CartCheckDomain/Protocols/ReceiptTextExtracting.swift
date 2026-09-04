import Foundation

/// Turns a photographed receipt into structured line items. Implemented in
/// CartCheckData on top of the Vision framework's on-device text
/// recognition — nothing in this package depends on that.
public protocol ReceiptTextExtracting: Sendable {
    func extractLines(fromReceiptImageData data: Data) async throws -> [ReceiptLine]
}
