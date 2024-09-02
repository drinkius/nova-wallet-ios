import SnapKit
import UIKit
import SoraUI

struct VoteCardModel {
    let viewModel: VoteCardView.ViewModel
}

final class VoteCardView: RoundedView {
    private let gradientView: RoundedGradientBackgroundView = .create { view in
        view.applyCellBackgroundStyle()
    }

    private var summaryLabel: UILabel = .create { view in
        view.apply(style: .title3Primary)
        view.numberOfLines = 0
        view.textAlignment = .left
    }

    private let requestedView: GenericPairValueView<
        MultiValueView,
        UILabel
    > = .create { view in
        view.setVerticalAndSpacing(Constants.requestedViewInnerSpacing)
        view.fView.spacing = Constants.requestedViewInnerSpacing

        view.fView.stackView.alignment = .leading
        view.fView.valueTop.apply(style: .footnoteSecondary)
        view.fView.valueTop.text = "Requested:"
        view.fView.valueBottom.apply(style: .title3Primary)
        view.sView.apply(style: .caption1Secondary)
    }

    private var assetAmountLabel: UILabel {
        requestedView.fView.valueBottom
    }

    private var fiatAmountLabel: UILabel {
        requestedView.sView
    }

    private let readMoreButton: LoadableActionView = .create { view in
        view.actionButton.applyEnabledStyle(colored: R.color.colorButtonBackgroundSecondary()!)
        view.actionButton.imageWithTitleView?.title = "Read more"
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var cornerRadius: CGFloat {
        didSet {
            super.cornerRadius = cornerRadius
            gradientView.cornerRadius = cornerRadius
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func bind(viewModel: ViewModel) {
        gradientView.bind(model: viewModel.gradientModel)

        summaryLabel.text = viewModel.summary

        guard let requestedAmount = viewModel.requestedAmount else {
            requestedView.isHidden = true
            return
        }

        assetAmountLabel.text = requestedAmount.assetAmount
        fiatAmountLabel.text = requestedAmount.fiatAmount
    }
}

extension VoteCardView: CardStackable {
    func didBecomeTopView() {}

    func prepareForReuse() {
        transform = .identity
        summaryLabel.text = nil
        assetAmountLabel.text = nil
        fiatAmountLabel.text = nil
        requestedView.isHidden = false
    }
}

private extension VoteCardView {
    func setupLayout() {
        addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let content = UIView.vStack(
            spacing: Constants.contentSpacing,
            [
                summaryLabel,
                FlexibleSpaceView(),
                requestedView
            ]
        )

        addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(Constants.contentInset)
        }

        addSubview(readMoreButton)
        readMoreButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(Constants.contentInset)
            make.top.equalTo(content.snp.bottom).offset(Constants.buttonTopOffset)
            make.height.equalTo(UIConstants.actionHeight)
        }
    }
}

// MARK: ViewModel

extension VoteCardView {
    struct ViewModel {
        struct RequestedAmount {
            let assetAmount: String
            let fiatAmount: String
        }

        let summary: String
        let requestedAmount: RequestedAmount?
        let gradientModel: GradientBannerModel
    }
}

// MARK: Constants

private extension VoteCardView {
    enum Constants {
        static let contentInset: CGFloat = 24
        static let contentSpacing: CGFloat = 12
        static let requestedViewInnerSpacing: CGFloat = 8
        static let buttonTopOffset: CGFloat = 16
    }
}

enum VoteResult {
    case aye
    case nay
    case abstain

    var dismissalDirection: CardsZStack.DismissalDirection {
        switch self {
        case .aye:
            .right
        case .nay:
            .left
        case .abstain:
            .top
        }
    }
}
