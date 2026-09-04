import FoundationModels

/// The shape the on-device model is asked to fill in for one candidate
/// pairing between a scanned cart item and a receipt line. IDs are the
/// item's UUID string so the response can be mapped back onto the exact
/// `CartItem`/`ReceiptLine` it was given — the model never invents data,
/// it only refers back to what it was shown.
@Generable
struct CartMatchPayload {
    @Guide(description: "The UUID of the scanned cart item this refers to. Omit only if this entry is a receipt line with no corresponding scanned item.")
    var cartItemID: String?

    @Guide(description: "The UUID of the receipt line this refers to. Omit only if this entry is a scanned cart item that never appeared on the receipt.")
    var receiptLineID: String?

    var outcome: CartMatchOutcomePayload
    var confidence: CartMatchConfidencePayload

    @Guide(description: "One brief, plain-language sentence explaining the reasoning, written for the shopper reviewing this — not a log line.")
    var reasoning: String
}

@Generable
enum CartMatchOutcomePayload: String {
    /// Same product, same price — nothing worth flagging.
    case matchesExactly
    /// Same product, but the receipt's price differs from what was scanned.
    case priceMismatch
    /// Scanned while shopping but no receipt line corresponds to it.
    case missingFromReceipt
    /// A receipt line with no scanned cart item behind it.
    case missingFromCart
}

@Generable
enum CartMatchConfidencePayload: String {
    case low, medium, high
}

@Generable
struct CartMatchPayloads {
    var matches: [CartMatchPayload]
}
