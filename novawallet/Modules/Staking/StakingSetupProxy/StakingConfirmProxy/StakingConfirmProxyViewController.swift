import UIKit
import SoraFoundation

final class StakingConfirmProxyViewController: UIViewController, ViewHolder {
    typealias RootViewType = StakingConfirmProxyViewLayout

    let presenter: StakingConfirmProxyPresenterProtocol

    init(
        presenter: StakingConfirmProxyPresenterProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = StakingConfirmProxyViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocalization()
        setupHandlers()
        presenter.setup()
    }

    private func setupLocalization() {
        let languages = selectedLocale.rLanguages

        rootView.networkCell.titleLabel.text = R.string.localizable.commonNetwork(
            preferredLanguages: languages
        )
        rootView.proxiedWalletCell.titleLabel.text = R.string.localizable.stakingConfirmProxyWallet(
            preferredLanguages: languages
        )
        rootView.proxiedAddressCell.titleLabel.text = R.string.localizable.stakingConfirmProxyAccountProxied(
            preferredLanguages: languages
        )
        rootView.proxyDepositView.titleButton.imageWithTitleView?.title = R.string.localizable.stakingSetupProxyDeposit(
            preferredLanguages: languages
        )
        rootView.feeCell.rowContentView.locale = selectedLocale
        rootView.proxyTypeCell.titleLabel.text = R.string.localizable.stakingConfirmProxyTypeTitle(
            preferredLanguages: languages
        )
        rootView.proxyTypeCell.detailsLabel.text = R.string.localizable.stakingConfirmProxyTypeSubtitle(
            preferredLanguages: languages
        )
        rootView.proxyAddressCell.titleLabel.text = R.string.localizable.stakingConfirmProxyAccountProxy(
            preferredLanguages: languages
        )
        title = R.string.localizable.delegationsAddTitle(
            preferredLanguages: languages
        )
    }

    private func setupHandlers() {
        rootView.proxiedAddressCell.addTarget(
            self,
            action: #selector(proxiedAddressAction),
            for: .touchUpInside
        )
        rootView.proxyAddressCell.addTarget(
            self,
            action: #selector(proxyAddressAction),
            for: .touchUpInside
        )
        rootView.proxyDepositView.addTarget(
            self,
            action: #selector(depositInfoAction),
            for: .touchUpInside
        )
        rootView.actionButton.actionButton.addTarget(
            self,
            action: #selector(confirmAction),
            for: .touchUpInside
        )
    }

    @objc private func proxiedAddressAction() {
        presenter.showProxiedAddressOptions()
    }

    @objc private func proxyAddressAction() {
        presenter.showProxyAddressOptions()
    }

    @objc private func depositInfoAction() {
        presenter.showDepositInfo()
    }

    @objc private func confirmAction() {
        presenter.confirm()
    }
}

extension StakingConfirmProxyViewController: StakingConfirmProxyViewProtocol {
    func didReceiveProxyDeposit(viewModel: LoadableViewModelState<NetworkFeeInfoViewModel>) {
        rootView.proxyDepositView.bind(loadableViewModel: viewModel)
    }

    func didReceiveFee(viewModel: BalanceViewModelProtocol?) {
        rootView.feeCell.rowContentView.bind(viewModel: viewModel)
    }

    func didReceiveNetwork(viewModel: NetworkViewModel) {
        rootView.networkCell.bind(viewModel: viewModel)
    }

    func didReceiveWallet(viewModel: StackCellViewModel) {
        rootView.proxiedWalletCell.bind(viewModel: viewModel)
    }

    func didReceiveProxiedAddress(viewModel: DisplayAddressViewModel) {
        rootView.proxiedAddressCell.bind(viewModel: viewModel.cellViewModel)
    }

    func didReceiveProxyAddress(viewModel: DisplayAddressViewModel) {
        rootView.proxyAddressCell.bind(viewModel: viewModel.cellViewModel)
    }

    func didStartLoading() {
        rootView.actionButton.startLoading()
    }

    func didStopLoading() {
        rootView.actionButton.stopLoading()
    }
}

extension StakingConfirmProxyViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            applyLocalization()
        }
    }
}
