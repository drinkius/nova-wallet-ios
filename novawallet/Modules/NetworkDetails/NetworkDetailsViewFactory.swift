import SoraFoundation
import Operation_iOS
import SubstrateSdk

struct NetworkDetailsViewFactory {
    static func createView(with chain: ChainModel) -> NetworkDetailsViewProtocol? {
        let connectionFactory = ConnectionFactory(
            logger: Logger.shared,
            operationQueue: OperationManagerFacade.assetsSyncQueue
        )

        let chainRegistry = ChainRegistryFactory.createDefaultRegistry()

        let repository = SubstrateRepositoryFactory().createChainRepository()

        let operationManager = OperationManager(
            operationQueue: OperationManagerFacade.assetsSyncQueue
        )

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )

        let operationQueue: OperationQueue = {
            let operationQueue = OperationQueue()
            operationQueue.qualityOfService = .userInitiated
            return operationQueue
        }()

        let nodePingOperationFactory = NodePingOperationFactory(
            storageRequestFactory: storageRequestFactory,
            operationQueue: operationQueue
        )

        let interactor = NetworkDetailsInteractor(
            chain: chain,
            connectionFactory: connectionFactory,
            chainRegistry: chainRegistry,
            repository: repository,
            nodePingOperationFactory: nodePingOperationFactory,
            operationQueue: operationQueue
        )

        let wireframe = NetworkDetailsWireframe()

        let viewModelFactory = NetworkDetailsViewModelFactory(
            localizationManager: LocalizationManager.shared,
            networkViewModelFactory: NetworkViewModelFactory()
        )

        let presenter = NetworkDetailsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            chain: chain,
            viewModelFactory: viewModelFactory
        )

        let view = NetworkDetailsViewController(presenter: presenter)

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}
