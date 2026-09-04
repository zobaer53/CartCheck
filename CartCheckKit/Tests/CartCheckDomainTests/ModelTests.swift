import Foundation
import Testing
@testable import CartCheckDomain

@Suite("ItemKey")
struct ItemKeyTests {
    @Test("prefers barcode over name when both are present")
    func prefersBarcode() {
        let key = ItemKey.make(barcode: "0123456789", name: "Organic Bananas")
        #expect(key == "barcode:0123456789")
    }

    @Test("falls back to a normalized name when there's no barcode")
    func fallsBackToName() {
        #expect(ItemKey.make(barcode: nil, name: "  Organic   Bananas ") == "name:organic bananas")
    }

    @Test("treats a blank barcode the same as no barcode")
    func blankBarcodeIsIgnored() {
        #expect(ItemKey.make(barcode: "  ", name: "Milk") == "name:milk")
    }

    @Test("name-derived keys are case- and whitespace-insensitive")
    func nameKeysNormalize() {
        let a = ItemKey.make(barcode: nil, name: "Organic Bananas")
        let b = ItemKey.make(barcode: nil, name: "organic  bananas")
        #expect(a == b)
    }
}

@Suite("Trip")
struct TripTests {
    @Test("only confirmed mismatches count toward the overcharge total")
    func onlyConfirmedMismatchesCount() {
        let scanned = CartItem(name: "Organic Bananas", priceSeen: Decimal(string: "3.49"))
        let receipt = ReceiptLine(rawText: "ORG BANANA 4011", parsedName: "Organic Bananas", price: Decimal(string: "4.29"))

        func match(_ decision: ReviewDecision) -> ProposedMatch {
            ProposedMatch(
                cartItem: scanned,
                receiptLine: receipt,
                outcome: .priceMismatch,
                confidence: .high,
                reasoning: "Same product, different price.",
                decision: decision
            )
        }

        let trip = Trip(matches: [
            match(.confirmedMismatch),
            match(.pending),
            match(.notAMismatch),
            match(.skipped),
        ])

        // Only the one .confirmedMismatch entry contributes: 4.29 - 3.49 = 0.80
        #expect(trip.confirmedOverchargeTotal == Decimal(string: "0.80"))
    }

    @Test("a negative delta (undercharge) never contributes to the total")
    func undercreditIsExcluded() {
        let scanned = CartItem(name: "Milk", priceSeen: 5.00)
        let receipt = ReceiptLine(rawText: "MILK", parsedName: "Milk", price: 4.00)
        let match = ProposedMatch(
            cartItem: scanned,
            receiptLine: receipt,
            outcome: .priceMismatch,
            confidence: .high,
            reasoning: "Charged less than scanned.",
            decision: .confirmedMismatch
        )

        #expect(Trip(matches: [match]).confirmedOverchargeTotal == 0)
    }

    @Test("pendingReviewCount ignores exact matches and already-decided ones")
    func pendingReviewCount() {
        let exact = ProposedMatch(outcome: .matchesExactly, confidence: .high, reasoning: "", decision: .pending)
        let pendingMismatch = ProposedMatch(outcome: .priceMismatch, confidence: .medium, reasoning: "", decision: .pending)
        let decidedMismatch = ProposedMatch(outcome: .priceMismatch, confidence: .medium, reasoning: "", decision: .confirmedMismatch)

        let trip = Trip(matches: [exact, pendingMismatch, decidedMismatch])
        #expect(trip.pendingReviewCount == 1)
    }
}

@Suite("ProposedMatch")
struct ProposedMatchTests {
    @Test("priceDelta is nil unless both sides have a price")
    func priceDeltaRequiresBothSides() {
        let onlyScanned = ProposedMatch(
            cartItem: CartItem(name: "Milk", priceSeen: 5.00),
            outcome: .missingFromReceipt,
            confidence: .low,
            reasoning: ""
        )
        #expect(onlyScanned.priceDelta == nil)
    }
}
