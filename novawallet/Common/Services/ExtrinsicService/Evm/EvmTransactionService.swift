import Foundation
import BigInt
import SubstrateSdk
import RobinHood

typealias EvmFeeTransactionResult = Result<BigUInt, Error>
typealias EvmEstimateFeeClosure = (EvmFeeTransactionResult) -> Void
typealias EvmSubmitTransactionResult = Result<String, Error>
typealias EvmTransactionSubmitClosure = (EvmSubmitTransactionResult) -> Void
typealias EvmTransactionBuilderClosure = (EvmTransactionBuilderProtocol) throws -> EvmTransactionBuilderProtocol

protocol EvmTransactionServiceProtocol {
    func estimateFee(
        _ closure: @escaping EvmTransactionBuilderClosure,
        fallbackGasLimit: BigUInt,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping EvmEstimateFeeClosure
    )

    func submit(
        _ closure: @escaping EvmTransactionBuilderClosure,
        signer: SigningWrapperProtocol,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping EvmTransactionSubmitClosure
    )
}

enum EvmTransactionServiceError: Error {
    case invalidGasLimit(String)
    case invalidGasPrice(String)
    case invalidNonce(String)
}

final class EvmTransactionService {
    let accountId: AccountId
    let operationFactory: EthereumOperationFactoryProtocol
    let gasPriceProvider: EvmGasPriceProviderProtocol
    let chain: ChainModel
    let operationQueue: OperationQueue

    init(
        accountId: AccountId,
        operationFactory: EthereumOperationFactoryProtocol,
        gasPriceProvider: EvmGasPriceProviderProtocol,
        chain: ChainModel,
        operationQueue: OperationQueue
    ) {
        self.accountId = accountId
        self.operationFactory = operationFactory
        self.gasPriceProvider = gasPriceProvider
        self.chain = chain
        self.operationQueue = operationQueue
    }

    private func createGasLimitOrDefaultWrapper(
        for transaction: EthereumTransaction,
        fallbackGasLimit: BigUInt
    ) -> CompoundOperationWrapper<BigUInt> {
        let gasEstimationOperation = operationFactory.createGasLimitOperation(for: transaction)

        let mappingOperation = ClosureOperation<BigUInt> {
            do {
                let gasLimitString = try gasEstimationOperation.extractNoCancellableResultData()

                guard let gasLimit = BigUInt.fromHexString(gasLimitString) else {
                    throw EvmTransactionServiceError.invalidGasLimit(gasLimitString)
                }

                return gasLimit
            } catch is JSONRPCError {
                return fallbackGasLimit
            }
        }

        mappingOperation.addDependency(gasEstimationOperation)

        return CompoundOperationWrapper(targetOperation: mappingOperation, dependencies: [gasEstimationOperation])
    }
}

extension EvmTransactionService: EvmTransactionServiceProtocol {
    func estimateFee(
        _ closure: @escaping EvmTransactionBuilderClosure,
        fallbackGasLimit: BigUInt,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping EvmEstimateFeeClosure
    ) {
        do {
            let address = try accountId.toAddress(using: chain.chainFormat)
            let builder = EvmTransactionBuilder(address: address, chainId: chain.evmChainId)
            let transaction = (try closure(builder)).buildTransaction()

            let gasEstimationWrapper = createGasLimitOrDefaultWrapper(
                for: transaction,
                fallbackGasLimit: fallbackGasLimit
            )

            let gasPriceWrapper = gasPriceProvider.getGasPriceWrapper()

            let mapOperation = ClosureOperation<BigUInt> {
                let gasLimit = try gasEstimationWrapper.targetOperation.extractNoCancellableResultData()
                let gasPrice = try gasPriceWrapper.targetOperation.extractNoCancellableResultData()

                return gasLimit * gasPrice
            }

            mapOperation.addDependency(gasEstimationWrapper.targetOperation)
            mapOperation.addDependency(gasPriceWrapper.targetOperation)

            mapOperation.completionBlock = {
                queue.async {
                    do {
                        let fee = try mapOperation.extractNoCancellableResultData()
                        completionClosure(.success(fee))
                    } catch {
                        completionClosure(.failure(error))
                    }
                }
            }

            let operations = gasEstimationWrapper.allOperations + gasPriceWrapper.allOperations + [mapOperation]

            operationQueue.addOperations(operations, waitUntilFinished: false)
        } catch {
            dispatchInQueueWhenPossible(queue) {
                completionClosure(.failure(error))
            }
        }
    }

    func submit(
        _ closure: @escaping EvmTransactionBuilderClosure,
        signer: SigningWrapperProtocol,
        runningIn queue: DispatchQueue,
        completion completionClosure: @escaping EvmTransactionSubmitClosure
    ) {
        do {
            let address = try accountId.toAddress(using: chain.chainFormat)
            let initBuilder = EvmTransactionBuilder(address: address, chainId: chain.evmChainId)
            let builder = try closure(initBuilder)

            let gasEstimationOperation = operationFactory.createGasLimitOperation(for: builder.buildTransaction())
            let gasPriceWrapper = gasPriceProvider.getGasPriceWrapper()
            let nonceOperation = operationFactory.createTransactionsCountOperation(for: accountId, block: .pending)

            let sendOperation = operationFactory.createSendTransactionOperation {
                let gasLimitString = try gasEstimationOperation.extractNoCancellableResultData()
                let gasPrice = try gasPriceWrapper.targetOperation.extractNoCancellableResultData()
                let nonceString = try nonceOperation.extractNoCancellableResultData()

                guard let gasLimit = BigUInt.fromHexString(gasLimitString) else {
                    throw EvmTransactionServiceError.invalidGasLimit(gasLimitString)
                }

                guard let nonce = BigUInt.fromHexString(nonceString) else {
                    throw EvmTransactionServiceError.invalidNonce(nonceString)
                }

                return try builder
                    .usingGasLimit(gasLimit)
                    .usingGasPrice(gasPrice)
                    .usingNonce(nonce)
                    .signing(using: { data in
                        try signer.sign(data).rawData()
                    })
                    .build()
            }

            sendOperation.addDependency(gasEstimationOperation)
            sendOperation.addDependency(gasPriceWrapper.targetOperation)
            sendOperation.addDependency(nonceOperation)

            sendOperation.completionBlock = {
                queue.async {
                    do {
                        let hash = try sendOperation.extractNoCancellableResultData()
                        completionClosure(.success(hash))
                    } catch {
                        completionClosure(.failure(error))
                    }
                }
            }

            let operations = [gasEstimationOperation] + gasPriceWrapper.allOperations + [nonceOperation, sendOperation]

            operationQueue.addOperations(operations, waitUntilFinished: false)
        } catch {
            dispatchInQueueWhenPossible(queue) {
                completionClosure(.failure(error))
            }
        }
    }
}
