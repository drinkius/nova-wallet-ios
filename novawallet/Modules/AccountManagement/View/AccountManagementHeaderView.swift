import UIKit
import SoraUI
import SnapKit

final class AccountManagementHeaderView: UIView {
    let textBackgroundView: TriangularedView = {
        let view = TriangularedView()
        view.sideLength = 10.0
        view.shadowOpacity = 0.0
        view.fillColor = .clear
        view.highlightedFillColor = .clear
        view.strokeWidth = 1.0
        view.strokeColor = R.color.colorCheckboxBorder()!
        view.highlightedStrokeColor = R.color.colorCheckboxBorder()!
        return view
    }()

    let textField: AnimatedTextField = {
        let field = AnimatedTextField()
        field.contentInsets = UIEdgeInsets(top: 8.0, left: 16.0, bottom: 6.0, right: 16.0)
        field.titleColor = R.color.colorTextSecondary()!
        field.titleFont = .caption1
        field.textColor = R.color.colorTextPrimary()
        field.textFont = .regularSubheadline
        field.placeholderColor = R.color.colorTextSecondary()!
        field.placeholderFont = .regularSubheadline
        field.cursorColor = R.color.colorTextPrimary()!
        return field
    }()

    private(set) var hintView: BorderedIconLabelView?

    var bottomInset: CGFloat = 0.0 {
        didSet {
            if let hintView = hintView {
                hintView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().inset(bottomInset)
                }
            }
        }
    }

    var showsHintView: Bool {
        get {
            hintView != nil
        }

        set {
            if newValue {
                setupHintView()
            } else {
                clearHintView()
            }

            updateFieldConstraints()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindHint(text: String, icon: UIImage?) {
        hintView?.iconDetailsView.detailsLabel.text = text
        hintView?.iconDetailsView.imageView.image = icon
    }

    private func setupHintView() {
        guard hintView == nil else {
            return
        }

        let view = BorderedIconLabelView()
        view.iconDetailsView.stackView.alignment = .top
        view.iconDetailsView.mode = .iconDetails
        view.iconDetailsView.iconWidth = 20.0
        view.iconDetailsView.spacing = 12.0
        view.iconDetailsView.detailsLabel.textColor = R.color.colorTextPrimary()
        view.iconDetailsView.detailsLabel.font = .caption1
        view.contentInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        view.backgroundView.fillColor = R.color.colorBlockBackground()!
        view.backgroundView.highlightedFillColor = R.color.colorBlockBackground()!
        view.backgroundView.cornerRadius = 12.0

        addSubview(view)

        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16.0)
            make.bottom.equalToSuperview().inset(bottomInset)
        }

        hintView = view
    }

    private func clearHintView() {
        hintView?.removeFromSuperview()
        hintView = nil
    }

    private func applyFieldConstraints(for make: ConstraintMaker) {
        make.top.equalToSuperview().inset(10.0)
        make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
        make.height.equalTo(52.0)

        if let hintView = hintView {
            make.bottom.equalTo(hintView.snp.top).offset(-16.0)
        } else {
            make.bottom.equalToSuperview().inset(textBackgroundView.strokeWidth)
        }
    }

    private func updateFieldConstraints() {
        textBackgroundView.snp.remakeConstraints { make in
            applyFieldConstraints(for: make)
        }
    }

    func setupLayout() {
        addSubview(textBackgroundView)
        textBackgroundView.snp.makeConstraints { make in
            applyFieldConstraints(for: make)
        }

        textBackgroundView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(textBackgroundView.strokeWidth)
        }
    }
}
