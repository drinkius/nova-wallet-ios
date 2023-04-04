extension String {
    enum Separator: String.Element {
        case slash = "/"
        case colon = ":"
    }

    func split(by separator: Separator, maxSplits: Int = .max) -> [String] {
        split(separator: separator.rawValue, maxSplits: maxSplits).map { String($0) }
    }
}
