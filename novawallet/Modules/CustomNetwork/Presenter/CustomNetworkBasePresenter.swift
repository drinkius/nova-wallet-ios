import Foundation
import SoraFoundation

class CustomNetworkBasePresenter {
    weak var view: CustomNetworkViewProtocol?
    let wireframe: CustomNetworkWireframeProtocol
    private let interactor: CustomNetworkBaseInteractorInputProtocol
    
    var partialURL: String?
    var partialName: String?
    var partialCurrencySymbol: String?
    var partialChainId: String?
    var partialBlockExplorerURL: String?
    var partialCoingeckoURL: String?
    
    var chainType: ChainType
    var knownChain: ChainModel?

    init(
        chainType: ChainType,
        knownChain: ChainModel?,
        interactor: CustomNetworkBaseInteractorInputProtocol,
        wireframe: CustomNetworkWireframeProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.chainType = chainType
        self.knownChain = knownChain
        self.interactor = interactor
        self.wireframe = wireframe
        self.localizationManager = localizationManager
    }
    
    func actionConfirm() {
        fatalError("Must be overriden by subclass")
    }
    
    func completeButtonTitle() -> String {
        fatalError("Must be overriden by subclass")
    }
    
    func checkInfoCompleted() -> Bool {
        if
            let partialURL,
            let partialName,
            let partialCurrencySymbol
        {
            !partialURL.isEmpty
            && !partialName.isEmpty
            && !partialCurrencySymbol.isEmpty
        } else {
            false
        }
    }
    
    // MARK: Provide view models
    
    func provideButtonViewModel(loading: Bool) {
        let completed = checkInfoCompleted()
        
        let title: String = if completed {
            completeButtonTitle()
        } else {
            R.string.localizable.networkNodeAddButtonEnterDetails(
                preferredLanguages: selectedLocale.rLanguages
            )
        }
        
        let viewModel = NetworkNodeViewLayout.LoadingButtonViewModel(
            title: title,
            enabled: completed,
            loading: loading
        )
        
        view?.didReceiveButton(viewModel: viewModel)
    }
    
    func provideURLViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialURL ?? "",
            placeholder: "wss://rpc.network.io"
        )
        view?.didReceiveUrl(viewModel: inputViewModel)
    }

    func provideNameViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialName ?? "",
            placeholder: R.string.localizable.commonName(preferredLanguages: selectedLocale.rLanguages)
        )
        view?.didReceiveName(viewModel: inputViewModel)
    }
    
    func provideCurrencySymbolViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialCurrencySymbol ?? "",
            placeholder: R.string.localizable.commonToken(
                preferredLanguages: selectedLocale.rLanguages
            ).uppercased()
        )
        view?.didReceiveCurrencySymbol(viewModel: inputViewModel)
    }
    
    func provideChainIdViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialChainId ?? "",
            placeholder: "012345"
        )
        view?.didReceiveChainId(viewModel: inputViewModel)
    }
    
    func provideBlockExplorerURLViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialBlockExplorerURL ?? "",
            required: false,
            placeholder: ""
        )
        view?.didReceiveBlockExplorerUrl(viewModel: inputViewModel)
    }
    
    func provideCoingeckoURLViewModel() {
        let inputViewModel = InputViewModel.createNotEmptyInputViewModel(
            for: partialCoingeckoURL ?? "",
            required: false,
            placeholder: ""
        )
        view?.didReceiveCoingeckoUrl(viewModel: inputViewModel)
    }
    
    func provideNetworkTypeViewModel() {
        view?.didReceiveNetworkType(
            chainType,
            show: knownChain == nil
        )
    }
    
    // MARK: Setup
    
    func completeSetup() {
        provideViewModel()
        provideButtonViewModel(loading: false)
    }
}

// MARK: CustomNetworkPresenterProtocol

extension CustomNetworkBasePresenter: CustomNetworkPresenterProtocol {
    func setup() {
        completeSetup()
    }
    
    func select(segment: ChainType?) {
        guard let segment else { return }
        
        chainType = segment
        
        cleanPartialValues()
        provideViewModel()
    }

    func handlePartial(url: String) {
        partialURL = url
        
        provideButtonViewModel(loading: false)
    }

    func handlePartial(name: String) {
        partialName = name
        
        provideButtonViewModel(loading: false)
    }
    
    func handlePartial(currencySymbol: String) {
        partialCurrencySymbol = currencySymbol
        
        provideButtonViewModel(loading: false)
    }
    
    func handlePartial(blockExplorerURL: String) {
        partialBlockExplorerURL = blockExplorerURL
        
        provideButtonViewModel(loading: false)
    }
    
    func handlePartial(coingeckoURL: String) {
        partialCoingeckoURL = coingeckoURL
        
        provideButtonViewModel(loading: false)
    }

    func confirm() {
        provideButtonViewModel(loading: true)
        
        actionConfirm()
    }
}

// MARK: CustomNetworkBaseInteractorOutputProtocol

extension CustomNetworkBasePresenter: CustomNetworkBaseInteractorOutputProtocol {
    func didReceive(_ error: CustomNetworkBaseInteractorError) {
        let close = R.string.localizable.commonClose(
            preferredLanguages: selectedLocale.rLanguages
        )
        
        let errorContent = error.toErrorContent(for: selectedLocale)
        
        wireframe.present(
            message: errorContent.message,
            title: errorContent.title,
            closeAction: close,
            from: view
        )
        
        provideButtonViewModel(loading: false)
    }
}

// MARK: Private

private extension CustomNetworkBasePresenter {
    func cleanPartialValues() {
        partialURL = nil
        partialName = nil
        partialCurrencySymbol = nil
        partialChainId = nil
        partialBlockExplorerURL = nil
        partialCoingeckoURL = nil
    }
    
    func provideViewModel() {
        provideTitle()
        provideNetworkTypeViewModel()
        provideURLViewModel()
        provideNameViewModel()
        provideCurrencySymbolViewModel()
        provideBlockExplorerURLViewModel()
        provideCoingeckoURLViewModel()
        provideButtonViewModel(loading: false)
        
        if chainType == .evm {
            provideChainIdViewModel()
        }
    }
    
    func provideTitle() {
        let title = R.string.localizable.networkAddTitle(
            preferredLanguages: selectedLocale.rLanguages
        )
        view?.didReceiveTitle(text: title)
    }
}

// MARK: Localizable

extension CustomNetworkBasePresenter: Localizable {
    func applyLocalization() {
        guard let view, view.isSetup else { return }
        
        provideViewModel()
    }
}
