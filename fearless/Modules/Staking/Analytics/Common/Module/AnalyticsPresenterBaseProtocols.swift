import Foundation

protocol AnalyticsPresenterBaseProtocol: AnyObject {
    func setup()
    func reload()
    func didSelectPeriod(_ period: AnalyticsPeriod)
    func didSelectPrevious()
    func didSelectNext()
    func handleReward(_ rewardModel: AnalyticsRewardDetailsModel)
}

protocol AnalyticsBaseViewModel {
    var sections: [AnalyticsRewardSection] { get }
    var emptyListDescription: String { get }
    var isEmpty: Bool { get }
}