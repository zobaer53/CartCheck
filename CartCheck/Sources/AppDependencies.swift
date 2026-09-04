import Foundation
import CartCheckDomain
import CartCheckData

/// Everything a view model needs, built once at launch and handed down.
/// Kept as a plain struct of protocol-typed values (not concrete
/// SwiftData/Vision/FoundationModels types) so nothing above this layer
/// depends on how persistence or on-device AI are actually implemented.
struct AppDependencies {
    let tripStore: TripStore
    let priceHistoryStore: PriceHistoryStore
    let receiptTextExtractor: ReceiptTextExtracting
    let matcher: CartReceiptMatching

    let reconcileTrip: ReconcileTripUseCase
    let confirmMatchDecision: ConfirmMatchDecisionUseCase
    let monthlySummary: MonthlySummaryUseCase

    init(
        tripStore: TripStore,
        priceHistoryStore: PriceHistoryStore,
        receiptTextExtractor: ReceiptTextExtracting,
        matcher: CartReceiptMatching
    ) {
        self.tripStore = tripStore
        self.priceHistoryStore = priceHistoryStore
        self.receiptTextExtractor = receiptTextExtractor
        self.matcher = matcher

        self.reconcileTrip = ReconcileTripUseCase(matcher: matcher, priceHistoryStore: priceHistoryStore)
        self.confirmMatchDecision = ConfirmMatchDecisionUseCase(priceHistoryStore: priceHistoryStore)
        self.monthlySummary = MonthlySummaryUseCase(tripStore: tripStore)
    }
}
