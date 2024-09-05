import Foundation
import SubstrateSdk
import Operation_iOS
import SoraFoundation

final class VoteCardViewModel {
    weak var view: StackCardViewUpdatable?

    let locale: Locale
    let priceLocalSubscriptionFactory: PriceProviderFactoryProtocol

    private let gradient: GradientModel

    private let summaryFetchOperationFactory: OpenGovSummaryOperationFactoryProtocol
    private let actionDetailsOperationFactory: ReferendumActionOperationFactoryProtocol

    private let balanceViewModelFactory: BalanceViewModelFactoryProtocol

    private let chain: ChainModel
    private let referendum: ReferendumLocal
    private let connection: JSONRPCEngine
    private let runtimeProvider: RuntimeProviderProtocol

    private var priceProvider: StreamableProvider<PriceData>?
    private var price: PriceData?

    private let operationQueue: OperationQueue

    private let onVote: (VoteResult, ReferendumIdLocal) -> Void
    private let onBecomeTop: (ReferendumIdLocal) -> Void

    private var actionDetailsCancellable = CancellableCallStore()
    private var summaryCancellable = CancellableCallStore()

    init(
        operationQueue: OperationQueue,
        summaryFetchOperationFactory: OpenGovSummaryOperationFactoryProtocol,
        actionDetailsOperationFactory: ReferendumActionOperationFactoryProtocol,
        priceLocalSubscriptionFactory: PriceProviderFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeProviderProtocol,
        chain: ChainModel,
        referendum: ReferendumLocal,
        currencyManager: CurrencyManagerProtocol,
        gradient: GradientModel,
        locale: Locale,
        onVote: @escaping (VoteResult, ReferendumIdLocal) -> Void,
        onBecomeTop: @escaping (ReferendumIdLocal) -> Void
    ) {
        self.operationQueue = operationQueue
        self.summaryFetchOperationFactory = summaryFetchOperationFactory
        self.actionDetailsOperationFactory = actionDetailsOperationFactory
        self.priceLocalSubscriptionFactory = priceLocalSubscriptionFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.connection = connection
        self.runtimeProvider = runtimeProvider
        self.chain = chain
        self.referendum = referendum
        self.gradient = gradient
        self.locale = locale
        self.onVote = onVote
        self.onBecomeTop = onBecomeTop
        self.currencyManager = currencyManager
    }

    func onAddToStack() {
        view?.setSummary(loadingState: .loading)
        view?.setRequestedAmount(loadingState: .loading)

        loadSummary()
        loadDetails()
    }

    func onPop(direction: CardsZStack.DismissalDirection) {
        let voteResult = VoteResult(from: direction)

        onVote(voteResult, referendum.index)
    }

    func onBecomeTopView() {
        onBecomeTop(referendum.index)
    }

    func onSetup() {
        makeSubscriptions()

        view?.setBackgroundGradient(model: gradient)
    }
}

private extension VoteCardViewModel {
    func loadSummary() {
        guard !summaryCancellable.hasCall else {
            return
        }

        let summaryFetchOperation = summaryFetchOperationFactory.createSummaryOperation(for: referendum.index)

        execute(
            operation: summaryFetchOperation,
            inOperationQueue: operationQueue,
            backingCallIn: summaryCancellable,
            runningCallbackIn: .main
        ) { [weak self] result in
            switch result {
            case let .success(model):
                guard let summary = model?.summary else {
                    return
                }

                self?.view?.setSummary(loadingState: .loaded(value: summary))
            case let .failure(error):
                print(error)
            }
        }
    }

    func loadDetails() {
        guard !actionDetailsCancellable.hasCall else {
            return
        }

        let wrapper = actionDetailsOperationFactory.fetchActionWrapper(
            for: referendum,
            connection: connection,
            runtimeProvider: runtimeProvider
        )

        executeCancellable(
            wrapper: wrapper,
            inOperationQueue: operationQueue,
            backingCallIn: actionDetailsCancellable,
            runningCallbackIn: .main
        ) { [weak self] result in
            switch result {
            case let .success(actionDetails):
                self?.updateRequestedAmount(using: actionDetails)
            case let .failure(error):
                print(error)
            }
        }
    }

    func updateRequestedAmount(using actionDetails: ReferendumActionLocal) {
        guard
            let requestedAmount = actionDetails.spentAmount(),
            let precision = chain.utilityAssetDisplayInfo()?.assetPrecision,
            let decimalAmount = Decimal.fromSubstrateAmount(
                requestedAmount,
                precision: precision
            )
        else {
            return
        }

        let balanceViewModel = balanceViewModelFactory.balanceFromPrice(decimalAmount, priceData: price).value(
            for: locale
        )

        view?.setRequestedAmount(loadingState: .loaded(value: balanceViewModel))
    }

    func makeSubscriptions() {
        if let priceId = chain.utilityAsset()?.priceId {
            priceProvider = subscribeToPrice(for: priceId, currency: selectedCurrency)
        }
    }
}

// MARK: PriceLocalStorageSubscriber

extension VoteCardViewModel: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(
        result: Result<PriceData?, any Error>,
        priceId _: AssetModel.PriceId
    ) {
        guard let price = try? result.get() else {
            return
        }

        self.price = price
    }
}

// MARK: SelectedCurrencyDepending

extension VoteCardViewModel: SelectedCurrencyDepending {
    func applyCurrency() {
        if let priceId = chain.utilityAsset()?.priceId {
            priceProvider = subscribeToPrice(for: priceId, currency: selectedCurrency)
        }
    }
}
