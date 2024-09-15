import Foundation
import SoraFoundation

final class TinderGovSetupPresenter {
    weak var view: TinderGovSetupViewProtocol?
    private let wireframe: TinderGovSetupWireframeProtocol
    let interactor: TinderGovSetupInteractorInputProtocol

    let chain: ChainModel
    let metaAccount: MetaAccountModel

    let balanceViewModelFactory: BalanceViewModelFactoryProtocol

    let chainAssetViewModelFactory: ChainAssetViewModelFactoryProtocol
    let referendumStringsViewModelFactory: ReferendumDisplayStringFactoryProtocol
    let lockChangeViewModelFactory: ReferendumLockChangeViewModelFactoryProtocol
    let dataValidatingFactory: GovernanceValidatorFactoryProtocol
    let logger: LoggerProtocol

    private(set) var assetBalance: AssetBalance?

    private(set) var votesResult: CallbackStorageSubscriptionResult<ReferendumTracksVotingDistribution>?
    private(set) var priceData: PriceData?
    private(set) var blockNumber: BlockNumber?
    private(set) var blockTime: BlockTime?

    private(set) var lockDiff: GovernanceLockStateDiff?

    private(set) var inputResult: AmountInputResult?
    private(set) var conviction: ConvictionVoting.Conviction = .none
    private(set) var initVotingPower: VotingPowerLocal?

    init(
        chain: ChainModel,
        metaAccount: MetaAccountModel,
        initData: ReferendumVotingInitData,
        dataValidatingFactory: GovernanceValidatorFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,

        chainAssetViewModelFactory: ChainAssetViewModelFactoryProtocol,
        referendumStringsViewModelFactory: ReferendumDisplayStringFactoryProtocol,
        lockChangeViewModelFactory: ReferendumLockChangeViewModelFactoryProtocol,
        interactor: TinderGovSetupInteractorInputProtocol,
        wireframe: TinderGovSetupWireframeProtocol,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.chain = chain
        self.metaAccount = metaAccount
        votesResult = initData.votesResult
        blockNumber = initData.blockNumber
        blockTime = initData.blockTime

        lockDiff = initData.lockDiff
        initVotingPower = initData.presetVotingPower
        self.dataValidatingFactory = dataValidatingFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.chainAssetViewModelFactory = chainAssetViewModelFactory

        self.referendumStringsViewModelFactory = referendumStringsViewModelFactory
        self.lockChangeViewModelFactory = lockChangeViewModelFactory
        self.interactor = interactor
        self.wireframe = wireframe
        self.logger = logger

        self.localizationManager = localizationManager
    }
}

// MARK: TinderGovSetupPresenterProtocol

extension TinderGovSetupPresenter: TinderGovSetupPresenterProtocol {
    func proceed() {
        performValidation { [weak self] in
            guard
                let self,
                let assetInfo = chain.utilityAssetDisplayInfo(),
                let votingPower = deriveVotePower(using: assetInfo)
            else {
                return
            }

            interactor.process(votingPower: votingPower)
        }
    }

    func setup() {
        if let initVotingPower, let assetInfo = chain.utilityAssetDisplayInfo() {
            conviction = ConvictionVoting.Conviction(from: initVotingPower.conviction)
            inputResult = .absolute(initVotingPower.amount.decimal(assetInfo: assetInfo))

            updateAfterAmountChanged()
            provideConviction()
        }

        updateView()

        interactor.setup()
    }

    func updateAmount(_ newValue: Decimal?) {
        inputResult = newValue.map { .absolute($0) }

        updateAfterAmountChanged()
    }

    func selectAmountPercentage(_ percentage: Float) {
        inputResult = .rate(Decimal(Double(percentage)))

        provideAmountInputViewModel()

        updateAfterAmountChanged()
    }

    func selectConvictionValue(_ value: UInt) {
        guard let newConviction = ConvictionVoting.Conviction(rawValue: UInt8(value)) else {
            return
        }

        conviction = newConviction

        updateAfterConvictionSelect()
    }

    func reuseGovernanceLock() {
        guard let model = deriveReuseLocks() else {
            return
        }

        inputResult = .absolute(model.governance)

        provideAmountInputViewModel()

        updateAfterAmountChanged()
    }

    func reuseAllLock() {
        guard let model = deriveReuseLocks() else {
            return
        }

        inputResult = .absolute(model.all)

        provideAmountInputViewModel()

        updateAfterAmountChanged()
    }
}

// MARK: TinderGovSetupInteractorOutputProtocol

extension TinderGovSetupPresenter: TinderGovSetupInteractorOutputProtocol {
    func didProcessVotingPower() {
        wireframe.showTinderGov(
            from: view,
            locale: selectedLocale
        )
    }

    func didReceiveLockStateDiff(_ diff: GovernanceLockStateDiff) {
        lockDiff = diff

        updateLockedAmountView()
        updateLockedPeriodView()
        provideReuseLocksViewModel()
    }

    func didReceiveAccountVotes(
        _ votes: CallbackStorageSubscriptionResult<ReferendumTracksVotingDistribution>
    ) {
        votesResult = votes

        refreshLockDiff()
    }

    func didReceiveBlockNumber(_ blockNumber: BlockNumber) {
        self.blockNumber = blockNumber

        interactor.refreshBlockTime()

        updateLockedAmountView()
        updateLockedPeriodView()
    }

    func didReceiveBlockTime(_ blockTime: BlockTime) {
        self.blockTime = blockTime

        updateLockedAmountView()
        updateLockedPeriodView()
    }

    func didReceiveAssetBalance(_ assetBalance: AssetBalance?) {
        self.assetBalance = assetBalance

        updateAfterBalanceReceive()
    }

    func didReceivePrice(_ price: PriceData?) {
        priceData = price

        updateAmountPriceView()
    }

    func didReceiveBaseError(_ error: ReferendumVoteInteractorError) {
        logger.error("Did receive base error: \(error)")

        processError(error)
    }
}

// MARK: Private

private extension TinderGovSetupPresenter {
    func updateView() {
        updateAvailableBalanceView()
        provideAmountInputViewModel()
        updateChainAssetViewModel()
        updateAmountPriceView()
        updateLockedAmountView()
        updateLockedPeriodView()
        provideReuseLocksViewModel()
        updateVotesView()
    }

    func updateVotesView() {
        guard
            let assetInfo = chain.utilityAssetDisplayInfo(),
            let votingAmount = deriveVotePower(using: assetInfo)
        else {
            return
        }

        let voteString = referendumStringsViewModelFactory.createVotes(
            from: votingAmount.votingAmount,
            chain: chain,
            locale: selectedLocale
        )

        view?.didReceiveVotes(viewModel: voteString ?? "")
    }

    func updateAfterAmountChanged() {
        refreshLockDiff()
        updateVotesView()
        updateAmountPriceView()
    }

    func refreshLockDiff() {
        guard let trackVoting = votesResult?.value else {
            return
        }

        interactor.refreshLockDiff(
            for: trackVoting,
            blockHash: votesResult?.blockHash
        )
    }

    func updateAfterConvictionSelect() {
        updateVotesView()
        refreshLockDiff()
    }

    func updateAfterBalanceReceive() {
        updateAvailableBalanceView()
        updateAmountPriceView()
        provideAmountInputViewModelIfRate()
        provideReuseLocksViewModel()
    }

    func processError(_ error: ReferendumVoteInteractorError) {
        switch error {
        case .assetBalanceFailed, .priceFailed, .votingReferendumFailed, .accountVotesFailed,
             .blockNumberSubscriptionFailed:
            wireframe.presentRequestStatus(on: view, locale: selectedLocale) { [weak self] in
                self?.interactor.remakeSubscriptions()
            }
        case .blockTimeFailed:
            wireframe.presentRequestStatus(on: view, locale: selectedLocale) { [weak self] in
                self?.interactor.refreshBlockTime()
            }
        case .stateDiffFailed:
            wireframe.presentRequestStatus(on: view, locale: selectedLocale) { [weak self] in
                self?.refreshLockDiff()
            }
        case let .votingPowerSaveFailed(error):
            wireframe.present(
                error: error,
                from: view,
                locale: selectedLocale
            )
        default:
            break
        }
    }

    func performValidation(notifying completionBlock: @escaping DataValidationRunnerCompletion) {
        guard let assetInfo = chain.utilityAssetDisplayInfo() else {
            return
        }

        let votePower = deriveVotePower(using: assetInfo)

        let params = GovernanceVotePowerValidatingParams(
            assetBalance: assetBalance,
            votePower: votePower,
            assetInfo: assetInfo
        )

        let handlers = GovernanceVoteValidatingHandlers(
            convictionUpdateClosure: { [weak self] in
                self?.selectConvictionValue(0)
                self?.provideConviction()
            },
            feeErrorClosure: { [weak self] in
                // TODO: Implement validation error processing
            }
        )

        DataValidationRunner.validateVotingPower(
            factory: dataValidatingFactory,
            params: params,
            selectedLocale: selectedLocale,
            handlers: handlers,
            successClosure: completionBlock
        )
    }

    func deriveVotePower(using assetInfo: AssetBalanceDisplayInfo) -> VotingPowerLocal? {
        guard let amount = inputResult?.absoluteValue(from: balance()).toSubstrateAmount(
            precision: assetInfo.assetPrecision
        ) else {
            return nil
        }

        return VotingPowerLocal(
            chainId: chain.chainId,
            metaId: metaAccount.metaId,
            conviction: .init(from: conviction),
            amount: amount
        )
    }

    func balance() -> Decimal {
        let balanceValue = assetBalance?.freeInPlank ?? 0

        guard
            let precision = chain.utilityAsset()?.displayInfo.assetPrecision,
            let balance = Decimal.fromSubstrateAmount(balanceValue, precision: precision) else {
            return 0
        }

        return balance
    }

    private func updateAvailableBalanceView() {
        let freeInPlank = assetBalance?.freeInPlank ?? 0

        let precision = chain.utilityAsset()?.displayInfo.assetPrecision ?? 0
        let balanceDecimal = Decimal.fromSubstrateAmount(
            freeInPlank,
            precision: precision
        ) ?? 0

        let viewModel = balanceViewModelFactory.balanceFromPrice(
            balanceDecimal,
            priceData: nil
        ).value(for: selectedLocale).amount

        view?.didReceiveBalance(viewModel: viewModel)
    }

    private func updateChainAssetViewModel() {
        guard let asset = chain.utilityAsset() else {
            return
        }

        let chainAsset = ChainAsset(chain: chain, asset: asset)
        let viewModel = chainAssetViewModelFactory.createViewModel(from: chainAsset)
        view?.didReceiveInputChainAsset(viewModel: viewModel)
    }

    private func updateAmountPriceView() {
        if chain.utilityAsset()?.priceId != nil {
            let inputAmount = inputResult?.absoluteValue(from: balance()) ?? 0

            let priceData = priceData ?? PriceData.zero()

            let price = balanceViewModelFactory.priceFromAmount(
                inputAmount,
                priceData: priceData
            ).value(for: selectedLocale)

            view?.didReceiveAmountInputPrice(viewModel: price)
        } else {
            view?.didReceiveAmountInputPrice(viewModel: nil)
        }
    }

    private func provideAmountInputViewModelIfRate() {
        guard case .rate = inputResult else {
            return
        }

        provideAmountInputViewModel()
    }

    private func provideAmountInputViewModel() {
        let inputAmount = inputResult?.absoluteValue(from: balance())

        let viewModel = balanceViewModelFactory.createBalanceInputViewModel(
            inputAmount
        ).value(for: selectedLocale)

        view?.didReceiveAmount(inputViewModel: viewModel)
    }

    private func updateLockedAmountView() {
        guard
            let lockDiff = lockDiff,
            let viewModel = lockChangeViewModelFactory.createAmountTransitionAfterVotingViewModel(
                from: lockDiff,
                locale: selectedLocale
            ) else {
            return
        }

        view?.didReceiveLockedAmount(viewModel: viewModel)
    }

    private func updateLockedPeriodView() {
        guard
            let lockDiff = lockDiff,
            let blockNumber = blockNumber,
            let blockTime = blockTime,
            let viewModel = lockChangeViewModelFactory.createPeriodTransitionAfterVotingViewModel(
                from: lockDiff,
                blockNumber: blockNumber,
                blockTime: blockTime,
                locale: selectedLocale
            ) else {
            return
        }

        view?.didReceiveLockedPeriod(viewModel: viewModel)
    }

    func provideConviction() {
        view?.didReceiveConviction(viewModel: UInt(conviction.rawValue))
    }

    private func provideReuseLocksViewModel() {
        guard let model = deriveReuseLocks() else {
            return
        }

        let governance: String?

        if model.governance > 0 {
            governance = balanceViewModelFactory.amountFromValue(model.governance).value(for: selectedLocale)
        } else {
            governance = nil
        }

        let all: String?

        if model.all > 0, model.all != model.governance {
            all = balanceViewModelFactory.amountFromValue(model.all).value(for: selectedLocale)
        } else {
            all = nil
        }

        let viewModel = ReferendumLockReuseViewModel(governance: governance, all: all)
        view?.didReceiveLockReuse(viewModel: viewModel)
    }

    private func deriveReuseLocks() -> ReferendumReuseLockModel? {
        let governanceLocksInPlank = lockDiff?.before.maxLockedAmount ?? 0
        let allLocksInPlank = assetBalance?.frozenInPlank ?? 0

        guard
            let precision = chain.utilityAssetDisplayInfo()?.assetPrecision,
            let governanceLockDecimal = Decimal.fromSubstrateAmount(governanceLocksInPlank, precision: precision),
            let allLockDecimal = Decimal.fromSubstrateAmount(allLocksInPlank, precision: precision) else {
            return nil
        }

        return ReferendumReuseLockModel(governance: governanceLockDecimal, all: allLockDecimal)
    }
}

extension TinderGovSetupPresenter: Localizable {
    func applyLocalization() {
        if let view, view.isSetup {
            updateView()
        }
    }
}
