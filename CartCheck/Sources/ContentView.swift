import SwiftUI

struct ContentView: View {
    let dependencies: AppDependencies

    @State private var activeTripViewModel: ActiveTripViewModel
    @State private var reviewViewModel: ReviewViewModel
    @State private var historyViewModel: HistoryViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _activeTripViewModel = State(initialValue: ActiveTripViewModel(dependencies: dependencies))
        _reviewViewModel = State(initialValue: ReviewViewModel(dependencies: dependencies))
        _historyViewModel = State(initialValue: HistoryViewModel(dependencies: dependencies))
    }

    var body: some View {
        TabView {
            ScanView(viewModel: activeTripViewModel)
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }

            ReviewView(viewModel: reviewViewModel)
                .tabItem { Label("Review", systemImage: "checklist") }
                .badge(reviewViewModel.pendingReviews.count)

            HistoryView(viewModel: historyViewModel)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        }
        .onChange(of: activeTripViewModel.justCompletedTrip) { _, newValue in
            guard newValue != nil else { return }
            Task {
                await reviewViewModel.refresh()
                await historyViewModel.refresh()
            }
        }
    }
}

#Preview {
    ContentView(
        dependencies: AppDependencies(
            tripStore: PreviewTripStore(),
            priceHistoryStore: PreviewPriceHistoryStore(),
            receiptTextExtractor: PreviewReceiptTextExtractor(),
            matcher: PreviewCartReceiptMatcher()
        )
    )
}
