import Foundation

/// How sure the matcher is that a cart item and a receipt line are the same
/// product. Never used on its own to decide anything — it's shown to the
/// shopper alongside the comparison so they can judge it themselves.
public enum MatchConfidence: String, Codable, Sendable, Comparable {
    case low, medium, high

    private var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    public static func < (lhs: MatchConfidence, rhs: MatchConfidence) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// What kind of discrepancy (if any) a proposed match represents.
public enum MatchOutcome: String, Codable, Sendable {
    /// Same item, same price — nothing worth surfacing.
    case matchesExactly
    /// Same item, different price between what was scanned and the receipt.
    case priceMismatch
    /// Scanned while shopping but no corresponding receipt line was found.
    case missingFromReceipt
    /// On the receipt but nothing scanned matches it.
    case missingFromCart
}

/// A shopper's decision on a flagged discrepancy. Only `.confirmedMismatch`
/// ever counts toward a running overcharge total — everything else is
/// discarded rather than silently kept as an unproven accusation.
public enum ReviewDecision: String, Codable, Sendable {
    case pending
    case confirmedMismatch
    case notAMismatch
    case skipped
}

/// A candidate pairing between something scanned and something on the
/// receipt, along with the matcher's reasoning and the shopper's decision.
public struct ProposedMatch: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public var cartItem: CartItem?
    public var receiptLine: ReceiptLine?
    public var outcome: MatchOutcome
    public var confidence: MatchConfidence
    public var reasoning: String
    public var decision: ReviewDecision

    public init(
        id: UUID = UUID(),
        cartItem: CartItem? = nil,
        receiptLine: ReceiptLine? = nil,
        outcome: MatchOutcome,
        confidence: MatchConfidence,
        reasoning: String,
        decision: ReviewDecision = .pending
    ) {
        self.id = id
        self.cartItem = cartItem
        self.receiptLine = receiptLine
        self.outcome = outcome
        self.confidence = confidence
        self.reasoning = reasoning
        self.decision = decision
    }

    /// Receipt price minus scanned price. Positive means the receipt
    /// charged more than what was seen on the shelf.
    public var priceDelta: Decimal? {
        guard let scanned = cartItem?.priceSeen, let charged = receiptLine?.price else { return nil }
        return charged - scanned
    }

    /// Whether this pairing is worth putting in front of the shopper at all.
    public var needsReview: Bool {
        outcome != .matchesExactly
    }
}
