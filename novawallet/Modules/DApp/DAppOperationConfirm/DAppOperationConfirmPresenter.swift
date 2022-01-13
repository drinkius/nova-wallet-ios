import Foundation
import BigInt
import SoraFoundation
import SubstrateSdk

final class DAppOperationConfirmPresenter {
    weak var view: DAppOperationConfirmViewProtocol?
    let wireframe: DAppOperationConfirmWireframeProtocol
    let interactor: DAppOperationConfirmInteractorInputProtocol
    let logger: LoggerProtocol?

    private(set) weak var delegate: DAppOperationConfirmDelegate?

    let viewModelFactory: DAppOperationConfirmViewModelFactoryProtocol
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol

    private var confirmationModel: DAppOperationConfirmModel?
    private var feeModel: RuntimeDispatchInfo?
    private var priceData: PriceData?

    init(
        interactor: DAppOperationConfirmInteractorInputProtocol,
        wireframe: DAppOperationConfirmWireframeProtocol,
        delegate: DAppOperationConfirmDelegate,
        viewModelFactory: DAppOperationConfirmViewModelFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.delegate = delegate
        self.viewModelFactory = viewModelFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.logger = logger

        self.localizationManager = localizationManager
    }

    private func provideConfirmationViewModel() {
        guard let model = confirmationModel else {
            return
        }

        let viewModel = viewModelFactory.createViewModel(from: model)
        view?.didReceive(confimationViewModel: viewModel)
    }

    private func provideFeeViewModel() {
        guard let feeModel = feeModel, let confirmationModel = confirmationModel else {
            view?.didReceive(feeViewModel: .loading)
            return
        }

        guard
            let fee = BigUInt(feeModel.fee),
            let asset = confirmationModel.chain.utilityAssets().first,
            let feeDecimal = Decimal.fromSubstrateAmount(fee, precision: Int16(asset.precision)) else {
            view?.didReceive(feeViewModel: .loading)
            return
        }

        if fee > 0 {
            let viewModel = balanceViewModelFactory.balanceFromPrice(feeDecimal, priceData: priceData)
                .value(for: selectedLocale)
            view?.didReceive(feeViewModel: .loaded(value: viewModel))
        } else {
            view?.didReceive(feeViewModel: .empty)
        }
    }
}

extension DAppOperationConfirmPresenter: DAppOperationConfirmPresenterProtocol {
    func setup() {
        provideConfirmationViewModel()
        provideFeeViewModel()

        interactor.setup()
    }

    func confirm() {
        interactor.confirm()
    }

    func reject() {
        interactor.reject()
    }

    func activateTxDetails() {
        interactor.prepareTxDetails()
    }
}

extension DAppOperationConfirmPresenter: DAppOperationConfirmInteractorOutputProtocol {
    func didReceive(modelResult: Result<DAppOperationConfirmModel, Error>) {
        switch modelResult {
        case let .success(model):
            confirmationModel = model
        case let .failure(error):
            confirmationModel = nil

            if !wireframe.present(error: error, from: view, locale: selectedLocale) {
                logger?.error("Confirmation error: \(error)")
            }
        }

        provideConfirmationViewModel()
        provideFeeViewModel()
    }

    func didReceive(feeResult: Result<RuntimeDispatchInfo, Error>) {
        switch feeResult {
        case let .success(fee):
            feeModel = fee
        case let .failure(error):
            feeModel = nil

            if !wireframe.present(error: error, from: view, locale: selectedLocale) {
                logger?.error("Fee error: \(error)")
            }
        }

        provideFeeViewModel()
    }

    func didReceive(priceResult: Result<PriceData?, Error>) {
        switch priceResult {
        case let .success(priceData):
            self.priceData = priceData
        case let .failure(error):
            priceData = nil

            if !wireframe.present(error: error, from: view, locale: selectedLocale) {
                logger?.error("Price error: \(error)")
            }
        }

        provideFeeViewModel()
    }

    func didReceive(responseResult: Result<DAppOperationResponse, Error>, for request: DAppOperationRequest) {
        switch responseResult {
        case let .success(response):
            delegate?.didReceiveConfirmationResponse(response, for: request)
            wireframe.close(view: view)

        case let .failure(error):
            if !wireframe.present(error: error, from: view, locale: selectedLocale) {
                logger?.error("Response error: \(error)")
            }
        }
    }

    func didReceive(txDetailsResult: Result<JSON, Error>) {
        switch txDetailsResult {
        case let .success(txDetails):
            wireframe.showTxDetails(from: view, json: txDetails)
        case let .failure(error):
            if !wireframe.present(error: error, from: view, locale: selectedLocale) {
                logger?.error("Tx details error: \(error)")
            }
        }
    }
}

extension DAppOperationConfirmPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            provideConfirmationViewModel()
            provideFeeViewModel()
        }
    }
}
