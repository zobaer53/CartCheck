import SwiftUI

struct ReviewView: View {
    @Bindable var viewModel: ReviewViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.pendingReviews.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Review",
                        systemImage: "checkmark.circle",
                        description: Text("Flagged mismatches from your trips will show up here.")
                    )
                } else {
                    List(viewModel.pendingReviews) { review in
                        MatchReviewCard(review: review) { decision in
                            Task { await viewModel.decide(review, decision: decision) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Review")
            .task { await viewModel.refresh() }
            .refreshable { await viewModel.refresh() }
            .overlay {
                if viewModel.isLoading && viewModel.pendingReviews.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}
