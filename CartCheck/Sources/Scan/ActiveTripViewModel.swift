import Foundation
import CartCheckDomain
import CartCheckData

/// Drives the "scan as you shop, then reconcile" flow for the trip
/// currently in progress. A trip only exists here in memory until the
/// receipt is photographed — nothing is persisted until reconciliation
/// succeeds.
@Observable
@MainActor
final class ActiveTripViewModel {
    private let dependencies: AppDependencies
    private let liveActivity = TripLiveActivityController()

    var store: String = "" {
        didSet { updateLiveActivity() }
    }
    var cartItems: [CartItem] = []
    var isReconciling = false
    var reconciliationError: String?
    /// Set once a receipt has been reconciled and saved, so the Scan tab
    /// can prompt the shopper to check the Review tab and then reset.
    var justCompletedTrip: Trip?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func addItem(barcode: String?, name: String, priceSeen: Decimal?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        cartItems.append(CartItem(barcode: barcode, name: trimmedName, priceSeen: priceSeen))
        updateLiveActivity()
    }

    func removeItems(at offsets: IndexSet) {
        cartItems.remove(atOffsets: offsets)
        updateLiveActivity()
    }

    func updateItem(id: UUID, name: String, priceSeen: Decimal?) {
        guard let index = cartItems.firstIndex(where: { $0.id == id }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        cartItems[index].name = trimmedName
        cartItems[index].priceSeen = priceSeen
        updateLiveActivity()
    }

    /// A Live Activity on the Lock Screen showing the running count and
    /// total, so the shopper never has to switch back to the app mid-cart
    /// just to see it — starts on the first item, ends once the trip is
    /// reconciled or the cart is emptied. Best-effort: if the shopper
    /// hasn't allowed Live Activities, scanning works exactly the same
    /// either way.
    private func updateLiveActivity() {
        guard !cartItems.isEmpty else {
            liveActivity.end()
            return
        }
        let total = cartItems.compactMap(\.priceSeen).reduce(0, +)
        liveActivity.start(storeName: storeNameOrNil, itemsScanned: cartItems.count, runningTotal: total)
        liveActivity.update(itemsScanned: cartItems.count, runningTotal: total)
    }

    func dismissCompletedTrip() {
        justCompletedTrip = nil
    }

    private var storeNameOrNil: String? {
        let trimmed = store.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func processReceipt(imageData: Data) async {
        guard !cartItems.isEmpty else {
            reconciliationError = "Scan at least one item before photographing the receipt."
            return
        }

        isReconciling = true
        reconciliationError = nil
        defer { isReconciling = false }

        do {
            let receiptLines = try await dependencies.receiptTextExtractor.extractLines(fromReceiptImageData: imageData)
            guard !receiptLines.isEmpty else {
                reconciliationError = "Couldn't read any line items from that photo. Try again with the receipt flat and well lit."
                return
            }

            let matches = try await dependencies.reconcileTrip(
                cartItems: cartItems,
                receiptLines: receiptLines,
                store: storeNameOrNil
            )

            let trip = Trip(store: storeNameOrNil, cartItems: cartItems, receiptLines: receiptLines, matches: matches)
            try await dependencies.tripStore.save(trip)

            justCompletedTrip = trip
            cartItems = []
            liveActivity.end()
        } catch {
            reconciliationError = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        guard let matcherError = error as? FoundationModelsMatcherError else {
            return error.localizedDescription
        }
        switch matcherError {
        case .modelUnavailable(.deviceNotEligible):
            return "This device doesn't support the on-device AI CartCheck needs to compare your receipt."
        case .modelUnavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings to let CartCheck compare your receipt on-device."
        case .modelUnavailable(.modelNotReady):
            return "The on-device model is still getting ready. Try again in a moment."
        @unknown default:
            return "CartCheck couldn't compare your receipt right now."
        }
    }
}
