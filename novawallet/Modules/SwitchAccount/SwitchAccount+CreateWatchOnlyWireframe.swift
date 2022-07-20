import Foundation

extension SwitchAccount {
    final class CreateWatchOnlyWireframe: CreateWatchOnlyWireframeProtocol {
        func proceed(from view: CreateWatchOnlyViewProtocol?) {
            guard let navigationController = view?.controller.navigationController else {
                return
            }

            navigationController.popToRootViewController(animated: true)
        }
    }
}
