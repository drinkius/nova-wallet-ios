import Foundation
import RobinHood
import SoraFoundation

final class DelegateVotedReferendaPresenter {
    weak var view: DelegateVotedReferendaViewProtocol?
    let wireframe: DelegateVotedReferendaWireframeProtocol
    let interactor: DelegateVotedReferendaInteractorInputProtocol

    let viewModelFactory: DelegateReferendumsModelFactoryProtocol
    let statusViewModelFactory: ReferendumStatusViewModelFactoryProtocol
    let sorting: ReferendumsSorting
    let logger: LoggerProtocol
    let name: String

    private var price: PriceData?
    private var referendums: [ReferendumLocal]?
    private var referendumsMetadata: ReferendumMetadataMapping?
    private var blockNumber: BlockNumber?
    private var blockTime: BlockTime?

    private var maxStatusTimeInterval: TimeInterval?
    private var countdownTimer: CountdownTimer?
    private var timeModels: [UInt: StatusTimeViewModel?]?
    private var chain: ChainModel?
    private var voting: GovernanceOffchainVotes?

    deinit {
        invalidateTimer()
    }

    init(
        interactor: DelegateVotedReferendaInteractorInputProtocol,
        wireframe: DelegateVotedReferendaWireframeProtocol,
        viewModelFactory: DelegateReferendumsModelFactoryProtocol,
        statusViewModelFactory: ReferendumStatusViewModelFactoryProtocol,
        sorting: ReferendumsSorting,
        name: String,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
        self.statusViewModelFactory = statusViewModelFactory
        self.sorting = sorting
        self.logger = logger
        self.name = name
        self.localizationManager = localizationManager
    }

    private func updateReferendumsView() {
        guard let view = view else {
            return
        }
        guard let currentBlock = blockNumber,
              let blockTime = blockTime,
              let referendums = referendums,
              let chainModel = chain,
              let voting = voting else {
            return
        }

        let referendumsViewModels = viewModelFactory.createReferendumsViewModel(input: .init(
            referendums: referendums,
            metadataMapping: referendumsMetadata,
            votes: voting,
            offchainVotes: nil,
            chainInfo: .init(chain: chainModel, currentBlock: currentBlock, blockDuration: blockTime),
            locale: selectedLocale,
            voterName: name
        ))

        view.update(viewModels: referendumsViewModels)
    }

    private func updateTimeModels() {
        guard let view = view else {
            return
        }
        guard let currentBlock = blockNumber, let blockTime = blockTime, let referendums = referendums else {
            return
        }

        let timeModels = statusViewModelFactory.createTimeViewModels(
            referendums: referendums,
            currentBlock: currentBlock,
            blockDuration: blockTime,
            locale: selectedLocale
        )

        self.timeModels = timeModels
        maxStatusTimeInterval = timeModels.compactMap { $0.value?.timeInterval }.max(by: <)
        invalidateTimer()
        setupTimer()
        updateTimerDisplay()

        view.updateReferendums(time: timeModels)
    }

    private func invalidateTimer() {
        countdownTimer?.delegate = nil
        countdownTimer?.stop()
        countdownTimer = nil
    }

    private func setupTimer() {
        guard let maxStatusTimeInterval = maxStatusTimeInterval else {
            return
        }

        countdownTimer = CountdownTimer()
        countdownTimer?.delegate = self
        countdownTimer?.start(with: maxStatusTimeInterval)
    }

    private func updateTimerDisplay() {
        guard
            let view = view,
            let maxStatusTimeInterval = maxStatusTimeInterval,
            let remainedTimeInterval = countdownTimer?.remainedInterval,
            let timeModels = timeModels else {
            return
        }

        let elapsedTime = maxStatusTimeInterval >= remainedTimeInterval ?
            maxStatusTimeInterval - remainedTimeInterval : 0

        let updatedTimeModels = timeModels.reduce(into: timeModels) { result, model in
            guard let timeModel = model.value,
                  let time = timeModel.timeInterval else {
                return
            }

            guard time > elapsedTime else {
                result[model.key] = nil
                return
            }
            let remainedTime = time - elapsedTime
            guard let updatedViewModel = timeModel.updateModelClosure(remainedTime) else {
                result[model.key] = nil
                return
            }

            result[model.key] = .init(
                viewModel: updatedViewModel,
                timeInterval: time,
                updateModelClosure: timeModel.updateModelClosure
            )
        }

        self.timeModels = updatedTimeModels
        view.updateReferendums(time: updatedTimeModels)
    }
}

extension DelegateVotedReferendaPresenter: DelegateVotedReferendaInteractorOutputProtocol {
    func didReceiveChain(_ chainModel: ChainModel) {
        chain = chainModel
        updateReferendumsView()
    }

    func didReceiveReferendumsMetadata(_ changes: [DataProviderChange<ReferendumMetadataLocal>]) {
        let indexedReferendums = Array((referendumsMetadata ?? [:]).values).reduceToDict()

        referendumsMetadata = changes.reduce(into: referendumsMetadata ?? [:]) { accum, change in
            switch change {
            case let .insert(newItem), let .update(newItem):
                accum[newItem.referendumId] = newItem
            case let .delete(deletedIdentifier):
                if let referendumId = indexedReferendums[deletedIdentifier]?.referendumId {
                    accum[referendumId] = nil
                }
            }
        }
        updateReferendumsView()
    }

    func didReceiveOffchainVoting(_ voting: GovernanceOffchainVotes) {
        if self.voting != voting {
            self.voting = voting
            updateReferendumsView()
        }
    }

    func didReceiveBlockNumber(_ blockNumber: BlockNumber) {
        self.blockNumber = blockNumber

        updateReferendumsView()
        // interactor.refresh()
    }

    func didReceiveBlockTime(_ blockTime: BlockTime) {
        self.blockTime = blockTime
        updateTimeModels()
    }

    func didReceiveReferendums(_ referendums: [ReferendumLocal]) {
        self.referendums = referendums.sorted { sorting.compare(referendum1: $0, referendum2: $1) }

        updateReferendumsView()
        updateTimeModels()
    }

    func didReceiveError(_ error: DelegateVotedReferendaError) {
        logger.error("Did receive error: \(error)")
    }
}

extension DelegateVotedReferendaPresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            updateReferendumsView()
        }
    }
}

extension DelegateVotedReferendaPresenter: DelegateVotedReferendaPresenterProtocol {
    func setup() {
        interactor.setup()
    }
}

extension DelegateVotedReferendaPresenter: CountdownTimerDelegate {
    func didStart(with _: TimeInterval) {
        updateTimerDisplay()
    }

    func didCountdown(remainedInterval _: TimeInterval) {
        updateTimerDisplay()
    }

    func didStop(with _: TimeInterval) {
        updateTimerDisplay()
    }
}
