import UIKit
import SoraUI

final class NetworkManageNodeViewLayout: UIView {

    let containerView: ScrollableContainerView = {
        let view = ScrollableContainerView(axis: .vertical, respectsSafeArea: true)
        view.stackView.alignment = .fill
        return view
    }()

    let titleLabel: UILabel = .create { view in
        view.apply(style: .semiboldBodyPrimary)
        view.textAlignment = .left
    }
    
    let nodeNameLabel: UILabel = .create { view in
        view.apply(style: .footnoteSecondary)
        view.textAlignment = .left
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = R.color.colorBottomSheetBackground()

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addAction() -> StackActionCell {
        let cell = StackActionCell()

        cell.rowContentView.disclosureIndicatorView.image = R.image.iconSmallArrow()?.tinted(
            with: R.color.colorIconSecondary()!
        )

        cell.preferredHeight = NetworkManageNodeMeasurement.cellHeight

        cell.borderView.borderType = .none

        containerView.stackView.addArrangedSubview(cell)

        return cell
    }

    private func setupLayout() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.layoutMargins = UIEdgeInsets(
            top: 0.0,
            left: UIConstants.horizontalInset,
            bottom: 0.0,
            right: UIConstants.horizontalInset
        )

        containerView.stackView.addArrangedSubview(titleLabel)
        containerView.stackView.addArrangedSubview(nodeNameLabel)

        containerView.stackView.setCustomSpacing(
            NetworkManageNodeMeasurement.titleSpacing,
            after: titleLabel
        )

        containerView.stackView.setCustomSpacing(
            NetworkManageNodeMeasurement.nodeNameSpacing,
            after: nodeNameLabel
        )
    }
}

enum NetworkManageNodeMeasurement {
    static let titleHeight: CGFloat = 22.0
    static let nodeNameHeight: CGFloat = 18

    static let cellHeight: CGFloat = 48.0

    static let titleSpacing: CGFloat = 10
    static let nodeNameSpacing: CGFloat = 12

    static func measurePreferredHeight(for actionsCount: Int) -> CGFloat {
        let cellsHeight = cellHeight * CGFloat(actionsCount)

        let calculatedHeight = titleHeight + nodeNameHeight  + titleSpacing + nodeNameSpacing + cellsHeight

        let maxHeight = ModalSheetPresentationConfiguration.maximumContentHeight

        return min(maxHeight, calculatedHeight)
    }
}
