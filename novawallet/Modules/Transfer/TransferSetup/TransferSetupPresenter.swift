import Foundation
import BigInt
import SoraFoundation
import SubstrateSdk

final class TransferSetupPresenter {
    weak var view: TransferSetupViewProtocol?
    let wireframe: TransferSetupWireframeProtocol
    let interactor: TransferSetupInteractorInputProtocol

    let chainAsset: ChainAsset

    let senderAccountAddress: AccountAddress
    private(set) var recepientAddress: AccountAddress?

    private(set) var senderSendingAssetBalance: AssetBalance?
    private(set) var senderUtilityAssetBalance: AssetBalance?

    private(set) var recepientSendingAssetBalance: AssetBalance?
    private(set) var recepientUtilityAssetBalance: AssetBalance?

    private(set) var sendingAssetPrice: PriceData?
    private(set) var utilityAssetPrice: PriceData?

    private lazy var iconGenerator = PolkadotIconGenerator()

    private(set) var fee: BigUInt?

    var inputResult: AmountInputResult?

    let networkViewModelFactory: NetworkViewModelFactoryProtocol
    let sendingBalanceViewModelFactory: BalanceViewModelFactoryProtocol
    let utilityBalanceViewModelFactory: BalanceViewModelFactoryProtocol?

    let dataValidatingFactory: TransferDataValidatorFactoryProtocol

    var isUtilityTransfer: Bool {
        chainAsset.chain.utilityAssets().first?.assetId == chainAsset.asset.assetId
    }

    init(
        interactor: TransferSetupInteractorInputProtocol,
        wireframe: TransferSetupWireframeProtocol,
        chainAsset: ChainAsset,
        recepientAddress: AccountAddress?,
        networkViewModelFactory: NetworkViewModelFactoryProtocol,
        sendingBalanceViewModelFactory: BalanceViewModelFactoryProtocol,
        utilityBalanceViewModelFactory: BalanceViewModelFactoryProtocol?,
        senderAccountAddress: AccountAddress,
        dataValidatingFactory: TransferDataValidatorFactoryProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.chainAsset = chainAsset
        self.recepientAddress = recepientAddress
        self.networkViewModelFactory = networkViewModelFactory
        self.sendingBalanceViewModelFactory = sendingBalanceViewModelFactory
        self.utilityBalanceViewModelFactory = utilityBalanceViewModelFactory
        self.senderAccountAddress = senderAccountAddress
        self.dataValidatingFactory = dataValidatingFactory

        self.localizationManager = localizationManager
    }

    private func updateChainAssetViewModel() {
        let networkViewModel = networkViewModelFactory.createViewModel(from: chainAsset.chain)

        let assetIconUrl = chainAsset.asset.icon ?? chainAsset.chain.icon
        let assetIconViewModel = RemoteImageViewModel(url: assetIconUrl)

        let assetViewModel = AssetViewModel(
            symbol: chainAsset.asset.symbol,
            imageViewModel: assetIconViewModel
        )

        let viewModel = ChainAssetViewModel(
            networkViewModel: networkViewModel,
            assetViewModel: assetViewModel
        )

        view?.didReceiveChainAsset(viewModel: viewModel)
    }

    private func provideRecepientStateViewModel() {
        if
            let recepientAddress = recepientAddress,
            let accountId = try? recepientAddress.toAccountId(),
            let icon = try? iconGenerator.generateFromAccountId(accountId) {
            let iconViewModel = DrawableIconViewModel(icon: icon)
            let viewModel = AccountFieldStateViewModel(icon: iconViewModel)
            view?.didReceiveAccountState(viewModel: viewModel)
        } else {
            let viewModel = AccountFieldStateViewModel(icon: nil)
            view?.didReceiveAccountState(viewModel: viewModel)
        }
    }

    private func provideRecepientInputViewModel() {
        let value = recepientAddress ?? ""
        let inputViewModel = InputViewModel.createAccountInputViewModel(for: value)

        view?.didReceiveAccountInput(viewModel: inputViewModel)
    }

    private func provideAmountInputViewModelIfRate() {
        guard case .rate = inputResult else {
            return
        }

        provideAmountInputViewModel()
    }

    private func provideAmountInputViewModel() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee())

        let viewModel = sendingBalanceViewModelFactory.createBalanceInputViewModel(
            inputAmount
        ).value(for: selectedLocale)

        view?.didReceiveAmount(inputViewModel: viewModel)
    }

    private func updateFeeView() {
        let optAssetInfo = chainAsset.chain.utilityAssets().first?.displayInfo
        if let fee = fee, let assetInfo = optAssetInfo {
            let feeDecimal = Decimal.fromSubstrateAmount(
                fee,
                precision: assetInfo.assetPrecision
            ) ?? 0.0

            let viewModelFactory = utilityBalanceViewModelFactory ?? sendingBalanceViewModelFactory
            let priceData = isUtilityTransfer ? sendingAssetPrice : utilityAssetPrice

            let viewModel = viewModelFactory.balanceFromPrice(
                feeDecimal,
                priceData: priceData
            ).value(for: selectedLocale)

            view?.didReceiveFee(viewModel: viewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    private func updateTransferableBalance() {
        if let senderSendingAssetBalance = senderSendingAssetBalance {
            let precision = chainAsset.asset.displayInfo.assetPrecision
            let balanceDecimal = Decimal.fromSubstrateAmount(
                senderSendingAssetBalance.transferable,
                precision: precision
            ) ?? 0

            let viewModel = sendingBalanceViewModelFactory.balanceFromPrice(
                balanceDecimal,
                priceData: nil
            ).value(for: selectedLocale).amount

            view?.didReceiveTransferableBalance(viewModel: viewModel)
        }
    }

    private func updateAmountPriceView() {
        if chainAsset.asset.priceId != nil {
            let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee()) ?? 0

            let priceData = sendingAssetPrice ?? PriceData(price: "0", usdDayChange: nil)

            let price = sendingBalanceViewModelFactory.priceFromAmount(
                inputAmount,
                priceData: priceData
            ).value(for: selectedLocale)

            view?.didReceiveAmountInputPrice(viewModel: price)
        } else {
            view?.didReceiveAmountInputPrice(viewModel: nil)
        }
    }

    private func balanceMinusFee() -> Decimal {
        let balanceValue = senderSendingAssetBalance?.transferable ?? 0
        let feeValue = isUtilityTransfer ? (fee ?? 0) : 0

        let precision = chainAsset.assetDisplayInfo.assetPrecision

        guard
            let balance = Decimal.fromSubstrateAmount(balanceValue, precision: precision),
            let fee = Decimal.fromSubstrateAmount(feeValue, precision: precision) else {
            return 0
        }

        return balance - fee
    }

    private func refreshFee() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee()) ?? 0
        let assetInfo = chainAsset.assetDisplayInfo

        guard let amount = inputAmount.toSubstrateAmount(
            precision: assetInfo.assetPrecision
        ) else {
            return
        }

        interactor.estimateFee(for: amount, recepient: recepientAddress)
    }
}

extension TransferSetupPresenter: TransferSetupPresenterProtocol {
    func setup() {
        updateChainAssetViewModel()
        updateFeeView()
        provideRecepientStateViewModel()
        provideRecepientInputViewModel()
        provideAmountInputViewModel()
        updateAmountPriceView()

        interactor.setup()
    }

    func updateRecepient(partialAddress: String) {
        let accountId = try? partialAddress.toAccountId(using: chainAsset.chain.chainFormat)
        if accountId != nil {
            recepientAddress = partialAddress
        } else {
            recepientAddress = nil
        }

        provideRecepientStateViewModel()
    }

    func updateAmount(_ newValue: Decimal?) {
        inputResult = newValue.map { .absolute($0) }

        refreshFee()
        updateAmountPriceView()
    }

    func selectAmountPercentage(_ percentage: Float) {
        inputResult = .rate(Decimal(Double(percentage)))

        provideAmountInputViewModel()

        refreshFee()
        updateAmountPriceView()
    }

    func proceed() {}
}

extension TransferSetupPresenter: TransferSetupInteractorOutputProtocol {
    func didReceiveSendingAssetSenderBalance(_ balance: AssetBalance?) {
        senderSendingAssetBalance = balance

        updateTransferableBalance()
    }

    func didReceiveUtilityAssetSenderBalance(_ balance: AssetBalance?) {
        senderUtilityAssetBalance = balance
    }

    func didReceiveSendingAssetRecepientBalance(_ balance: AssetBalance?) {
        recepientSendingAssetBalance = balance
    }

    func didReceiveUtilityAssetRecepientBalance(_ balance: AssetBalance?) {
        recepientUtilityAssetBalance = balance
    }

    func didReceiveFee(_ fee: BigUInt) {
        self.fee = fee

        updateFeeView()
        provideAmountInputViewModelIfRate()
        updateAmountPriceView()
    }

    func didReceiveSendingAssetPrice(_ priceData: PriceData?) {
        sendingAssetPrice = priceData

        if isUtilityTransfer {
            updateFeeView()
        }

        updateAmountPriceView()
    }

    func didReceiveUtilityAssetPrice(_ priceData: PriceData?) {
        utilityAssetPrice = priceData

        updateFeeView()
    }

    func didReceiveUtilityAssetMinBalance(_: BigUInt) {}

    func didReceiveSendingAssetMinBalance(_: BigUInt) {}

    func didCompleteSetup() {
        refreshFee()
    }

    func didReceiveSetup(error _: Error) {}
}

extension TransferSetupPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            updateChainAssetViewModel()
            updateFeeView()
            updateTransferableBalance()
            provideRecepientStateViewModel()
            provideRecepientInputViewModel()
            provideAmountInputViewModel()
            updateAmountPriceView()
        }
    }
}
