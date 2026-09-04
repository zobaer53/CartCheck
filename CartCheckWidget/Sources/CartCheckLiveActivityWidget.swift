import ActivityKit
import WidgetKit
import SwiftUI

struct CartCheckLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CartCheckActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.itemsScanned)", systemImage: "barcode.viewfinder")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.runningTotal.currencyString)
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.storeName ?? "Shopping")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "barcode.viewfinder")
            } compactTrailing: {
                Text(context.state.runningTotal.currencyString)
                    .font(.caption.monospacedDigit())
            } minimal: {
                Image(systemName: "barcode.viewfinder")
            }
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<CartCheckActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.storeName ?? "Shopping")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(context.state.itemsScanned) items scanned")
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            Text(context.state.runningTotal.currencyString)
                .font(.title3.weight(.semibold).monospacedDigit())
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.05))
    }
}
