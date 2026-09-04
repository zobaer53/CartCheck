import Foundation
import CartCheckDomain

/// A flagged match, paired with which trip it belongs to so a decision can
/// be written back to the right place.
struct PendingReview: Identifiable {
    let tripID: UUID
    let tripStore: String?
    let match: ProposedMatch
    var id: UUID { match.id }
}

@Observable
@MainActor
final class ReviewViewModel {
    private let dependencies: AppDependencies

    var pendingReviews: [PendingReview] = []
    var isLoading = false
    var errorMessage: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let trips = try await dependencies.tripStore.fetchAll()
            pendingReviews = trips.flatMap { trip in
                trip.matches
                    .filter { $0.needsReview && $0.decision == .pending }
                    .map { PendingReview(tripID: trip.id, tripStore: trip.store, match: $0) }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Only a confirmed mismatch ever counts toward an overcharge total —
    /// this decision is what turns a proposal into that, or discards it.
    func decide(_ review: PendingReview, decision: ReviewDecision) async {
        do {
            guard var trip = try await dependencies.tripStore.fetch(id: review.tripID) else { return }
            guard let index = trip.matches.firstIndex(where: { $0.id == review.match.id }) else { return }

            trip.matches[index] = try await dependencies.confirmMatchDecision(
                match: trip.matches[index],
                decision: decision,
                store: trip.store
            )
            try await dependencies.tripStore.save(trip)

            pendingReviews.removeAll { $0.id == review.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
