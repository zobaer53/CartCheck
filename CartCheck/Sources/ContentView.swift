import SwiftUI

// Placeholder shell reflecting the two real moments in the app: scanning
// while you shop, and reviewing whatever didn't match afterward. Both tabs
// are stand-ins until CartCheckDomain/CartCheckData exist.
struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Barcode + receipt scanning goes here.")
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Scan")
            }
            .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }

            NavigationStack {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Flagged mismatches to confirm go here.")
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Review")
            }
            .tabItem { Label("Review", systemImage: "checklist") }
        }
    }
}

#Preview {
    ContentView()
}
