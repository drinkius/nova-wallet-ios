import XCTest
import Foundation
import CommonWallet
@testable import novawallet

class TransferValidatorTests: XCTestCase {
    func testThrowErrorIfAmountIsNotPositive() {
        let utilityAsset = ChainModelGenerator.generateAssetWithId(0)
        let validator = TransferValidator(utilityAsset: utilityAsset)
        let transferAmount = AmountDecimal(value: 0)
        let transferInfo = TransferInfo.stub(amount: transferAmount)
        let transferMetadata = TransferMetaData(feeDescriptions: [])

        let errorExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [], metadata: transferMetadata)
        } catch {
            if case TransferValidatingError.zeroAmount = error {
                errorExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [errorExpectation], timeout: Constants.defaultExpectationDuration)
    }

    func testThrowMissingBalanceError() {
        let utilityAsset = ChainModelGenerator.generateAssetWithId(0)
        let validator = TransferValidator(utilityAsset: utilityAsset)
        let transferAmount = AmountDecimal(value: 1)
        let transferInfo = TransferInfo.stub(amount: transferAmount)
        let transferMetadata = TransferMetaData(feeDescriptions: [])

        let errorExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [], metadata: transferMetadata)
        } catch {
            if case TransferValidatingError.missingBalance = error {
                errorExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [errorExpectation], timeout: Constants.defaultExpectationDuration)
    }

    func testThrowUnsuffientFundsError() {
        let utilityAsset = ChainModelGenerator.generateAssetWithId(0)
        let validator = TransferValidator(utilityAsset: utilityAsset)
        let transferAmount = AmountDecimal(value: 0.9)
        let availableAmount = AmountDecimal(value: 1)
        let asset = "assetId"
        let fee = Fee(value: AmountDecimal(value: 0.01), feeDescription: .stub)
        let transferInfo = TransferInfo.stub(amount: transferAmount, asset: asset, fees: [fee])
        let transferMetadata = TransferMetaData(feeDescriptions: [])
        let balance = BalanceData(
            identifier: asset,
            balance: availableAmount,
            context: [BalanceContext.freeKey: "0.9"]
        )

        let errorExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [balance], metadata: transferMetadata)
        } catch {
            if case TransferValidatingError.unsufficientFunds = error {
                errorExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [errorExpectation], timeout: Constants.defaultExpectationDuration)
    }

    func testThrowSenderBalanceTooLowError() {
        let utilityAsset = ChainModelGenerator.generateAssetWithId(0)
        let validator = TransferValidator(utilityAsset: utilityAsset)
        let transferAmount = AmountDecimal(value: 0.9)
        let availableAmount = AmountDecimal(value: 1)
        let asset = "assetId"
        let fee = Fee(value: AmountDecimal(value: 0.01), feeDescription: .stub)
        let transferInfo = TransferInfo.stub(amount: transferAmount, asset: asset, fees: [fee])
        let transferMetadata = TransferMetaData(feeDescriptions: [], context: [
            TransferMetadataContext.assetMinBalanceKey: "1"
        ])
        let balance = BalanceData(
            identifier: asset,
            balance: availableAmount,
            context: [
                BalanceContext.freeKey: "1.0001"
            ]
        )

        let errorExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [balance], metadata: transferMetadata)
        } catch {
            if case NovaTransferValidatingError.cantPayFee = error {
                errorExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [errorExpectation], timeout: Constants.defaultExpectationDuration)
    }

    func testThrowReceiverBalanceTooLowError() {
        let utilityAsset = ChainModelGenerator.generateAssetWithId(0)
        let validator = TransferValidator(utilityAsset: utilityAsset)
        let transferAmount = AmountDecimal(value: 0.1)
        let availableAmount = AmountDecimal(value: 1.2)
        let asset = "assetId"
        let fee = Fee(value: AmountDecimal(value: 0.1), feeDescription: .stub)
        let transferInfo = TransferInfo.stub(amount: transferAmount, asset: asset, fees: [fee])
        let transferMetadata = TransferMetaData(feeDescriptions: [], context: [
            TransferMetadataContext.receiverAssetBalanceKey: "0",
            TransferMetadataContext.assetMinBalanceKey: "1"
        ])
        let balance = BalanceData(
            identifier: asset,
            balance: availableAmount,
            context: [
                BalanceContext.freeKey: availableAmount.stringValue
            ]
        )

        let errorExpectation = XCTestExpectation()
        do {
            _ = try validator.validate(info: transferInfo, balances: [balance], metadata: transferMetadata)
        } catch {
            if case NovaTransferValidatingError.receiverBalanceTooLow = error {
                errorExpectation.fulfill()
            } else {
                XCTFail(error.localizedDescription)
            }
        }

        wait(for: [errorExpectation], timeout: Constants.defaultExpectationDuration)
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

    static func stub(amount: AmountDecimal, asset: String, fees: [Fee]) -> TransferInfo {
        TransferInfo(
            source: "",
            destination: "",
            amount: amount,
            asset: asset,
            details: "",
            fees: fees
        )
    }
}

private extension FeeDescription {
    static var stub: FeeDescription {
        FeeDescription(
            identifier: "",
            assetId: "",
            type: "",
            parameters: []
        )
    }
}
