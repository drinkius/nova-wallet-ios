import Foundation
import UIKit

protocol DAppAlertPresentable: AlertPresentable {
    func showFavoritesRemovalConfirmation(
        from view: ControllerBackedProtocol?,
        name: String,
        locale: Locale,
        handler: @escaping () -> Void
    )

    func showAuthorizedRemovalConfirmation(
        from view: ControllerBackedProtocol?,
        name: String,
        locale: Locale,
        handler: @escaping () -> Void
    )

    func showUnknownDappWarning(
        from view: ControllerBackedProtocol?,
        locale: Locale,
        handler: @escaping () -> Void
    )
}

extension DAppAlertPresentable {
    func showFavoritesRemovalConfirmation(
        from view: ControllerBackedProtocol?,
        name: String,
        locale: Locale,
        handler: @escaping () -> Void
    ) {
        let title = R.string.localizable.dappRemoveFavoritesTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.dappRemoveFavoritesMessage(
            name,
            preferredLanguages: locale.rLanguages
        )

        showRemoval(from: view, title: title, message: message, locale: locale, handler: handler)
    }

    func showAuthorizedRemovalConfirmation(
        from view: ControllerBackedProtocol?,
        name: String,
        locale: Locale,
        handler: @escaping () -> Void
    ) {
        let title = R.string.localizable.dappRemoveAuthorizedTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.dappRemoveAuthorizedMessage(
            name,
            preferredLanguages: locale.rLanguages
        )

        showRemoval(from: view, title: title, message: message, locale: locale, handler: handler)
    }

    func showUnknownDappWarning(
        from view: ControllerBackedProtocol?,
        locale: Locale,
        handler: @escaping () -> Void
    ) {
        let action = AlertPresentableAction(
            title: R.string.localizable.dappUnknownWarningOpen(preferredLanguages: locale.rLanguages),
            style: .destructive,
            handler: handler
        )
        let viewModel = AlertPresentableViewModel(
            title: R.string.localizable.dappUnknownWarningTitle(preferredLanguages: locale.rLanguages),
            message: R.string.localizable.dappUnknownWarningMessage(preferredLanguages: locale.rLanguages),
            actions: [action],
            closeAction: R.string.localizable.commonClose(preferredLanguages: locale.rLanguages)
        )

        present(
            viewModel: viewModel,
            style: .alert,
            from: view
        )
    }

    private func showRemoval(
        from view: ControllerBackedProtocol?,
        title: String,
        message: String,
        locale: Locale,
        handler: @escaping () -> Void
    ) {
        let removeTitle = R.string.localizable.commonRemove(preferredLanguages: locale.rLanguages)

        let removeAction = AlertPresentableAction(title: removeTitle, style: .destructive, handler: handler)

        let closeTitle = R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages)

        let viewModel = AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [removeAction],
            closeAction: closeTitle
        )

        present(viewModel: viewModel, style: .alert, from: view)
    }
}
