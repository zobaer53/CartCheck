// CartCheckDomain
//
// Pure Swift — no Apple-framework imports belong in this target. This is
// where the real model goes once development starts for real: a scanned
// cart item, a receipt line extracted by OCRTool, the match between them,
// and the use case that turns "these two don't line up" into something the
// user has to confirm before it counts as a mismatch.
//
// See the CartCheck app-idea doc (Random iOS Apps project) for the concept
// this layer needs to express.
