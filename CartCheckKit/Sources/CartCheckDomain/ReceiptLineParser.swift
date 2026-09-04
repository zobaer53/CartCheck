import Foundation

/// Turns raw OCR text lines from a photographed receipt into structured
/// line items. Kept as pure string processing — with no dependency on how
/// the text was extracted — so it's testable without a camera or the
/// Vision framework.
public enum ReceiptLineParser {
    public static func parse(_ rawLines: [String]) -> [ReceiptLine] {
        rawLines.compactMap(parseLine)
    }

    /// Matches a trailing price at the end of a line, e.g. "$4.29" or
    /// "4.29", optionally preceded by whitespace. Anchored to the end of
    /// the string so a product code like "4011" (no decimal point) is
    /// never mistaken for a price.
    private static let priceRegex = #"\$?\d+\.\d{2}\s*$"#

    /// Lines that are never product line items, even if they happen to end
    /// in something price-shaped (a subtotal, a tax line, a card balance).
    private static let skipKeywords = [
        "subtotal", "total", "sales tax", "tax", "change due", "change",
        "cash", "credit", "debit", "visa", "mastercard", "amex", "discover",
        "balance", "tender", "approved", "auth code", "thank you",
        "member savings", "you saved", "order #", "receipt", "cashier",
        "reg#", "trans#", "items sold",
    ]

    static func parseLine(_ raw: String) -> ReceiptLine? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        guard !skipKeywords.contains(where: { lower.contains($0) }) else { return nil }

        guard let priceRange = trimmed.range(of: priceRegex, options: .regularExpression) else { return nil }

        let priceText = trimmed[priceRange]
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
        guard let price = Decimal(string: priceText) else { return nil }

        var name = String(trimmed[..<priceRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        if name.isEmpty { name = trimmed }

        return ReceiptLine(rawText: trimmed, parsedName: name, price: price, quantity: 1)
    }
}
