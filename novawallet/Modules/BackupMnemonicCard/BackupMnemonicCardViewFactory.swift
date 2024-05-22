import Foundation
import SoraKeystore
import SoraFoundation
import SoraUI

struct BackupMnemonicCardViewFactory {
    static func createView(
        with metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) -> BackupMnemonicCardViewProtocol? {
        let keychain = Keychain()

        let interactor = BackupMnemonicCardInteractor(
            metaAccount: metaAccount,
            chain: chain,
            keystore: keychain,
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        let wireframe = BackupMnemonicCardWireframe()

        let networkViewModelFactory = NetworkViewModelFactory()

        let presenter = BackupMnemonicCardPresenter(
            interactor: interactor,
            wireframe: wireframe,
            metaAccount: metaAccount,
            chain: chain,
            networkViewModelFactory: networkViewModelFactory,
            localizationManager: LocalizationManager.shared
        )

        let appearanceAnimator = FadeAnimator(
            from: 0.0,
            to: 1.0,
            duration: 0.2,
            delay: 0.0,
            options: .curveEaseInOut
        )

        let disappearanceAnimator = FadeAnimator(
            from: 1.0,
            to: 0.0,
            duration: 0.15,
            delay: 0.0,
            options: .curveEaseInOut
        )

        let view = BackupMnemonicCardViewController(
            presenter: presenter,
            appearanceAnimator: appearanceAnimator,
            disappearanceAnimator: disappearanceAnimator,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}
