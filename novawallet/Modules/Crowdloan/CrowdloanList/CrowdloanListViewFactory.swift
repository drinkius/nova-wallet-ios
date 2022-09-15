import Foundation
import SoraFoundation
import SubstrateSdk
import SoraKeystore
import IrohaCrypto
import RobinHood

struct CrowdloanListViewFactory {
    static func createView(with sharedState: CrowdloanSharedState) -> CrowdloanListViewProtocol? {
        guard let interactor = createInteractor(from: sharedState),
              let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let wireframe = CrowdloanListWireframe(state: sharedState)

        let localizationManager = LocalizationManager.shared

        let viewModelFactory = CrowdloansViewModelFactory(
            amountFormatterFactory: AssetBalanceFormatterFactory(),
            balanceViewModelFactoryFacade: BalanceViewModelFactoryFacade(
                priceAssetInfoFactory: PriceAssetInfoFactory(currencyManager: currencyManager)
            )
        )

        let presenter = CrowdloanListPresenter(
            interactor: interactor,
            wireframe: wireframe,
            viewModelFactory: viewModelFactory,
            localizationManager: localizationManager,
            crowdloansCalculator: CrowdloansCalculator(),
            accountManagementFilter: AccountManagementFilter(),
            logger: Logger.shared
        )

        let view = CrowdloanListViewController(
            presenter: presenter,
            localizationManager: localizationManager
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }

    private static func createInteractor(
        from state: CrowdloanSharedState
    ) -> CrowdloanListInteractor? {
        guard
            let currencyManager = CurrencyManager.shared,
            let selectedMetaAccount = SelectedWalletSettings.shared.value else {
            return nil
        }

        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let repository = SubstrateRepositoryFactory().createChainStorageItemRepository()

        let operationManager = OperationManagerFacade.sharedManager
        let logger = Logger.shared

        let crowdloanRemoteSubscriptionService = CrowdloanRemoteSubscriptionService(
            chainRegistry: chainRegistry,
            repository: AnyDataProviderRepository(repository),
            operationManager: operationManager,
            logger: logger
        )

        let storageRequestFactory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: operationManager
        )

        let crowdloanOperationFactory = CrowdloanOperationFactory(
            requestOperationFactory: storageRequestFactory,
            operationManager: operationManager
        )

        return CrowdloanListInteractor(
            selectedMetaAccount: selectedMetaAccount,
            crowdloanState: state,
            chainRegistry: chainRegistry,
            crowdloanOperationFactory: crowdloanOperationFactory,
            crowdloanRemoteSubscriptionService: crowdloanRemoteSubscriptionService,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            jsonDataProviderFactory: JsonDataProviderFactory.shared,
            operationManager: operationManager,
            applicationHandler: ApplicationHandler(),
            currencyManager: currencyManager,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            logger: logger
        )
    }
}
