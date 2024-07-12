import Foundation
import UIKit

final class CustomNetworkWireframe: CustomNetworkWireframeProtocol {
    func showNetworksList(
        from view: CustomNetworkViewProtocol?,
        successAlertTitle: String
    ) {
        guard
            let viewControllers = view?.controller.navigationController?.viewControllers,
            let networksListViewController = viewControllers.first(where: { $0 is NetworksListViewController })
        else {
            return
        }

        view?.controller.navigationController?.popToViewController(
            networksListViewController,
            animated: true
        )

        presentSuccessNotification(
            successAlertTitle,
            from: networksListViewController as? ControllerBackedProtocol
        )
    }
}
