import Foundation
import UIKit.UIImage

struct PurchaseAction {
    let title: String
    let url: URL
    let icon: UIImage
    let displayURL: String
}

protocol PurchaseProviderProtocol {
    func with(appName: String) -> Self
    func with(logoUrl: URL) -> Self
    func with(colorCode: String) -> Self
    func with(callbackUrl: URL) -> Self
    func buildPurchaseActions(
        for chainAsset: ChainAsset,
        accountId: AccountId
    ) -> [PurchaseAction]
}

extension PurchaseProviderProtocol {
    func with(appName _: String) -> Self {
        self
    }

    func with(logoUrl _: URL) -> Self {
        self
    }

    func with(colorCode _: String) -> Self {
        self
    }

    func with(callbackUrl _: URL) -> Self {
        self
    }
}
