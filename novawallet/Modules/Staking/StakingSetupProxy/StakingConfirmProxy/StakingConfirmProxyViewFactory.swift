import Foundation
import SoraFoundation

struct StakingConfirmProxyViewFactory {
    static func createView(
        state: RelaychainStakingSharedStateProtocol,
        proxyAddress: AccountAddress
    ) -> StakingConfirmProxyViewProtocol? {
        guard let currencyManager = CurrencyManager.shared,
              let wallet = SelectedWalletSettings.shared.value,
              let interactor = createInteractor(
                  state: state,
                  proxyAddress: proxyAddress
              ) else {
            return nil
        }

        let wireframe = StakingConfirmProxyWireframe()

        let chainAsset = state.stakingOption.chainAsset

        let priceAssetInfoFactory = PriceAssetInfoFactory(currencyManager: currencyManager)
        let balanceViewModelFactory = BalanceViewModelFactory(
            targetAssetInfo: chainAsset.assetDisplayInfo,
            priceAssetInfoFactory: priceAssetInfoFactory
        )
        let dataValidatingFactory = ProxyDataValidatorFactory(
            presentable: wireframe,
            balanceViewModelFactoryFacade: BalanceViewModelFactoryFacade(
                priceAssetInfoFactory: priceAssetInfoFactory
            )
        )

        let presenter = StakingConfirmProxyPresenter(
            chainAsset: chainAsset,
            wallet: wallet,
            proxyAddress: proxyAddress,
            interactor: interactor,
            wireframe: wireframe,
            balanceViewModelFactory: balanceViewModelFactory,
            dataValidatingFactory: dataValidatingFactory,
            displayAddressViewModelFactory: DisplayAddressViewModelFactory(),
            networkViewModelFactory: NetworkViewModelFactory(),
            localizationManager: LocalizationManager.shared
        )

        let view = StakingConfirmProxyViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.baseView = view
        interactor.basePresenter = presenter
        dataValidatingFactory.view = view

        return view
    }

    private static func createInteractor(
        state: RelaychainStakingSharedStateProtocol,
        proxyAddress: AccountAddress
    ) -> StakingConfirmProxyInteractor? {
        let chainRegistry = ChainRegistryFacade.sharedRegistry
        let chainAsset = state.stakingOption.chainAsset

        guard
            let selectedAccount = SelectedWalletSettings.shared.value.fetch(
                for: chainAsset.chain.accountRequest()
            ),
            let connection = chainRegistry.getConnection(for: chainAsset.chain.chainId),
            let runtimeRegistry = chainRegistry.getRuntimeProvider(for: chainAsset.chain.chainId),
            let currencyManager = CurrencyManager.shared else {
            return nil
        }

        let extrinsicServiceFactory = ExtrinsicServiceFactory(
            runtimeRegistry: runtimeRegistry,
            engine: connection,
            operationManager: OperationManagerFacade.sharedManager,
            userStorageFacade: UserDataStorageFacade.shared
        )

        let accountProviderFactory = AccountProviderFactory(
            storageFacade: UserDataStorageFacade.shared,
            operationManager: OperationManagerFacade.sharedManager,
            logger: Logger.shared
        )

        return StakingConfirmProxyInteractor(
            proxyAccount: proxyAddress,
            signingWrapperFactory: SigningWrapperFactory(),
            runtimeService: runtimeRegistry,
            sharedState: state,
            walletLocalSubscriptionFactory: WalletLocalSubscriptionFactory.shared,
            accountProviderFactory: accountProviderFactory,
            priceLocalSubscriptionFactory: PriceProviderFactory.shared,
            callFactory: SubstrateCallFactory(),
            feeProxy: ExtrinsicFeeProxy(),
            extrinsicServiceFactory: extrinsicServiceFactory,
            selectedAccount: selectedAccount,
            chainAsset: chainAsset,
            currencyManager: currencyManager,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )
    }
}
