import Foundation

enum SharedContainerGroup {
    static var name: String {
        #if F_RELEASE
            return "group.novafoundation.novawallettel"
        #else
            return "group.novafoundation.novawallettel"
        #endif
    }
}
