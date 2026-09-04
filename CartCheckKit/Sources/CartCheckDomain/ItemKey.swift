import Foundation

/// Identifies "the same product" across trips so price history can be
/// looked up and recorded consistently. Barcode is authoritative when we
/// have one; otherwise we fall back to a normalized product name, since a
/// receipt line may be matched to an item that was never scanned.
public enum ItemKey {
    public static func make(barcode: String?, name: String) -> String {
        if let barcode, !barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "barcode:\(barcode)"
        }
        return "name:\(normalize(name))"
    }

    static func normalize(_ name: String) -> String {
        name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}
