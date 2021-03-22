import Foundation

protocol EventVisitorProtocol: class {
    func processSelectedAccountChanged(event: SelectedAccountChanged)
    func processSelectedUsernameChanged(event: SelectedUsernameChanged)
    func processSelectedConnectionChanged(event: SelectedConnectionChanged)
    func processBalanceChanged(event: WalletBalanceChanged)
    func processStakingChanged(event: WalletStakingInfoChanged)
    func processNewTransaction(event: WalletNewTransactionInserted)
    func processPurchaseCompletion(event: PurchaseCompleted)
    func processTypeRegistryPrepared(event: TypeRegistryPrepared)
    func processEraStakersInfoChanged(event: EraStakersInfoChanged)
}

extension EventVisitorProtocol {
    func processSelectedAccountChanged(event: SelectedAccountChanged) {}
    func processSelectedConnectionChanged(event: SelectedConnectionChanged) {}
    func processBalanceChanged(event: WalletBalanceChanged) {}
    func processStakingChanged(event: WalletStakingInfoChanged) {}
    func processNewTransaction(event: WalletNewTransactionInserted) {}
    func processSelectedUsernameChanged(event: SelectedUsernameChanged) {}
    func processPurchaseCompletion(event: PurchaseCompleted) {}
    func processTypeRegistryPrepared(event: TypeRegistryPrepared) {}
    func processEraStakersInfoChanged(event: EraStakersInfoChanged) {}
}
