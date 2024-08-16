import Operation_iOS
import SoraKeystore
import SubstrateSdk

protocol ExtrinsicServiceFactoryProtocol {
    func createService(
        account: ChainAccountResponse,
        chain: ChainModel,
        extensions: [ExtrinsicSignedExtending]
    ) -> ExtrinsicServiceProtocol

    func createOperationFactory(
        account: ChainAccountResponse,
        chain: ChainModel,
        extensions: [ExtrinsicSignedExtending]
    ) -> ExtrinsicOperationFactoryProtocol
}

extension ExtrinsicServiceFactoryProtocol {
    func createService(
        account: ChainAccountResponse,
        chain: ChainModel
    ) -> ExtrinsicServiceProtocol {
        createService(
            account: account,
            chain: chain,
            extensions: ExtrinsicSignedExtensionFacade().createFactory(for: chain.chainId).createExtensions()
        )
    }

    func createService(
        account: ChainAccountResponse,
        chain: ChainModel,
        feeAssetConversionId: AssetConversionPallet.AssetId
    ) -> ExtrinsicServiceProtocol {
        createService(
            account: account,
            chain: chain,
            extensions: ExtrinsicSignedExtensionFacade().createFactory(for: chain.chainId).createExtensions(
                payingFeeIn: feeAssetConversionId
            )
        )
    }

    func createOperationFactory(
        account: ChainAccountResponse,
        chain: ChainModel
    ) -> ExtrinsicOperationFactoryProtocol {
        createOperationFactory(
            account: account,
            chain: chain,
            extensions: ExtrinsicSignedExtensionFacade().createFactory(for: chain.chainId).createExtensions()
        )
    }

    func createOperationFactory(
        account: ChainAccountResponse,
        chain: ChainModel,
        feeAssetConversionId: AssetConversionPallet.AssetId
    ) -> ExtrinsicOperationFactoryProtocol {
        createOperationFactory(
            account: account,
            chain: chain,
            extensions: ExtrinsicSignedExtensionFacade().createFactory(for: chain.chainId).createExtensions(
                payingFeeIn: feeAssetConversionId
            )
        )
    }
}

final class ExtrinsicServiceFactory {
    private let runtimeRegistry: RuntimeCodingServiceProtocol & RuntimeProviderProtocol
    private let engine: JSONRPCEngine
    private let operationQueue: OperationQueue
    private let userStorageFacade: StorageFacadeProtocol
    private let metadataHashOperationFactory: MetadataHashOperationFactoryProtocol

    init(
        runtimeRegistry: RuntimeCodingServiceProtocol & RuntimeProviderProtocol,
        engine: JSONRPCEngine,
        operationQueue: OperationQueue,
        userStorageFacade: StorageFacadeProtocol,
        substrateStorageFacade: StorageFacadeProtocol
    ) {
        self.runtimeRegistry = runtimeRegistry
        self.engine = engine

        metadataHashOperationFactory = MetadataHashOperationFactory(
            metadataRepositoryFactory: RuntimeMetadataRepositoryFactory(storageFacade: substrateStorageFacade),
            operationQueue: operationQueue
        )

        self.operationQueue = operationQueue
        self.userStorageFacade = userStorageFacade
    }
}

extension ExtrinsicServiceFactory: ExtrinsicServiceFactoryProtocol {
    func createService(
        account: ChainAccountResponse,
        chain: ChainModel,
        extensions: [ExtrinsicSignedExtending]
    ) -> ExtrinsicServiceProtocol {
        let senderResolvingFactory = ExtrinsicSenderResolutionFactory(
            chainAccount: account,
            chain: chain,
            userStorageFacade: userStorageFacade
        )

        let flowState = HydraFlowState(
            account: account,
            chain: chain,
            connection: engine,
            runtimeProvider: runtimeRegistry,
            userStorageFacade: userStorageFacade,
            substrateStorageFacade: SubstrateDataStorageFacade.shared,
            operationQueue: operationQueue
        )
        let feeEstimationRegistry = ExtrinsicFeeEstimationRegistry(
            chain: chain,
            flowState: flowState,
            operationQueue: operationQueue
        )

        return ExtrinsicService(
            chain: chain,
            runtimeRegistry: runtimeRegistry,
            senderResolvingFactory: senderResolvingFactory,
            metadataHashOperationFactory: metadataHashOperationFactory,
            feeEstimationRegistry: feeEstimationRegistry,
            extensions: extensions,
            engine: engine,
            operationManager: OperationManager(operationQueue: operationQueue)
        )
    }

    func createOperationFactory(
        account: ChainAccountResponse,
        chain: ChainModel,
        extensions: [ExtrinsicSignedExtending]
    ) -> ExtrinsicOperationFactoryProtocol {
        let senderResolvingFactory = ExtrinsicSenderResolutionFactory(
            chainAccount: account,
            chain: chain,
            userStorageFacade: userStorageFacade
        )
        let flowState = HydraFlowState(
            account: account,
            chain: chain,
            connection: engine,
            runtimeProvider: runtimeRegistry,
            userStorageFacade: userStorageFacade,
            substrateStorageFacade: SubstrateDataStorageFacade.shared,
            operationQueue: operationQueue
        )
        let feeEstimationRegistry = ExtrinsicFeeEstimationRegistry(
            chain: chain,
            flowState: flowState,
            operationQueue: operationQueue
        )

        return ExtrinsicOperationFactory(
            chain: chain,
            runtimeRegistry: runtimeRegistry,
            customExtensions: extensions,
            engine: engine,
            feeEstimationRegistry: feeEstimationRegistry,
            metadataHashOperationFactory: metadataHashOperationFactory,
            senderResolvingFactory: senderResolvingFactory,
            blockHashOperationFactory: BlockHashOperationFactory(),
            operationManager: OperationManager(operationQueue: operationQueue)
        )
    }
}
