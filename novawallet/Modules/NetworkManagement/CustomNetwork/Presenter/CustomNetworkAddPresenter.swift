import Foundation
import SoraFoundation

final class CustomNetworkAddPresenter: CustomNetworkBasePresenter {
    let interactor: CustomNetworkAddInteractorInputProtocol

    init(
        chainType: ChainType,
        knownChain: ChainModel?,
        interactor: CustomNetworkAddInteractorInputProtocol,
        wireframe: CustomNetworkWireframeProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor

        super.init(
            chainType: chainType,
            knownChain: knownChain,
            interactor: interactor,
            wireframe: wireframe,
            localizationManager: localizationManager
        )
    }

    override func actionConfirm() {
        guard
            let partialURL,
            let partialName,
            let partialCurrencySymbol
        else {
            return
        }

        let request = CustomNetwork.AddRequest(
            networkType: chainType,
            url: partialURL,
            name: partialName,
            currencySymbol: partialCurrencySymbol,
            chainId: partialChainId,
            blockExplorerURL: partialBlockExplorerURL,
            coingeckoURL: partialCoingeckoURL
        )

        interactor.addNetwork(with: request)
    }

    override func completeButtonTitle() -> String {
        R.string.localizable.networksListAddNetworkButtonTitle(
            preferredLanguages: selectedLocale.rLanguages
        )
    }

    override func handle(partial url: String) {
        super.handle(partial: url)

        guard
            chainType == .substrate,
            NSPredicate.ws.evaluate(with: url)
        else {
            return
        }

        provideButtonViewModel(loading: true)
        interactor.fetchNetworkProperties(for: url)
    }
}
