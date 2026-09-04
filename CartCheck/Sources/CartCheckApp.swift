import SwiftUI

// Composition root. Nothing to wire up yet — no repositories exist until
// the Domain/Data layers are built out (see the CartCheck app-idea doc in
// the Random iOS Apps project for the full concept and phased plan).
@main
struct CartCheckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
