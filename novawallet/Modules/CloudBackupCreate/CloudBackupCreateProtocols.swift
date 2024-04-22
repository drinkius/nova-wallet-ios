import SoraFoundation

protocol CloudBackupCreateViewProtocol: ControllerBackedProtocol, LoadableViewProtocol {
    func didReceive(passwordViewModel: InputViewModelProtocol)
    func didReceive(confirmViewModel: InputViewModelProtocol)
    func didRecieve(hints: [HintListView.ViewModel])
    func didReceive(canContinue: Bool)
}

protocol CloudBackupCreatePresenterProtocol: AnyObject {
    func setup()
    func applyEnterPasswordChange()
    func applyConfirmPasswordChange()
    func activateContinue()
}

protocol CloudBackupCreateInteractorInputProtocol: AnyObject {
    func createWallet(for password: String)
}

protocol CloudBackupCreateInteractorOutputProtocol: AnyObject {
    func didCreateWallet()
    func didReceive(error: CloudBackupCreateInteractorError)
}

protocol CloudBackupCreateWireframeProtocol: AlertPresentable, ErrorPresentable, CommonRetryable {}
