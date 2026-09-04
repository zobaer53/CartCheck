import SwiftUI
import CartCheckDomain

/// Mirrors the "show your work, then ask" review moment: the shared
/// comparison card, plus three neutral decision options — never a
/// pre-selected default.
struct MatchReviewCard: View {
    let review: PendingReview
    let onDecide: (ReviewDecision) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let store = review.tripStore {
                Text(store.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            MatchComparisonCard(match: review.match) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("Yes, that's a mismatch") { onDecide(.confirmedMismatch) }
                            .buttonStyle(.borderedProminent)
                        Button("No, different item") { onDecide(.notAMismatch) }
                            .buttonStyle(.bordered)
                    }
                    Button("Not sure — skip it") { onDecide(.skipped) }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
