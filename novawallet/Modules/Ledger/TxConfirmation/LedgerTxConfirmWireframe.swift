import UIKit
import SoraUI

final class LedgerTxConfirmWireframe: LedgerTxConfirmWireframeProtocol {
    weak var transactionStatusView: ControllerBackedProtocol?

    private func replaceTransactionStatus(
        with newTransactionStatusView: ControllerBackedProtocol,
        on view: ControllerBackedProtocol?
    ) {
        let factory = ModalSheetPresentationFactory(configuration: ModalSheetPresentationConfiguration.fearless)

        newTransactionStatusView.controller.modalTransitioningFactory = factory
        newTransactionStatusView.controller.modalPresentationStyle = .custom

        if transactionStatusView != nil {
            view?.controller.dismiss(animated: false)

            transactionStatusView = newTransactionStatusView

            view?.controller.present(newTransactionStatusView.controller, animated: false)
        } else {
            transactionStatusView = newTransactionStatusView

            view?.controller.present(newTransactionStatusView.controller, animated: true)
        }
    }

    func complete(on view: ControllerBackedProtocol?) {
        view?.controller.dismiss(animated: true)
    }

    func transitToTransactionReview(
        on view: ControllerBackedProtocol?,
        timer: CountdownTimerMediator,
        deviceName: String
    ) {
        guard
            let transactionSignView = LedgerBottomSheetViewFactory.createReviewLedgerTransactionView(
                for: timer,
                deviceName: deviceName
            ) else {
            return
        }

        replaceTransactionStatus(with: transactionSignView, on: view)
    }

    func transitToTransactionExpired(
        on view: ControllerBackedProtocol?,
        expirationTimeInterval: TimeInterval,
        completion: @escaping MessageSheetCallback
    ) {
        guard
            let transactionExpiredView = LedgerBottomSheetViewFactory.createTransactionExpiredView(
                for: expirationTimeInterval,
                completionClosure: completion
            ) else {
            return
        }

        replaceTransactionStatus(with: transactionExpiredView, on: view)
    }

    func transitToTransactionNotSupported(
        on view: ControllerBackedProtocol?,
        completion: @escaping MessageSheetCallback
    ) {
        guard let notSupportedView = LedgerBottomSheetViewFactory.createTransactionNotSupportedView(
            completionClosure: completion
        ) else {
            return
        }

        replaceTransactionStatus(with: notSupportedView, on: view)
    }

    func transitToMetadataOutdated(
        on view: ControllerBackedProtocol?,
        chainName: String,
        completion: @escaping MessageSheetCallback
    ) {
        guard let outdateMetadataView = LedgerBottomSheetViewFactory.createMetadataOutdatedView(
            chainName: chainName,
            completionClosure: completion
        ) else {
            return
        }

        replaceTransactionStatus(with: outdateMetadataView, on: view)
    }

    func transitToInvalidSignature(
        on view: ControllerBackedProtocol?,
        completion: @escaping MessageSheetCallback
    ) {
        guard let invalidSignatureView = LedgerBottomSheetViewFactory.createSignatureInvalidView(
            completionClosure: completion
        ) else {
            return
        }

        replaceTransactionStatus(with: invalidSignatureView, on: view)
    }

    func closeTransactionStatus(on view: ControllerBackedProtocol?) {
        if transactionStatusView != nil {
            transactionStatusView = nil

            view?.controller.dismiss(animated: true)
        }
    }
}
