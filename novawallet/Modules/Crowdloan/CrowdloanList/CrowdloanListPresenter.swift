import Foundation
import SoraFoundation
import BigInt
import SubstrateSdk

final class CrowdloanListPresenter {
    weak var view: CrowdloanListViewProtocol?
    let wireframe: CrowdloanListWireframeProtocol
    let interactor: CrowdloanListInteractorInputProtocol
    let viewModelFactory: CrowdloansViewModelFactoryProtocol
    let logger: LoggerProtocol?
    let accountManagementFilter: AccountManagementFilterProtocol

    private var selectedChainResult: Result<ChainModel, Error>?
    private var accountInfoResult: Result<AccountInfo?, Error>?
    private var crowdloansResult: Result<[Crowdloan], Error>?
    private var displayInfoResult: Result<CrowdloanDisplayInfoDict, Error>?
    private var blockNumber: BlockNumber?
    private var blockDurationResult: Result<BlockTime, Error>?
    private var leasingPeriodResult: Result<LeasingPeriod, Error>?
    private var leasingOffsetResult: Result<LeasingOffset, Error>?
    private var priceDataResult: Result<PriceData?, Error>?
    private var contributionsResult: Result<CrowdloanContributionDict, Error>?
    private var externalContributions: [ExternalContribution]?
    private var leaseInfoResult: Result<ParachainLeaseInfoDict, Error>?
    private var wallet: MetaAccountModel?

    private lazy var walletSwitchViewModelFactory = WalletSwitchViewModelFactory()
    private let crowdloansCalculator: CrowdloansCalculatorProtocol

    init(
        interactor: CrowdloanListInteractorInputProtocol,
        wireframe: CrowdloanListWireframeProtocol,
        viewModelFactory: CrowdloansViewModelFactoryProtocol,
        localizationManager: LocalizationManagerProtocol,
        crowdloansCalculator: CrowdloansCalculatorProtocol,
        accountManagementFilter: AccountManagementFilterProtocol,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
        self.logger = logger
        self.crowdloansCalculator = crowdloansCalculator
        self.accountManagementFilter = accountManagementFilter
        self.localizationManager = localizationManager
    }

    private func updateWalletSwitchView() {
        guard let wallet = wallet else {
            return
        }

        let viewModel = walletSwitchViewModelFactory.createViewModel(
            from: wallet.walletIdenticonData(),
            walletType: wallet.type
        )

        view?.didReceive(walletSwitchViewModel: viewModel)
    }

    private func updateChainView() {
        guard let chainResult = selectedChainResult else {
            return
        }

        guard
            case let .success(chain) = chainResult,
            let asset = chain.utilityAssets().first else {
            provideViewError(chainAsset: nil)
            return
        }

        let balance: BigUInt?

        if let accountInfoResult = accountInfoResult {
            balance = (try? accountInfoResult.get()?.data.available) ?? 0
        } else {
            balance = nil
        }

        let viewModel = viewModelFactory.createChainViewModel(
            from: chain,
            asset: asset,
            balance: balance,
            locale: selectedLocale
        )

        view?.didReceive(chainInfo: viewModel)
    }

    private func createMetadataResult() -> Result<CrowdloanMetadata, Error>? {
        guard
            let blockDurationResult = blockDurationResult,
            let leasingPeriodResult = leasingPeriodResult,
            let leasingOffsetResult = leasingOffsetResult,
            let blockNumber = blockNumber else {
            return nil
        }

        do {
            let blockDuration = try blockDurationResult.get()
            let leasingPeriod = try leasingPeriodResult.get()
            let leasingOffset = try leasingOffsetResult.get()

            let metadata = CrowdloanMetadata(
                blockNumber: blockNumber,
                blockDuration: blockDuration,
                leasingPeriod: leasingPeriod,
                leasingOffset: leasingOffset
            )

            return .success(metadata)
        } catch {
            return .failure(error)
        }
    }

    private func createViewInfoResult() -> Result<CrowdloansViewInfo, Error>? {
        guard
            let displayInfoResult = displayInfoResult,
            let metadataResult = createMetadataResult(),
            let contributionsResult = contributionsResult,
            let leaseInfoResult = leaseInfoResult else {
            return nil
        }

        do {
            let contributions = try contributionsResult.get()
            let leaseInfo = try leaseInfoResult.get()
            let metadata = try metadataResult.get()
            let displayInfo = try? displayInfoResult.get()

            let viewInfo = CrowdloansViewInfo(
                contributions: contributions,
                leaseInfo: leaseInfo,
                displayInfo: displayInfo,
                metadata: metadata
            )

            return .success(viewInfo)
        } catch {
            return .failure(error)
        }
    }

    private func updateListView() {
        guard let chainResult = selectedChainResult else {
            return
        }

        guard case let .success(chain) = chainResult, let asset = chain.utilityAssets().first else {
            provideViewError(chainAsset: nil)
            return
        }

        guard
            let crowdloansResult = crowdloansResult,
            let viewInfoResult = createViewInfoResult() else {
            return
        }

        let chainAsset = ChainAssetDisplayInfo(asset: asset.displayInfo, chain: chain.chainFormat)
        do {
            let crowdloans = try crowdloansResult.get()
            let priceData = try? priceDataResult?.get() ?? nil
            let viewInfo = try viewInfoResult.get()
            let externalContributionsCount = externalContributions?.count ?? 0

            let amount: Decimal?
            if let contributionsResult = try contributionsResult?.get() {
                amount = crowdloansCalculator.calculateTotal(
                    precision: chain.utilityAsset().map { Int16($0.precision) },
                    contributions: contributionsResult,
                    externalContributions: externalContributions ?? []
                )
            } else {
                amount = nil
            }

            let viewModel = viewModelFactory.createViewModel(
                from: crowdloans,
                viewInfo: viewInfo,
                chainAsset: chainAsset,
                externalContributionsCount: externalContributionsCount,
                amount: amount,
                priceData: priceData,
                locale: selectedLocale
            )

            view?.didReceive(listState: .loaded(viewModel: viewModel))
        } catch {
            provideViewError(chainAsset: chainAsset)
        }
    }

    private func openCrowdloan(for paraId: ParaId) {
        let displayInfoDict = try? displayInfoResult?.get()
        let displayInfo = displayInfoDict?[paraId]

        guard
            let crowdloans = try? crowdloansResult?.get(),
            let selectedCrowdloan = crowdloans.first(where: { $0.paraId == paraId })
        else { return }

        wireframe.presentContributionSetup(
            from: view,
            crowdloan: selectedCrowdloan,
            displayInfo: displayInfo
        )
    }

    private func provideViewError(chainAsset: ChainAssetDisplayInfo?) {
        let viewModel = viewModelFactory.createErrorViewModel(
            chainAsset: chainAsset,
            locale: selectedLocale
        )
        view?.didReceive(listState: .loaded(viewModel: viewModel))
    }
}

extension CrowdloanListPresenter: CrowdloanListPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func refresh(shouldReset: Bool) {
        crowdloansResult = nil

        if shouldReset {
            view?.didReceive(listState: .loading)
        }

        if case .success = selectedChainResult {
            interactor.refresh()
        } else {
            interactor.setup()
        }
    }

    func selectCrowdloan(_ paraId: ParaId) {
        guard let wallet = wallet, let chain = try? selectedChainResult?.get() else {
            return
        }

        if wallet.fetch(for: chain.accountRequest()) != nil {
            openCrowdloan(for: paraId)
        } else if accountManagementFilter.canAddAccount(to: wallet, chain: chain) {
            guard let view = view else {
                return
            }

            let message = R.string.localizable.commonChainCrowdloanAccountMissingMessage(
                chain.name,
                preferredLanguages: selectedLocale.rLanguages
            )

            wireframe.presentAddAccount(
                from: view,
                chainName: chain.name,
                message: message,
                locale: selectedLocale
            ) { [weak self] in
                self?.wireframe.showWalletDetails(from: self?.view, wallet: wallet)
            }
        } else {
            guard let view = view else {
                return
            }

            wireframe.presentNoAccountSupport(
                from: view,
                walletType: wallet.type,
                chainName: chain.name,
                locale: selectedLocale
            )
        }
    }

    func becomeOnline() {
        interactor.becomeOnline()
    }

    func putOffline() {
        interactor.putOffline()
    }

    func selectChain() {
        guard
            let chain = try? selectedChainResult?.get(),
            let asset = chain.utilityAsset() else {
            return
        }

        let chainAssetId = ChainAsset(chain: chain, asset: asset).chainAssetId

        wireframe.selectChain(
            from: view,
            delegate: self,
            selectedChainAssetId: chainAssetId
        )
    }

    func handleWalletSwitch() {
        wireframe.showWalletSwitch(from: view)
    }

    func handleYourContributions() {
        guard
            let chainResult = selectedChainResult,
            let crowdloansResult = crowdloansResult,
            let viewInfoResult = createViewInfoResult(),
            case let .success(chain) = chainResult,
            let asset = chain.utilityAssets().first
        else { return }

        do {
            let crowdloans = try crowdloansResult.get()
            let viewInfo = try viewInfoResult.get()
            let chainAsset = ChainAssetDisplayInfo(asset: asset.displayInfo, chain: chain.chainFormat)

            wireframe.showYourContributions(
                crowdloans: crowdloans,
                viewInfo: viewInfo,
                chainAsset: chainAsset,
                from: view
            )
        } catch {
            logger?.error(error.localizedDescription)
        }
    }
}

extension CrowdloanListPresenter: CrowdloanListInteractorOutputProtocol {
    func didReceiveDisplayInfo(result: Result<CrowdloanDisplayInfoDict, Error>) {
        logger?.info("Did receive display info: \(result)")

        displayInfoResult = result
        updateListView()
    }

    func didReceiveCrowdloans(result: Result<[Crowdloan], Error>) {
        logger?.info("Did receive crowdloans: \(result)")

        crowdloansResult = result
        updateListView()
    }

    func didReceiveBlockNumber(result: Result<BlockNumber?, Error>) {
        switch result {
        case let .success(blockNumber):
            self.blockNumber = blockNumber

            updateListView()
        case let .failure(error):
            logger?.error("Did receivee block number error: \(error)")
        }
    }

    func didReceiveBlockDuration(result: Result<BlockTime, Error>) {
        blockDurationResult = result
        updateListView()
    }

    func didReceiveLeasingPeriod(result: Result<LeasingPeriod, Error>) {
        leasingPeriodResult = result
        updateListView()
    }

    func didReceiveLeasingOffset(result: Result<LeasingOffset, Error>) {
        leasingOffsetResult = result
        updateListView()
    }

    func didReceiveContributions(result: Result<CrowdloanContributionDict, Error>) {
        if case let .failure(error) = result {
            logger?.error("Did receive contributions error: \(error)")
        }

        contributionsResult = result
        updateListView()
    }

    func didReceiveExternalContributions(result: Result<[ExternalContribution], Error>) {
        switch result {
        case let .success(contributions):
            let positiveContributions = contributions.filter { $0.amount > 0 }
            externalContributions = positiveContributions
            if !positiveContributions.isEmpty {
                updateListView()
            }
        case let .failure(error):
            logger?.error("Did receive external contributions error: \(error)")
        }
    }

    func didReceiveLeaseInfo(result: Result<ParachainLeaseInfoDict, Error>) {
        if case let .failure(error) = result {
            logger?.error("Did receive lease info error: \(error)")
        }

        leaseInfoResult = result
        updateListView()
    }

    func didReceiveSelectedChain(result: Result<ChainModel, Error>) {
        selectedChainResult = result
        updateChainView()
        updateListView()
    }

    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>) {
        accountInfoResult = result
        updateChainView()
    }

    func didReceive(wallet: MetaAccountModel) {
        self.wallet = wallet

        updateWalletSwitchView()
    }

    func didReceivePriceData(result: Result<PriceData?, Error>?) {
        priceDataResult = result
        updateListView()
    }
}

extension CrowdloanListPresenter: AssetSelectionDelegate {
    func assetSelection(view _: AssetSelectionViewProtocol, didCompleteWith chainAsset: ChainAsset) {
        if let currentChain = try? selectedChainResult?.get(), currentChain.chainId == chainAsset.chain.chainId {
            return
        }

        selectedChainResult = .success(chainAsset.chain)
        accountInfoResult = nil
        crowdloansResult = nil
        displayInfoResult = nil
        blockNumber = nil
        blockDurationResult = nil
        leasingPeriodResult = nil
        contributionsResult = nil
        leaseInfoResult = nil

        updateChainView()

        view?.didReceive(listState: .loading)

        interactor.saveSelected(chainModel: chainAsset.chain)
    }
}

extension CrowdloanListPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            updateChainView()
            updateListView()
        }
    }
}
