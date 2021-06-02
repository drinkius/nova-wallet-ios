import Foundation
import SoraFoundation
import CommonWallet

protocol StakingMainViewProtocol: ControllerBackedProtocol, Localizable {
    func didReceive(viewModel: StakingMainViewModelProtocol)
    func didReceiveChainName(chainName newChainName: LocalizableResource<String>)
    func didRecieveNetworkStakingInfo(viewModel: LocalizableResource<NetworkStakingInfoViewModelProtocol>?)

    func didReceiveStakingState(viewModel: StakingViewState)
    func didReceiveAnalytics(viewModel: LocalizableResource<RewardAnalyticsWidgetViewModel>)
}

protocol StakingMainPresenterProtocol: AnyObject {
    func setup()
    func performMainAction()
    func performAccountAction()
    func performManageStakingAction()
    func performNominationStatusAction()
    func performValidationStatusAction()
    func performRewardInfoAction()
    func performChangeValidatorsAction()
    func performBondMoreAction()
    func performRedeemAction()
    func performAnalyticsAction()
    func updateAmount(_ newValue: Decimal)
    func selectAmountPercentage(_ percentage: Float)
    func selectStory(at index: Int)
}

protocol StakingMainInteractorInputProtocol: AnyObject {
    func setup()
}

protocol StakingMainInteractorOutputProtocol: AnyObject {
    func didReceive(selectedAddress: String)
    func didReceive(price: PriceData?)
    func didReceive(priceError: Error)
    func didReceive(totalReward: TotalRewardItem)
    func didReceive(totalReward: Error)
    func didReceive(accountInfo: AccountInfo?)
    func didReceive(balanceError: Error)
    func didReceive(calculator: RewardCalculatorEngineProtocol)
    func didReceive(calculatorError: Error)
    func didReceive(stashItem: StashItem?)
    func didReceive(stashItemError: Error)
    func didReceive(ledgerInfo: StakingLedger?)
    func didReceive(ledgerInfoError: Error)
    func didReceive(nomination: Nomination?)
    func didReceive(nominationError: Error)
    func didReceive(validatorPrefs: ValidatorPrefs?)
    func didReceive(validatorError: Error)
    func didReceive(electionStatus: ElectionStatus?)
    func didReceive(electionStatusError: Error)
    func didReceive(eraStakersInfo: EraStakersInfo)
    func didReceive(eraStakersInfoError: Error)
    func didReceive(networkStakingInfo: NetworkStakingInfo)
    func didReceive(networkStakingInfoError: Error)
    func didReceive(payee: RewardDestinationArg?)
    func didReceive(payeeError: Error)
    func didReceive(newChain: Chain)
    func didReceieve(rewardItemData: Result<[SubscanRewardItemData], Error>)

    func didReceiveMaxNominatorsPerValidator(result: Result<UInt32, Error>)

    func didReceiveControllerAccount(result: Result<AccountItem?, Error>)
}

protocol StakingMainWireframeProtocol: AlertPresentable, ErrorPresentable, StakingErrorPresentable {
    func showSetupAmount(from view: StakingMainViewProtocol?, amount: Decimal?)

    func showManageStaking(
        from view: StakingMainViewProtocol?,
        items: [StakingManageOption],
        delegate: ModalPickerViewControllerDelegate?,
        context: AnyObject?
    )

    func showRecommendedValidators(
        from view: StakingMainViewProtocol?,
        existingBonding: ExistingBonding
    )

    func showStories(
        from view: ControllerBackedProtocol?,
        startingFrom index: Int
    )

    func showRewardDetails(from view: ControllerBackedProtocol?, maxReward: Decimal, avgReward: Decimal)

    func showRewardPayoutsForNominator(from view: ControllerBackedProtocol?, stashAddress: AccountAddress)
    func showRewardPayoutsForValidator(from view: ControllerBackedProtocol?, stashAddress: AccountAddress)
    func showStakingBalance(from view: ControllerBackedProtocol?)
    func showNominatorValidators(from view: ControllerBackedProtocol?)
    func showRewardDestination(from view: ControllerBackedProtocol?)
    func showControllerAccount(from view: ControllerBackedProtocol?)

    func showAccountsSelection(from view: StakingMainViewProtocol?)
    func showBondMore(from view: ControllerBackedProtocol?)
    func showRedeem(from view: ControllerBackedProtocol?)
    func showAnalytics(from view: ControllerBackedProtocol?)
}

protocol StakingMainViewFactoryProtocol: AnyObject {
    static func createView() -> StakingMainViewProtocol?
}
