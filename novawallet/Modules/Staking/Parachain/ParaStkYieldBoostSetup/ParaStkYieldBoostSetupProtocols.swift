import BigInt
import CommonWallet

protocol ParaStkYieldBoostSetupViewProtocol: ControllerBackedProtocol, LoadableViewProtocol {
    func didReceiveCollator(viewModel: AccountDetailsSelectionViewModel?)
    func didReceiveRewardComparison(viewModel: ParaStkYieldBoostComparisonViewModel)
    func didReceiveYieldBoostSelected(_ isSelected: Bool)
    func didReceiveYieldBoostPeriod(days: UInt?)
    func didReceiveAssetBalance(viewModel: AssetBalanceViewModelProtocol)
    func didReceiveAmount(inputViewModel: AmountInputViewModelProtocol)
}

protocol ParaStkYieldBoostSetupPresenterProtocol: AnyObject {
    func setup()
}

protocol ParaStkYieldBoostSetupInteractorInputProtocol: AnyObject {
    func setup()
    func requestParams(for stake: BigUInt, collator: AccountId)
}

protocol ParaStkYieldBoostSetupInteractorOutputProtocol: AnyObject {
    func didReceiveAssetBalance(_ balance: AssetBalance?)
    func didReceiveRewardCalculator(_ calculator: ParaStakingRewardCalculatorEngineProtocol)
    func didReceivePrice(_ priceData: PriceData?)
    func didReceiveDelegator(_ delegator: ParachainStaking.Delegator?)
    func didReceiveDelegationIdentities(_ identities: [AccountId: AccountIdentity]?)
    func didReceiveScheduledRequests(_ scheduledRequests: [ParachainStaking.DelegatorScheduledRequest]?)
    func didReceiveYieldBoostTasks(_ tasks: [ParaStkYieldBoostState.Task])
    func didReceiveYieldBoostParams(_ params: ParaStkYieldBoostResponse, stake: BigUInt, collator: AccountId)
    func didReceiveError(_ error: ParaStkYieldBoostSetupInteractorError)
}

protocol ParaStkYieldBoostSetupWireframeProtocol: AnyObject {}
