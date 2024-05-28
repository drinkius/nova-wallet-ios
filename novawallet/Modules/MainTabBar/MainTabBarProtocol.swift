import UIKit

protocol MainTabBarViewProtocol: ControllerBackedProtocol {
    func didReplaceView(for newView: UIViewController, for index: Int)
}

protocol MainTabBarPresenterProtocol: AnyObject {
    func setup()
    func viewDidAppear()
}

protocol MainTabBarInteractorInputProtocol: AnyObject {
    func setup()
    func setPushNotificationsSetupScreenSeen()
    func approveCloudBackupChanges()
}

protocol MainTabBarInteractorOutputProtocol: AnyObject {
    func didRequestImportAccount(source: SecretSource)
    func didRequestScreenOpen(_ screen: UrlHandlingScreen)
    func didRequestPushScreenOpen(_ screen: PushNotification.OpenScreen)
    func didRequestReviewCloud(changes: CloudBackupSyncResult.Changes)
    func didFailApplyingCloud(changes: CloudBackupSyncResult.Changes, error: Error)
    func didRequestPushNotificationsSetupOpen()
}

protocol MainTabBarWireframeProtocol: AlertPresentable, AuthorizationAccessible {
    func presentAccountImport(on view: MainTabBarViewProtocol?, source: SecretSource)
    func presentScreenIfNeeded(
        on view: MainTabBarViewProtocol?,
        screen: UrlHandlingScreen,
        locale: Locale
    )
    func presentScreenIfNeeded(
        on view: MainTabBarViewProtocol?,
        screen: PushNotification.OpenScreen
    )
    func presentPushNotificationsSetup(
        on view: MainTabBarViewProtocol?,
        completion: @escaping () -> Void
    )

    func presentCloudBackupReview(
        from view: MainTabBarViewProtocol?,
        changes: CloudBackupSyncResult.Changes,
        delegate: CloudBackupReviewChangesDelegate
    )
}

protocol MainTabBarViewFactoryProtocol: AnyObject {
    static func createView() -> MainTabBarViewProtocol?
}
