import XCTest
import Foundation
import CommonWallet
@testable import fearless

class TransferValidatorTests: XCTestCase {
    func testThrowErrorIfAmountIsNotPositive() {
        let validator = TransferValidator()
        let zeroAmount = AmountDecimal(value: 0)
        let transferInfo = TransferInfo.stub(amount: zeroAmount)
        let transferMetadata = TransferMetaData(feeDescriptions: [])

        let zeroAmountErrorThrowsExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [], metadata:  transferMetadata)
        } catch {
            if case TransferValidatingError.zeroAmount = error {
                zeroAmountErrorThrowsExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [zeroAmountErrorThrowsExpectation], timeout: Constants.defaultExpectationDuration)
    }
}

private extension TransferInfo {
    static func stub(amount: AmountDecimal) -> TransferInfo {
        TransferInfo(
            source: "",
            destination: "",
            amount: amount,
            asset: "",
            details: "",
            fees: []
        )
    }
}
