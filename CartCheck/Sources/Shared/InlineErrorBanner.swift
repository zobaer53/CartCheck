import SwiftUI

/// A visible, dismiss-free error banner for the top of a tab. Replaces
/// silently-set `errorMessage` properties that were never rendered — the
/// view model clears the message at the start of its next refresh, so this
/// clears itself on pull-to-refresh with no extra state.
struct InlineErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.red.opacity(0.1))
    }
}
