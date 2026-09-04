import Foundation
import ActivityKit

/// Owns the single Live Activity for whatever trip is currently in
/// progress. Starting one is best-effort — if the shopper hasn't allowed
/// Live Activities, CartCheck just doesn't show one; scanning and
/// reconciling work exactly the same either way.
@MainActor
final class TripLiveActivityController {
    private var activity: Activity<CartCheckActivityAttributes>?

    func start(storeName: String?, itemsScanned: Int, runningTotal: Decimal) {
        guard activity == nil, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = CartCheckActivityAttributes(storeName: storeName)
        let state = CartCheckActivityAttributes.ContentState(itemsScanned: itemsScanned, runningTotal: runningTotal)
        activity = try? Activity.request(attributes: attributes, contentState: state)
    }

    func update(itemsScanned: Int, runningTotal: Decimal) {
        guard let activity else { return }
        let state = CartCheckActivityAttributes.ContentState(itemsScanned: itemsScanned, runningTotal: runningTotal)
        Task { await activity.update(using: state) }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(dismissalPolicy: .immediate) }
    }
}
