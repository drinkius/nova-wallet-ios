import Foundation
import SoraFoundation

final class MainTabBarPresenter {
    weak var view: MainTabBarViewProtocol?
    var interactor: MainTabBarInteractorInputProtocol!
    var wireframe: MainTabBarWireframeProtocol!
    let localizationManager: LocalizationManagerProtocol

    init(localizationManager: LocalizationManagerProtocol) {
        self.localizationManager = localizationManager
    }
}

extension MainTabBarPresenter: MainTabBarPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func viewDidAppear() {}
}

extension MainTabBarPresenter: MainTabBarInteractorOutputProtocol {
    func didRequestImportAccount(source: SecretSource) {
        wireframe.presentAccountImport(on: view, source: source)
    }

    func didRequestScreenOpen(_ screen: UrlHandlingScreen) {
        wireframe.presentScreenIfNeeded(
            on: view,
            screen: screen,
            locale: localizationManager.selectedLocale
        )
    }

    func didRequestPushScreenOpen(_ screen: PushNotification.OpenScreen) {
        wireframe.presentScreenIfNeeded(
            on: view,
            screen: screen
        )
    }

    func didRequestReviewCloud(changes _: CloudBackupSyncResult.Changes) {
        wireframe.presentCloudBackupUnsyncedChanges(from: view) { [weak self] in
            self?.wireframe.presentReviewUpdates(from: self?.view)
        }
    }

    func didFailApplyingCloudChanges(error _: Error) {
        wireframe.presentCloudBackupUpdateFailedIfNeeded(from: view) { [weak self] in
            self?.wireframe.presentReviewUpdates(from: self?.view)
        }
    }

    func didRequestPushNotificationsSetupOpen() {
        wireframe.presentPushNotificationsSetup(on: view) { [weak self] in
            self?.interactor.setPushNotificationsSetupScreenSeen()
        }
    }
}
