import Foundation
import SoraFoundation

final class ExportMnemonicPresenter {
    weak var view: ExportGenericViewProtocol?
    let wireframe: ExportMnemonicWireframeProtocol
    let interactor: ExportMnemonicInteractorInputProtocol
    let localizationManager: LocalizationManagerProtocol

    private(set) var exportData: ExportMnemonicData?

    init(
        interactor: ExportMnemonicInteractorInputProtocol,
        wireframe: ExportMnemonicWireframeProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.localizationManager = localizationManager
    }
}

extension ExportMnemonicPresenter: ExportGenericPresenterProtocol {
    func setup() {
        interactor.fetchExportData()
    }

    func activateExport() {
        guard let exportData = exportData else {
            return
        }

        wireframe.openConfirmationForMnemonic(exportData.mnemonic, from: view)
    }

    func activateAdvancedSettings() {}
}

extension ExportMnemonicPresenter: ExportMnemonicInteractorOutputProtocol {
    func didReceive(exportData: ExportMnemonicData) {
        self.exportData = exportData

        let viewModel = ExportGenericViewModel(sourceDetails: exportData.mnemonic.toString())
        view?.set(viewModel: viewModel)
    }

    func didReceive(error: Error) {
        if !wireframe.present(error: error, from: view, locale: localizationManager.selectedLocale) {
            _ = wireframe.present(
                error: CommonError.undefined,
                from: view,
                locale: localizationManager.selectedLocale
            )
        }
    }
}
