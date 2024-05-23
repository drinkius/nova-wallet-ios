import Foundation
import SoraKeystore
import SoraFoundation

struct AdvancedExportViewFactory {
    static func createView(
        with metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) -> AdvancedExportViewProtocol? {
        let keystore = Keychain()

        let interactor = AdvancedExportInteractor(keystore: keystore)
        let wireframe = AdvancedExportWireframe()

        let networkViewModelFactory = NetworkViewModelFactory()
        let advancedExportViewModelFactory = AdvancedExportViewModelFactory(
            networkViewModelFactory: networkViewModelFactory
        )

        let presenter = AdvancedExportPresenter(
            interactor: interactor,
            wireframe: wireframe,
            localizationManager: LocalizationManager.shared,
            logger: Logger.shared,
            viewModelFactory: advancedExportViewModelFactory,
            metaAccount: metaAccount,
            chain: chain
        )

        let view = AdvancedExportViewController(
            presenter: presenter,
            localizationManager: LocalizationManager.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        return view
    }
}
