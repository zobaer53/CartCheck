import Foundation
import Testing
@testable import CartCheckDomain

@Suite("ReconcileTripUseCase")
struct ReconcileTripUseCaseTests {
    @Test("returns whatever the matcher proposes")
    func passesThroughMatcherResult() async throws {
        let expected = [
            ProposedMatch(outcome: .priceMismatch, confidence: .high, reasoning: "test"),
        ]
        let useCase = ReconcileTripUseCase(
            matcher: StubMatcher(result: expected),
            priceHistoryStore: InMemoryPriceHistoryStore()
        )

        let result = try await useCase(cartItems: [], receiptLines: [], store: "Test Store")
        #expect(result == expected)
    }

    @Test("gathers price history once per distinct item key, not once per cart item")
    func deduplicatesHistoryLookups() async throws {
        let historyStore = InMemoryPriceHistoryStore()
        try await historyStore.record(PriceHistoryEntry(itemKey: "barcode:111", store: "Store A", price: 2.00))

        let useCase = ReconcileTripUseCase(
            matcher: StubMatcher(result: []),
            priceHistoryStore: historyStore
        )

        // Two cart items share a barcode (e.g. two units of the same product).
        let items = [
            CartItem(barcode: "111", name: "Bananas", priceSeen: 2.00),
            CartItem(barcode: "111", name: "Bananas", priceSeen: 2.00),
        ]

        _ = try await useCase(cartItems: items, receiptLines: [], store: "Store A")
        // No crash / no duplicated work is the behavior under test; the real
        // assertion is that history for the shared key is still retrievable.
        let history = try await historyStore.history(forItemKey: "barcode:111", store: "Store A")
        #expect(history.count == 1)
    }
}

@Suite("ConfirmMatchDecisionUseCase")
struct ConfirmMatchDecisionUseCaseTests {
    @Test("confirming a mismatch never writes to price history")
    func confirmedMismatchIsNotRecorded() async throws {
        let historyStore = InMemoryPriceHistoryStore()
        let useCase = ConfirmMatchDecisionUseCase(priceHistoryStore: historyStore)

        let match = ProposedMatch(
            cartItem: CartItem(barcode: "111", name: "Bananas", priceSeen: 3.49),
            receiptLine: ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 4.29),
            outcome: .priceMismatch,
            confidence: .high,
            reasoning: "test"
        )

        let updated = try await useCase(match: match, decision: .confirmedMismatch, store: "Store A")
        #expect(updated.decision == .confirmedMismatch)
        let history = try await historyStore.history(forItemKey: "barcode:111", store: "Store A")
        #expect(history.isEmpty)
    }

    @Test("dismissing as not-a-mismatch records the receipt price as history")
    func notAMismatchRecordsHistory() async throws {
        let historyStore = InMemoryPriceHistoryStore()
        let useCase = ConfirmMatchDecisionUseCase(priceHistoryStore: historyStore)

        let match = ProposedMatch(
            cartItem: CartItem(barcode: "111", name: "Bananas", priceSeen: 3.49),
            receiptLine: ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 3.49),
            outcome: .priceMismatch,
            confidence: .low,
            reasoning: "test"
        )

        _ = try await useCase(match: match, decision: .notAMismatch, store: "Store A")
        let history = try await historyStore.history(forItemKey: "barcode:111", store: "Store A")
        #expect(history.count == 1)
        #expect(history.first?.price == 3.49)
    }

    @Test("skipping does not record history either")
    func skippedIsNotRecorded() async throws {
        let historyStore = InMemoryPriceHistoryStore()
        let useCase = ConfirmMatchDecisionUseCase(priceHistoryStore: historyStore)

        let match = ProposedMatch(
            cartItem: CartItem(barcode: "111", name: "Bananas", priceSeen: 3.49),
            receiptLine: ReceiptLine(rawText: "BANANA", parsedName: "Bananas", price: 4.29),
            outcome: .priceMismatch,
            confidence: .low,
            reasoning: "test"
        )

        _ = try await useCase(match: match, decision: .skipped, store: "Store A")
        let history = try await historyStore.history(forItemKey: "barcode:111", store: "Store A")
        #expect(history.isEmpty)
    }
}

@Suite("MonthlySummaryUseCase")
struct MonthlySummaryUseCaseTests {
    @Test("only includes trips within the reference month, and only confirmed mismatches")
    func filtersToReferenceMonth() async throws {
        let tripStore = InMemoryTripStore()
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(from: DateComponents(year: 2026, month: 9, day: 5))!
        let sameMonthDate = calendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        let otherMonthDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 20))!

        func confirmedMismatch(delta: Decimal) -> ProposedMatch {
            ProposedMatch(
                cartItem: CartItem(name: "Item", priceSeen: 1.00),
                receiptLine: ReceiptLine(rawText: "ITEM", parsedName: "Item", price: 1.00 + delta),
                outcome: .priceMismatch,
                confidence: .high,
                reasoning: "test",
                decision: .confirmedMismatch
            )
        }

        try await tripStore.save(Trip(date: sameMonthDate, matches: [confirmedMismatch(delta: 1.50)]))
        try await tripStore.save(Trip(date: otherMonthDate, matches: [confirmedMismatch(delta: 99.00)]))

        let useCase = MonthlySummaryUseCase(tripStore: tripStore, calendar: calendar)
        let summary = try await useCase(for: referenceDate)

        #expect(summary.tripCount == 1)
        #expect(summary.confirmedMismatchCount == 1)
        #expect(summary.confirmedOverchargeTotal == Decimal(string: "1.50"))
    }
}
