import Foundation
import ActivityKit

/// Shown on the Lock Screen / Dynamic Island while a trip is in progress,
/// so the shopper never has to app-switch mid-cart just to see the count.
/// This file is compiled into both the app target (which starts/updates/
/// ends the activity) and the widget extension (which renders it) — the
/// two never communicate any other way.
struct CartCheckActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var itemsScanned: Int
        var runningTotal: Decimal
    }

    var storeName: String?
}
