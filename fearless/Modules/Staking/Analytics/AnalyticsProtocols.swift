import SoraFoundation

protocol AnalyticsViewProtocol: ControllerBackedProtocol {
    func configure(with viewModel: LocalizableResource<AnalyticsViewModel>)
}

protocol AnalyticsPresenterProtocol: AnyObject {
    func setup()
    func didSelectPeriod(_ period: AnalyticsPeriod)
}

protocol AnalyticsInteractorInputProtocol: AnyObject {
    func setup()
}

protocol AnalyticsInteractorOutputProtocol: AnyObject {
    func didReceieve(rewardItemData: Result<[SubscanRewardItemData], Error>)
    func didReceivePriceData(result: Result<PriceData?, Error>)
}

protocol AnalyticsWireframeProtocol: AnyObject {}
