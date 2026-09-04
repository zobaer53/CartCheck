import Foundation
import FoundationModels
import CartCheckDomain

public enum FoundationModelsMatcherError: Error {
    case modelUnavailable(SystemLanguageModel.Availability.UnavailableReason)
}

/// Reconciles a trip's scanned cart items against its receipt lines using
/// the on-device Foundation Models language model. Entirely local — no
/// network call, nothing leaves the phone.
///
/// The model is asked to propose, never to conclude: every field it
/// produces (outcome, confidence, reasoning) is there for the shopper to
/// judge, not to act on directly. `reconcile` below is a safety net that
/// guarantees every scanned item and every receipt line ends up
/// represented in the result even if the model's response leaves one out.
public struct FoundationModelsCartMatcher: CartReceiptMatching, Sendable {
    public init() {}

    public func match(
        cartItems: [CartItem],
        receiptLines: [ReceiptLine],
        priceHistory: [PriceHistoryEntry]
    ) async throws -> [ProposedMatch] {
        guard !cartItems.isEmpty || !receiptLines.isEmpty else { return [] }

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            if case .unavailable(let reason) = model.availability {
                throw FoundationModelsMatcherError.modelUnavailable(reason)
            }
            throw FoundationModelsMatcherError.modelUnavailable(.modelNotReady)
        }

        let session = LanguageModelSession(instructions: Self.instructionsText)
        let prompt = Self.buildPrompt(cartItems: cartItems, receiptLines: receiptLines, priceHistory: priceHistory)

        let response = try await session.respond(to: prompt, generating: CartMatchPayloads.self)
        return Self.reconcile(payloads: response.content.matches, cartItems: cartItems, receiptLines: receiptLines)
    }

    private static let instructionsText = """
    You compare items a shopper scanned while shopping against the line \
    items on their receipt, and point out anything that doesn't line up. \
    You are careful and literal: OCR text is often abbreviated or \
    misread, so weigh spelling similarity, price closeness, and the \
    shopper's past price history for that item — but never claim \
    certainty you don't have, that's what the confidence field is for. \
    You never decide anything on the shopper's behalf; you only describe \
    what you observe so they can confirm or dismiss it themselves.
    """

    private static func buildPrompt(
        cartItems: [CartItem],
        receiptLines: [ReceiptLine],
        priceHistory: [PriceHistoryEntry]
    ) -> Prompt {
        var lines: [String] = ["SCANNED WHILE SHOPPING:"]
        if cartItems.isEmpty {
            lines.append("(nothing scanned)")
        } else {
            for item in cartItems {
                let price = item.priceSeen.map { "$\($0)" } ?? "no price seen"
                lines.append("- id: \(item.id.uuidString), name: \(item.name), price: \(price)")
            }
        }

        lines.append("")
        lines.append("RECEIPT LINE ITEMS:")
        if receiptLines.isEmpty {
            lines.append("(no receipt lines)")
        } else {
            for line in receiptLines {
                let price = line.price.map { "$\($0)" } ?? "no price read"
                lines.append("- id: \(line.id.uuidString), text: \(line.rawText), price: \(price)")
            }
        }

        if !priceHistory.isEmpty {
            lines.append("")
            lines.append("PAST CONFIRMED PRICES FOR THESE PRODUCTS (context only):")
            for entry in priceHistory {
                let date = entry.date.formatted(date: .abbreviated, time: .omitted)
                lines.append("- \(entry.itemKey): $\(entry.price) on \(date)")
            }
        }

        lines.append("")
        lines.append("""
        Produce one entry per pairing you find. Every scanned item and \
        every receipt line must be referenced by at least one entry — if \
        something has no counterpart, still produce an entry for it alone \
        with the appropriate outcome.
        """)

        return Prompt(lines.joined(separator: "\n"))
    }

    /// Fills in any cart item or receipt line the model's response didn't
    /// reference, so completeness never depends on the model cooperating.
    /// Internal rather than private so the safety net itself — not just
    /// the end-to-end `match` call, which needs a live model — is directly
    /// unit testable.
    static func reconcile(
        payloads: [CartMatchPayload],
        cartItems: [CartItem],
        receiptLines: [ReceiptLine]
    ) -> [ProposedMatch] {
        let cartItemsByID = Dictionary(uniqueKeysWithValues: cartItems.map { ($0.id.uuidString, $0) })
        let receiptLinesByID = Dictionary(uniqueKeysWithValues: receiptLines.map { ($0.id.uuidString, $0) })

        var referencedCartItemIDs: Set<String> = []
        var referencedReceiptLineIDs: Set<String> = []

        var matches: [ProposedMatch] = payloads.map { payload in
            let cartItem = payload.cartItemID.flatMap { cartItemsByID[$0] }
            let receiptLine = payload.receiptLineID.flatMap { receiptLinesByID[$0] }
            if let cartItem { referencedCartItemIDs.insert(cartItem.id.uuidString) }
            if let receiptLine { referencedReceiptLineIDs.insert(receiptLine.id.uuidString) }

            return ProposedMatch(
                cartItem: cartItem,
                receiptLine: receiptLine,
                outcome: payload.outcome.domainValue,
                confidence: payload.confidence.domainValue,
                reasoning: payload.reasoning
            )
        }

        for item in cartItems where !referencedCartItemIDs.contains(item.id.uuidString) {
            matches.append(
                ProposedMatch(
                    cartItem: item,
                    outcome: .missingFromReceipt,
                    confidence: .low,
                    reasoning: "Scanned while shopping, but no matching line was found on the receipt."
                )
            )
        }

        for line in receiptLines where !referencedReceiptLineIDs.contains(line.id.uuidString) {
            matches.append(
                ProposedMatch(
                    receiptLine: line,
                    outcome: .missingFromCart,
                    confidence: .low,
                    reasoning: "On the receipt, but nothing scanned while shopping matches it."
                )
            )
        }

        return matches
    }
}

private extension CartMatchOutcomePayload {
    var domainValue: MatchOutcome {
        switch self {
        case .matchesExactly: .matchesExactly
        case .priceMismatch: .priceMismatch
        case .missingFromReceipt: .missingFromReceipt
        case .missingFromCart: .missingFromCart
        }
    }
}

private extension CartMatchConfidencePayload {
    var domainValue: MatchConfidence {
        switch self {
        case .low: .low
        case .medium: .medium
        case .high: .high
        }
    }
}
