import Foundation
import SubstrateSdk

enum RewardCalculatorParams {
    case noParams
    case inflation(parachainsCount: Int)

    var parachainsCount: Int? {
        switch self {
        case let .inflation(parachainsCount):
            return parachainsCount
        case .noParams:
            return nil
        }
    }
}

protocol RewardCalculatorParamsServiceProtocol {
    func subcribe(
        using notificationQueue: DispatchQueue,
        notificationClosure: @escaping (Result<RewardCalculatorParams, Error>) -> Void
    )
    func unsubscribe()
}

final class NoRewardCalculatorParamsService: RewardCalculatorParamsServiceProtocol {
    func subcribe(
        using notificationQueue: DispatchQueue,
        notificationClosure: @escaping (Result<RewardCalculatorParams, Error>) -> Void
    ) {
        notificationQueue.async {
            notificationClosure(.success(.noParams))
        }
    }

    func unsubscribe() {}
}

final class InflationRewardCalculatorParamsService {
    let connection: JSONRPCEngine
    let runtimeService: RuntimeCodingServiceProtocol
    let operationQueue: OperationQueue

    private var subscription: CallbackStorageSubscription<[StringScaleMapper<ParaId>]>?

    init(
        connection: JSONRPCEngine,
        runtimeService: RuntimeCodingServiceProtocol,
        operationQueue: OperationQueue
    ) {
        self.connection = connection
        self.runtimeService = runtimeService
        self.operationQueue = operationQueue
    }
}

extension InflationRewardCalculatorParamsService: RewardCalculatorParamsServiceProtocol {
    func subcribe(
        using notificationQueue: DispatchQueue,
        notificationClosure: @escaping (Result<RewardCalculatorParams, Error>) -> Void
    ) {
        subscription = CallbackStorageSubscription(
            request: UnkeyedSubscriptionRequest(storagePath: .parachains, localKey: ""),
            connection: connection,
            runtimeService: runtimeService,
            repository: nil,
            operationQueue: operationQueue,
            callbackQueue: notificationQueue
        ) { result in
            let parachainsCountResult: Result<RewardCalculatorParams, Error>

            switch result {
            case let .success(parachains):
                let count = parachains?.reduce(Int(0)) { accum, parachain in
                    parachain.value >= Paras.lowestPublicParaId ? accum + 1 : accum
                } ?? 0

                parachainsCountResult = .success(.inflation(parachainsCount: count))
            case let .failure(error):
                if
                    let encodingError = error as? StorageKeyEncodingOperationError,
                    case .invalidStoragePath = encodingError {
                    // no parachains support
                    parachainsCountResult = .success(.inflation(parachainsCount: 0))
                } else {
                    parachainsCountResult = .failure(error)
                }
            }

            notificationQueue.async {
                notificationClosure(parachainsCountResult)
            }
        }
    }

    func unsubscribe() {
        subscription = nil
    }
}
