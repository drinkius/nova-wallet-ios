import UIKit

final class CloudBackupSettingsInteractor {
    weak var presenter: CloudBackupSettingsInteractorOutputProtocol?

    let cloudBackupSyncFacade: CloudBackupSyncFacadeProtocol

    init(cloudBackupSyncFacade: CloudBackupSyncFacadeProtocol) {
        self.cloudBackupSyncFacade = cloudBackupSyncFacade
    }

    private func subscribeBackupState() {
        cloudBackupSyncFacade.unsubscribeState(self)

        cloudBackupSyncFacade.subscribeState(
            self,
            notifyingIn: .main
        ) { [weak self] state in
            self?.presenter?.didReceive(state: state)
        }
    }
}

extension CloudBackupSettingsInteractor: CloudBackupSettingsInteractorInputProtocol {
    func setup() {
        subscribeBackupState()
    }

    func retryStateFetch() {
        subscribeBackupState()
    }

    func enableBackup() {
        cloudBackupSyncFacade.enableBackup(
            for: nil,
            runCompletionIn: .main
        ) { [weak self] result in
            guard case let .failure(error) = result else {
                return
            }

            self?.presenter?.didReceive(error: .enableBackup(error))
        }
    }

    func disableBackup() {
        cloudBackupSyncFacade.disableBackup(runCompletionIn: .main) { [weak self] result in
            guard case let .failure(error) = result else {
                return
            }

            self?.presenter?.didReceive(error: .disableBackup(error))
        }
    }
}
