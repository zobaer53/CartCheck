# CartCheck

Scan barcodes as you shop, photograph the receipt at checkout, and let
on-device AI reconcile the two. Anything that doesn't match is flagged for
you to confirm — nothing is ever logged as an overcharge until you say so.

Full idea, evidence, and competitive landscape: see the `cartcheck-app-idea.md`
doc in the **Random iOS Apps** Claude project, and the published report at
https://claude.ai/code/artifact/5ad55b01-f1ae-4fed-899b-62b5fbc66785

## A note on the pitch vs. what's built

The original app idea assumed a WWDC 2026 announcement of image input and
two purpose-built tools (`OCRTool`, `BarcodeReaderTool`) for the Foundation
Models framework. Building against the actual installed Xcode 26.6 SDK
(inspecting `FoundationModels.framework`'s `.swiftinterface` directly)
confirmed those symbols don't exist there — only the text-only
`LanguageModelSession` / `@Generable` / `Tool` API that shipped at iOS 26
GA is present.

So the implementation is grounded differently, on frameworks confirmed
real in this SDK:

- **Barcode scanning**: VisionKit's `DataScannerViewController`, live
  camera, on-device.
- **Receipt OCR**: Vision's `VNRecognizeTextRequest`, on-device.
- **Reconciliation**: the real `LanguageModelSession`, given the OCR'd
  receipt text and scanned cart items, proposes matches via a
  `@Generable` schema. Still on-device, still no network call — just not
  literally the two named tools from the pitch, which don't exist yet.

## Status

**Phases 1–3 built**: Domain, Data, and App layers all exist and compile.

- **CartCheckDomain** (pure Swift): `CartItem`, `ReceiptLine`,
  `ProposedMatch`, `Trip`, `PriceHistoryEntry`; repository/service
  protocols; three use cases (`ReconcileTripUseCase`,
  `ConfirmMatchDecisionUseCase`, `MonthlySummaryUseCase`); a
  `ReceiptLineParser` that turns raw OCR lines into structured items.
- **CartCheckData**: `SwiftDataStore` (a `@ModelActor` implementing both
  `TripStore` and `PriceHistoryStore`), `VisionReceiptTextExtractor`,
  `FoundationModelsCartMatcher`.
- **CartCheck app**: three tabs (Scan / Review / History) wired to
  `@Observable` view models over the use cases above. Barcode scanning via
  `DataScannerViewController`, receipt capture via camera or photo
  library, a review card mirroring the original pitch's compare-and-confirm
  mockup.

36 tests passing across both packages (`swift test` in `CartCheckKit`).
Builds clean for iOS Simulator and device; launches without crashing on a
Simulator (verified via `xcrun simctl`).

**Not yet built / known gaps**:
- No product-name database — a scanned barcode has no name or price
  attached to it anywhere, so the shopper types both after each scan (or
  adds an item manually). This is an honest consequence of "no server,"
  not an oversight.
- No Live Activity for the in-progress cart total.
- No settings/onboarding — first launch drops straight into the Scan tab.
- Camera-driven flows (barcode scanning, live capture) are unverifiable in
  this environment (no camera in the Simulator) — compiled and reviewed,
  but not run on a physical device.

Setup mirrors `OneThingToday`: XcodeGen (`project.yml` → `.xcodeproj`),
Clean Architecture (Domain: pure Swift, Data: concrete repositories, App:
SwiftUI + `@Observable`), Swift Testing over XCTest.

iPhone only (`TARGETED_DEVICE_FAMILY: "1"`), no iPad support.

## Building

```
xcodegen generate
xcodebuild -project CartCheck.xcodeproj -scheme CartCheck \
  -destination 'generic/platform=iOS Simulator' build
```

The `.xcodeproj` is generated, not committed — regenerate it after pulling
if `project.yml` changed.

## Testing

```
cd CartCheckKit
swift test
```
