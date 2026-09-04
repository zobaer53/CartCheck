import SwiftUI
import CartCheckDomain

/// Everything that happened on a past trip — every match, not just the
/// ones that were once flagged for review, since a decision made on the
/// Review tab is otherwise never visible again once it scrolls off.
struct TripDetailView: View {
    let trip: Trip

    var body: some View {
        List {
            Section {
                summaryRow
            }
            Section("Items (\(trip.matches.count))") {
                if trip.matches.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "cart",
                        description: Text("This trip has no reconciled items.")
                    )
                } else {
                    ForEach(sortedMatches) { match in
                        MatchComparisonCard(match: match) {
                            decisionBadge(for: match)
                        }
                    }
                }
            }
        }
        .navigationTitle(trip.store ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Unresolved and confirmed-mismatch items surface first; skipped,
    /// dismissed, and cleanly-matched items sink to the bottom.
    private var sortedMatches: [ProposedMatch] {
        trip.matches.sorted { lhs, rhs in
            sortRank(for: lhs) < sortRank(for: rhs)
        }
    }

    private func sortRank(for match: ProposedMatch) -> Int {
        if match.needsReview && match.decision == .pending { return 0 }
        if match.decision == .confirmedMismatch { return 1 }
        if match.outcome == .matchesExactly { return 3 }
        return 2
    }

    private var summaryRow: some View {
        HStack {
            Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                .foregroundStyle(.secondary)
            Spacer()
            if trip.confirmedOverchargeTotal > 0 {
                Label(trip.confirmedOverchargeTotal.currencyString, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            if trip.pendingReviewCount > 0 {
                Text("\(trip.pendingReviewCount) to review")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    /// `.matchesExactly` matches never go through the review flow, so their
    /// `decision` stays `.pending` forever — outcome, not decision, is what
    /// says "matched" here.
    private func decisionBadge(for match: ProposedMatch) -> some View {
        Group {
            if match.outcome == .matchesExactly {
                Label("Matched", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                switch match.decision {
                case .pending:
                    Label("Needs review", systemImage: "questionmark.circle")
                        .foregroundStyle(.orange)
                case .confirmedMismatch:
                    Label("Confirmed mismatch", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                case .notAMismatch:
                    Label("Not a mismatch", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                case .skipped:
                    Label("Skipped", systemImage: "arrow.uturn.forward.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.caption.weight(.medium))
    }
}
