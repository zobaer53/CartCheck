# CartCheck

Scan barcodes as you shop, photograph the receipt at checkout, and let
on-device AI (Foundation Models — image input, `OCRTool`, `BarcodeReaderTool`,
all new at WWDC 2026) reconcile the two. Anything that doesn't match is
flagged for you to confirm — nothing is ever logged as an overcharge until
you say so.

Full idea, evidence, and competitive landscape: see the `cartcheck-app-idea.md`
doc in the **Random iOS Apps** Claude project, and the published report at
https://claude.ai/code/artifact/5ad55b01-f1ae-4fed-899b-62b5fbc66785

## Status

Phase 0 — scaffold only. XcodeGen project + Clean Architecture package
skeleton (`CartCheckDomain` / `CartCheckData`), no business logic yet, no
dev plan written yet.

Setup mirrors `OneThingToday`: XcodeGen (`project.yml` → `.xcodeproj`),
Clean Architecture (Domain: pure Swift, Data: concrete repositories, App:
SwiftUI + `@Observable`), Swift Testing over XCTest.

iPhone only (`TARGETED_DEVICE_FAMILY: "1"`), no iPad support.

## Before writing real code, confirm

- **Minimum iOS version for the new Foundation Models APIs.** Image input
  (`Attachment(UIImage(...))`), `OCRTool`, and `BarcodeReaderTool` were
  announced at WWDC 2026 — confirm in Xcode which iOS version they actually
  require (this project currently targets iOS 26.0, which may need to move
  to 26.2+ or later once that's confirmed).
- Whether `NSCameraUsageDescription` (already in `CartCheck/Info.plist`)
  needs anything else alongside it once real camera/scanning code is
  written — check against a real build's Info.plist per the
  `INFOPLIST_KEY_*` synthesis gap documented in OneThingToday's history.

## To generate the Xcode project

```
xcodegen generate
```
