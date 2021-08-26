import UIKit
import Charts

protocol FWChartViewDelegate: AnyObject {
    func didSelectXValue(_ value: Double)
    func didUnselect()
}

protocol FWChartViewProtocol where Self: UIView {
    func setChartData(_ data: ChartData)
    var chartDelegate: FWChartViewDelegate? { get set }
}

final class FWBarChartView: BarChartView {
    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    weak var chartDelegate: FWChartViewDelegate?

    let xAxisFormmater = ChartAxisFormmatter()

    override init(frame: CGRect) {
        super.init(frame: frame)

        delegate = self
        backgroundColor = .clear
        chartDescription?.enabled = false

        autoScaleMinMaxEnabled = true
        doubleTapToZoomEnabled = false
        maxVisibleCount = 40
        drawBarShadowEnabled = false
        drawValueAboveBarEnabled = false
        highlightFullBarEnabled = false

        xAxis.gridLineDashLengths = [2.5, 2.5]
        xAxis.gridLineDashPhase = 0
        xAxis.gridColor = UIColor.white.withAlphaComponent(0.64)
        xAxis.labelFont = .p3Paragraph
        xAxis.labelPosition = .bottom
        xAxis.valueFormatter = xAxisFormmater

        leftAxis.labelCount = 2
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: formatter)
        leftAxis.labelFont = .systemFont(ofSize: 8, weight: .semibold)
        leftAxis.labelTextColor = UIColor.white.withAlphaComponent(0.64)
        leftAxis.axisMinimum = 0

        rightAxis.enabled = false
        drawBordersEnabled = false
        minOffset = 0
        legend.enabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FWBarChartView: FWChartViewProtocol {
    func setChartData(_ data: ChartData) {
        let dataEntries = data.amounts.enumerated().map { index, amount in
            BarChartDataEntry(x: Double(index), yValues: [amount])
        }

        let set = BarChartDataSet(entries: dataEntries)
        set.drawIconsEnabled = false
        set.drawValuesEnabled = false
        set.colors = [
            R.color.colorAccent()!
        ]

        xAxisFormmater.xAxisValues = data.xAxisValues
        xAxis.labelCount = data.xAxisValues.count

        let data = BarChartData(dataSet: set)
        data.barWidth = 0.4

        self.data = data
        animate(yAxisDuration: 0.3, easingOption: .easeInOutCubic)
    }
}

extension FWBarChartView: ChartViewDelegate {
    func chartValueSelected(_: ChartViewBase, entry: ChartDataEntry, highlight _: Highlight) {
        chartDelegate?.didSelectXValue(entry.x)
    }

    func chartValueNothingSelected(_: ChartViewBase) {
        chartDelegate?.didUnselect()
    }
}

class ChartAxisFormmatter: IAxisValueFormatter {
    var xAxisValues = [String]()

    func stringForValue(_: Double, axis _: AxisBase?) -> String {
        ""
    }
}