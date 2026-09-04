import Foundation
import Testing
@testable import CartCheckDomain

@Suite("ReceiptLineParser")
struct ReceiptLineParserTests {
    @Test("parses an abbreviated register line with a dollar-sign price")
    func parsesDollarSignPrice() {
        let line = ReceiptLineParser.parseLine("ORG BANANA 4011        $4.29")
        #expect(line?.parsedName == "ORG BANANA 4011")
        #expect(line?.price == Decimal(string: "4.29"))
    }

    @Test("parses a plain trailing price with no dollar sign")
    func parsesPlainPrice() {
        let line = ReceiptLineParser.parseLine("WHOLE MILK GAL         4.19")
        #expect(line?.price == Decimal(string: "4.19"))
        #expect(line?.parsedName == "WHOLE MILK GAL")
    }

    @Test("does not mistake a bare product code for a price")
    func rejectsCodeWithoutDecimal() {
        #expect(ReceiptLineParser.parseLine("4011") == nil)
    }

    @Test("rejects a subtotal line even though it ends in a price")
    func rejectsSubtotal() {
        #expect(ReceiptLineParser.parseLine("SUBTOTAL          12.48") == nil)
    }

    @Test("rejects a tax line")
    func rejectsTax() {
        #expect(ReceiptLineParser.parseLine("SALES TAX          0.87") == nil)
    }

    @Test("rejects blank lines")
    func rejectsBlank() {
        #expect(ReceiptLineParser.parseLine("   ") == nil)
    }

    @Test("rejects a line with no price at all")
    func rejectsNoPrice() {
        #expect(ReceiptLineParser.parseLine("THANK YOU FOR SHOPPING") == nil)
    }

    @Test("parse filters a whole receipt down to just the line items")
    func parsesWholeReceipt() {
        let lines = ReceiptLineParser.parse([
            "WALMART",
            "ORG BANANA 4011        $4.29",
            "WHOLE MILK GAL         4.19",
            "SUBTOTAL               8.48",
            "SALES TAX              0.59",
            "TOTAL                  9.07",
            "VISA CREDIT            9.07",
            "THANK YOU",
        ])
        #expect(lines.count == 2)
        #expect(lines[0].price == Decimal(string: "4.29"))
        #expect(lines[1].price == Decimal(string: "4.19"))
    }
}
