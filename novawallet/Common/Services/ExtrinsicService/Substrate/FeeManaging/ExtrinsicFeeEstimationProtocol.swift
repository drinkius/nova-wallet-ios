import Foundation
import Operation_iOS
import BigInt
import SubstrateSdk

protocol ExtrinsicFeeEstimationResultProtocol {
    var items: [ExtrinsicFeeProtocol] { get }
}

enum ExtrinsicFeeEstimatingError: Error {
    case brokenFee
}

protocol ExtrinsicFeeEstimating {
    func createFeeEstimatingWrapper(
        connection: JSONRPCEngine,
        runtimeService: RuntimeCodingServiceProtocol,
        extrinsicCreatingResultClosure: @escaping () throws -> ExtrinsicsCreationResult
    ) -> CompoundOperationWrapper<ExtrinsicFeeEstimationResultProtocol>
}

protocol ExtrinsicFeeEstimationRegistring {
    func createFeeEstimatingWrapper(
        payingIn chainAssetId: ChainAssetId?,
        connection: JSONRPCEngine,
        runtimeService: RuntimeCodingServiceProtocol,
        extrinsicCreatingResultClosure: @escaping () throws -> ExtrinsicsCreationResult
    ) -> CompoundOperationWrapper<ExtrinsicFeeEstimationResultProtocol>

    func createFeeInstallerWrapper(
        paingIn chainAssetId: ChainAssetId?,
        connection: JSONRPCEngine,
        runtimeService: RuntimeCodingServiceProtocol
    ) -> CompoundOperationWrapper<ExtrinsicFeeInstalling>
}
