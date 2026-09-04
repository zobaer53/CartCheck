import SwiftUI
import VisionKit

/// Full-screen barcode scanner, with a plain-language fallback when live
/// scanning isn't available on this device (the Simulator has no camera,
/// and DataScannerViewController is unsupported on some older hardware).
struct ScannerSheet: View {
    let onBarcodeScanned: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    BarcodeScannerView { payload in
                        onBarcodeScanned(payload)
                        dismiss()
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Scanning Unavailable",
                        systemImage: "barcode.viewfinder",
                        description: Text("This device can't scan barcodes right now. Add the item manually instead.")
                    )
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
