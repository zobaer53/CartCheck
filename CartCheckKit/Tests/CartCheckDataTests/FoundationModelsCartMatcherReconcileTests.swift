import Foundation
import Testing
@testable import CartCheckData
@testable import CartCheckDomain

/// Covers the reconciliation safety net directly, without a live model:
/// completeness (every cart item and every receipt line ends up
/// represented) has to hold no matter what the model's response looks
/// like, including a response that leaves things out or hallucinates an ID.
@Suite("FoundationModelsCartMatcher.reconcile")
struct FoundationModelsCartMatcherReconcileTests {
    @Test("a payload referencing both sides produces exactly one match, with no synthesized extras")
    func fullyReferencedPairProducesOneMatch() {
        let cartItem = CartItem(name: "Bananas", priceSeen: 3.49)
        let receiptLine = ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 3.49)

        let payload = CartMatchPayload(
            cartItemID: cartItem.id.uuidString,
            receiptLineID: receiptLine.id.uuidString,
            outcome: .matchesExactly,
            confidence: .high,
            reasoning: "Same name, same price."
        )

        let result = FoundationModelsCartMatcher.reconcile(
            payloads: [payload],
            cartItems: [cartItem],
            receiptLines: [receiptLine]
        )

        #expect(result.count == 1)
        #expect(result.first?.cartItem == cartItem)
        #expect(result.first?.receiptLine == receiptLine)
        #expect(result.first?.outcome == .matchesExactly)
    }

    @Test("a cart item the model's response never mentions still gets a synthesized entry")
    func unreferencedCartItemIsSynthesized() {
        let mentioned = CartItem(name: "Bananas", priceSeen: 3.49)
        let forgotten = CartItem(name: "Milk", priceSeen: 4.19)
        let receiptLine = ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 3.49)

        let payload = CartMatchPayload(
            cartItemID: mentioned.id.uuidString,
            receiptLineID: receiptLine.id.uuidString,
            outcome: .matchesExactly,
            confidence: .high,
            reasoning: "test"
        )

        let result = FoundationModelsCartMatcher.reconcile(
            payloads: [payload],
            cartItems: [mentioned, forgotten],
            receiptLines: [receiptLine]
        )

        #expect(result.count == 2)
        let synthesized = result.first { $0.cartItem == forgotten }
        #expect(synthesized?.outcome == .missingFromReceipt)
        #expect(synthesized?.receiptLine == nil)
    }

    @Test("a receipt line the model's response never mentions still gets a synthesized entry")
    func unreferencedReceiptLineIsSynthesized() {
        let cartItem = CartItem(name: "Bananas", priceSeen: 3.49)
        let mentioned = ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 3.49)
        let forgotten = ReceiptLine(rawText: "MILK", parsedName: "Milk", price: 4.19)

        let payload = CartMatchPayload(
            cartItemID: cartItem.id.uuidString,
            receiptLineID: mentioned.id.uuidString,
            outcome: .matchesExactly,
            confidence: .high,
            reasoning: "test"
        )

        let result = FoundationModelsCartMatcher.reconcile(
            payloads: [payload],
            cartItems: [cartItem],
            receiptLines: [mentioned, forgotten]
        )

        #expect(result.count == 2)
        let synthesized = result.first { $0.receiptLine == forgotten }
        #expect(synthesized?.outcome == .missingFromCart)
        #expect(synthesized?.cartItem == nil)
    }

    @Test("a hallucinated ID that matches nothing does not count as a reference")
    func hallucinatedIDDoesNotCountAsReferenced() {
        let cartItem = CartItem(name: "Bananas", priceSeen: 3.49)

        let payload = CartMatchPayload(
            cartItemID: UUID().uuidString, // not cartItem.id
            receiptLineID: nil,
            outcome: .missingFromReceipt,
            confidence: .low,
            reasoning: "hallucinated"
        )

        let result = FoundationModelsCartMatcher.reconcile(
            payloads: [payload],
            cartItems: [cartItem],
            receiptLines: []
        )

        // The hallucinated payload (cartItem resolves to nil) plus a
        // synthesized safety-net entry for the real, still-unreferenced item.
        #expect(result.count == 2)
        #expect(result.contains { $0.cartItem == cartItem && $0.outcome == .missingFromReceipt })
    }

    @Test("an empty response synthesizes an entry for every cart item and receipt line")
    func emptyResponseSynthesizesEverything() {
        let cartItem = CartItem(name: "Bananas", priceSeen: 3.49)
        let receiptLine = ReceiptLine(rawText: "MILK", parsedName: "Milk", price: 4.19)

        let result = FoundationModelsCartMatcher.reconcile(
            payloads: [],
            cartItems: [cartItem],
            receiptLines: [receiptLine]
        )

        #expect(result.count == 2)
        #expect(result.contains { $0.cartItem == cartItem && $0.outcome == .missingFromReceipt })
        #expect(result.contains { $0.receiptLine == receiptLine && $0.outcome == .missingFromCart })
    }
}
