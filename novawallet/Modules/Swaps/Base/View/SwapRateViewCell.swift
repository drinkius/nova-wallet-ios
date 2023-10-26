import SoraUI

final class SwapRateViewCell: RowView<SwapRateView>, StackTableViewCellProtocol {
    var titleButton: RoundedButton { rowContentView.titleView }
    var valueLabel: UILabel { rowContentView.valueView }

    func bind(loadableViewModel: LoadableViewModelState<String>) {
        rowContentView.bind(loadableViewModel: loadableViewModel)
    }
}
